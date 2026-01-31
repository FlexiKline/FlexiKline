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

/// K线图绘制类型
sealed class FlexiChartType {
  const FlexiChartType();

  String get key;

  /// 全实心蜡烛图类型
  static const barSolid = FlexiBarChartType.allSolid;

  /// 全空心蜡烛图类型
  static const barHollow = FlexiBarChartType.allHollow;

  /// 上涨空心蜡烛图类型
  static const barUpHollow = FlexiBarChartType.upHollow;

  /// 下跌空心蜡烛图类型
  static const barDownHollow = FlexiBarChartType.downHollow;

  /// OHLC美国线类型
  static const barOhlc = FlexiBarChartType.ohlc;

  /// 普通折线图类型
  static const lineNormal = FlexiLineChartType.normal;

  /// 涨跌线图类型
  static const lineUpdown = FlexiLineChartType.updown;

  /// 支持的图表类型列表
  static const List<FlexiChartType> supportedTypes = [
    ...FlexiBarChartType.supportedTypes,
    ...FlexiLineChartType.supportedTypes,
  ];

  /// 创建蜡烛图类型
  ///
  /// [style] 蜡烛图样式，默认为 [ChartBarStyle.allSolid]
  factory FlexiChartType.bar([ChartBarStyle style = ChartBarStyle.allSolid]) {
    return FlexiBarChartType(style);
  }

  /// 创建线图类型
  ///
  /// [style] 线图样式，默认为 [ChartLineStyle.normal]
  factory FlexiChartType.line([ChartLineStyle style = ChartLineStyle.normal]) {
    return FlexiLineChartType(style);
  }

  /// 是否为线图类型
  bool get isLine => this is FlexiLineChartType;

  /// 是否为蜡烛图类型
  bool get isBar => this is FlexiBarChartType;
}

/// 蜡烛图类型，包含蜡烛图样式
final class FlexiBarChartType extends FlexiChartType {
  const FlexiBarChartType(this.style);

  final ChartBarStyle style;

  /// 全实心蜡烛图类型
  static const allSolid = FlexiBarChartType(ChartBarStyle.allSolid);

  /// 全空心蜡烛图类型
  static const allHollow = FlexiBarChartType(ChartBarStyle.allHollow);

  /// 上涨空心蜡烛图类型
  static const upHollow = FlexiBarChartType(ChartBarStyle.upHollow);

  /// 下跌空心蜡烛图类型
  static const downHollow = FlexiBarChartType(ChartBarStyle.downHollow);

  /// OHLC美国线类型
  static const ohlc = FlexiBarChartType(ChartBarStyle.ohlc);

  /// 蜡烛图类型列表
  static const List<FlexiBarChartType> supportedTypes = [
    allSolid,
    allHollow,
    upHollow,
    downHollow,
    ohlc,
  ];

  @override
  String get key => 'bar_${style.name}';

  @override
  bool operator ==(Object other) => identical(this, other) || other is FlexiBarChartType && style == other.style;

  @override
  int get hashCode => style.hashCode;
}

/// 线图类型，包含线图样式
final class FlexiLineChartType extends FlexiChartType {
  const FlexiLineChartType(this.style);

  final ChartLineStyle style;

  /// 普通折线图类型
  static const normal = FlexiLineChartType(ChartLineStyle.normal);

  /// 涨跌线图类型
  static const updown = FlexiLineChartType(ChartLineStyle.updown);

  /// 线图类型列表
  static const List<FlexiLineChartType> supportedTypes = [
    normal,
    updown,
  ];

  @override
  String get key => 'line_${style.name}';

  @override
  bool operator ==(Object other) => identical(this, other) || other is FlexiLineChartType && style == other.style;

  @override
  int get hashCode => style.hashCode;
}

/// K线柱状图的绘制样式
enum ChartBarStyle {
  allSolid, // 全实心
  allHollow, // 全空心
  upHollow, // 上涨空心
  downHollow, // 下跌空心
  ohlc; // Open-high-low-close chart(美国线)

  bool get isHollowUp => this == upHollow || this == allHollow;

  bool get isHollowDown => this == downHollow || this == allHollow;
}

/// K线线图的绘制样式
enum ChartLineStyle {
  normal, // 普通折线
  updown; // 涨跌线
}

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

/// 绘制位置
///
/// 主要是指定TimeIndicator的绘制位置
enum DrawPosition {
  // top, // 不支持
  middle,
  bottom,
}

/// 缩放位置
///
/// 将绘制区域宽度三等分, [auto] 会根据当前缩放开始时的焦点位置, 自行决定缩放位置.
enum ScalePosition {
  auto,
  left,
  middle,
  right,
}

