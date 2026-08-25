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

/// Widget 测试：FlexiKlineWidget.indicator + IIndicatorConfig
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

/// 测试用 IIndicatorConfig 实现
class _FakeIndicatorConfig implements IIndicatorConfig {
  @override
  CandleBaseIndicator get candle => TestCandleIndicator();

  @override
  TimeBaseIndicator get time => TestTimeIndicator();

  @override
  List<Indicator> get mainIndicators => const [];

  @override
  List<Indicator> get subIndicators => const [];

  @override
  Map<String, dynamic>? getConfig(String key) => null;

  @override
  Future<bool> setConfig(String key, Map<String, dynamic> value) async => true;
}

void main() {
  group('v2.2.0/FlexiKlineWidget/indicator', () {
    testWidgets('FlexiKlineWidget.indicator 从 IIndicatorConfig 挂载', (tester) async {
      final controller = createChartController();
      final cfg = _FakeIndicatorConfig();

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 480,
              child: FlexiKlineWidget.indicator(
                controller: controller,
                indicatorConfig: cfg,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FlexiKlineWidget), findsOneWidget);
      expect(controller.isMounted, isTrue);

      await disposeChart(tester, controller);
    });
  });
}
