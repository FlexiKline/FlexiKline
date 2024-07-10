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

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../core/export.dart';
import 'common.dart';
import 'object.dart';
import 'serializers.dart';
import 'collection/sortable_hash_set.dart';

part 'indicator.g.dart';

/// Indicator绘制模式
///
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
///
/// [key] 唯一指定Indicator
/// [name] 用于展示
/// [height] 指标图高度
/// [padding] 限制指标图绘制区域
/// [paintMode] 控制多指标图一起的绘制方式.
///   [PaintMode.combine] 多指标时, 统一使用父Indicator的高度和padding.
///   [PaintMode.alone] 多指标时, 使用自己的height进行绘制.
abstract class Indicator {
  Indicator({
    required this.key,
    required this.name,
    required this.height,
    required this.padding,
    this.paintMode = PaintMode.combine,
  });

  final ValueKey key;
  final String name;
  double height;
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
    EdgeInsets? padding,
    bool reset = false,
  }) {
    bool hasChange = false;
    if (height != null && height > 0 && height != this.height) {
      this.height = height;
      hasChange = true;
    }

    if (padding != null && padding != this.padding) {
      this.padding = padding;
      hasChange = true;
    }
    if (reset || hasChange) {
      paintObject?.resetPaintBounding();
    }
    return reset || hasChange;
  }

  PaintObject createPaintObject(KlineBindingBase controller);

  @mustCallSuper
  void dispose() {
    paintObject?.dispose();
    paintObject = null;
  }

  Map<String, dynamic> toJson() => const {};

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
/// [zIndex] 确定指标在绘制时的顺序, 按升序排序; 数值大的将会绘制数值小的上面;
///   主要在[MultiPaintObjectIndicator]中会有用, 确定多个指标在同一区域的绘制顺序.
abstract class SinglePaintObjectIndicator extends Indicator
    implements Comparable<SinglePaintObjectIndicator> {
  SinglePaintObjectIndicator({
    required super.key,
    required super.name,
    required super.height,
    required super.padding,
    super.paintMode,
    this.zIndex = 0,
  });

  final int zIndex;

  @override
  SinglePaintObjectBox createPaintObject(
    covariant KlineBindingBase controller,
  );

  @override
  int compareTo(SinglePaintObjectIndicator other) {
    return zIndex.compareTo(other.zIndex);
  }
}

/// 多个绘制Indicator的配置.
///
/// [children] 维护具体的Indicator配置.
@CopyWith()
@FlexiIndicatorSerializable
class MultiPaintObjectIndicator<T extends SinglePaintObjectIndicator>
    extends Indicator {
  MultiPaintObjectIndicator({
    required super.key,
    required super.name,
    required super.height,
    required super.padding,
    this.drawBelowTipsArea = false,
    Iterable<T> children = const [],
  })  : children = SortableHashSet<T>.from(children),
        _initialPadding = padding;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final SortableHashSet<T> children;

  bool drawBelowTipsArea;

  final EdgeInsets _initialPadding;

  /// 当前[tipsHeight]是否需要更新布局参数
  bool needUpdateLayout(double tipsHeight) {
    return _initialPadding.top + tipsHeight != padding.top;
  }

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
      padding: indicator.paintMode.isCombine ? padding : null,
    );
    indicator.paintObject = indicator.createPaintObject(controller);
    indicator.paintObject!.parent = paintObject;
  }

  @override
  bool updateLayout({
    double? height,
    EdgeInsets? padding,
    bool reset = false,
    double? tipsHeight,
  }) {
    if (tipsHeight != null) {
      // 如果tipsHeight不为空, 说明是绘制过程中动态调整, 只需要在MultiPaintObjectIndicator原padding基础上增加即可.
      padding = _initialPadding.copyWith(
        top: _initialPadding.top + tipsHeight,
      );
    }
    bool hasChange = super.updateLayout(
      height: height,
      padding: padding,
      reset: reset,
    );
    for (var child in children) {
      final childChange = child.updateLayout(
        height: child.paintMode.isCombine ? this.height : null,
        padding: child.paintMode.isCombine ? this.padding : null,
        reset: reset,
      );
      hasChange = hasChange || childChange;
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
    // 使用前先解绑
    newIndicator.dispose();
    children.append(newIndicator)?.dispose();
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

extension IndicatorExt on Indicator {
  Map<ValueKey, dynamic> getCalcParams() {
    if (this is SinglePaintObjectIndicator) {
      return (this as SinglePaintObjectIndicator).getCalcParams();
    } else if (this is MultiPaintObjectIndicator) {
      return (this as MultiPaintObjectIndicator).getCalcParams();
    }
    return const <ValueKey, dynamic>{};
  }
}

extension SinglePaintObjectIndicatorExt on SinglePaintObjectIndicator {
  Map<ValueKey, dynamic> getCalcParams() {
    if (this is IPrecomputable) {
      return {key: (this as IPrecomputable).getCalcParam()};
    }
    return const <ValueKey, dynamic>{};
  }
}

extension MultiPaintObjectIndicatorExt on MultiPaintObjectIndicator {
  Map<ValueKey, dynamic> getCalcParams() {
    final results = <ValueKey, dynamic>{};
    for (var child in children) {
      results.addAll(child.getCalcParams());
    }
    return results;
  }
}
