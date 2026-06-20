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
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
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
    kd.mergeCandleList(candles, computedDataCount: m.computedDataCount);

    final sw = Stopwatch()..start();
    for (int i = 0; i < 50; i++) {
      await kd.precomputeKlineData(
        computedDataCount: m.computedDataCount,
        newList: candles,
        mainPaintObjects: m.mainPaintObject.children,
        subPaintObjects: const [],
        reset: true,
      );
    }
    sw.stop();
    debugPrint(
        'precompute: 50x(1000 candles x $indicatorCount indicators) in ${sw.elapsedMilliseconds}ms');
    expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(0));
  });
}
