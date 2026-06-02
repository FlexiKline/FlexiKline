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

/// 测试用 [PaintContext] 最小化实现
///
/// 提供 [PaintContext] 接口的空壳实现，用于不需要真实绑定环境的
/// 单元测试（如 [IndicatorPaintObjectManager] 的属性测试）。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'test_kline_config.dart';

class TestPaintContext implements PaintContext {
  @override
  IFlexiKlineTheme get theme => TestFlexiKlineTheme();

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
  @override
  bool get isChartZooming => false;
  @override
  double get startCandleDx => 0;
  @override
  double get paintDxOffset => 0;
  @override
  bool get isCrossing => false;
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
  @override
  Rect get mainRect => Rect.zero;
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
  void reportChartZoomSlideBarRect(Rect rect) {}
  @override
  int? getComputedDataIndex(ComputedIndicatorKey key) => null;
  @override
  int get computedDataCount => 0;
  @override
  void requestRepaint() {}
}
