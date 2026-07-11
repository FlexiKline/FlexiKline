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

/// 属性测试：激活层指标管理
library;

import 'dart:math';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  const numRuns = 100;

  // =========================================================================
  // Property 2: 从缓存激活指标
  // =========================================================================
  group(
    'v2.2.0/IndicatorPaintObjectManager/activate/M2_从缓存激活',
    () {
      test(
        'mountIndicators 后 PaintObject 集合的 key 等于激活子集 S，'
        '且每个 PaintObject 的 indicator 与缓存一致',
        () {
          final rng = Random(100);
          for (int run = 0; run < numRuns; run++) {
            final pair = randomMainSub(rng);
            final context = FakePaintContext();

            final mainIndicators = pair.main.map(createIndicator).toList();
            final subIndicators = pair.sub.map(createIndicator).toList();

            // 随机选择激活子集
            final activateMain = randomSubset(rng, pair.main);
            final activateSub = randomSubset(rng, pair.sub).take(defaultSubIndicatorMaxCount).toList();

            final mainChildrenKeys = activateMain.map(descToKey).toSet();
            final subKeys = activateSub.map(descToKey).toSet();

            final expectedMainChildrenKeys = Set<IIndicatorKey>.of(mainChildrenKeys);
            final expectedSubKeys = Set<IIndicatorKey>.of(subKeys);

            final config = FakeFlexiKlineConfiguration(
              mainChildren: mainChildrenKeys,
              subKeys: subKeys,
            );
            final manager = IndicatorPaintObjectManager(configuration: config);

            manager.mountIndicators(
              candle: TestCandleIndicator(),
              time: TestTimeIndicator(),
              mainIndicators: mainIndicators,
              subIndicators: subIndicators,
              context: context,
            );

            // 验证主区 PaintObject 集合的 key（排除 candle）
            final actualMainKeysFiltered = manager.mainIndicatorKeys.where((k) => k != candleIndicatorKey).toSet();
            expect(
              actualMainKeysFiltered,
              equals(expectedMainChildrenKeys),
              reason: 'run#$run: 主区 PaintObject key 应等于激活子集',
            );

            // 验证副区 PaintObject 集合的 key（排除 time）
            final actualSubKeysFiltered = manager.subIndicatorKeys.where((k) => k != timeIndicatorKey).toSet();
            expect(
              actualSubKeysFiltered,
              equals(expectedSubKeys),
              reason: 'run#$run: 副区 PaintObject key 应等于激活子集',
            );

            // 验证每个主区 PaintObject 的 indicator 与传入的 Indicator 实例一致
            for (final key in expectedMainChildrenKeys) {
              final paintObject = manager.mainPaintObject.children.firstWhereOrNull((obj) => obj.key == key);
              expect(paintObject, isNotNull, reason: 'run#$run: 主区应包含 key=$key');
              final expectedIndicator = mainIndicators.firstWhere((i) => i.key == key);
              expect(
                identical(paintObject!.indicator, expectedIndicator),
                isTrue,
                reason: 'run#$run: 主区 PaintObject($key) 的 indicator 应与缓存一致',
              );
            }

            // 验证每个副区 PaintObject 的 indicator 与传入的 Indicator 实例一致
            for (final key in expectedSubKeys) {
              final paintObject = manager.subPaintObjects.firstWhereOrNull((obj) => obj.key == key);
              expect(paintObject, isNotNull, reason: 'run#$run: 副区应包含 key=$key');
              final expectedIndicator = subIndicators.firstWhere((i) => i.key == key);
              expect(
                identical(paintObject!.indicator, expectedIndicator),
                isTrue,
                reason: 'run#$run: 副区 PaintObject($key) 的 indicator 应与缓存一致',
              );
            }
          }
        },
      );
    },
  );

  // =========================================================================
  // Property 3: 取消激活不影响声明层
  // =========================================================================
  group(
    'v2.2.0/IndicatorPaintObjectManager/activate/M3_取消激活不影响声明层',
    () {
      test(
        'removeMainPaintObject/removeSubPaintObject 后 PaintObject 移除，'
        'slot 映射和缓存不变',
        () {
          final rng = Random(101);
          for (int run = 0; run < numRuns; run++) {
            final pair = randomMainSub(rng);
            final context = FakePaintContext();

            final mainIndicators = pair.main.map(createIndicator).toList();
            final subIndicators = pair.sub.map(createIndicator).toList();

            // 全部激活
            final allMainKeys = pair.main.map(descToKey).toSet();
            final allSubKeys = pair.sub.map(descToKey).toSet();

            final config = FakeFlexiKlineConfiguration(
              mainChildren: allMainKeys,
              subKeys: allSubKeys,
            );
            final manager = IndicatorPaintObjectManager(configuration: config);

            manager.mountIndicators(
              candle: TestCandleIndicator(),
              time: TestTimeIndicator(),
              mainIndicators: mainIndicators,
              subIndicators: subIndicators,
              context: context,
            );

            // 记录激活后的 slot 映射快照
            final allKeys = <IIndicatorKey>{...allMainKeys, ...allSubKeys};
            final slotSnapshot = <ComputedIndicatorKey, int>{};
            for (final key in allKeys) {
              if (key is ComputedIndicatorKey) {
                final slot = manager.getComputedDataIndex(key);
                if (slot != null) slotSnapshot[key] = slot;
              }
            }
            final computedDataCapacityBefore = manager.computedDataCapacity;

            // 随机选择要移除的子集
            final removeMainKeys = randomSubset(rng, pair.main).map(descToKey).toSet();
            final removeSubKeys = randomSubset(rng, pair.sub).map(descToKey).toSet();

            for (final key in removeMainKeys) {
              manager.removeMainPaintObject(key);
            }
            for (final key in removeSubKeys) {
              manager.removeSubPaintObject(key);
            }

            // 验证：PaintObject 已从绘制队列移除
            for (final key in removeMainKeys) {
              expect(
                manager.mainPaintObject.children.firstWhereOrNull((obj) => obj.key == key),
                isNull,
                reason: 'run#$run: 已 remove 的主区 key=$key 不应存在',
              );
            }
            for (final key in removeSubKeys) {
              expect(
                manager.subPaintObjects.firstWhereOrNull((obj) => obj.key == key),
                isNull,
                reason: 'run#$run: 已 remove 的副区 key=$key 不应存在',
              );
            }

            // 验证：slot 映射不变
            for (final entry in slotSnapshot.entries) {
              expect(
                manager.getComputedDataIndex(entry.key),
                equals(entry.value),
                reason: 'run#$run: remove 后 ${entry.key} 的 slot 应保持 ${entry.value}',
              );
            }

            // 验证：computedDataCapacity 不变
            expect(manager.computedDataCapacity, equals(computedDataCapacityBefore),
                reason: 'run#$run: remove 后 computedDataCapacity 应保持不变');

            // 验证：缓存不变（重新 add 应成功）
            for (final key in removeMainKeys) {
              expect(manager.addMainPaintObject(key, context), isNotNull,
                  reason: 'run#$run: remove 后重新 addMainPaintObject($key) 应成功');
            }
            for (final key in removeSubKeys) {
              expect(manager.addSubPaintObject(key, context), isNotNull,
                  reason: 'run#$run: remove 后重新 addSubPaintObject($key) 应成功');
            }
          }
        },
      );
    },
  );

  // =========================================================================
  // Property 4: 持久化 key 恢复与自愈
  // =========================================================================
  group(
    'v2.2.0/IndicatorPaintObjectManager/activate/M4_持久化key恢复',
    () {
      test(
        'init() 后实际激活 key 集合等于持久化 key 与声明 key 的交集',
        () {
          final rng = Random(102);
          for (int run = 0; run < numRuns; run++) {
            final pair = randomMainSub(rng);
            final context = FakePaintContext();

            final mainIndicators = pair.main.map(createIndicator).toList();
            final subIndicators = pair.sub.map(createIndicator).toList();

            final declaredMainKeys = pair.main.map(descToKey).toSet();
            final declaredSubKeys = pair.sub.map(descToKey).toSet();

            // 生成随机持久化 key 集合（可能包含不在声明集合中的 key）
            final persistMainDescs = randomIndicatorList(rng);
            final persistSubDescs = randomIndicatorList(rng);
            // 去重
            final seenMain = <String>{};
            final uniquePersistMain = persistMainDescs.where((d) => seenMain.add(d.keyToken)).toList();
            final seenSub = <String>{
              ...uniquePersistMain.map((d) => d.keyToken),
            };
            final uniquePersistSub = persistSubDescs.where((d) => seenSub.add(d.keyToken)).toList();

            final persistMainKeys = uniquePersistMain.map(descToKey).toSet();
            final persistSubKeys = uniquePersistSub.map(descToKey).toSet();

            final expectedMainActivated = persistMainKeys.intersection(declaredMainKeys);
            final expectedSubActivated = persistSubKeys.intersection(declaredSubKeys);

            final config = FakeFlexiKlineConfiguration(
              mainChildren: persistMainKeys,
              subKeys: persistSubKeys,
            );
            final manager = IndicatorPaintObjectManager(configuration: config);

            manager.mountIndicators(
              candle: TestCandleIndicator(),
              time: TestTimeIndicator(),
              mainIndicators: mainIndicators,
              subIndicators: subIndicators,
              context: context,
            );

            // 验证主区激活 key 集合（排除 candle）
            final actualMainKeys = manager.mainIndicatorKeys.where((k) => k != candleIndicatorKey).toSet();
            expect(actualMainKeys, equals(expectedMainActivated),
                reason: 'run#$run: 主区激活 key 应等于 persistMainKeys ∩ declaredMainKeys');

            // 验证副区激活 key 集合（排除 time）
            final actualSubKeys = manager.subIndicatorKeys.where((k) => k != timeIndicatorKey).toSet();
            expect(actualSubKeys, equals(expectedSubActivated),
                reason: 'run#$run: 副区激活 key 应等于 persistSubKeys ∩ declaredSubKeys');
          }
        },
      );
    },
  );
}
