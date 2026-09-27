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

/// 绘制工具单测的支撑件。
///
/// 绘制工具的被测面是「一组屏幕坐标 → 命中判据与绘制产物」，与 K 线数据、手势、Widget
/// 布局都无关，所以这里给一个纯几何的 [DrawContext]：区域按参数给定，坐标换算走线性映射。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';

/// 纯几何 [DrawContext]。
///
/// 价格映射刻意用线性关系（`value = maxValue - dy`），让测试能直接手算 dy 与 value 的
/// 对应，不必构造 KlineData。时间映射同理按 [msPerPx] 线性换算。
class FakeDrawContext implements DrawContext {
  FakeDrawContext({
    this.mainRect = const Rect.fromLTRB(0, 0, 400, 300),
    this.timeRect = const Rect.fromLTRB(0, 300, 400, 320),
    DrawConfig? drawConfig,
    this.drawMagnet = MagnetMode.normal,
    this.maxValue = 300,
    this.msPerPx = 1000,
    this.selectedObject,
  }) : drawConfig = drawConfig ?? const DrawConfig(enable: true);

  @override
  final Rect mainRect;

  @override
  final Rect timeRect;

  @override
  final DrawConfig drawConfig;

  @override
  final MagnetMode drawMagnet;

  /// `dy == mainRect.top` 处对应的 value，向下线性递减。
  final double maxValue;

  /// 每像素代表的毫秒数。
  final double msPerPx;

  /// 当前选中(编辑态)的绘制对象；不指定即「无选中」，这是绘制产物断言的中性基线。
  DrawObject? selectedObject;

  @override
  Rect get canvasRect => Rect.fromLTRB(
    mainRect.left,
    mainRect.top,
    mainRect.right,
    timeRect.bottom,
  );

  @override
  IFlexiKlineTheme get theme => const _FakeTheme();

  @override
  KlineData get klineData => KlineData.empty;

  @override
  double get candleWidthHalf => 4;

  @override
  double? valueToDy(FlexiNum value, {bool correct = false}) {
    return maxValue - value.toDouble();
  }

  @override
  FlexiNum? dyToValue(double dy, {bool check = false}) {
    return FlexiNum.fromNum(maxValue - dy);
  }

  @override
  int? dxToTimestamp(double dx) => (dx * msPerPx).round();

  @override
  double? timestampToDx(int ts) => ts / msPerPx;

  @override
  int? dxToIndex(double dx) => dx.floor();

  @override
  double? indexToDx(int index, {bool check = false}) => index.toDouble();

  @override
  FlexiCandleModel? dxToCandle(double dx) => null;

  @override
  bool get isDebug => false;

  @override
  void logd(String msg, {Object? error, StackTrace? stackTrace}) {}
  @override
  void logi(String msg, {Object? error, StackTrace? stackTrace}) {}
  @override
  void logw(String msg, {Object? error, StackTrace? stackTrace}) {}
  @override
  void loge(String msg, {Object? error, StackTrace? stackTrace}) {}

  @override
  Map<String, dynamic>? getConfig(String key) => null;

  @override
  Future<bool> setConfig(String key, Map<String, dynamic> value) async => true;

  @override
  bool isSelectedDrawObject(DrawObject object) => selectedObject == object;
}

class _FakeTheme implements IFlexiKlineTheme {
  const _FakeTheme();

  @override
  Color get longColor => const Color(0xFF33BD65);
  @override
  Color get shortColor => const Color(0xFFE84E74);
  @override
  Color get chartBg => const Color(0xFFFFFFFF);
  @override
  Color get tooltipBg => const Color(0xFFF2F2F2);
  @override
  Color get countdownBg => const Color(0xFFBDBDBD);
  @override
  Color get crossTextBg => const Color(0xFF111111);
  @override
  Color get lastPriceBg => const Color(0x8A000000);
  @override
  Color get latestPriceBg => const Color(0xFF000000);
  @override
  Color get dragBg => const Color(0x33000000);
  @override
  Color get gridLineColor => const Color(0xFFE9EDF0);
  @override
  Color get crosshairColor => const Color(0xFF000000);
  @override
  Color get drawToolColor => const Color(0xFF448AFF);
  @override
  Color get markLineColor => const Color(0xFF2196F3);
  @override
  Color get lineChartColor => const Color(0xFF0066FF);
  @override
  Color get textColor => const Color(0xFF000000);
  @override
  Color get ticksTextColor => const Color(0xFF949494);
  @override
  Color get lastPriceColor => const Color(0xFF5F5F5F);
  @override
  Color get crossTextColor => const Color(0xFFFFFFFF);
  @override
  Color get tooltipTextColor => const Color(0xFF949494);
}
