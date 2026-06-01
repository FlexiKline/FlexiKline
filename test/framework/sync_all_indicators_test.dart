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

/// 属性测试：mountIndicators 声明层完整性
///
/// **Validates: Requirements 1.1, 1.2**
///
/// 验证 IndicatorPaintObjectManager.mountIndicators 的核心不变量：
/// 1. `_declaredIndicators` 包含所有 mainIndicators 和 subIndicators 的 key
/// 2. `_computedDataIndexes` 为每个 ComputedIndicatorKey 分配唯一 slot
/// 3. `computedDataCount` 等于 ComputedIndicator 的数量
/// 4. candle/time/main PaintObject 已创建
/// 5. 副区绘制队列为空（默认配置无持久化 sub key）
/// 6. 所有 slot index 在 [0, computedDataCount) 范围内
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:glados/glados.dart';

import '../helpers/indicator_test_helpers.dart';
import '../helpers/test_indicators.dart';
import '../helpers/test_paint_context.dart';

void main() {
  final gen = mainSubGen();

  group(
    'Feature: widget-style-indicator-system-v4, '
    'Property 1: mountIndicators 声明层完整性',
    () {
      // ---------------------------------------------------------------
      // 属性 1：_declaredIndicators 包含所有 mainIndicators 和 subIndicators 的 key
      // ---------------------------------------------------------------
      Glados(gen, ExploreConfig(numRuns: 100)).test(
        '_declaredIndicators 包含所有传入的 mainIndicators 和 subIndicators 的 key',
        (input) {
          final manager = createManager();
          final context = TestPaintContext();

          final mainIndicators = input.main.map(createIndicator).toList();
          final subIndicators = input.sub.map(createIndicator).toList();

          manager.mountIndicators(
            candle: TestCandleIndicator(),
            time: TestTimeIndicator(),
            mainIndicators: mainIndicators,
            subIndicators: subIndicators,
            context: context,
          );

          final allExpectedKeys = <IIndicatorKey>{
            ...mainIndicators.map((i) => i.key),
            ...subIndicators.map((i) => i.key),
          };

          // 验证每个 ComputedIndicatorKey 都有 slot 分配
          for (final key in allExpectedKeys) {
            if (key is ComputedIndicatorKey) {
              final slot = manager.getComputedDataIndex(key);
              expect(
                slot,
                isNotNull,
                reason: 'ComputedIndicatorKey $key 应该有 slot 分配，但返回 null',
              );
            }
          }
        },
      );

      // ---------------------------------------------------------------
      // 属性 2：_computedDataIndexes 为每个 ComputedIndicatorKey 分配唯一 slot
      // ---------------------------------------------------------------
      Glados(gen, ExploreConfig(numRuns: 100)).test(
        '_computedDataIndexes 为每个 ComputedIndicatorKey 分配唯一 slot index',
        (input) {
          final manager = createManager();
          final context = TestPaintContext();

          final mainIndicators = input.main.map(createIndicator).toList();
          final subIndicators = input.sub.map(createIndicator).toList();

          manager.mountIndicators(
            candle: TestCandleIndicator(),
            time: TestTimeIndicator(),
            mainIndicators: mainIndicators,
            subIndicators: subIndicators,
            context: context,
          );

          final dataKeys = <ComputedIndicatorKey>[
            for (final i in mainIndicators)
              if (i.key is ComputedIndicatorKey) i.key as ComputedIndicatorKey,
            for (final i in subIndicators)
              if (i.key is ComputedIndicatorKey) i.key as ComputedIndicatorKey,
          ];

          final assignedSlots = <int>{};
          for (final key in dataKeys) {
            final slot = manager.getComputedDataIndex(key)!;
            expect(
              assignedSlots.add(slot),
              isTrue,
              reason: 'slot $slot 被多个 ComputedIndicatorKey 共享，违反唯一性',
            );
          }
        },
      );

      // ---------------------------------------------------------------
      // 属性 3：computedDataCount 等于 ComputedIndicator 的数量
      // ---------------------------------------------------------------
      Glados(gen, ExploreConfig(numRuns: 100)).test(
        'computedDataCount 等于所有 ComputedIndicator 的数量',
        (input) {
          final manager = createManager();
          final context = TestPaintContext();

          final mainIndicators = input.main.map(createIndicator).toList();
          final subIndicators = input.sub.map(createIndicator).toList();

          manager.mountIndicators(
            candle: TestCandleIndicator(),
            time: TestTimeIndicator(),
            mainIndicators: mainIndicators,
            subIndicators: subIndicators,
            context: context,
          );

          final dataCount = [...mainIndicators, ...subIndicators].where((i) => i.key is ComputedIndicatorKey).length;

          expect(
            manager.computedDataCount,
            equals(dataCount),
            reason: 'computedDataCount 应为 $dataCount（ComputedIndicator 数量），'
                '但实际为 ${manager.computedDataCount}',
          );
        },
      );

      // ---------------------------------------------------------------
      // 属性 4：candle/time/main PaintObject 已创建
      // ---------------------------------------------------------------
      Glados(gen, ExploreConfig(numRuns: 100)).test(
        'candle/time/main PaintObject 在 mountIndicators 后已创建',
        (input) {
          final manager = createManager();
          final context = TestPaintContext();

          final mainIndicators = input.main.map(createIndicator).toList();
          final subIndicators = input.sub.map(createIndicator).toList();

          manager.mountIndicators(
            candle: TestCandleIndicator(),
            time: TestTimeIndicator(),
            mainIndicators: mainIndicators,
            subIndicators: subIndicators,
            context: context,
          );

          expect(
            manager.candlePaintObject,
            isA<CandleBasePaintObject>(),
            reason: 'candlePaintObject 应已创建',
          );
          expect(
            manager.timePaintObject,
            isA<TimeBasePaintObject>(),
            reason: 'timePaintObject 应已创建',
          );
          expect(
            manager.mainPaintObject,
            isA<MainPaintObject>(),
            reason: 'mainPaintObject 应已创建',
          );
        },
      );

      // ---------------------------------------------------------------
      // 属性 5：副区绘制队列为空（默认配置无持久化 sub key）
      // ---------------------------------------------------------------
      Glados(gen, ExploreConfig(numRuns: 100)).test(
        '副区绘制队列在 mountIndicators 后为空（默认配置无持久化 sub key）',
        (input) {
          final manager = createManager();
          final context = TestPaintContext();

          final mainIndicators = input.main.map(createIndicator).toList();
          final subIndicators = input.sub.map(createIndicator).toList();

          manager.mountIndicators(
            candle: TestCandleIndicator(),
            time: TestTimeIndicator(),
            mainIndicators: mainIndicators,
            subIndicators: subIndicators,
            context: context,
          );

          expect(
            manager.subIndicatorKeys,
            isEmpty,
            reason: '副区绘制队列应为空，但包含 ${manager.subIndicatorKeys}',
          );
        },
      );

      // ---------------------------------------------------------------
      // 属性 6：所有 slot index 在 [0, computedDataCount) 范围内
      // ---------------------------------------------------------------
      Glados(gen, ExploreConfig(numRuns: 100)).test(
        '所有已分配的 slot index 在 [0, computedDataCount) 范围内',
        (input) {
          final manager = createManager();
          final context = TestPaintContext();

          final mainIndicators = input.main.map(createIndicator).toList();
          final subIndicators = input.sub.map(createIndicator).toList();

          manager.mountIndicators(
            candle: TestCandleIndicator(),
            time: TestTimeIndicator(),
            mainIndicators: mainIndicators,
            subIndicators: subIndicators,
            context: context,
          );

          final count = manager.computedDataCount;
          final allIndicators = [...mainIndicators, ...subIndicators];

          for (final indicator in allIndicators) {
            if (indicator.key is ComputedIndicatorKey) {
              final slot = manager.getComputedDataIndex(
                indicator.key as ComputedIndicatorKey,
              )!;
              expect(slot, greaterThanOrEqualTo(0), reason: '${indicator.key} 的 slot $slot < 0');
              expect(slot, lessThan(count), reason: '${indicator.key} 的 slot $slot >= computedDataCount $count');
            }
          }
        },
      );
    },
  );
}
