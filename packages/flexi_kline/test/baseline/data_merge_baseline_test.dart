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

/// Step 1 翻转前基准（2.6.1 倒序）：数据合并契约。
///
/// 把 `KlineData.replace` / `updateLatest` / `appendHistory` 在一组脚本序列下的
/// **结果 ts 顺序** 与 **返回 Range** 冻结成可执行规格。当前倒序约定下：
///
/// - `replace` 原样存入（约定批次「新→旧」），`list[0]` 最新。
/// - `updateLatest` 合并最新方向，覆盖/前插到数组头部，返回 `Range(0, mergedLen)`。
/// - `appendHistory` 合并历史方向，追加到数组尾部，返回 `Range.fullRecompute`。
///
/// 数据正向化（v2.7.0）后，存储翻为「旧→新」（`list.last` 最新），本文件的每条
/// 期望都应翻成镜像：ts 序列整体反转，`updateLatest` 改为写尾段、`appendHistory`
/// 改为写头段。届时逐条改写期望即可，差异即契约翻转点。
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

  group('replace baseline (descending store)', () {
    test('merge_replace_keeps_new_to_old_order_and_full_recompute', () {
      final data = freshWith([]);
      final range = data.replace(bars([50, 40, 30, 20, 10]), slotCount: 1);
      // 约定批次新→旧，原样存入；list[0]=50（最新）。
      expect(tssOf(data), [50, 40, 30, 20, 10]);
      expect(range, Range.fullRecompute);
    });
  });

  group('updateLatest baseline (descending store)', () {
    test('merge_update_same_ts_in_place', () {
      // 同 ts 推送最新根：原地覆盖，顺序与长度不变。
      final data = freshWith([50, 40, 30]);
      final range = data.updateLatest(bars([50]), slotCount: 1);
      expect(tssOf(data), [50, 40, 30]);
      expect(range, const Range(0, 1));
    });

    test('merge_update_new_candle_prepends', () {
      // 新一根（ts 更新）：前插到数组头部，已有下标整体后移。
      final data = freshWith([50, 40, 30]);
      final range = data.updateLatest(bars([60, 50]), slotCount: 1);
      expect(tssOf(data), [60, 50, 40, 30]);
      expect(range, const Range(0, 2));
    });

    test('merge_update_wrong_direction_returns_null', () {
      // 批次比现有数据更旧：方向错误，返回 null，数据不变。
      final data = freshWith([50, 40, 30]);
      final range = data.updateLatest(bars([20, 10]), slotCount: 1);
      expect(range, isNull);
      expect(tssOf(data), [50, 40, 30]);
    });
  });

  group('appendHistory baseline (descending store)', () {
    test('merge_append_history_appends_to_tail', () {
      // 历史方向（更旧）：追加到数组尾部，返回全量重算。
      final data = freshWith([50, 40, 30]);
      final range = data.appendHistory(bars([20, 10]), slotCount: 1);
      expect(tssOf(data), [50, 40, 30, 20, 10]);
      expect(range, Range.fullRecompute);
    });

    test('merge_append_history_overlap_replaces_tail', () {
      // 与尾端重叠：覆盖重叠的历史根。
      final data = freshWith([50, 40, 30]);
      final range = data.appendHistory(bars([30, 20, 10]), slotCount: 1);
      expect(tssOf(data), [50, 40, 30, 20, 10]);
      expect(range, Range.fullRecompute);
    });

    test('merge_append_history_wrong_direction_returns_null', () {
      // 批次比最新根更新：方向错误，返回 null。
      final data = freshWith([50, 40, 30]);
      final range = data.appendHistory(bars([70, 60]), slotCount: 1);
      expect(range, isNull);
      expect(tssOf(data), [50, 40, 30]);
    });
  });
}
