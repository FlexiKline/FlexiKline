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

/// 数据合并契约: `replace` / `updateLatest` / `appendHistory` 的存储顺序与返回 Range。
///
/// - `replace` 按升序原样存入，`list.first` 最旧、`list.last` 最新。
/// - `updateLatest` 合并到尾部，返回被改写的尾段 `Range(tailStart, length)`。
/// - `appendHistory` 合并到头部，返回 `Range.fullRecompute`。
@Tags(['baseline'])
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const spec = KlineSpec(symbol: 'TEST', interval: invalidInterval);

  /// 按给定 ts 列表造蜡烛（close 恒 100，几何无关）。
  List<CandleModel> bars(List<int> tss) => [
    for (final ts in tss) CandleModel(timestamp: ts, open: '100', high: '101', low: '99', close: '100', volume: '1'),
  ];

  KlineData freshWith(List<int> tss) {
    final data = KlineData(spec, list: bars(tss).map((c) => c.toFlexiCandleModel(1, ComputeMode.fast)).toList());
    addTearDown(data.dispose);
    return data;
  }

  List<int> tssOf(KlineData data) => [for (final m in data.list) m.ts];

  group('replace baseline (ascending store)', () {
    test('merge_replace_keeps_old_to_new_order_and_full_recompute', () {
      final data = freshWith([]);
      final range = data.replace(bars([10, 20, 30, 40, 50]), slotCount: 1);
      // 批次升序原样存入；list.first=10（最旧）、list.last=50（最新）。
      expect(tssOf(data), [10, 20, 30, 40, 50]);
      expect(range, Range.fullRecompute);
    });
  });

  group('updateLatest baseline (ascending store)', () {
    test('merge_update_same_ts_in_place', () {
      // 同 ts 推送最新根：原地覆盖尾段，顺序与长度不变。
      final data = freshWith([30, 40, 50]);
      final range = data.updateLatest(bars([50]), slotCount: 1);
      expect(tssOf(data), [30, 40, 50]);
      expect(range, const Range(2, 3));
    });

    test('merge_update_new_candle_appends_to_tail', () {
      // 新一根（ts 更新）：截尾追加到尾部，已有下标不动。
      final data = freshWith([30, 40, 50]);
      final range = data.updateLatest(bars([50, 60]), slotCount: 1);
      expect(tssOf(data), [30, 40, 50, 60]);
      expect(range, const Range(2, 4));
    });

    test('merge_update_wrong_direction_returns_null', () {
      // 批次比现有数据更旧：方向错误，返回 null，数据不变。
      final data = freshWith([30, 40, 50]);
      final range = data.updateLatest(bars([10, 20]), slotCount: 1);
      expect(range, isNull);
      expect(tssOf(data), [30, 40, 50]);
    });
  });

  group('appendHistory baseline (ascending store)', () {
    test('merge_append_history_prepends_to_head', () {
      // 历史方向（更旧）：插到数组头部，返回全量重算。
      final data = freshWith([30, 40, 50]);
      final range = data.appendHistory(bars([10, 20]), slotCount: 1);
      expect(tssOf(data), [10, 20, 30, 40, 50]);
      expect(range, Range.fullRecompute);
    });

    test('merge_append_history_overlap_replaces_head', () {
      // 与头端重叠：覆盖重叠的历史根。
      final data = freshWith([30, 40, 50]);
      final range = data.appendHistory(bars([10, 20, 30]), slotCount: 1);
      expect(tssOf(data), [10, 20, 30, 40, 50]);
      expect(range, Range.fullRecompute);
    });

    test('merge_append_history_wrong_direction_returns_null', () {
      // 批次比最旧根更新：方向错误，返回 null。
      final data = freshWith([30, 40, 50]);
      final range = data.appendHistory(bars([60, 70]), slotCount: 1);
      expect(range, isNull);
      expect(tssOf(data), [30, 40, 50]);
    });
  });
}
