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
/// - **Property 5: candle/time 无条件更新** — Validates: Requirements 4.2
/// - **Property 6: diff 增删的 slot 与缓存一致性** — Validates: Requirements 4.4, 4.5
/// - **Property 7: diff 配置变化更新已激活 PaintObject** — Validates: Requirements 4.6
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:glados/glados.dart';

import '../helpers/indicator_test_helpers.dart';
import '../helpers/test_indicators.dart';
import '../helpers/test_kline_config.dart';
import '../helpers/test_paint_context.dart';

// ---------------------------------------------------------------------------
// 本文件专用生成器
// ---------------------------------------------------------------------------

/// 生成随机 candle height（用于区分不同 candle 实例）
final _candleHeightGen = any.intInRange(100, 500).map((h) => h.toDouble());

/// 生成随机 time height（用于区分不同 time 实例）
final _timeHeightGen = any.intInRange(15, 50).map((h) => h.toDouble());

void main() {
  // =========================================================================
  // Property 5: candle/time 无条件更新
  // =========================================================================
  group(
    'Feature: widget-style-indicator-system-v4, '
    'Property 5: candle/time 无条件更新',
    () {
      /// **Validates: Requirements 4.2**
      Glados(
        _candleHeightGen.bind(
          (oldCH) => _candleHeightGen.bind(
            (newCH) => _timeHeightGen.bind(
              (oldTH) => _timeHeightGen.map(
                (newTH) => (
                  oldCandleH: oldCH,
                  newCandleH: newCH,
                  oldTimeH: oldTH,
                  newTimeH: newTH,
                ),
              ),
            ),
          ),
        ),
        ExploreConfig(numRuns: 100),
      ).test(
        'updateIndicators 后 candle/time PaintObject 的 indicator 等于新实例',
        (input) {
          final manager = createManager();
          final context = TestPaintContext();

          final oldCandle = TestCandleIndicator(height: input.oldCandleH);
          final oldTime = TestTimeIndicator(height: input.oldTimeH);
          final newCandle = TestCandleIndicator(height: input.newCandleH);
          final newTime = TestTimeIndicator(height: input.newTimeH);

          // 1. 首次挂载
          manager.mountIndicators(
            candle: oldCandle,
            time: oldTime,
            mainIndicators: [],
            subIndicators: [],
            context: context,
          );

          expect(identical(manager.candlePaintObject.indicator, oldCandle), isTrue);
          expect(identical(manager.timePaintObject.indicator, oldTime), isTrue);

          // 2. 增量更新（无条件更新 candle/time）
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
            reason: 'updateIndicators 后 candlePaintObject.indicator 应为新实例',
          );
          expect(
            identical(manager.timePaintObject.indicator, newTime),
            isTrue,
            reason: 'updateIndicators 后 timePaintObject.indicator 应为新实例',
          );
        },
      );
    },
  );

  // =========================================================================
  // Property 6: diff 增删的 slot 与缓存一致性
  // =========================================================================
  group(
    'Feature: widget-style-indicator-system-v4, '
    'Property 6: diff 增删的 slot 与缓存一致性',
    () {
      /// **Validates: Requirements 4.4, 4.5**
      ///
      /// 生成器确保 main 和 sub 的 key 空间不交叉（符合业务约束：
      /// main 指标不会移到 sub，sub 指标不会移到 main）。
      /// 策略：main 使用原始 id（0~19），sub 使用 id+20 偏移。
      final listGen = indicatorListGen(indicatorDescWithHeightGen);

      Glados(
        listGen.bind(
          (oldMainDescs) => listGen.bind(
            (newMainDescs) => listGen.bind(
              (oldSubDescsRaw) {
                final oldSubDescs = oldSubDescsRaw.map((d) => IndicatorDesc(d.type, d.id + 20, d.height)).toList();
                return listGen.map((newSubDescsRaw) {
                  final newSubDescs = newSubDescsRaw.map((d) => IndicatorDesc(d.type, d.id + 20, d.height)).toList();
                  // 确保各列表内部 key 唯一
                  final seenOldMain = <String>{};
                  final uniqueOldMain = oldMainDescs.where((d) => seenOldMain.add('${d.type.name}_${d.id}')).toList();
                  final seenNewMain = <String>{};
                  final uniqueNewMain = newMainDescs.where((d) => seenNewMain.add('${d.type.name}_${d.id}')).toList();
                  final seenOldSub = <String>{};
                  final uniqueOldSub = oldSubDescs.where((d) => seenOldSub.add('${d.type.name}_${d.id}')).toList();
                  final seenNewSub = <String>{};
                  final uniqueNewSub = newSubDescs.where((d) => seenNewSub.add('${d.type.name}_${d.id}')).toList();
                  return (
                    old: (main: uniqueOldMain, sub: uniqueOldSub),
                    new_: (main: uniqueNewMain, sub: uniqueNewSub),
                  );
                });
              },
            ),
          ),
        ),
        ExploreConfig(numRuns: 100),
      ).test(
        'diff 增删后 slot 与缓存状态一致',
        (input) {
          final context = TestPaintContext();

          final oldMainIndicators = input.old.main.map(createIndicator).toList();
          final oldSubIndicators = input.old.sub.map(createIndicator).toList();
          final newMainIndicators = input.new_.main.map(createIndicator).toList();
          final newSubIndicators = input.new_.sub.map(createIndicator).toList();

          final manager = createManager();

          // 1. 首次挂载
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

          // 2. 增量更新
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

          // 3. 验证：移除的 ComputedIndicator slot 被回收
          for (final key in removedKeys) {
            if (key is ComputedIndicatorKey) {
              expect(manager.getComputedDataIndex(key), isNull, reason: '移除的 $key 的 slot 应被回收');
            }
          }

          // 4. 验证：新增的 ComputedIndicator 获得 slot
          for (final key in addedKeys) {
            if (key is ComputedIndicatorKey) {
              final slot = manager.getComputedDataIndex(key);
              expect(slot, isNotNull, reason: '新增的 $key 应获得 slot');
              expect(slot, greaterThanOrEqualTo(0), reason: '$key 的 slot < 0');
            }
          }

          // 5. 验证：保留的 ComputedIndicator slot 不变
          final keptKeys = {
            ...oldMainKeys.intersection(newMainKeys),
            ...oldSubKeys.intersection(newSubKeys),
          };
          for (final key in keptKeys) {
            if (key is ComputedIndicatorKey) {
              expect(manager.getComputedDataIndex(key), equals(oldDataSlots[key]), reason: '保留的 $key 的 slot 应不变');
            }
          }

          // 6. 验证：computedDataCount 等于新声明集合中 ComputedIndicator 的数量
          final expectedCount = newAllKeys.whereType<ComputedIndicatorKey>().length;
          expect(manager.computedDataCount, equals(expectedCount),
              reason: 'computedDataCount 应等于新声明 ComputedIndicator 数量 $expectedCount');

          // 7. 验证：新增指标不自动创建 PaintObject
          final mainKeysExcludingCandle = manager.mainIndicatorKeys.where((k) => k != candleIndicatorKey).toSet();
          expect(mainKeysExcludingCandle, isEmpty, reason: '新增指标不应自动创建主区 PaintObject');
          expect(manager.subIndicatorKeys, isEmpty, reason: '新增指标不应自动创建副区 PaintObject');
        },
      );
    },
  );

  // =========================================================================
  // Property 7: diff 配置变化更新已激活 PaintObject
  // =========================================================================
  group(
    'Feature: widget-style-indicator-system-v4, '
    'Property 7: diff 配置变化更新已激活 PaintObject',
    () {
      /// **Validates: Requirements 4.6**
      Glados(
        any.intInRange(1, 6).bind(
              (count) => any
                  .listWithLength(
                    count,
                    any.intInRange(50, 200).bind(
                          (oldH) => any.intInRange(201, 400).map(
                                (newH) => (
                                  oldHeight: oldH.toDouble(),
                                  newHeight: newH.toDouble(),
                                ),
                              ),
                        ),
                  )
                  .map((pairs) => (count: count, pairs: pairs)),
            ),
        ExploreConfig(numRuns: 100),
      ).test(
        'key 相同但参数不同时，已激活 PaintObject 的 indicator 更新为新实例',
        (input) {
          final context = TestPaintContext();

          final indicatorPairs = <({
            ComputedIndicatorKey key,
            TestComputedIndicator oldInd,
            TestComputedIndicator newInd,
          })>[];

          for (int i = 0; i < input.pairs.length; i++) {
            final pair = input.pairs[i];
            final key = ComputedIndicatorKey('cfg_$i');
            indicatorPairs.add((
              key: key,
              oldInd: TestComputedIndicator(key: key, height: pair.oldHeight),
              newInd: TestComputedIndicator(key: key, height: pair.newHeight),
            ));
          }

          final oldMainIndicators = indicatorPairs.map((p) => p.oldInd as Indicator).toList();
          final newMainIndicators = indicatorPairs.map((p) => p.newInd as Indicator).toList();
          final mainChildrenKeys = indicatorPairs.map((p) => p.key as IIndicatorKey).toSet();

          final config = TestFlexiKlineConfiguration(mainChildren: mainChildrenKeys);
          final manager = createManager(config);

          manager.mountIndicators(
            candle: TestCandleIndicator(),
            time: TestTimeIndicator(),
            mainIndicators: oldMainIndicators,
            subIndicators: [],
            context: context,
          );

          // 验证指标已激活
          for (final pair in indicatorPairs) {
            expect(manager.mainIndicatorKeys.toSet().contains(pair.key), isTrue, reason: '${pair.key} 应已激活');
          }

          // updateIndicators 传入 key 相同但 height 不同的新指标
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
            expect(paintObject, isNotNull, reason: '${pair.key} 的 PaintObject 应仍存在');
            expect(
              identical(paintObject!.indicator, pair.newInd),
              isTrue,
              reason: '${pair.key} 的 indicator 应为新实例 (newH=${pair.newInd.height})',
            );
          }
        },
      );
    },
  );
}
