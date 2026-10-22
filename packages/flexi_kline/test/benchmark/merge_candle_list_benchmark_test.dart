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
  final report = BenchReport('merge_candle_list', config: {'candles': 2000, 'history': 500, 'rounds': 7});
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

  test('merge candle list 增量路径: 更新最新一根与追加历史', () async {
    const spec = KlineSpec(symbol: 'BENCH', interval: invalidInterval);
    final candles = await genRandomCandleList(count: 2000);
    // 默认日线、按时间倒序: 历史从最早一根的前一天开始。
    final earliest = DateTime.fromMillisecondsSinceEpoch(candles.last.timestamp);
    final history = await genRandomCandleList(count: 500, dateTime: earliest.subtract(const Duration(days: 1)));

    final data = KlineData(spec)..replace(candles, slotCount: 0);
    // 同一时间戳的两个报价交替推送。
    final ticks = [candles.first, candles.first.copyWith(close: candles.first.high)];
    report.measure(
      'merge/update-latest/1',
      () {
        for (int i = 0; i < 100; i++) {
          data.updateLatest([ticks[i % 2]], slotCount: 0);
        }
      },
      rounds: 7,
      perRound: 100,
      unit: 'us/op',
    );
    expect(data.length, candles.length, reason: '前置：同一时间戳只更新、不新增');

    // 每次追加都要一份未追加过的数据; 预先建好, 不计入计时。
    final pool = [for (int i = 0; i < 8 * 10; i++) KlineData(spec)..replace(candles, slotCount: 0)].iterator;
    report.measure(
      'merge/append-history/500',
      () {
        for (int i = 0; i < 10; i++) {
          pool.moveNext();
          pool.current.appendHistory(history, slotCount: 0);
        }
      },
      rounds: 7,
      perRound: 10,
      unit: 'us/op',
    );
    expect(pool.current.length, candles.length + history.length, reason: '前置：历史要接在已有数据之后');
  });
}
