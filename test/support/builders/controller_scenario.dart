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

/// Controller 级薄 arrange 脚手架。
library;

import 'package:flexi_kline/flexi_kline.dart';

import '../doubles/fake_kline_config.dart';
import '../doubles/test_indicators.dart';

/// Controller 级场景构建器
class ControllerScenario {
  ControllerScenario({FakeFlexiKlineConfiguration? config})
      : controller = FlexiKlineController(
          configuration: config ?? FakeFlexiKlineConfiguration(),
        );

  final FlexiKlineController controller;

  /// switch → update → mount → initState 完整链。
  Future<void> initWithData(
    KlineSpec spec,
    List<CandleModel> candles, {
    List<Indicator> mainIndicators = const [],
    List<Indicator> subIndicators = const [],
  }) async {
    controller.switchKlineData(spec);
    controller.replaceKlineData(spec, candles);
    controller.mountIndicators(
      candle: TestCandleIndicator(),
      time: TestTimeIndicator(),
      mainIndicators: mainIndicators,
      subIndicators: subIndicators,
    );
    controller.initState();
  }

  void dispose() => controller.dispose();
}
