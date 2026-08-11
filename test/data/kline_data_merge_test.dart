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

CandleModel _candle(int timestamp) => CandleModel(
      timestamp: timestamp,
      open: Decimal.one,
      high: Decimal.fromInt(2),
      low: Decimal.zero,
      close: Decimal.one,
      volume: Decimal.one,
    );

KlineData _data() => KlineData(const KlineSpec(symbol: 'T', interval: invalidInterval));

void main() {
  group('KlineData directional merge', () {
    test('replace 完整替换数据并要求全量计算', () {
      final data = _data();
      addTearDown(data.dispose);

      final range = data.replace([_candle(3), _candle(2), _candle(1)], slotCount: 2);

      expect(range, Range.fullRecompute);
      expect(data.list.map((item) => item.ts), [3, 2, 1]);
      expect(data.list.every((item) => item.slotCount == 2), isTrue);
    });

    test('updateLatest 覆盖头部并返回增量范围', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(3), _candle(2), _candle(1)], slotCount: 0);

      final range = data.updateLatest([_candle(4), _candle(3)], slotCount: 0);

      expect(range, const Range(0, 2));
      expect(data.list.map((item) => item.ts), [4, 3, 2, 1]);
    });

    test('updateLatest 覆盖同时间戳蜡烛时保留指标数据', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(2), _candle(1)], slotCount: 1);
      data.latest!.set(0, 42);
      final updated = CandleModel(
        timestamp: 2,
        open: Decimal.one,
        high: Decimal.fromInt(3),
        low: Decimal.zero,
        close: Decimal.fromInt(2),
        volume: Decimal.fromInt(4),
      );

      data.updateLatest([updated], slotCount: 1);

      expect(data.latest!.close.toDecimal(), Decimal.fromInt(2));
      expect(data.latest!.vol.toDecimal(), Decimal.fromInt(4));
      expect(data.latest!.get<int>(0), 42);
    });

    test('updateLatest 等长错位批次不继承其他蜡烛的指标数据', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(5), _candle(4), _candle(3)], slotCount: 1);
      data[0].set(0, 50);
      data[1].set(0, 40);
      data[2].set(0, 30);

      data.updateLatest([_candle(6), _candle(4), _candle(3)], slotCount: 1);

      expect(data.list.map((item) => item.ts), [6, 4, 3]);
      expect(data.list.map((item) => item.get<int>(0)), [null, 40, 30]);
    });

    test('updateLatest 跨过时间缺口仍保留匹配蜡烛的指标数据', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(5), _candle(4), _candle(3)], slotCount: 1);
      data[0].set(0, 50);
      data[1].set(0, 40);
      data[2].set(0, 30);

      data.updateLatest([_candle(6), _candle(5), _candle(3)], slotCount: 1);

      expect(data.list.map((item) => item.ts), [6, 5, 3]);
      expect(data.list.map((item) => item.get<int>(0)), [null, 50, 30]);
    });

    test('updateLatest 新旧混合批次保留重叠蜡烛的指标数据', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(3), _candle(2), _candle(1)], slotCount: 1);
      data[0].set(0, 30);
      data[1].set(0, 20);
      data[2].set(0, 10);

      data.updateLatest([_candle(4), _candle(3)], slotCount: 1);

      expect(data.list.map((item) => item.ts), [4, 3, 2, 1]);
      expect(data.list.map((item) => item.get<int>(0)), [null, 30, 20, 10]);
    });

    test('appendHistory 覆盖尾部并要求全量计算', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(3), _candle(2), _candle(1)], slotCount: 0);

      final range = data.appendHistory([_candle(1), _candle(0)], slotCount: 0);

      expect(range, Range.fullRecompute);
      expect(data.list.map((item) => item.ts), [3, 2, 1, 0]);
    });

    test('updateLatest 拒绝空批次和历史方向数据', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(3), _candle(2), _candle(1)], slotCount: 0);
      final before = List.of(data.list);

      expect(data.updateLatest([], slotCount: 0), isNull);
      expect(data.updateLatest([_candle(1), _candle(0)], slotCount: 0), isNull);
      expect(data.list, before);
    });

    test('appendHistory 拒绝空批次和最新方向数据', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(3), _candle(2), _candle(1)], slotCount: 0);
      final before = List.of(data.list);

      expect(data.appendHistory([], slotCount: 0), isNull);
      expect(data.appendHistory([_candle(4)], slotCount: 0), isNull);
      expect(data.list, before);
    });
  });
}
