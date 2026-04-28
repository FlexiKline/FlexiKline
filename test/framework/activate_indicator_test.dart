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
///
/// 包含以下属性：
/// - **Property 2: 从缓存激活指标** — Validates: Requirements 1.3, 1.4
/// - **Property 3: 取消激活不影响声明层** — Validates: Requirements 1.5, 1.6
/// - **Property 4: 持久化 key 恢复与自愈** — Validates: Requirements 3.2, 3.3, 3.4, 13.4
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:glados/glados.dart';

import '../helpers/indicator_test_helpers.dart';
import '../helpers/test_indicators.dart';
import '../helpers/test_kline_config.dart';
import '../helpers/test_paint_context.dart';

void main() {
  final gen = mainSubGen();

  // =========================================================================
  // Property 2: 从缓存激活指标
  // =========================================================================
  group(
    'Feature: widget-style-indicator-system-v4, '
    'Property 2: 从缓存激活指标',
    () {
      /// **Validates: Requirements 1.3, 1.4**
      ///
      /// 对于任意已通过 mountIndicators 声明的 Indicator 集合，以及该集合的
      /// 任意子集 S，对 S 中每个 key 调用 addMainPaintObject 或
      /// addSubPaintObject 后，对应区域的 PaintObject 集合的 key 应恰好等于 S，
      /// 且每个 PaintObject 的 indicator 应与 _declaredIndicators 中缓存的实例一致。
      Glados(
        gen.bind(
          (pair) => any.intInRange(0, pair.main.length + 1).bind(
                (mainSubsetLen) =>
                    any.intInRange(0, pair.sub.length.clamp(0, defaultSubIndicatorMaxCount) + 1).map((subSubsetLen) {
                  final mainSubset = pair.main.take(mainSubsetLen).toList();
                  final subSubset = pair.sub.take(subSubsetLen).toList();
                  return (
                    allMain: pair.main,
                    allSub: pair.sub,
                    activateMain: mainSubset,
                    activateSub: subSubset,
                  );
                }),
              ),
        ),
        ExploreConfig(numRuns: 100),
      ).test(
        'mountIndicators 后 PaintObject 集合的 key 等于激活子集 S，'
        '且每个 PaintObject 的 indicator 与缓存一致',
        (input) {
          final context = TestPaintContext();

          final mainIndicators = input.allMain.map(createIndicator).toList();
          final subIndicators = input.allSub.map(createIndicator).toList();

          // 构建持久化 key 集合（激活子集）
          final mainChildrenKeys = input.activateMain.map(descToKey).toSet();
          final subKeys = input.activateSub.map(descToKey).toSet();

          // 保存一份副本用于验证（init 中 appendPaintObject 会修改原 Set）
          final expectedMainChildrenKeys = Set<IIndicatorKey>.of(mainChildrenKeys);
          final expectedSubKeys = Set<IIndicatorKey>.of(subKeys);

          final config = TestFlexiKlineConfiguration(
            mainChildren: mainChildrenKeys,
            subKeys: subKeys,
          );
          final manager = createManager(config);

          // 1. 挂载指标：注册 slot + 缓存 + 创建 PaintObject + 恢复已选中指标
          manager.mountIndicators(
            candle: TestCandleIndicator(),
            time: TestTimeIndicator(),
            mainIndicators: mainIndicators,
            subIndicators: subIndicators,
            context: context,
          );

          // 3. 验证主区 PaintObject 集合的 key（排除 candle）
          final actualMainKeysFiltered = manager.mainIndicatorKeys.where((k) => k != candleIndicatorKey).toSet();
          expect(
            actualMainKeysFiltered,
            equals(expectedMainChildrenKeys),
            reason: '主区 PaintObject key 集合（排除 candle）应等于激活子集 '
                '$expectedMainChildrenKeys，但实际为 $actualMainKeysFiltered',
          );

          // 4. 验证副区 PaintObject 集合的 key（排除 time）
          final actualSubKeysFiltered = manager.subIndicatorKeys.where((k) => k != timeIndicatorKey).toSet();
          expect(
            actualSubKeysFiltered,
            equals(expectedSubKeys),
            reason: '副区 PaintObject key 集合应等于激活子集 '
                '$expectedSubKeys，但实际为 $actualSubKeysFiltered',
          );

          // 5. 验证每个主区 PaintObject 的 indicator 与传入的 Indicator 实例一致
          for (final key in expectedMainChildrenKeys) {
            final paintObject = manager.mainPaintObject.children.firstWhereOrNull((obj) => obj.key == key);
            expect(paintObject, isNotNull, reason: '主区应包含 key=$key 的 PaintObject');
            final expectedIndicator = mainIndicators.firstWhere((i) => i.key == key);
            expect(
              identical(paintObject!.indicator, expectedIndicator),
              isTrue,
              reason: '主区 PaintObject($key) 的 indicator 应与缓存实例一致',
            );
          }

          // 6. 验证每个副区 PaintObject 的 indicator 与传入的 Indicator 实例一致
          for (final key in expectedSubKeys) {
            final paintObject = manager.subPaintObjects.firstWhereOrNull((obj) => obj.key == key);
            expect(paintObject, isNotNull, reason: '副区应包含 key=$key 的 PaintObject');
            final expectedIndicator = subIndicators.firstWhere((i) => i.key == key);
            expect(
              identical(paintObject!.indicator, expectedIndicator),
              isTrue,
              reason: '副区 PaintObject($key) 的 indicator 应与缓存实例一致',
            );
          }
        },
      );
    },
  );

  // =========================================================================
  // Property 3: 取消激活不影响声明层
  // =========================================================================
  group(
    'Feature: widget-style-indicator-system-v4, '
    'Property 3: 取消激活不影响声明层',
    () {
      /// **Validates: Requirements 1.5, 1.6**
      Glados(
        gen.bind(
          (pair) {
            final totalLen = pair.main.length + pair.sub.length;
            if (totalLen == 0) {
              return any.always((
                allMain: pair.main,
                allSub: pair.sub,
                removeMain: <IndicatorDesc>[],
                removeSub: <IndicatorDesc>[],
              ));
            }
            return any.intInRange(0, pair.main.length + 1).bind(
                  (rmMainLen) => any.intInRange(0, pair.sub.length + 1).map((rmSubLen) {
                    return (
                      allMain: pair.main,
                      allSub: pair.sub,
                      removeMain: pair.main.take(rmMainLen).toList(),
                      removeSub: pair.sub.take(rmSubLen).toList(),
                    );
                  }),
                );
          },
        ),
        ExploreConfig(numRuns: 100),
      ).test(
        'removeMainPaintObject/removeSubPaintObject 后 PaintObject 移除，'
        'slot 映射和缓存不变',
        (input) {
          final context = TestPaintContext();

          final mainIndicators = input.allMain.map(createIndicator).toList();
          final subIndicators = input.allSub.map(createIndicator).toList();

          // 全部激活
          final allMainKeys = input.allMain.map(descToKey).toSet();
          final allSubKeys = input.allSub.map(descToKey).toSet();

          final config = TestFlexiKlineConfiguration(
            mainChildren: allMainKeys,
            subKeys: allSubKeys,
          );
          final manager = createManager(config);

          manager.mountIndicators(
            candle: TestCandleIndicator(),
            time: TestTimeIndicator(),
            mainIndicators: mainIndicators,
            subIndicators: subIndicators,
            context: context,
          );

          // 记录激活后的 slot 映射快照
          final allKeys = <IIndicatorKey>{...allMainKeys, ...allSubKeys};
          final slotSnapshot = <DataIndicatorKey, int>{};
          for (final key in allKeys) {
            if (key is DataIndicatorKey) {
              final slot = manager.getIndicatorDataIndex(key);
              if (slot != null) slotSnapshot[key] = slot;
            }
          }
          final indicatorCountBefore = manager.indicatorCount;

          // 执行 remove 操作
          final removeMainKeys = input.removeMain.map(descToKey).toSet();
          final removeSubKeys = input.removeSub.map(descToKey).toSet();

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
              reason: '已 remove 的主区 key=$key 不应存在于绘制队列中',
            );
          }
          for (final key in removeSubKeys) {
            expect(
              manager.subPaintObjects.firstWhereOrNull((obj) => obj.key == key),
              isNull,
              reason: '已 remove 的副区 key=$key 不应存在于绘制队列中',
            );
          }

          // 验证：slot 映射不变
          for (final entry in slotSnapshot.entries) {
            expect(
              manager.getIndicatorDataIndex(entry.key),
              equals(entry.value),
              reason: 'remove 后 ${entry.key} 的 slot 应保持 ${entry.value}',
            );
          }

          // 验证：indicatorCount 不变
          expect(manager.indicatorCount, equals(indicatorCountBefore), reason: 'remove 后 indicatorCount 应保持不变');

          // 验证：缓存不变（重新 add 应成功）
          for (final key in removeMainKeys) {
            expect(manager.addMainPaintObject(key, context), isNotNull,
                reason: 'remove 后重新 addMainPaintObject($key) 应成功');
          }
          for (final key in removeSubKeys) {
            expect(manager.addSubPaintObject(key, context), isNotNull,
                reason: 'remove 后重新 addSubPaintObject($key) 应成功');
          }
        },
      );
    },
  );

  // =========================================================================
  // Property 4: 持久化 key 恢复与自愈
  // =========================================================================
  group(
    'Feature: widget-style-indicator-system-v4, '
    'Property 4: 持久化 key 恢复与自愈',
    () {
      /// **Validates: Requirements 3.2, 3.3, 3.4, 13.4**
      ///
      /// 持久化 key 集合可能包含不在声明集合中的 key，init() 后实际激活的
      /// key 集合应等于持久化 key 与声明 key 的交集。
      Glados(
        gen.bind(
          (pair) {
            return any.intInRange(0, 9).bind(
                  (persistMainLen) => any
                      .listWithLength(
                        persistMainLen,
                        any.intInRange(0, 25).bind(
                              (id) => any.choose([IndicatorType.data, IndicatorType.business]).map(
                                  (type) => IndicatorDesc(type, id)),
                            ),
                      )
                      .bind(
                        (persistMainDescs) => any.intInRange(0, 9).bind(
                              (persistSubLen) => any
                                  .listWithLength(
                                persistSubLen,
                                any.intInRange(0, 25).bind(
                                      (id) => any.choose([IndicatorType.data, IndicatorType.business]).map(
                                          (type) => IndicatorDesc(type, id)),
                                    ),
                              )
                                  .map((persistSubDescs) {
                                final seenMain = <String>{};
                                final uniquePersistMain =
                                    persistMainDescs.where((d) => seenMain.add('${d.type.name}_${d.id}')).toList();
                                final seenSub = <String>{
                                  ...uniquePersistMain.map((d) => '${d.type.name}_${d.id}'),
                                };
                                final uniquePersistSub =
                                    persistSubDescs.where((d) => seenSub.add('${d.type.name}_${d.id}')).toList();
                                return (
                                  declaredMain: pair.main,
                                  declaredSub: pair.sub,
                                  persistMain: uniquePersistMain,
                                  persistSub: uniquePersistSub,
                                );
                              }),
                            ),
                      ),
                );
          },
        ),
        ExploreConfig(numRuns: 100),
      ).test(
        'init() 后实际激活 key 集合等于持久化 key 与声明 key 的交集',
        (input) {
          final context = TestPaintContext();

          final mainIndicators = input.declaredMain.map(createIndicator).toList();
          final subIndicators = input.declaredSub.map(createIndicator).toList();

          final declaredMainKeys = input.declaredMain.map(descToKey).toSet();
          final declaredSubKeys = input.declaredSub.map(descToKey).toSet();

          final persistMainKeys = input.persistMain.map(descToKey).toSet();
          final persistSubKeys = input.persistSub.map(descToKey).toSet();

          // main 和 sub 的声明缓存是分开的，交集需要分别计算
          final expectedMainActivated = persistMainKeys.intersection(declaredMainKeys);
          final expectedSubActivated = persistSubKeys.intersection(declaredSubKeys);

          final config = TestFlexiKlineConfiguration(
            mainChildren: persistMainKeys,
            subKeys: persistSubKeys,
          );
          final manager = createManager(config);

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
              reason: '主区激活 key 应等于 persistMainKeys ∩ declaredMainKeys');

          // 验证副区激活 key 集合（排除 time）
          final actualSubKeys = manager.subIndicatorKeys.where((k) => k != timeIndicatorKey).toSet();
          expect(actualSubKeys, equals(expectedSubActivated), reason: '副区激活 key 应等于 persistSubKeys ∩ declaredSubKeys');
        },
      );
    },
  );
}
