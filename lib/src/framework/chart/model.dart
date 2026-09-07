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
/// [autoActivate] 是否在首次声明或从 false 变为 true 时自动激活。
/// [paintMode] 控制多指标图一起的绘制方式。
///   [PaintMode.combine] 多指标时，统一使用父 Indicator 的高度和 padding。
///   [PaintMode.alone] 多指标时，使用自己的 height 进行绘制。
/// [zIndex] 确定指标在绘制时的顺序，按升序排序；数值大的将会绘制在数值小的上面；
///   主要在 [MainPaintObjectIndicator] 中有用，确定多个指标在同一区域的绘制顺序。
abstract class Indicator<K extends IIndicatorKey> {
  Indicator({
    required this.key,
    required this.height,
    required this.padding,
    required this.autoActivate,
    this.paintMode = PaintMode.combine,
    this.zIndex = 0,
  });

  final K key;

  double height;

  final EdgeInsets padding;

  /// 是否在首次声明或从 false 变为 true 时自动激活。
  ///
  /// 该属性只触发自动 show；变为 false 不会自动 hide。
  final bool autoActivate;

  final PaintMode paintMode;

  final int zIndex;

  @factory
  PaintObject<Indicator<K>> createPaintObject();

  Map<String, dynamic> toJson() => const {};
}

/// 普通指标配置基类
///
/// 用于 Candle、Time、Main、Volume 等框架内置指标，不占 slot。
/// 对应 [DirectPaintObject]。
abstract class DirectIndicator extends Indicator<DirectIndicatorKey> {
  DirectIndicator({
    required super.key,
    required super.height,
    required super.padding,
    super.autoActivate = false,
    super.paintMode,
    super.zIndex,
  });

  @override
  DirectPaintObject<DirectIndicator> createPaintObject();
}

/// 数据指标配置基类
///
/// 用于 KDJ、MACD、MA 等需要 precompute 并写入 FlexiCandleModel.slots 的指标。
/// 注册时会分配 dataIndex，对应 [ComputedPaintObject]。
abstract class ComputedIndicator extends Indicator<ComputedIndicatorKey> {
  ComputedIndicator({
    required super.key,
    required super.height,
    required super.padding,
    super.autoActivate = false,
    super.paintMode,
    super.zIndex,
  });

  @override
  ComputedPaintObject<ComputedIndicator> createPaintObject();

  /// 创建该指标的计算器（平行于 [createPaintObject]）。
  ///
  /// [dataIndex] 由 [IndicatorPaintObjectManager] 在分配 slot 后注入。
  /// 每个 [ComputedIndicator] 都必须提供计算器：计算已从 PaintObject 下沉到
  /// [IndicatorCalculator]，由 [KlineDataPipeline] 驱动。
  @factory
  IndicatorCalculator createCalculator(int dataIndex);

  /// 指标计算参数。
  ///
  /// 用于判断配置变化后是否需要重新预计算。
  dynamic get calcParam => null;

  /// 指标配置参数发生变化时，判断是否需要整段重新计算。
  ///
  /// 默认比较 [calcParam]。由 [IndicatorPaintObjectManager] 在声明更新时调用，
  /// 决定是否重建计算器并上报重算。
  bool shouldRecompute(covariant ComputedIndicator oldIndicator) {
    return oldIndicator.calcParam != calcParam && calcParam != null;
  }
}

/// 业务指标配置基类
///
/// 用于 Trade 等由业务数据或用户操作驱动的指标，不占 slot。
/// 对应 [ExternalPaintObject]。
abstract class ExternalIndicator extends Indicator<ExternalIndicatorKey> {
  ExternalIndicator({
    required super.key,
    required super.height,
    required super.padding,
    super.autoActivate = true,
    super.paintMode,
    super.zIndex,
  });

  @override
  ExternalPaintObject<ExternalIndicator> createPaintObject();
}

/// 蜡烛指标配置基类
///
/// 使用 [DirectIndicatorKey]，属于基础/系统指标，不占 slot。
abstract class CandleBaseIndicator extends DirectIndicator {
  /// 网格线的默认线样式, 沿用 grid 层边框的口径。
  static const defaultGridLine = LineConfig(
    type: LineType.solid,
    dashes: [2, 2],
    paint: PaintConfig(strokeWidth: defaultAuxiliaryLineWidth),
  );

  /// 主区横线默认按 nice 取整: 横线即价格刻度线, 值要好读。
  static const defaultHorizontalGrid = GridAxisConfig(
    mode: GridTickMode.nice(targetDivisions: 5),
    line: defaultGridLine,
  );

  /// 主区竖线默认按数量等分: 竖线是几何参考线, 位置与任何值都无关。
  static const defaultVerticalGrid = GridAxisConfig(
    mode: GridTickMode.count(5),
    line: defaultGridLine,
  );

  CandleBaseIndicator({
    required super.height,
    required super.padding,
    super.paintMode,
    super.zIndex,
    this.horizontalGrid = defaultHorizontalGrid,
    this.verticalGrid = defaultVerticalGrid,
  }) : super(key: candleIndicatorKey, autoActivate: true);

  /// 主区横向网格线(即 Y 轴价格刻度线)的配置。
  final GridAxisConfig horizontalGrid;

  /// 主区纵向网格线(几何参考线)的配置。
  ///
  /// [GridTickMode.nice] 在此不成立, 会退化为 [GridTickMode.count]: 竖线永不按时间取整,
  /// 否则网格会随平移缩放持续漂移。
  final GridAxisConfig verticalGrid;

  @override
  CandleBasePaintObject<CandleBaseIndicator> createPaintObject();
}

/// 时间指标配置基类
///
/// 使用 [DirectIndicatorKey]，属于基础/系统指标，不占 slot。
abstract class TimeBaseIndicator extends DirectIndicator {
  TimeBaseIndicator({
    required super.height,
    required super.padding,
    super.paintMode,
    super.zIndex,
    required this.position,
  }) : super(key: timeIndicatorKey, autoActivate: true);

  final DrawPosition position;

  @override
  TimeBasePaintObject<TimeBaseIndicator> createPaintObject();
}

/// MainIndicator 的配置
///
/// 使用 [DirectIndicatorKey]，属于基础/系统指标，不占 slot。
/// [children] 存储当前主区已选中的子指标 Key 集合。
@CopyWith()
@FlexiIndicatorSerializable
class MainPaintObjectIndicator<T extends Indicator<IIndicatorKey>> extends Indicator {
  MainPaintObjectIndicator({
    required this.size,
    required super.padding,
    this.drawBelowTipsArea = false,
    Set<IIndicatorKey>? children,
  })  : children = children ?? <IIndicatorKey>{},
        super(key: mainIndicatorKey, height: size.height, autoActivate: true);

  late Size size;

  @override
  double get height => size.height;
  final bool drawBelowTipsArea;

  /// 当前主区已选中指标集合（由 PaintObjectManager 管理）
  final Set<IIndicatorKey> children;

  @override
  MainPaintObject createPaintObject() {
    return MainPaintObject();
  }

  factory MainPaintObjectIndicator.fromJson(Map<String, dynamic> json) => _$MainPaintObjectIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MainPaintObjectIndicatorToJson(this);
}
