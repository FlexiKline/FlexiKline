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
  test('merge candle list 性能基线', () async {
    final candles = await genRandomCandleList(count: 2000);
    // genRandomCandleList with isHistory=true returns descending timestamps
    final spec = candles;

    final sw = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      final kd = KlineData(
        const KlineSpec(symbol: 'BENCH', interval: invalidInterval),
      );
      kd.mergeCandleList(spec, computedDataCount: 0);
    }
    sw.stop();
    debugPrint(
        'merge_candle_list: 100x2000 candles in ${sw.elapsedMilliseconds}ms');
    expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(0));
  });
}
