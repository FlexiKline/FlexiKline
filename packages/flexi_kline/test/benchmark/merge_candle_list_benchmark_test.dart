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

import '../support/support.dart';

void main() {
  final report = BenchReport('merge_candle_list', config: {'candles': 2000, 'rounds': 7});
  tearDownAll(report.write);

  test('merge candle list 性能基线', () async {
    // genRandomCandleList with isHistory=true returns descending timestamps
    final candles = await genRandomCandleList(count: 2000);
    report.measure(
      'merge/replace/2000',
      () {
        for (int i = 0; i < 10; i++) {
          KlineData(const KlineSpec(symbol: 'BENCH', interval: invalidInterval)).replace(candles, slotCount: 0);
        }
      },
      rounds: 7,
      perRound: 10,
      unit: 'us/op',
    );
  });
}
