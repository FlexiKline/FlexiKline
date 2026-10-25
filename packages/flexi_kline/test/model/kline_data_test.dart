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

import 'package:decimal/decimal.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

CandleModel _makeCandle(int ts) => CandleModel(
  timestamp: ts,
  open: Decimal.fromInt(1),
  high: Decimal.fromInt(1),
  low: Decimal.fromInt(1),
  close: Decimal.fromInt(1),
  volume: Decimal.fromInt(1),
);

void main() {
  group('indexAtOrBefore', () {
    KlineData createData(List<int> timestamps) {
      final data = KlineData(
        const KlineSpec(symbol: 'TEST', interval: invalidInterval),
      );
      data.replace(
        timestamps.map(_makeCandle).toList(),
        slotCount: 0,
      );
      return data;
    }

    test('精确时间戳返回对应真实蜡烛下标', () {
      final data = createData([100, 80, 50]);
      addTearDown(data.dispose);

      expect(data.indexAtOrBefore(100), 0);
      expect(data.indexAtOrBefore(80), 1);
      expect(data.indexAtOrBefore(50), 2);
    });

    test('时间缺口返回不晚于目标的最近真实蜡烛', () {
      final data = createData([100, 80, 50]);
      addTearDown(data.dispose);

      expect(data.indexAtOrBefore(90), 1);
      expect(data.indexAtOrBefore(79), 2);
    });

    test('空数据或目标超出已加载范围返回null', () {
      final empty = createData([]);
      final data = createData([100, 80, 50]);
      addTearDown(empty.dispose);
      addTearDown(data.dispose);

      expect(empty.indexAtOrBefore(80), isNull);
      expect(data.indexAtOrBefore(101), isNull);
      expect(data.indexAtOrBefore(49), isNull);
    });
  });
}
