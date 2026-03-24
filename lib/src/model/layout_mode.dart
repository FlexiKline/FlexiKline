// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:ui';

/// 布局模式
sealed class LayoutMode {
  const LayoutMode(this.prevMode);

  final LayoutMode? prevMode;

  Size get mainSize;

  /// 更新当前布局模式的[size]
  /// [sync] 是否同步到[mainSize]中.
  ///   Adapt模式下仅同步更新高度
  LayoutMode update(Size size, [bool sync = false]);

  bool get isFixed => this is FixedLayoutMode;
  bool get isAdapt => this is AdaptLayoutMode;
  bool get isNormal => this is NormalLayoutMode;
}

/// 正常模式(可自由调节宽高)
class NormalLayoutMode extends LayoutMode {
  const NormalLayoutMode(this.mainSize) : super(null);

  /// 主区正常模式下大小
  @override
  final Size mainSize;

  @override
  NormalLayoutMode update(Size size, [bool sync = false]) {
    return NormalLayoutMode(size);
  }
}

/// 自适应模式(Web/桌面端根据父布局[宽度]变化而变化)
class AdaptLayoutMode extends LayoutMode {
  /// 适配模式可以从正常模式进入
  const AdaptLayoutMode._(this.mainSize, [NormalLayoutMode? mode]) : super(mode);

  /// 根据[mainSize]与[mode]生成AdaptLayoutMode
  factory AdaptLayoutMode(Size mainSize, [LayoutMode? mode]) {
    switch (mode) {
      case null:
        return AdaptLayoutMode._(mainSize);
      case NormalLayoutMode():
        return AdaptLayoutMode._(mainSize, mode);
      case AdaptLayoutMode():
      case FixedLayoutMode():
        return AdaptLayoutMode._(
          mainSize,
          mode.prevMode is NormalLayoutMode ? mode.prevMode as NormalLayoutMode : null,
        );
    }
  }

  /// 主区适配宽度模式下大小
  @override
  final Size mainSize;

  @override
  AdaptLayoutMode update(Size size, [bool sync = false]) {
    if (prevMode != null && prevMode is NormalLayoutMode) {
      if (sync) {
        return AdaptLayoutMode._(
          size,
          NormalLayoutMode(Size(
            prevMode!.mainSize.width,
            size.height,
          )),
        );
      } else {
        return AdaptLayoutMode._(size, prevMode as NormalLayoutMode);
      }
    }
    return AdaptLayoutMode._(size);
  }
}

/// 固定大小模式(全屏/横屏)
class FixedLayoutMode extends LayoutMode {
  const FixedLayoutMode._(this.fixedSize, LayoutMode mode) : super(mode);

  /// 根据[fixedSize]和[mode]生成FixedLayoutMode
  factory FixedLayoutMode(Size fixedSize, LayoutMode mode) {
    switch (mode) {
      case NormalLayoutMode():
      case AdaptLayoutMode():
        return FixedLayoutMode._(fixedSize, mode);
      case FixedLayoutMode():
        assert(mode.prevMode != null, 'fixed prevMode must cannot be null');
        return FixedLayoutMode._(fixedSize, mode.prevMode!);
    }
  }

  /// 整体绘制区域固定大小
  final Size fixedSize;

  @override
  Size get mainSize {
    assert(prevMode != null, 'prevMode must cannot be null');
    return prevMode!.mainSize;
  }

  @override
  FixedLayoutMode update(Size size, [bool sync = false]) {
    assert(prevMode != null, 'prevMode must cannot be null');
    return FixedLayoutMode._(size, prevMode!);
  }
}
