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

part of 'indicator.dart';

/// 指标基础配置
///
/// [key] 唯一指定Indicator
/// [name] 用于展示
/// [height] 指标图高度
/// [padding] 限制指标图绘制区域
/// [paintMode] 控制多指标图一起的绘制方式.
///   [PaintMode.combine] 多指标时, 统一使用父Indicator的高度和padding.
///   [PaintMode.alone] 多指标时, 使用自己的height进行绘制.
/// [zIndex] 确定指标在绘制时的顺序, 按升序排序; 数值大的将会绘制数值小的上面;
///   主要在[MultiPaintObjectIndicator]中会有用, 确定多个指标在同一区域的绘制顺序.
abstract class Indicator implements IPrecomputable {
  Indicator({
    required this.key,
    required this.name,
    required this.height,
    required this.padding,
    this.paintMode = PaintMode.combine,
    this.zIndex = 0,
  });

  final IIndicatorKey key;

  /// TODO: 后续废弃
  @Deprecated('废弃, 使用key.label')
  final String name;

  double height;

  EdgeInsets padding;

  final PaintMode paintMode;

  final int zIndex; // TODO: 考虑下放到子类中

  // @override
  // bool operator ==(Object other) {
  //   if (identical(this, other)) return true;
  //   if (other is Indicator) {
  //     return other.runtimeType == runtimeType && other.key == key;
  //   }
  //   return false;
  // }

  // @override
  // int get hashCode {
  //   return key.hashCode;
  // }

  // PaintObject? _paintObject;
  // PaintObject? get paintObject => _paintObject;

  // void ensurePaintObject(IPaintContext context) {
  //   _paintObject ??= createPaintObject(context);
  // }

  // bool updateLayout({
  //   double? height,
  //   EdgeInsets? padding,
  //   bool reset = false,
  // }) {
  //   bool hasChange = false;
  //   if (height != null && height > 0 && height != this.height) {
  //     this.height = height;
  //     hasChange = true;
  //   }

  //   if (padding != null && padding != this.padding) {
  //     this.padding = padding;
  //     hasChange = true;
  //   }
  //   if (reset || hasChange) {
  //     paintObject?.resetPaintBounding();
  //   }
  //   return reset || hasChange;
  // }

  @factory
  PaintObject createPaintObject(IPaintContext context);

  // @mustCallSuper
  // void dispose() {
  //   _paintObject?.dispose();
  //   _paintObject = null;
  // }

  Map<String, dynamic> toJson() => const {};

  @override
  dynamic get calcParams => null;

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
    required super.padding,
    super.paintMode,
    super.zIndex,
  });

  @override
  SinglePaintObjectBox createPaintObject(covariant IPaintContext context);
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
  });
  //   Iterable<T> children = const [],
  // })  : children = SortableHashSet<T>.from(children),
  //       _initialPadding = padding;

  // @JsonKey(includeFromJson: false, includeToJson: false)
  // final SortableHashSet<T> children;

  bool drawBelowTipsArea;

  // final EdgeInsets _initialPadding;

  // /// 当前[tipsHeight]是否需要更新布局参数
  // bool needUpdateLayout(double tipsHeight) {
  //   return _initialPadding.top + tipsHeight != padding.top;
  // }

  @override
  MultiPaintObjectBox createPaintObject(IPaintContext context) {
    return MultiPaintObjectBox(context: context, indicator: this);
  }

  // @override
  // void ensurePaintObject(IPaintContext context) {
  //   _paintObject ??= createPaintObject(context);
  //   for (var child in children) {
  //     if (child.paintObject?._parent != paintObject) {
  //       child.paintObject?.dispose();
  //       _initChildPaintObject(context, child);
  //     }
  //   }
  // }

  // void _initChildPaintObject(
  //   IPaintContext context,
  //   Indicator indicator,
  // ) {
  //   indicator.updateLayout(
  //     height: indicator.paintMode.isCombine ? height : null,
  //     padding: indicator.paintMode.isCombine ? padding : null,
  //   );
  //   indicator._paintObject = indicator.createPaintObject(context);
  //   indicator._paintObject!._parent = paintObject;
  // }

  // @override
  // bool updateLayout({
  //   double? height,
  //   EdgeInsets? padding,
  //   bool reset = false,
  //   double? tipsHeight,
  // }) {
  //   if (tipsHeight != null) {
  //     // 如果tipsHeight不为空, 说明是绘制过程中动态调整, 只需要在MultiPaintObjectIndicator原padding基础上增加即可.
  //     padding = _initialPadding.copyWith(
  //       top: _initialPadding.top + tipsHeight,
  //     );
  //   }
  //   bool hasChange = super.updateLayout(
  //     height: height,
  //     padding: padding,
  //     reset: reset,
  //   );
  //   for (var child in children) {
  //     final childChange = child.updateLayout(
  //       height: child.paintMode.isCombine ? this.height : null,
  //       padding: child.paintMode.isCombine ? this.padding : null,
  //       reset: reset,
  //     );
  //     hasChange = hasChange || childChange;
  //   }
  //   return hasChange;
  // }

  // void appendIndicators(Iterable<T> indicators, IPaintContext context) {
  //   for (var indicator in indicators) {
  //     appendIndicator(indicator, context);
  //   }
  // }

  // void appendIndicator(
  //   T newIndicator,
  //   IPaintContext context,
  // ) {
  //   // 使用前先解绑
  //   newIndicator.dispose();
  //   children.append(newIndicator)?.dispose();
  //   if (paintObject != null) {
  //     // 说明当前父PaintObject已经创建, 需要及时创建新加入的newIndicator,
  //     _initChildPaintObject(context, newIndicator);
  //   }
  // }

  // void deleteIndicator(IIndicatorKey key) {
  //   children.removeWhere((element) {
  //     if (element.key == key) {
  //       element.dispose();
  //       return true;
  //     }
  //     return false;
  //   });
  // }

  // 从JSON映射转换为Response对象的工厂方法
  factory MultiPaintObjectIndicator.fromJson(Map<String, dynamic> json) =>
      _$MultiPaintObjectIndicatorFromJson(json);

  // 将Response对象转换为JSON映射的方法
  @override
  Map<String, dynamic> toJson() => _$MultiPaintObjectIndicatorToJson(this);
}
