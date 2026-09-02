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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// 测试用 [PaintContext] 假实现。
///
/// 所有方法返回安全默认值，用于不依赖真实绑定逻辑的单元测试。
class FakePaintContext implements PaintContext {
  @override
  IFlexiKlineTheme get theme => const _FakeTheme();

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
  bool get canUpdateLayoutHeight => false;

  /// 由测试驱动的缩放态；缩放中 `isFirstDrawTipsArea` 为 false，绘制期不参与 padding 计算。
  @override
  bool isChartZooming = false;

  @override
  double get startCandleDx => 0;

  @override
  double get paintDxOffset => 0;

  /// 由测试驱动的 cross 态；决定 tips 走 `doPaintChart` 还是 `doPaintCross` 分支。
  @override
  bool isCrossing = false;

  @override
  KlineData get klineData => KlineData.empty;

  @override
  ValueListenable<KlineSpec> get klineSpecListenable =>
      ValueNotifier(const KlineSpec(symbol: '', interval: invalidInterval));

  @override
  ValueListenable<KlineLoadingState> get loadingStateListenable => ValueNotifier(KlineLoadingState.none);

  @override
  SettingConfig get settingConfig => const SettingConfig();

  @override
  GridConfig get gridConfig => const GridConfig();

  @override
  CrossConfig get crossConfig => const CrossConfig();

  @override
  GestureConfig get gestureConfig => GestureConfig();

  @override
  double get candleWidth => 8;

  @override
  double get candleSpacing => 1;

  @override
  double get candleActualWidth => 9;

  @override
  double get candleWidthHalf => 4;

  @override
  FlexiNum? dyToCandleValue(double dy, {bool check = false}) => null;

  @override
  double candleValueToDy(FlexiNum value, {bool correct = false}) => 0;

  @override
  Rect get canvasRect => Rect.zero;

  /// 由测试驱动的主区区域；默认 [Rect.zero]，需要非零 `chartRect.height`（例如断言
  /// `dyFactor`）的测试自行赋值。
  @override
  Rect mainRect = Rect.zero;

  @override
  Rect get subRect => Rect.zero;

  @override
  Rect get timeRect => Rect.zero;

  @override
  Rect get chartZoomSlideBarRect => Rect.zero;

  @override
  double calculatePaneTop(int slot) => 0;

  @override
  Offset? get crossOffset => null;

  @override
  void requestCancelCross() {}

  @override
  void requestMoveToInitialPosition() {}

  @override
  void requestReleasePaintObject(PaintObject object) {}

  @override
  void reportChartZoomSlideBarRect(Rect rect) {}

  @override
  int? getComputedDataIndex(ComputedIndicatorKey key) => null;

  @override
  int get computedDataCapacity => 0;

  @override
  void requestRepaint() {}
}

/// 将 slot 查询代理到真实 manager，供 precompute 等需要读 slot 的集成测试。
class ManagerBackedPaintContext extends FakePaintContext {
  ManagerBackedPaintContext(this.manager);

  final IndicatorPaintObjectManager manager;

  @override
  int? getComputedDataIndex(ComputedIndicatorKey key) => manager.getComputedDataIndex(key);

  @override
  int get computedDataCapacity => manager.computedDataCapacity;
}

/// 内联的最小 [IFlexiKlineTheme] 实现，避免外部依赖。
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
