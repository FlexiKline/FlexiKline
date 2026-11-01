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

import 'package:flexi_kline_benchmark/src/data/candles.dart';
import 'package:flutter_test/flutter_test.dart';

/// 基准数据必须逐位可复现: 不同次运行、不同设备读数的差异只能来自渲染, 不能来自输入。
void main() {
  List<Map<String, dynamic>> dump({int count = 50, int offset = 0}) =>
      benchCandles(count: count, offset: offset).map((c) => c.toJson()).toList();

  test('same parameters produce identical candles', () {
    expect(dump(), dump());
    expect(dump(offset: 7), dump(offset: 7));
  });

  test('a different offset (seed) produces different candles', () {
    expect(dump(offset: 0), isNot(dump(offset: 50)));
    expect(dump(offset: 0).map((c) => c['close']), isNot(dump(offset: 50).map((c) => c['close'])));
  });

  test('a different count changes the series', () {
    expect(dump(count: 50), isNot(dump(count: 51)));
    expect(benchCandles(count: 51), hasLength(51));
  });

  test('candles are ascending and a history page is contiguous with the latest page', () {
    final latest = benchCandles(count: 20);
    final history = benchCandles(count: 20, offset: 20);
    final all = [...history, ...latest];
    for (var i = 1; i < all.length; i++) {
      expect(all[i].timestamp, greaterThan(all[i - 1].timestamp));
    }
    expect(latest.first.timestamp - history.last.timestamp, 60000);
  });
}