/// 指标 Key 基类（sealed，仅允许三种子类型）
///
/// - [FlexiIndicatorKey]：基础/系统指标（Candle、Time、Main 等），不占 slot。
/// - [FlexiDataIndicatorKey]：数据指标（KDJ、MACD 等），占 slot，需要 precompute。
/// - [FlexiBusinessIndicatorKey]：业务指标（Trade 等），不占 slot，由业务数据驱动。
sealed class IIndicatorKey {
  String get id;
  String get label;
}

/// 基础/系统指标 Key
///
/// 用于 Candle、Time、Main 等框架内置指标，不参与 slot 分配。
final class FlexiIndicatorKey implements IIndicatorKey {
  const FlexiIndicatorKey(
    this.id, {
    String? label,
  }) : label = label ?? id;

  @override
  final String id;

  @override
  final String label;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlexiIndicatorKey &&
        runtimeType == other.runtimeType &&
        id == other.id;
  }

  @override
  int get hashCode {
    return runtimeType.hashCode ^ id.hashCode;
  }

  @override
  String toString() {
    return 'base:$id:$label';
  }
}

/// 数据指标 Key
///
/// 用于 KDJ、MACD、MA 等需要 precompute 并写入 FlexiCandleModel.slots 的指标。
/// 注册时会分配 dataIndex，对应 PaintDataIndicator / PaintDataObject。
final class FlexiDataIndicatorKey implements IIndicatorKey {
  const FlexiDataIndicatorKey(
    this.id, {
    String? label,
  }) : label = label ?? id;

  @override
  final String id;

  @override
  final String label;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlexiDataIndicatorKey &&
        runtimeType == other.runtimeType &&
        id == other.id;
  }

  @override
  int get hashCode {
    return runtimeType.hashCode ^ id.hashCode;
  }

  @override
  String toString() {
    return 'data:$id:$label';
  }
}

/// 业务指标 Key
///
/// 用于 Trade 等由业务数据或用户操作驱动的指标，不占 slot。
/// 对应 PaintBusinessIndicator / PaintBusinessObject。
final class FlexiBusinessIndicatorKey implements IIndicatorKey {
  const FlexiBusinessIndicatorKey(
    this.id, {
    String? label,
  }) : label = label ?? id;

  @override
  final String id;

  @override
  final String label;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlexiBusinessIndicatorKey &&
        runtimeType == other.runtimeType &&
        id == other.id;
  }

  @override
  int get hashCode {
    return runtimeType.hashCode ^ id.hashCode;
  }

  @override
  String toString() {
    return 'business:$id:$label';
  }
}

const unknownIndicatorKey = FlexiIndicatorKey('unknown');

typedef IndicatorBuilder<T extends Indicator<IIndicatorKey>> = T Function(
  Map<String, dynamic>?,
);

const mainIndicatorKey = FlexiIndicatorKey('main', label: 'Main');
const candleIndicatorKey = FlexiIndicatorKey('candle', label: 'Candle');
const timeIndicatorKey = FlexiIndicatorKey('time', label: 'Time');

/// 可预计算接口
/// 实现 [IPrecomputable] 接口, 即代表当前对象是可以进行预计算.
abstract interface class IPrecomputable {
  dynamic get calcParam;
}

const mainIndicatorSlot = -1;

/// 指标图的绘制边界接口
abstract interface class IPaintBoundingBox {
  void resetPaintBounding({int? slot});

  /// 当前指标图画笔可以绘制的范围
  Rect get drawableRect;

  /// 当前指标图绘制区域
  Rect get chartRect;

  /// 当前指标图顶部绘制区域
  Rect get topRect;

  /// 当前指标图底部绘制区域
  Rect get bottomRect;
}

/// 指标图的绘制数据初始化接口
abstract interface class IPaintDataInit {
  /// 最大值/最小值
  MinMax get minMax;

  /// 数据预计算
  /// 1. 仅在数据源[KlineData]发生变化时回调.
  void precompute(Range range, {bool reset = false});

  void setMinMax(MinMax val);
}

/// 指标图的绘制接口/指标图的Cross事件绘制接口
abstract interface class IPaintObject {
  /// 计算指标需要的数据, 并返回 [start ~ end) 之间MinMax.
  MinMax? initState(int start, int end);

  /// 绘制指标图
  void paintChart(Canvas canvas, Size size);

  /// 在所有指标图绘制结束后额外的绘制
  void paintExtraAboveChart(Canvas canvas, Size size);

  /// 绘制Cross上的刻度值
  void onCross(Canvas canvas, Offset offset);

  /// 绘制顶部tips信息
  Size? paintTips(
    Canvas canvas, {
    FlexiCandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  });
}
