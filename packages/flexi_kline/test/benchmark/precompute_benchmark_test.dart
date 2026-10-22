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

@Tags(['benchmark'])
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/benchmark/bench_harness.dart';
import '../support/support.dart';

void main() {
  final report = BenchReport('precompute', config: {'candles': 1000, 'indicators': 10, 'rounds': 15});
  tearDownAll(report.write);

  test('precompute N candles x M indicators', () async {
    final candles = await genRandomCandleList(count: 1000);
    const indicatorCount = 10;

    final keys = List.generate(
      indicatorCount,
      (i) => ComputedIndicatorKey('bench_$i'),
    );

    final indicators = List.generate(
      indicatorCount,
      (i) => TestComputedIndicator(key: keys[i]),
    );

    final config = FakeFlexiKlineConfiguration(
      mainChildren: keys.cast<IIndicatorKey>().toSet(),
    );
    final ctx = FakePaintContext();
    final m = IndicatorPaintObjectManager(configuration: config);
    m.mountIndicators(
      candle: TestCandleIndicator(),
      time: TestTimeIndicator(),
      mainIndicators: indicators,
      subIndicators: const [],
      context: ctx,
    );

    // merge data
    final kd = KlineData(
      const KlineSpec(symbol: 'BENCH', interval: invalidInterval),
    );
    kd.replace(candles, slotCount: m.computedDataCapacity);

    final range = kd.computableRange;
    report.measure(
      'precompute/full/1000x$indicatorCount',
      () {
        for (int i = 0; i < 20; i++) {
          for (final calculator in m.visibleCalculators) {
            calculator.compute(kd, range, reset: true);
          }
        }
      },
      rounds: 15,
      perRound: 20,
      unit: 'us/op',
    );

    // 实时行情只重算最新一根: 增量区间 [0, 1)。
    report.measure(
      'precompute/latest/1000x$indicatorCount',
      () {
        for (int i = 0; i < 200; i++) {
          for (final calculator in m.visibleCalculators) {
            calculator.compute(kd, const Range(0, 1));
          }
        }
      },
      rounds: 15,
      perRound: 200,
      unit: 'us/op',
    );
  });
}
