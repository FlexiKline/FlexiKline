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
///   主要在[MainPaintObjectIndicator]中会有用, 确定多个指标在同一区域的绘制顺序.
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

  final int zIndex;

  @factory
  PaintObject createPaintObject(IPaintContext context);

  Map<String, dynamic> toJson() => const {};

  @override
  dynamic get calcParam => null;
}

/// 绘制对象的配置
/// 通过Indicator去创建PaintObject接口
/// 缓存Indicator对应创建的paintObject.
abstract class PaintObjectIndicator extends Indicator {
  PaintObjectIndicator({
    required super.key,
    required super.height,
    required super.padding,
    super.paintMode,
    super.zIndex,
  });

  @override
  PaintObjectBox createPaintObject(IPaintContext context);
}

/// 蜡烛指标配置基类
abstract class CandleBaseIndicator extends Indicator {
  CandleBaseIndicator({
    required super.height,
    required super.padding,
    super.paintMode,
    super.zIndex,
  }) : super(key: candleIndicatorKey);

  @override
  CandleBasePaintObject createPaintObject(covariant IPaintContext context);
}

/// 时间指标配置基类
abstract class TimeBaseIndicator extends Indicator {
  TimeBaseIndicator({
    required super.height,
    required super.padding,
    super.paintMode,
    super.zIndex,
    required this.position,
  }) : super(key: timeIndicatorKey);

  final DrawPosition position;

  @override
  TimeBasePaintObject createPaintObject(IPaintContext context);
}

/// MainIndicator的配置.
@CopyWith()
@FlexiIndicatorSerializable
class MainPaintObjectIndicator<T extends PaintObjectIndicator>
    extends Indicator {
  MainPaintObjectIndicator({
    required Size size,
    required super.padding,
    this.drawBelowTipsArea = false,
    Set<IIndicatorKey>? indicatorKeys,
  })  : _size = size,
        indicatorKeys = indicatorKeys ?? <IIndicatorKey>{},
        super(key: mainIndicatorKey, height: size.height);

  late Size _size;
  Size get size => _size;
  final bool drawBelowTipsArea;

  /// 当前主区已选中指标集合(由PaintObjectManager管理)
  final Set<IIndicatorKey> indicatorKeys;

  @override
  MainPaintObject createPaintObject(IPaintContext context) {
    return MainPaintObject(context: context, indicator: this);
  }

  factory MainPaintObjectIndicator.fromJson(Map<String, dynamic> json) =>
      _$MainPaintObjectIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MainPaintObjectIndicatorToJson(this);
}
