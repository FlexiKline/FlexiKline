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

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../constant.dart';
import '../core/export.dart';
import 'object.dart';
import 'serializers.dart';

part 'indicator.g.dart';

/// Indicator绘制模式
/// 注: PaintMode仅当Indicator加入MultiPaintObjectIndicator后起作用,
/// 代表当前Indicator的绘制是否是独立绘制的, 还是依赖于MultiPaintObjectIndicator
enum PaintMode {
  /// 组合模式, Indicator会联合其他子Indicator一起绘制, 坐标系共享.
  combine,

  /// 独立模式下, Indicator会按自己height和minmax独立绘制.
  alone;

  bool get isCombine => this == PaintMode.combine;
}

/// 指标基础配置
/// tipsHeight: 绘制区域顶部提示信息区域的高度
/// padding: 绘制区域的边界设定
abstract class Indicator {
  Indicator({
    required this.key,
    required this.name,
    required this.height,
    this.tipsHeight = 0.0,
    this.padding = defaultIndicatorPadding,
    this.paintMode = PaintMode.combine,
  });
  final ValueKey key;
  final String name;
  double height;
  double tipsHeight;
  EdgeInsets padding;

  final PaintMode paintMode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Indicator) {
      return other.runtimeType == runtimeType && other.key == key;
    }
    return false;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  PaintObject? paintObject;

  void ensurePaintObject(KlineBindingBase controller) {
    paintObject ??= createPaintObject(controller);
  }

  bool updateLayout({
    double? height,
    double? tipsHeight,
    EdgeInsets? padding,
  }) {
    bool hasChange = false;
    if (height != null && height > 0 && height != this.height) {
      this.height = height;
      hasChange = true;
    }
    if (tipsHeight != null && tipsHeight > 0 && tipsHeight != this.tipsHeight) {
      this.tipsHeight = tipsHeight;
      hasChange = true;
    }
    if (padding != null && padding != this.padding) {
      this.padding = padding;
      hasChange = true;
    }
    // if (hasChange && paintObject != null) {
    //   paintObject?.resetDrawBounding();
    // }
    return hasChange;
    // tipsHeight = newVal.tipsHeight;
    // padding = newVal.padding;
    // if (paintMode == PaintMode.combine) {
    //   height = newVal.height;
    // }
  }

  PaintObject createPaintObject(KlineBindingBase controller);

  @mustCallSuper
  void dispose() {
    paintObject?.dispose();
    paintObject = null;
  }

  Map<String, dynamic> toJson();

  static bool canUpdate(Indicator oldIndicator, Indicator newIndicator) {
    return oldIndicator.runtimeType == newIndicator.runtimeType &&
        oldIndicator.key == newIndicator.key;
  }

  static bool isMultiIndicator(Indicator indicator) {
    return indicator is MultiPaintObjectIndicator;
  }
}

/// 绘制对象的配置
/// 通过Indicator去创建PaintObject接口
/// 缓存Indicator对应创建的paintObject.
abstract class SinglePaintObjectIndicator extends Indicator {
  SinglePaintObjectIndicator({
    required super.key,
    required super.name,
    required super.height,
    super.tipsHeight,
    super.padding,
    super.paintMode,
  });

  @override
  SinglePaintObjectBox createPaintObject(
    covariant KlineBindingBase controller,
  );
}

/// 多个绘制Indicator的配置.
/// children 维护具体的Indicator配置.
@FlexiIndicatorSerializable
class MultiPaintObjectIndicator<T extends SinglePaintObjectIndicator>
    extends Indicator {
  MultiPaintObjectIndicator({
    required super.key,
    required super.name,
    required super.height,
    super.tipsHeight,
    super.padding,
    this.drawChartAlawaysBelowTipsArea = false,
    Iterable<T> children = const [],
  }) : children = LinkedHashSet<T>.from(children);

  @JsonKey(includeFromJson: false, includeToJson: false)
  final Set<T> children;
  bool drawChartAlawaysBelowTipsArea;

  @override
  MultiPaintObjectBox createPaintObject(
    KlineBindingBase controller,
  ) {
    return MultiPaintObjectBox(controller: controller, indicator: this);
  }

  @override
  void ensurePaintObject(KlineBindingBase controller) {
    paintObject ??= createPaintObject(controller);
    for (var child in children) {
      if (child.paintObject?.parent != paintObject) {
        child.paintObject?.dispose();
        _initChildPaintObject(controller, child);
      }
    }
  }

  void _initChildPaintObject(
    KlineBindingBase controller,
    Indicator indicator,
  ) {
    indicator.updateLayout(
      height: indicator.paintMode.isCombine ? height : null,
      tipsHeight: tipsHeight,
      padding: padding,
    );
    indicator.paintObject = indicator.createPaintObject(controller);
    indicator.paintObject!.parent = paintObject;
  }

  @override
  bool updateLayout({double? height, double? tipsHeight, EdgeInsets? padding}) {
    final hasChange = super.updateLayout(
      height: height,
      tipsHeight: tipsHeight,
      padding: padding,
    );
    if (hasChange) {
      for (var child in children) {
        child.updateLayout(
          height: child.paintMode.isCombine ? this.height : null,
          tipsHeight: this.tipsHeight,
          padding: this.padding,
        );
      }
    }
    return hasChange;
  }

  void appendIndicators(Iterable<T> indicators, KlineBindingBase controller) {
    for (var indicator in indicators) {
      appendIndicator(indicator, controller);
    }
  }

  void appendIndicator(
    T newIndicator,
    KlineBindingBase controller,
  ) {
    Indicator? old;
    if (children.contains(newIndicator)) {
      old = children.lookup(newIndicator);
      old?.dispose();
    }
    children.add(newIndicator);
    if (paintObject != null) {
      // 说明当前父PaintObject已经创建, 需要及时创建新加入的newIndicator,
      _initChildPaintObject(controller, newIndicator);
    }
  }

  void deleteIndicator(Key key) {
    children.removeWhere((element) {
      if (element.key == key) {
        element.dispose();
        return true;
      }
      return false;
    });
  }

  // 从JSON映射转换为Response对象的工厂方法
  factory MultiPaintObjectIndicator.fromJson(Map<String, dynamic> json) =>
      _$MultiPaintObjectIndicatorFromJson(json);

  // 将Response对象转换为JSON映射的方法
  @override
  Map<String, dynamic> toJson() => _$MultiPaintObjectIndicatorToJson(this);
}
