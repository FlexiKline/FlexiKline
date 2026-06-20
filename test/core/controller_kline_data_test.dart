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

/// 集成测试：FlexiKlineController K线数据流转
library;

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'TEST', interval: FlexiTimeInterval(1, TimeUnit.day));

List<CandleModel> _candles(int n) => List.generate(
      n,
      (i) => CandleModel(
        timestamp: 1000 + i * 86400000,
        open: Decimal.fromInt(100 + i),
        high: Decimal.fromInt(110 + i),
        low: Decimal.fromInt(90 + i),
        close: Decimal.fromInt(105 + i),
        volume: Decimal.fromInt(1000 + i),
      ),
    );

void main() {
  group('v2.2.0/FlexiKlineController/kline_data', () {
    testWidgets('mount 前 update 暂存 waiting，initState 后数据可用', (tester) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);

      scene.controller.switchKlineData(_spec);
      await scene.controller.updateKlineData(_spec, _candles(3));

      // mount 前: waiting 有数据，klineData 空
      expect(scene.controller.klineData.hasWaitingData, isTrue);
      expect(scene.controller.klineData.isEmpty, isTrue);

      scene.controller.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: const [],
      );
      scene.controller.initState();

      // flushPendingKlineData 模拟 Widget initState 中的调用
      scene.controller.flushPendingKlineData();
      // 内部 scheduleTask 是异步的，需要 pumpAndSettle 让调度执行完成
      await tester.pumpAndSettle();

      // flush 后: waiting 清空，klineData 非空
      expect(scene.controller.klineData.hasWaitingData, isFalse);
      expect(scene.controller.klineData.isEmpty, isFalse);
    });
  });
}
