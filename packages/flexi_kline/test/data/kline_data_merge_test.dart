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
import 'package:flexi_formatter/date_time.dart' show TimeUnit;
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

      final range = data.replace([_candle(1), _candle(2), _candle(3)], slotCount: 2);

      expect(range, Range.fullRecompute);
      expect(data.list.map((item) => item.ts), [1, 2, 3]);
      expect(data.list.every((item) => item.slotCount == 2), isTrue);
    });

    test('updateLatest 追加尾部并返回增量范围', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(1), _candle(2), _candle(3)], slotCount: 0);

      final range = data.updateLatest([_candle(3), _candle(4)], slotCount: 0);

      // 覆盖尾段 [2, 3) 的 ts=3, 追加 ts=4 -> 尾段 [2, 4).
      expect(range, const Range(2, 4));
      expect(data.list.map((item) => item.ts), [1, 2, 3, 4]);
    });

    test('updateLatest 覆盖同时间戳蜡烛时保留指标数据', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(1), _candle(2)], slotCount: 1);
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
      data.replace([_candle(3), _candle(4), _candle(5)], slotCount: 1);
      data[0].set(0, 30);
      data[1].set(0, 40);
      data[2].set(0, 50);

      data.updateLatest([_candle(3), _candle(4), _candle(6)], slotCount: 1);

      expect(data.list.map((item) => item.ts), [3, 4, 6]);
      expect(data.list.map((item) => item.get<int>(0)), [30, 40, null]);
    });

    test('updateLatest 跨过时间缺口仍保留匹配蜡烛的指标数据', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(3), _candle(4), _candle(5)], slotCount: 1);
      data[0].set(0, 30);
      data[1].set(0, 40);
      data[2].set(0, 50);

      data.updateLatest([_candle(3), _candle(5), _candle(6)], slotCount: 1);

      expect(data.list.map((item) => item.ts), [3, 5, 6]);
      expect(data.list.map((item) => item.get<int>(0)), [30, 50, null]);
    });

    test('updateLatest 新旧混合批次保留重叠蜡烛的指标数据', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(1), _candle(2), _candle(3)], slotCount: 1);
      data[0].set(0, 10);
      data[1].set(0, 20);
      data[2].set(0, 30);

      data.updateLatest([_candle(3), _candle(4)], slotCount: 1);

      expect(data.list.map((item) => item.ts), [1, 2, 3, 4]);
      expect(data.list.map((item) => item.get<int>(0)), [10, 20, 30, null]);
    });

    test('prependHistory 覆盖头部并要求全量计算', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(1), _candle(2), _candle(3)], slotCount: 0);

      final range = data.prependHistory([_candle(0), _candle(1)], slotCount: 0);

      expect(range, Range.fullRecompute);
      expect(data.list.map((item) => item.ts), [0, 1, 2, 3]);
    });

    test('updateLatest 拒绝空批次和历史方向数据', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(1), _candle(2), _candle(3)], slotCount: 0);
      final before = List.of(data.list);

      expect(data.updateLatest([], slotCount: 0), isNull);
      expect(data.updateLatest([_candle(0), _candle(1)], slotCount: 0), isNull);
      expect(data.list, before);
    });

    test('prependHistory 拒绝空批次和最新方向数据', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(1), _candle(2), _candle(3)], slotCount: 0);
      final before = List.of(data.list);

      expect(data.prependHistory([], slotCount: 0), isNull);
      expect(data.prependHistory([_candle(4)], slotCount: 0), isNull);
      expect(data.list, before);
    });

    test('三个合并入口在 debug 下断言批次按时间升序', () {
      final data = _data();
      addTearDown(data.dispose);
      final descending = [_candle(3), _candle(2), _candle(1)];

      expect(() => data.replace(descending, slotCount: 0), throwsAssertionError);
      data.replace([_candle(4), _candle(5)], slotCount: 0);
      expect(() => data.updateLatest([_candle(7), _candle(6)], slotCount: 0), throwsAssertionError);
      expect(() => data.prependHistory([_candle(2), _candle(1)], slotCount: 0), throwsAssertionError);
      expect(() => data.replace([_candle(1), _candle(1)], slotCount: 0), throwsAssertionError, reason: '要求严格升序');
      expect(data.list.map((item) => item.ts), [4, 5]);
    });
  });

  group('KlineData labelOriginIndex', () {
    test('replace 归零, 头部插入加上净头插根数, 最新端更新不变', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([_candle(5), _candle(6), _candle(7)], slotCount: 0);
      expect(data.labelOriginIndex, 0);

      // ts=5 与已有蜡烛重叠, 净头插 2 根.
      data.prependHistory([_candle(3), _candle(4), _candle(5)], slotCount: 0);
      expect(data.labelOriginIndex, 2);

      data.updateLatest([_candle(7), _candle(8)], slotCount: 0);
      expect(data.labelOriginIndex, 2);

      data.replace([_candle(1)], slotCount: 0);
      expect(data.labelOriginIndex, 0);
    });

    test('加载历史前后, 原有蜡烛里被选作标签的时间戳不变', () {
      final data = _data();
      addTearDown(data.dispose);
      data.replace([for (var ts = 10; ts < 20; ts++) _candle(ts)], slotCount: 0);
      const step = 3;
      Set<int> labelTs({int fromTs = 10}) => {
        for (var i = 0; i < data.length; i++)
          if ((i - data.labelOriginIndex) % step == 0 && data[i].ts >= fromTs) data[i].ts,
      };
      final before = labelTs();

      // 净头插 2 根, 不是 step 的倍数: 只按下标取模时标签会整体错位.
      data.prependHistory([_candle(8), _candle(9)], slotCount: 0);

      expect(labelTs(), before);
    });
  });

  group('KlineData timestamp <-> float index', () {
    const minute = 60000;
    KlineData minuteData(List<int> minutes) {
      final data = KlineData(const KlineSpec(symbol: 'T', interval: FlexiTimeInterval(1, TimeUnit.minute)));
      data.replace([for (final m in minutes) _candle(m * minute)], slotCount: 0);
      return data;
    }

    test('整根命中整数下标, 缺口内按时间戳插值, 两端按周期外推', () {
      // 第 1、2 根之间缺 1 根: ts=2 落在两根的正中.
      final data = minuteData([0, 1, 3]);
      addTearDown(data.dispose);

      expect(data.timestampToFloatIndex(0), 0);
      expect(data.timestampToFloatIndex(1 * minute), 1);
      expect(data.timestampToFloatIndex(2 * minute), 1.5);
      expect(data.timestampToFloatIndex(3 * minute), 2);
      expect(data.timestampToFloatIndex(-1 * minute), -1);
      expect(data.timestampToFloatIndex(5 * minute), 4);
    });

    test('floatIndexToTimestamp 是逆映射; 非有限值返回 null', () {
      final data = minuteData([0, 1, 3]);
      addTearDown(data.dispose);

      for (final ts in [-2 * minute, 0, 30000, 2 * minute, 3 * minute, 6 * minute]) {
        expect(data.floatIndexToTimestamp(data.timestampToFloatIndex(ts)!), ts, reason: 'ts=$ts');
      }
      expect(data.floatIndexToTimestamp(double.nan), isNull);
      expect(data.floatIndexToTimestamp(double.infinity), isNull);
    });

    test('空数据或无效周期返回 null', () {
      final empty = minuteData([]);
      addTearDown(empty.dispose);
      expect(empty.timestampToFloatIndex(0), isNull);
      expect(empty.floatIndexToTimestamp(0), isNull);

      final invalid = _data();
      addTearDown(invalid.dispose);
      invalid.replace([_candle(1), _candle(2)], slotCount: 0);
      expect(invalid.timestampToFloatIndex(1), isNull);
    });
  });
}
