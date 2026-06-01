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

/// 属性测试：Slot FIFO 复用与 computedDataCount
///
/// **Validates: Requirements 5.2, 5.3, 5.4**
///
/// 验证 IndicatorPaintObjectManager 的 slot 管理核心不变量：
/// 1. computedDataCount 始终等于当前已注册 key 的数量
/// 2. 回收的 slot 按 FIFO 顺序被下一次注册复用
/// 3. 每个已注册的 ComputedIndicatorKey 拥有唯一的 slot index
/// 4. 所有已分配的 slot index >= 0 且互不重复
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:glados/glados.dart';

import '../helpers/indicator_test_helpers.dart';
import '../helpers/test_slot_ops.dart';

void main() {
  group(
    'Feature: widget-style-indicator-system-v4, '
    'Property 8: Slot FIFO 复用与 computedDataCount',
    () {
      // ---------------------------------------------------------------
      // 属性 1：computedDataCount 等于当前已注册 key 的数量
      // ---------------------------------------------------------------
      Glados(slotOpsGen, ExploreConfig(numRuns: 100)).test(
        'computedDataCount 始终等于当前已注册 key 的数量',
        (ops) {
          final manager = createManager();
          final registeredKeys = <ComputedIndicatorKey>{};

          for (final op in ops) {
            switch (op) {
              case TestRegisterOp(:final key):
                manager.allocateComputedDataIndexes([key]);
                registeredKeys.add(key);
              case TestRecycleOp(:final key):
                manager.releaseComputedDataIndex(key);
                registeredKeys.remove(key);
            }

            expect(
              manager.computedDataCount,
              equals(registeredKeys.length),
              reason: '执行 $op 后 computedDataCount 应等于已注册 key 数量 '
                  '${registeredKeys.length}，但实际为 '
                  '${manager.computedDataCount}',
            );
          }
        },
      );

      // ---------------------------------------------------------------
      // 属性 2：回收的 slot 按 FIFO 顺序被下一次注册复用
      // ---------------------------------------------------------------
      Glados(any.intInRange(2, 8), ExploreConfig(numRuns: 100)).test(
        '回收的 slot 按 FIFO 顺序被复用',
        (keyCount) {
          final manager = createManager();

          final keys = List.generate(keyCount, (i) => ComputedIndicatorKey('fifo_$i'));
          manager.allocateComputedDataIndexes(keys);

          final originalSlots = <ComputedIndicatorKey, int>{};
          for (final key in keys) {
            originalSlots[key] = manager.getComputedDataIndex(key)!;
          }

          final recycleCount = keyCount ~/ 2;
          final recycledKeys = keys.sublist(0, recycleCount);
          final recycledSlots = <int>[];
          for (final key in recycledKeys) {
            recycledSlots.add(originalSlots[key]!);
            manager.releaseComputedDataIndex(key);
          }

          for (int i = 0; i < recycledSlots.length; i++) {
            final newKey = ComputedIndicatorKey('new_$i');
            manager.allocateComputedDataIndexes([newKey]);
            expect(
              manager.getComputedDataIndex(newKey),
              equals(recycledSlots[i]),
              reason: '第 ${i + 1} 个新 key 应复用回收队列中的 slot '
                  '${recycledSlots[i]}',
            );
          }
        },
      );

      // ---------------------------------------------------------------
      // 属性 3：每个已注册 key 拥有唯一的 slot index
      // ---------------------------------------------------------------
      Glados(slotOpsGen, ExploreConfig(numRuns: 100)).test(
        '每个已注册的 ComputedIndicatorKey 拥有唯一的 slot index',
        (ops) {
          final manager = createManager();

          for (final op in ops) {
            switch (op) {
              case TestRegisterOp(:final key):
                manager.allocateComputedDataIndexes([key]);
              case TestRecycleOp(:final key):
                manager.releaseComputedDataIndex(key);
            }
          }

          final registeredSlots = <int>{};
          for (int i = 0; i < 10; i++) {
            final key = ComputedIndicatorKey('key_$i');
            final slot = manager.getComputedDataIndex(key);
            if (slot != null) {
              expect(registeredSlots.add(slot), isTrue, reason: 'slot $slot 被多个 key 共享，违反唯一性');
            }
          }
        },
      );

      // ---------------------------------------------------------------
      // 属性 4：所有 slot index >= 0 且唯一
      // ---------------------------------------------------------------
      Glados(slotOpsGen, ExploreConfig(numRuns: 100)).test(
        '所有已分配的 slot index >= 0 且互不重复',
        (ops) {
          final manager = createManager();

          for (final op in ops) {
            switch (op) {
              case TestRegisterOp(:final key):
                manager.allocateComputedDataIndexes([key]);
              case TestRecycleOp(:final key):
                manager.releaseComputedDataIndex(key);
            }
          }

          final assignedSlots = <int>{};
          for (int i = 0; i < 10; i++) {
            final key = ComputedIndicatorKey('key_$i');
            final slot = manager.getComputedDataIndex(key);
            if (slot != null) {
              expect(slot, greaterThanOrEqualTo(0), reason: 'key_$i 的 slot $slot < 0');
              expect(assignedSlots.add(slot), isTrue, reason: 'key_$i 的 slot $slot 与其他 key 重复');
            }
          }
        },
      );
    },
  );
}
