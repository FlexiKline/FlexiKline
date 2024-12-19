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
    required this.height,
    required this.padding,
    this.paintMode = PaintMode.combine,
    this.zIndex = 0,
  });

  final IIndicatorKey key;

  double height;

  EdgeInsets padding;

  final PaintMode paintMode;

  final int zIndex; // TODO: 考虑下放到子类中

  @factory
  PaintObject createPaintObject(IPaintContext context);

  Map<String, dynamic> toJson() => const {};

  @override
  dynamic get calcParam => null;

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
    required super.height,
    required super.padding,
    super.paintMode,
    super.zIndex,
  });

  @override
  SinglePaintObjectBox createPaintObject(covariant IPaintContext context);
}

/// 多个绘制Indicator的配置.
/// TODO: 考虑与MultiPaintObjectBox一起更名为MainXXXPaintObject, 仅供MainIndicator使用, 后续再考虑扩展MultiPaintObject
@CopyWith()
@FlexiIndicatorSerializable
class MultiPaintObjectIndicator<T extends SinglePaintObjectIndicator>
    extends Indicator {
  MultiPaintObjectIndicator({
    required super.key,
    required Size size,
    required super.padding,
    this.drawBelowTipsArea = false,
  })  : _size = size,
        super(height: size.height);

  late Size _size;
  Size get size => _size;
  final bool drawBelowTipsArea;

  @override
  MultiPaintObjectBox createPaintObject(IPaintContext context) {
    return MultiPaintObjectBox(context: context, indicator: this);
  }

  // 从JSON映射转换为Response对象的工厂方法
  factory MultiPaintObjectIndicator.fromJson(Map<String, dynamic> json) =>
      _$MultiPaintObjectIndicatorFromJson(json);

  // 将Response对象转换为JSON映射的方法
  @override
  Map<String, dynamic> toJson() => _$MultiPaintObjectIndicatorToJson(this);
}
