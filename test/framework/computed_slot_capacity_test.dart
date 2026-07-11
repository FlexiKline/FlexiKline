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

/// 回归：删除「中间」ComputedIndicator 后，容量不回退、新蜡烛仍能容纳高位存活指标。
///
/// 这是本次 bug 的最小确定性复现（[slot_test] 以随机属性覆盖容量不变量，
/// 此处补一个针对「删中间」这一原始 bug 场景的确定性 + 蜡烛写入端到端的守卫）：
/// `computedDataCapacity` 用来给新蜡烛的 slots 定长，旧实现删中间后回退，
/// 导致高位存活指标写入越界、`setList` 静默失败丢数据。
library;

import 'package:flexi_kline/flexi_kline.dart' show ComputeMode, ComputedIndicatorKey, IndicatorPaintObjectManager;
import 'package:flexi_kline/src/model/export.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

/// 构造一根按 [slotCount] 定长 slots 的新蜡烛，
/// 模拟 `mergeCandleList` 中的 `e.toFlexiCandleModel(slotCount, mode)`。
FlexiCandleModel mergedCandle(int slotCount) => FlexiCandleModel.init(
      candle: CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '110',
        low: '95',
        close: '105',
        volume: '1000',
      ),
      count: slotCount,
      mode: ComputeMode.fast,
    );

void main() {
  test('v2.2.0/ComputedSlot/删中间指标后新蜡烛仍能容纳高位存活指标', () {
    final manager = IndicatorPaintObjectManager(
      configuration: FakeFlexiKlineConfiguration(),
    );
    const a = ComputedIndicatorKey('a');
    const b = ComputedIndicatorKey('b'); // 中间，将被删除
    const c = ComputedIndicatorKey('c'); // 最高位，删 b 后仍存活
    manager.allocateComputedDataIndexes([a, b, c]); // 0, 1, 2

    manager.releaseComputedDataIndex(b); // 删中间

    final slotC = manager.getComputedDataIndex(c)!;
    // 容量为高水位：删中间后不回退，仍覆盖最高存活 slot。
    expect(manager.computedDataCapacity, greaterThan(slotC));

    // 走真实指标写入路径 getOrInitList(slot,len)[i]=v：
    // 旧实现下 slot 越界 → setList 返回 false 不写回 → 静默丢数据。
    final candle = mergedCandle(manager.computedDataCapacity);
    candle.getOrInitList<Object>(slotC, 1)[0] = 123;
    expect(candle.getList<Object>(slotC)?[0], 123, reason: 'C 的数据应真正写入蜡烛，不再被静默丢弃');
  });
}
