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

library;

import 'package:decimal/decimal.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_indicators.dart';
import '../helpers/test_kline_config.dart';

void main() {
  group('FlexiKlineController initialization order', () {
    test('constructor should not throw before indicator sync', () {
      expect(
        () => FlexiKlineController(configuration: TestFlexiKlineConfiguration()),
        returnsNormally,
      );
    });

    testWidgets('updateKlineData before initState should queue waiting data', (tester) async {
      final controller = FlexiKlineController(
        configuration: TestFlexiKlineConfiguration(),
      );
      const spec = KlineSpec(symbol: 'TEST', interval: interval1m);

      controller.switchKlineData(spec);
      await controller.updateKlineData(
        spec,
        [
          CandleModel(
            timestamp: 1000,
            open: Decimal.parse('100'),
            high: Decimal.parse('110'),
            low: Decimal.parse('90'),
            close: Decimal.parse('105'),
            volume: Decimal.parse('1000'),
          ),
        ],
      );

      expect(controller.curKlineData.hasWaitingData, isTrue);
      expect(controller.curKlineData.isEmpty, isTrue);

      controller.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: const [],
      );
      controller.initState();
      controller.dispose();
    });
  });
}
