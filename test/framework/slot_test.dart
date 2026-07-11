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

/// 属性测试：Slot FIFO 复用与 computedDataCapacity
///
/// 验证 IndicatorPaintObjectManager 的 slot 管理核心不变量：
/// 1. computedDataCapacity 是高水位容量：恒 > 任意存活 slot 索引，且单调不减
/// 2. 回收的 slot 按 FIFO 顺序被下一次注册复用
/// 3. 每个已注册的 ComputedIndicatorKey 拥有唯一的 slot index
/// 4. 所有已分配的 slot index >= 0 且互不重复
library;

import 'dart:math';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  const numRuns = 100;

  group(
    'v2.2.0/IndicatorPaintObjectManager/slot',
    () {
      // ---------------------------------------------------------------
      // 属性 1：computedDataCapacity 是高水位容量
      //   - 恒 > 任意存活 key 的 slot 索引（新蜡烛才能容纳高位存活指标）
      //   - 一轮操作内单调不减（容量只增不减）
      // ---------------------------------------------------------------
      test(
        'computedDataCapacity 始终覆盖所有存活 slot 且单调不减',
        () {
          final rng = Random(300);
          for (int run = 0; run < numRuns; run++) {
            final ops = randomSlotOps(rng);
            final manager = IndicatorPaintObjectManager(
              configuration: FakeFlexiKlineConfiguration(),
            );
            final registeredKeys = <ComputedIndicatorKey>{};
            int prevCount = 0;

            for (final op in ops) {
              switch (op) {
                case TestRegisterOp(:final key):
                  manager.allocateComputedDataIndexes([key]);
                  registeredKeys.add(key);
                case TestRecycleOp(:final key):
                  manager.releaseComputedDataIndex(key);
                  registeredKeys.remove(key);
              }

              // 容量必须严格大于每个存活 key 的 slot 索引。
              for (final key in registeredKeys) {
                final slot = manager.getComputedDataIndex(key)!;
                expect(
                  manager.computedDataCapacity,
                  greaterThan(slot),
                  reason: 'run#$run: 执行 $op 后 computedDataCapacity '
                      '(${manager.computedDataCapacity}) 必须 > 存活 $key 的 slot $slot',
                );
              }

              // 高水位容量只增不减。
              expect(
                manager.computedDataCapacity,
                greaterThanOrEqualTo(prevCount),
                reason: 'run#$run: 执行 $op 后 computedDataCapacity 不应回退',
              );
              prevCount = manager.computedDataCapacity;
            }
          }
        },
      );

      // ---------------------------------------------------------------
      // 属性 2：回收的 slot 按 FIFO 顺序被下一次注册复用
      // ---------------------------------------------------------------
      test(
        '回收的 slot 按 FIFO 顺序被复用',
        () {
          final rng = Random(301);
          for (int run = 0; run < numRuns; run++) {
            final keyCount = 2 + rng.nextInt(6); // 2~7
            final manager = IndicatorPaintObjectManager(
              configuration: FakeFlexiKlineConfiguration(),
            );

            final keys = List.generate(
              keyCount,
              (i) => ComputedIndicatorKey('fifo_$i'),
            );
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
                reason: 'run#$run: 第 ${i + 1} 个新 key 应复用回收队列中的 slot '
                    '${recycledSlots[i]}',
              );
            }
          }
        },
      );

      // ---------------------------------------------------------------
      // 属性 3：每个已注册 key 拥有唯一的 slot index
      // ---------------------------------------------------------------
      test(
        '每个已注册的 ComputedIndicatorKey 拥有唯一的 slot index',
        () {
          final rng = Random(302);
          for (int run = 0; run < numRuns; run++) {
            final ops = randomSlotOps(rng);
            final manager = IndicatorPaintObjectManager(
              configuration: FakeFlexiKlineConfiguration(),
            );

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
                expect(registeredSlots.add(slot), isTrue, reason: 'run#$run: slot $slot 被多个 key 共享');
              }
            }
          }
        },
      );

      // ---------------------------------------------------------------
      // 属性 4：所有 slot index >= 0 且唯一
      // ---------------------------------------------------------------
      test(
        '所有已分配的 slot index >= 0 且互不重复',
        () {
          final rng = Random(303);
          for (int run = 0; run < numRuns; run++) {
            final ops = randomSlotOps(rng);
            final manager = IndicatorPaintObjectManager(
              configuration: FakeFlexiKlineConfiguration(),
            );

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
                expect(slot, greaterThanOrEqualTo(0), reason: 'run#$run: key_$i 的 slot $slot < 0');
                expect(assignedSlots.add(slot), isTrue, reason: 'run#$run: key_$i 的 slot $slot 重复');
              }
            }
          }
        },
      );
    },
  );
}
