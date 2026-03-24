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
