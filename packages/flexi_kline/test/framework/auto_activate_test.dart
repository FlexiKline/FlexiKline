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

/// 专项测试：autoActivate 自动激活设计不变量。
///
/// 覆盖三类指标首次自动激活、false↔true 翻转语义、持久化 ∪ autoActivate
/// 并存与去重等设计不变量。语义依据（lib 侧已定稿）：
/// - mount 时以「持久化恢复 key ∪ autoActivate==true 声明」去重后自动激活入树；
/// - updateIndicators 只返回本轮待激活 key（`!old.autoActivate && new.autoActivate`
///   且当前未在树），不自行创建/入树；
/// - autoActivate 只触发自动 show，由 true 变 false 不会自动 hide。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  IndicatorPaintObjectManager build({
    Set<IIndicatorKey>? mainChildren,
    Set<IIndicatorKey>? subKeys,
    int subMax = defaultSubIndicatorMaxCount,
  }) {
    return IndicatorPaintObjectManager(
      configuration: FakeFlexiKlineConfiguration(
        mainChildren: mainChildren,
        subKeys: subKeys,
      ),
      subIndicatorMaxCount: subMax,
    );
  }

  /// 主区激活 key（排除系统 candle）。
  Set<IIndicatorKey> mainActivated(IndicatorPaintObjectManager m) =>
      m.mainIndicatorKeys.where((k) => k != candleIndicatorKey).toSet();

  /// 副区激活 key（排除系统 time）。
  Set<IIndicatorKey> subActivated(IndicatorPaintObjectManager m) =>
      m.subIndicatorKeys.where((k) => k != timeIndicatorKey).toSet();

  group('autoActivate/首次自动激活', () {
    test('三类指标 autoActivate:true 首次声明 → mount 后均在对应绘制树', () {
      final ctx = FakePaintContext();
      final m = build();
      const directK = DirectIndicatorKey('d1');
      const computedK = ComputedIndicatorKey('c1');
      const externalK = ExternalIndicatorKey('e1');

      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [
          TestDirectIndicator(key: directK, autoActivate: true),
          TestComputedIndicator(key: computedK, autoActivate: true),
        ],
        subIndicators: [
          TestExternalIndicator(key: externalK, autoActivate: true),
        ],
        context: ctx,
      );

      expect(mainActivated(m), containsAll(<IIndicatorKey>[directK, computedK]));
      expect(subActivated(m), contains(externalK));
    });
  });

  group('autoActivate/翻转语义', () {
    test('false→true：mount 未激活；update 返回该 key 为待激活', () {
      final ctx = FakePaintContext();
      final m = build();
      const key = ExternalIndicatorKey('e_flip');
      final oldExt = TestExternalIndicator(key: key, autoActivate: false);

      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [oldExt],
        subIndicators: const [],
        context: ctx,
      );

      // autoActivate:false → mount 不激活。
      expect(mainActivated(m), isNot(contains(key)));

      final newExt = TestExternalIndicator(key: key, autoActivate: true);
      final indicatorChanges = m.updateIndicators(
        context: ctx,
        oldCandle: TestCandleIndicator(),
        newCandle: TestCandleIndicator(),
        oldTime: TestTimeIndicator(),
        newTime: TestTimeIndicator(),
        oldMainIndicators: [oldExt],
        newMainIndicators: [newExt],
        oldSubIndicators: const [],
        newSubIndicators: const [],
      );

      expect(indicatorChanges.main, contains(key)); // false→true → 待激活
    });

    test('true→false：indicatorChanges 不含该 key，且对象仍在树（不自动 hide）', () {
      final ctx = FakePaintContext();
      final m = build();
      const key = ExternalIndicatorKey('e_stay');
      final oldExt = TestExternalIndicator(key: key, autoActivate: true);

      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [oldExt],
        subIndicators: const [],
        context: ctx,
      );

      // autoActivate:true → mount 已激活入树。
      expect(mainActivated(m), contains(key));

      final newExt = TestExternalIndicator(key: key, autoActivate: false);
      final indicatorChanges = m.updateIndicators(
        context: ctx,
        oldCandle: TestCandleIndicator(),
        newCandle: TestCandleIndicator(),
        oldTime: TestTimeIndicator(),
        newTime: TestTimeIndicator(),
        oldMainIndicators: [oldExt],
        newMainIndicators: [newExt],
        oldSubIndicators: const [],
        newSubIndicators: const [],
      );

      expect(indicatorChanges.main, isNot(contains(key))); // 不重激活
      expect(mainActivated(m), contains(key)); // 仍在树（true→false 不 hide）
    });

    test('hide 后同值 rebuild：indicatorChanges 不含该 key，且不在树', () {
      final ctx = FakePaintContext();
      final m = build();
      const key = ExternalIndicatorKey('e_hide');
      final ext = TestExternalIndicator(key: key, autoActivate: true);

      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [ext],
        subIndicators: const [],
        context: ctx,
      );
      expect(mainActivated(m), contains(key));

      // 用户隐藏。
      m.removeMainPaintObject(key);
      expect(mainActivated(m), isNot(contains(key)));

      // old(true)→new(true) 同值 rebuild：条件 !old.autoActivate 为 false → 不重激活。
      final indicatorChanges = m.updateIndicators(
        context: ctx,
        oldCandle: TestCandleIndicator(),
        newCandle: TestCandleIndicator(),
        oldTime: TestTimeIndicator(),
        newTime: TestTimeIndicator(),
        oldMainIndicators: [ext],
        newMainIndicators: [TestExternalIndicator(key: key, autoActivate: true)],
        oldSubIndicators: const [],
        newSubIndicators: const [],
      );

      expect(indicatorChanges.main, isNot(contains(key)));
      expect(mainActivated(m), isNot(contains(key))); // 保持隐藏
    });
  });

  group('autoActivate/持久化并存与去重', () {
    test('持久化 ∪ autoActivate：mount 后主区含持久化 A 与 auto B', () {
      final ctx = FakePaintContext();
      const keyA = DirectIndicatorKey('persist_a');
      const keyB = DirectIndicatorKey('auto_b');
      final m = build(mainChildren: {keyA});

      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [
          TestDirectIndicator(key: keyA, autoActivate: false), // 仅靠持久化恢复
          TestDirectIndicator(key: keyB, autoActivate: true), // 仅靠 autoActivate
        ],
        subIndicators: const [],
        context: ctx,
      );

      expect(mainActivated(m), containsAll(<IIndicatorKey>[keyA, keyB]));
    });

    test('副区去重不误驱逐：持久化与 autoActivate 同 key，subMax=1 → 恰含一个', () {
      final ctx = FakePaintContext();
      const keyA = ExternalIndicatorKey('dup_a');
      final m = build(subKeys: {keyA}, subMax: 1);

      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: [
          TestExternalIndicator(key: keyA, autoActivate: true),
        ],
        context: ctx,
      );

      // 持久化 {a} ∪ auto {a} 去重 → 仅入队一次，不因两条路径重复入队而自我驱逐。
      expect(subActivated(m), equals(<IIndicatorKey>{keyA}));
    });
  });

  group('autoActivate/sync 与 mount 同口径', () {
    // 回归：sync 只看 children/sub，而 mount 激活 children ∪ autoActivate，
    // 导致仅靠 autoActivate 入树的指标被 sync 误判为待隐藏。
    test('主区 autoActivate 指标不在 children → sync 不把它判为待隐藏', () {
      final ctx = FakePaintContext();
      const key = DirectIndicatorKey('auto_main');
      // children 为空：该 key 仅靠 autoActivate 入树。
      final m = build();

      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [TestDirectIndicator(key: key, autoActivate: true)],
        subIndicators: const [],
        context: ctx,
      );
      expect(mainActivated(m), contains(key));

      final diff = m.syncFlexiKlineConfig();

      expect(diff.mainToHide, isNot(contains(key)));
      expect(mainActivated(m), contains(key));
    });

    test('副区 autoActivate 指标不在 sub → sync 不把它判为待隐藏', () {
      final ctx = FakePaintContext();
      const key = ExternalIndicatorKey('auto_sub');
      final m = build();

      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: [TestExternalIndicator(key: key, autoActivate: true)],
        context: ctx,
      );
      expect(subActivated(m), contains(key));

      final diff = m.syncFlexiKlineConfig();

      expect(diff.subToHide, isNot(contains(key)));
      expect(subActivated(m), contains(key));
    });

    test('非 autoActivate 的持久化指标从 children 移除 → sync 仍判为待隐藏', () {
      final ctx = FakePaintContext();
      const key = DirectIndicatorKey('persist_only');
      // 初始 children 含该 key，但 autoActivate:false。
      final m = build(mainChildren: {key});

      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [TestDirectIndicator(key: key, autoActivate: false)],
        subIndicators: const [],
        context: ctx,
      );
      expect(mainActivated(m), contains(key));

      // 构造一份 children 不含该 key 的新配置来 sync（模拟用户隐藏后另一侧追平）。
      final current = m.flexiKlineConfig;
      final next = FlexiKlineConfig(
        grid: current.grid,
        setting: current.setting,
        gesture: current.gesture,
        cross: current.cross,
        draw: current.draw,
        mainIndicator: current.mainIndicator.copyWith(children: <IIndicatorKey>{}),
        sub: current.sub,
      );
      final diff = m.syncFlexiKlineConfig(next);

      // 非 autoActivate 不被豁免，照常待隐藏。
      expect(diff.mainToHide, contains(key));
    });

    test('非 autoActivate 指标经 add 激活后 → sync 同一份配置不隐藏（主/副区）', () {
      final ctx = FakePaintContext();
      const mainKey = DirectIndicatorKey('manual_main');
      const subKey = ExternalIndicatorKey('manual_sub');
      final m = build();

      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [TestDirectIndicator(key: mainKey, autoActivate: false)],
        subIndicators: [TestExternalIndicator(key: subKey, autoActivate: false)],
        context: ctx,
      );
      // 仅声明、未激活。
      expect(mainActivated(m), isNot(contains(mainKey)));
      expect(subActivated(m), isNot(contains(subKey)));

      // 手动激活会把 key 写进与配置共享的 children / sub。
      m.addMainPaintObject(mainKey, ctx);
      m.addSubPaintObject(subKey, ctx);
      expect(mainActivated(m), contains(mainKey));
      expect(subActivated(m), contains(subKey));

      final diff = m.syncFlexiKlineConfig(m.flexiKlineConfig);

      expect(diff.mainToHide, isNot(contains(mainKey)));
      expect(diff.subToHide, isNot(contains(subKey)));
      expect(mainActivated(m), contains(mainKey));
      expect(subActivated(m), contains(subKey));
    });

    test('配置 children 含未注册 key（如横屏独有指标回到竖屏）→ 忽略，不 show 也不 hide，key 保留', () {
      final ctx = FakePaintContext();
      const unregistered = DirectIndicatorKey('landscape_only');
      final m = build(mainChildren: {unregistered}, subKeys: {const ExternalIndicatorKey('landscape_sub')});

      // 竖屏侧未注册该 key：mount 跳过并告警，不入树。
      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: const [],
        context: ctx,
      );
      expect(mainActivated(m), isEmpty);
      expect(subActivated(m), isEmpty);

      final diff = m.syncFlexiKlineConfig(m.flexiKlineConfig);

      expect(diff.mainToShow, isEmpty);
      expect(diff.mainToHide, isEmpty);
      expect(diff.subToShow, isEmpty);
      expect(diff.subToHide, isEmpty);
      // 未注册 key 不被清理：共享配置回到横屏侧时仍能恢复。
      expect(m.flexiKlineConfig.mainIndicator.children, contains(unregistered));
    });
  });
}
