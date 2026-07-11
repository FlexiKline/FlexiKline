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

/// 属性测试：updateIndicators 增量更新
///
/// 包含以下属性：
/// - **Property 5: candle/time 无条件更新**
/// - **Property 6: diff 增删的 slot 与缓存一致性**
/// - **Property 7: diff 配置变化更新已激活 PaintObject**
library;

import 'dart:math';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  const numRuns = 100;

  // =========================================================================
  // Property 5: candle/time 无条件更新
  // =========================================================================
  group(
    'v2.2.0/IndicatorPaintObjectManager/update/M5_candle_time无条件更新',
    () {
      test(
        'updateIndicators 后 candle/time PaintObject 的 indicator 等于新实例',
        () {
          final rng = Random(200);
          for (int run = 0; run < numRuns; run++) {
            final manager = IndicatorPaintObjectManager(
              configuration: FakeFlexiKlineConfiguration(),
            );
            final context = FakePaintContext();

            final oldCandleH = 100.0 + rng.nextInt(400);
            final newCandleH = 100.0 + rng.nextInt(400);
            final oldTimeH = 15.0 + rng.nextInt(35);
            final newTimeH = 15.0 + rng.nextInt(35);

            final oldCandle = TestCandleIndicator(height: oldCandleH);
            final oldTime = TestTimeIndicator(height: oldTimeH);
            final newCandle = TestCandleIndicator(height: newCandleH);
            final newTime = TestTimeIndicator(height: newTimeH);

            manager.mountIndicators(
              candle: oldCandle,
              time: oldTime,
              mainIndicators: [],
              subIndicators: [],
              context: context,
            );

            expect(identical(manager.candlePaintObject.indicator, oldCandle), isTrue);
            expect(identical(manager.timePaintObject.indicator, oldTime), isTrue);

            manager.updateIndicators(
              oldCandle: oldCandle,
              newCandle: newCandle,
              oldTime: oldTime,
              newTime: newTime,
              oldMainIndicators: [],
              newMainIndicators: [],
              oldSubIndicators: [],
              newSubIndicators: [],
              context: context,
            );

            expect(
              identical(manager.candlePaintObject.indicator, newCandle),
              isTrue,
              reason: 'run#$run: candlePaintObject.indicator 应为新实例',
            );
            expect(
              identical(manager.timePaintObject.indicator, newTime),
              isTrue,
              reason: 'run#$run: timePaintObject.indicator 应为新实例',
            );
          }
        },
      );
    },
  );

  // =========================================================================
  // Property 6: diff 增删的 slot 与缓存一致性
  // =========================================================================
  group(
    'v2.2.0/IndicatorPaintObjectManager/update/M6_diff增删slot一致性',
    () {
      test(
        'diff 增删后 slot 与缓存状态一致',
        () {
          final rng = Random(201);
          for (int run = 0; run < numRuns; run++) {
            final context = FakePaintContext();

            // 生成 old/new 两组指标，main 使用原始 id，sub 使用 id+20 偏移
            final oldMainDescs = randomIndicatorList(rng, randomIndicatorDescWithHeight);
            final newMainDescs = randomIndicatorList(rng, randomIndicatorDescWithHeight);
            final oldSubDescsRaw = randomIndicatorList(rng, randomIndicatorDescWithHeight);
            final newSubDescsRaw = randomIndicatorList(rng, randomIndicatorDescWithHeight);

            final oldSubDescs = oldSubDescsRaw.map((d) => IndicatorDesc(d.kind, d.id + 20, d.height)).toList();
            final newSubDescs = newSubDescsRaw.map((d) => IndicatorDesc(d.kind, d.id + 20, d.height)).toList();

            final oldMainIndicators = oldMainDescs.map(createIndicator).toList();
            final oldSubIndicators = oldSubDescs.map(createIndicator).toList();
            final newMainIndicators = newMainDescs.map(createIndicator).toList();
            final newSubIndicators = newSubDescs.map(createIndicator).toList();

            final manager = IndicatorPaintObjectManager(
              configuration: FakeFlexiKlineConfiguration(),
            );

            manager.mountIndicators(
              candle: TestCandleIndicator(),
              time: TestTimeIndicator(),
              mainIndicators: oldMainIndicators,
              subIndicators: oldSubIndicators,
              context: context,
            );

            // 记录同步前的状态
            final oldMainKeys = oldMainIndicators.map((i) => i.key).toSet();
            final oldSubKeys = oldSubIndicators.map((i) => i.key).toSet();
            final oldAllKeys = {...oldMainKeys, ...oldSubKeys};

            final oldDataSlots = <ComputedIndicatorKey, int>{};
            for (final key in oldAllKeys) {
              if (key is ComputedIndicatorKey) {
                final slot = manager.getComputedDataIndex(key);
                if (slot != null) oldDataSlots[key] = slot;
              }
            }

            // 增量更新
            manager.updateIndicators(
              oldCandle: TestCandleIndicator(),
              newCandle: TestCandleIndicator(),
              oldTime: TestTimeIndicator(),
              newTime: TestTimeIndicator(),
              oldMainIndicators: oldMainIndicators,
              newMainIndicators: newMainIndicators,
              oldSubIndicators: oldSubIndicators,
              newSubIndicators: newSubIndicators,
              context: context,
            );

            // 计算 diff
            final newMainKeys = newMainIndicators.map((i) => i.key).toSet();
            final newSubKeys = newSubIndicators.map((i) => i.key).toSet();
            final newAllKeys = {...newMainKeys, ...newSubKeys};
            final removedKeys = oldAllKeys.difference(newAllKeys);
            final addedKeys = newAllKeys.difference(oldAllKeys);

            // 验证：移除的 ComputedIndicator slot 被回收
            for (final key in removedKeys) {
              if (key is ComputedIndicatorKey) {
                expect(manager.getComputedDataIndex(key), isNull, reason: 'run#$run: 移除的 $key 的 slot 应被回收');
              }
            }

            // 验证：新增的 ComputedIndicator 获得 slot
            for (final key in addedKeys) {
              if (key is ComputedIndicatorKey) {
                final slot = manager.getComputedDataIndex(key);
                expect(slot, isNotNull, reason: 'run#$run: 新增的 $key 应获得 slot');
                expect(slot, greaterThanOrEqualTo(0));
              }
            }

            // 验证：保留的 ComputedIndicator slot 不变
            final keptKeys = {
              ...oldMainKeys.intersection(newMainKeys),
              ...oldSubKeys.intersection(newSubKeys),
            };
            for (final key in keptKeys) {
              if (key is ComputedIndicatorKey) {
                expect(manager.getComputedDataIndex(key), equals(oldDataSlots[key]),
                    reason: 'run#$run: 保留的 $key 的 slot 应不变');
              }
            }

            // 验证：computedDataCapacity 是高水位容量，覆盖所有存活 slot
            //（只增不减，不随删除回退）
            for (final key in newAllKeys) {
              if (key is ComputedIndicatorKey) {
                final slot = manager.getComputedDataIndex(key)!;
                expect(manager.computedDataCapacity, greaterThan(slot),
                    reason: 'run#$run: computedDataCapacity '
                        '(${manager.computedDataCapacity}) 必须 > 存活 $key 的 slot $slot');
              }
            }

            // 验证：新增指标不自动创建 PaintObject
            final mainKeysExcludingCandle = manager.mainIndicatorKeys.where((k) => k != candleIndicatorKey).toSet();
            expect(mainKeysExcludingCandle, isEmpty, reason: 'run#$run: 新增指标不应自动创建主区 PaintObject');
            expect(manager.subIndicatorKeys, isEmpty, reason: 'run#$run: 新增指标不应自动创建副区 PaintObject');
          }
        },
      );
    },
  );

  // =========================================================================
  // Property 7: diff 配置变化更新已激活 PaintObject
  // =========================================================================
  group(
    'v2.2.0/IndicatorPaintObjectManager/update/M7_diff配置变化更新PO',
    () {
      test(
        'key 相同但参数不同时，已激活 PaintObject 的 indicator 更新为新实例',
        () {
          final rng = Random(202);
          for (int run = 0; run < numRuns; run++) {
            final context = FakePaintContext();

            final count = 1 + rng.nextInt(5);
            final indicatorPairs = <({
              ComputedIndicatorKey key,
              TestComputedIndicator oldInd,
              TestComputedIndicator newInd,
            })>[];

            for (int i = 0; i < count; i++) {
              final key = ComputedIndicatorKey('cfg_$i');
              final oldH = 50.0 + rng.nextInt(150);
              final newH = 201.0 + rng.nextInt(199);
              indicatorPairs.add((
                key: key,
                oldInd: TestComputedIndicator(key: key, height: oldH),
                newInd: TestComputedIndicator(key: key, height: newH),
              ));
            }

            final oldMainIndicators = indicatorPairs.map((p) => p.oldInd as Indicator).toList();
            final newMainIndicators = indicatorPairs.map((p) => p.newInd as Indicator).toList();
            final mainChildrenKeys = indicatorPairs.map((p) => p.key as IIndicatorKey).toSet();

            final config = FakeFlexiKlineConfiguration(mainChildren: mainChildrenKeys);
            final manager = IndicatorPaintObjectManager(configuration: config);

            manager.mountIndicators(
              candle: TestCandleIndicator(),
              time: TestTimeIndicator(),
              mainIndicators: oldMainIndicators,
              subIndicators: [],
              context: context,
            );

            // 验证指标已激活
            for (final pair in indicatorPairs) {
              expect(manager.mainIndicatorKeys.toSet().contains(pair.key), isTrue,
                  reason: 'run#$run: ${pair.key} 应已激活');
            }

            manager.updateIndicators(
              oldCandle: TestCandleIndicator(),
              newCandle: TestCandleIndicator(),
              oldTime: TestTimeIndicator(),
              newTime: TestTimeIndicator(),
              oldMainIndicators: oldMainIndicators,
              newMainIndicators: newMainIndicators,
              oldSubIndicators: [],
              newSubIndicators: [],
              context: context,
            );

            // 验证已激活 PaintObject 的 indicator 等于新实例
            for (final pair in indicatorPairs) {
              final paintObject = manager.mainPaintObject.children.firstWhereOrNull((obj) => obj.key == pair.key);
              expect(paintObject, isNotNull, reason: 'run#$run: ${pair.key} 的 PaintObject 应仍存在');
              expect(
                identical(paintObject!.indicator, pair.newInd),
                isTrue,
                reason: 'run#$run: ${pair.key} 的 indicator 应为新实例',
              );
            }
          }
        },
      );
    },
  );
}
