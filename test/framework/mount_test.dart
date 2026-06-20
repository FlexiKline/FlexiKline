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

/// 属性测试：mountIndicators 声明层完整性 (M1)
library;

import 'dart:math';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  const numRuns = 100;

  group(
    'v2.2.0/IndicatorPaintObjectManager/mount',
    () {
      // ---------------------------------------------------------------
      // 属性 1：_declaredIndicators 包含所有 mainIndicators 和 subIndicators 的 key
      // ---------------------------------------------------------------
      test(
        '_declaredIndicators 包含所有传入的 mainIndicators 和 subIndicators 的 key',
        () {
          final rng = Random(42);
          for (int run = 0; run < numRuns; run++) {
            final input = randomMainSub(rng);
            final manager = IndicatorPaintObjectManager(
              configuration: FakeFlexiKlineConfiguration(),
            );
            final context = FakePaintContext();

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

            for (final key in allExpectedKeys) {
              if (key is ComputedIndicatorKey) {
                final slot = manager.getComputedDataIndex(key);
                expect(
                  slot,
                  isNotNull,
                  reason: 'run#$run: ComputedIndicatorKey $key 应该有 slot 分配',
                );
              }
            }
          }
        },
      );

      // ---------------------------------------------------------------
      // 属性 2：_computedDataIndexes 为每个 ComputedIndicatorKey 分配唯一 slot
      // ---------------------------------------------------------------
      test(
        '_computedDataIndexes 为每个 ComputedIndicatorKey 分配唯一 slot index',
        () {
          final rng = Random(43);
          for (int run = 0; run < numRuns; run++) {
            final input = randomMainSub(rng);
            final manager = IndicatorPaintObjectManager(
              configuration: FakeFlexiKlineConfiguration(),
            );
            final context = FakePaintContext();

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
                reason: 'run#$run: slot $slot 被多个 ComputedIndicatorKey 共享',
              );
            }
          }
        },
      );

      // ---------------------------------------------------------------
      // 属性 3：computedDataCount 等于 ComputedIndicator 的数量
      // ---------------------------------------------------------------
      test(
        'computedDataCount 等于所有 ComputedIndicator 的数量',
        () {
          final rng = Random(44);
          for (int run = 0; run < numRuns; run++) {
            final input = randomMainSub(rng);
            final manager = IndicatorPaintObjectManager(
              configuration: FakeFlexiKlineConfiguration(),
            );
            final context = FakePaintContext();

            final mainIndicators = input.main.map(createIndicator).toList();
            final subIndicators = input.sub.map(createIndicator).toList();

            manager.mountIndicators(
              candle: TestCandleIndicator(),
              time: TestTimeIndicator(),
              mainIndicators: mainIndicators,
              subIndicators: subIndicators,
              context: context,
            );

            final dataCount = [...mainIndicators, ...subIndicators]
                .where((i) => i.key is ComputedIndicatorKey)
                .length;

            expect(
              manager.computedDataCount,
              equals(dataCount),
              reason: 'run#$run: computedDataCount 应为 $dataCount',
            );
          }
        },
      );

      // ---------------------------------------------------------------
      // 属性 4：candle/time/main PaintObject 已创建
      // ---------------------------------------------------------------
      test(
        'candle/time/main PaintObject 在 mountIndicators 后已创建',
        () {
          final rng = Random(45);
          for (int run = 0; run < numRuns; run++) {
            final input = randomMainSub(rng);
            final manager = IndicatorPaintObjectManager(
              configuration: FakeFlexiKlineConfiguration(),
            );
            final context = FakePaintContext();

            final mainIndicators = input.main.map(createIndicator).toList();
            final subIndicators = input.sub.map(createIndicator).toList();

            manager.mountIndicators(
              candle: TestCandleIndicator(),
              time: TestTimeIndicator(),
              mainIndicators: mainIndicators,
              subIndicators: subIndicators,
              context: context,
            );

            expect(manager.candlePaintObject, isA<CandleBasePaintObject>());
            expect(manager.timePaintObject, isA<TimeBasePaintObject>());
            expect(manager.mainPaintObject, isA<MainPaintObject>());
          }
        },
      );

      // ---------------------------------------------------------------
      // 属性 5：副区绘制队列为空（默认配置无持久化 sub key）
      // ---------------------------------------------------------------
      test(
        '副区绘制队列在 mountIndicators 后为空（默认配置无持久化 sub key）',
        () {
          final rng = Random(46);
          for (int run = 0; run < numRuns; run++) {
            final input = randomMainSub(rng);
            final manager = IndicatorPaintObjectManager(
              configuration: FakeFlexiKlineConfiguration(),
            );
            final context = FakePaintContext();

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
              reason: 'run#$run: 副区绘制队列应为空',
            );
          }
        },
      );

      // ---------------------------------------------------------------
      // 属性 6：所有 slot index 在 [0, computedDataCount) 范围内
      // ---------------------------------------------------------------
      test(
        '所有已分配的 slot index 在 [0, computedDataCount) 范围内',
        () {
          final rng = Random(47);
          for (int run = 0; run < numRuns; run++) {
            final input = randomMainSub(rng);
            final manager = IndicatorPaintObjectManager(
              configuration: FakeFlexiKlineConfiguration(),
            );
            final context = FakePaintContext();

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
                expect(slot, greaterThanOrEqualTo(0),
                    reason: 'run#$run: ${indicator.key} slot $slot < 0');
                expect(slot, lessThan(count),
                    reason: 'run#$run: ${indicator.key} slot $slot >= $count');
              }
            }
          }
        },
      );
    },
  );
}
