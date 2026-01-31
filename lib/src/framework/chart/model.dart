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
/// [K] 指标 Key 类型，用于区分指标类别（基础/数据/业务）。
/// [key] 唯一指定 Indicator。
/// [height] 指标图高度。
/// [padding] 限制指标图绘制区域。
/// [paintMode] 控制多指标图一起的绘制方式。
///   [PaintMode.combine] 多指标时，统一使用父 Indicator 的高度和 padding。
///   [PaintMode.alone] 多指标时，使用自己的 height 进行绘制。
/// [zIndex] 确定指标在绘制时的顺序，按升序排序；数值大的将会绘制在数值小的上面；
///   主要在 [MainPaintObjectIndicator] 中有用，确定多个指标在同一区域的绘制顺序。
abstract class Indicator<K extends IIndicatorKey> implements IPrecomputable {
  Indicator({
    required this.key,
    required this.height,
    required this.padding,
    this.paintMode = PaintMode.combine,
    this.zIndex = 0,
  });

  final K key;

  double height;

  final EdgeInsets padding;

  final PaintMode paintMode;

  final int zIndex;

  @factory
  PaintObject<Indicator<K>> createPaintObject(IPaintContext context);

  Map<String, dynamic> toJson() => const {};

  @override
  dynamic get calcParam => null;
}

/// 普通指标配置基类
///
/// 用于 Candle、Time、Main、Volume 等框架内置指标，不占 slot。
/// 对应 [NormalPaintObject]。
abstract class NormalIndicator extends Indicator<NormalIndicatorKey> {
  NormalIndicator({
    required super.key,
    required super.height,
    required super.padding,
    super.paintMode,
    super.zIndex,
  });

  @override
  NormalPaintObject<NormalIndicator> createPaintObject(IPaintContext context);
}

/// 数据指标配置基类
///
/// 用于 KDJ、MACD、MA 等需要 precompute 并写入 FlexiCandleModel.slots 的指标。
/// 注册时会分配 dataIndex，对应 [DataPaintObject]。
abstract class DataIndicator extends Indicator<DataIndicatorKey> {
  DataIndicator({
    required super.key,
    required super.height,
    required super.padding,
    super.paintMode,
    super.zIndex,
  });

  @override
  DataPaintObject<DataIndicator> createPaintObject(IPaintContext context);
}

/// 业务指标配置基类
///
/// 用于 Trade 等由业务数据或用户操作驱动的指标，不占 slot。
/// 对应 [BusinessPaintObject]。
abstract class BusinessIndicator extends Indicator<BusinessIndicatorKey> {
  BusinessIndicator({
    required super.key,
    required super.height,
    required super.padding,
    super.paintMode,
    super.zIndex,
  });

  @override
  BusinessPaintObject<BusinessIndicator> createPaintObject(
    IPaintContext context,
  );
}

/// 蜡烛指标配置基类
///
/// 使用 [NormalIndicatorKey]，属于基础/系统指标，不占 slot。
abstract class CandleBaseIndicator extends NormalIndicator {
  CandleBaseIndicator({
    required super.height,
    required super.padding,
    super.paintMode,
    super.zIndex,
  }) : super(key: candleIndicatorKey);

  @override
  CandleBasePaintObject<CandleBaseIndicator> createPaintObject(
    covariant IPaintContext context,
  );
}

/// 时间指标配置基类
///
/// 使用 [NormalIndicatorKey]，属于基础/系统指标，不占 slot。
abstract class TimeBaseIndicator extends NormalIndicator {
  TimeBaseIndicator({
    required super.height,
    required super.padding,
    super.paintMode,
    super.zIndex,
    required this.position,
  }) : super(key: timeIndicatorKey);

  final DrawPosition position;

  @override
  TimeBasePaintObject<TimeBaseIndicator> createPaintObject(
    IPaintContext context,
  );
}

/// MainIndicator 的配置
///
/// 使用 [NormalIndicatorKey]，属于基础/系统指标，不占 slot。
/// [children] 存储当前主区已选中的子指标 Key 集合。
@CopyWith()
@FlexiIndicatorSerializable
class MainPaintObjectIndicator<T extends Indicator<IIndicatorKey>> extends NormalIndicator {
  MainPaintObjectIndicator({
    required this.size,
    required super.padding,
    this.drawBelowTipsArea = false,
    Set<IIndicatorKey>? children,
  })  : children = children ?? <IIndicatorKey>{},
        super(key: mainIndicatorKey, height: size.height);

  late Size size;

  @override
  double get height => size.height;
  final bool drawBelowTipsArea;

  /// 当前主区已选中指标集合（由 PaintObjectManager 管理）
  final Set<IIndicatorKey> children;

  @override
  MainPaintObject createPaintObject(IPaintContext context) {
    return MainPaintObject(context: context, indicator: this);
  }

  factory MainPaintObjectIndicator.fromJson(Map<String, dynamic> json) => _$MainPaintObjectIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MainPaintObjectIndicatorToJson(this);
}
