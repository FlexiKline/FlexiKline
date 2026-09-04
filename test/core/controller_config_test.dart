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

/// Controller 级配置行为：落盘时机与重载追平。
library;

import 'dart:ui';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  /// 构造并挂载一个 Controller。
  FlexiKlineController mountController(
    FakeFlexiKlineConfiguration config, {
    List<Indicator> mainIndicators = const [],
    List<Indicator> subIndicators = const [],
  }) {
    final controller = FlexiKlineController(configuration: config);
    controller.mountIndicators(
      candle: TestCandleIndicator(),
      time: TestTimeIndicator(),
      mainIndicators: mainIndicators,
      subIndicators: subIndicators,
    );
    controller.initState();
    return controller;
  }

  group('v2.4.0/FlexiKlineController/config-store', () {
    test('storeFlexiKlineConfig 只落盘，不改写运行时状态', () {
      final config = FakeFlexiKlineConfiguration(shareConfigInstance: true);
      final controller = mountController(config);
      addTearDown(controller.dispose);
      // 共享实例：与 Controller 内部持有的是同一个对象。
      final shared = config.getFlexiKlineConfig();
      final mainIndicatorBefore = shared.mainIndicator;
      final subBefore = shared.sub;

      controller.storeFlexiKlineConfig();

      expect(
        identical(shared.mainIndicator, mainIndicatorBefore),
        isTrue,
        reason: '配置已是运行时的实时镜像，store 不应替换 mainIndicator；'
            '替换会断开与运行时 indicator 的 children 共享。',
      );
      expect(
        identical(shared.sub, subBefore),
        isTrue,
        reason: 'sub 由 add/removeSubPaintObject 实时维护，store 不应替换该 Set。',
      );
      expect(config.savedConfigs, hasLength(1));
      expect(
        identical(config.savedConfigs.single, shared),
        isTrue,
        reason: '落盘的就是 Controller 持有的那份配置对象。',
      );
    });

    test('dispose 不自动落盘', () {
      final config = FakeFlexiKlineConfiguration();
      final controller = mountController(config);

      controller.dispose();

      expect(
        config.savedConfigs,
        isEmpty,
        reason: '落盘时机由业务侧决定，框架不代为保存；'
            '否则从属侧 dispose 会用自己的运行时状态覆盖共享配置。',
      );
    });

    test('onThemeChanged 不自动落盘', () {
      final config = FakeFlexiKlineConfiguration();
      final controller = mountController(config);
      addTearDown(controller.dispose);

      controller.onThemeChanged();

      expect(
        config.savedConfigs,
        isEmpty,
        reason: '主题变化只重建 PaintObject 的主题派生资源，不修改 FlexiKlineConfig。',
      );
    });

    test('未挂载时 storeFlexiKlineConfig 不落盘', () {
      final config = FakeFlexiKlineConfiguration();
      final controller = FlexiKlineController(configuration: config);
      addTearDown(controller.dispose);

      controller.storeFlexiKlineConfig();

      expect(config.savedConfigs, isEmpty);
    });
  });

  group('v2.4.0/FlexiKlineController/config-reload', () {
    final mainKey = directKey(1);
    final subKey = computedKey(1);

    List<Indicator> declaredMain() => [TestDirectIndicator(key: mainKey)];
    List<Indicator> declaredSub() => [TestComputedIndicator(key: subKey)];

    test('配置里已激活而树上没有的指标，reload 后进入绘制树', () {
      final config = FakeFlexiKlineConfiguration(shareConfigInstance: true);
      final controller = mountController(
        config,
        mainIndicators: declaredMain(),
        subIndicators: declaredSub(),
      );
      addTearDown(controller.dispose);
      final shared = config.getFlexiKlineConfig();
      // 模拟对侧 Controller 在共享配置上激活了两个指标。
      shared.mainIndicator.children.add(mainKey);
      shared.sub.add(subKey);

      controller.reloadFlexiKlineConfig();

      expect(controller.mainIndicatorKeys, contains(mainKey));
      expect(controller.subIndicatorKeys, contains(subKey));
    });

    test('树上已激活而配置里没有的指标，reload 后退出绘制树', () {
      final config = FakeFlexiKlineConfiguration(shareConfigInstance: true);
      final controller = mountController(
        config,
        mainIndicators: declaredMain(),
        subIndicators: declaredSub(),
      );
      addTearDown(controller.dispose);
      controller.showMainIndicator(mainKey);
      controller.showSubIndicator(subKey);
      final shared = config.getFlexiKlineConfig();
      // 模拟对侧 Controller 在共享配置上隐藏了两个指标。
      shared.mainIndicator.children.remove(mainKey);
      shared.sub.remove(subKey);

      controller.reloadFlexiKlineConfig();

      expect(controller.mainIndicatorKeys, isNot(contains(mainKey)));
      expect(controller.subIndicatorKeys, isNot(contains(subKey)));
    });

    test('配置 children 不含 candle 时 reload 不误隐藏蜡烛图', () {
      final config = FakeFlexiKlineConfiguration(shareConfigInstance: true);
      final controller = mountController(config);
      addTearDown(controller.dispose);
      final shared = config.getFlexiKlineConfig();
      // 模拟来自旧版持久化的配置：children 里没有 candle。
      shared.mainIndicator.children.clear();

      controller.reloadFlexiKlineConfig();

      expect(
        controller.mainIndicatorKeys,
        contains(candleIndicatorKey),
        reason: 'candle 由 mountIndicators 直接挂载，差异计算必须显式排除它。',
      );
    });

    test('reload 后运行时 indicator 与配置仍共享同一 children Set', () {
      final config = FakeFlexiKlineConfiguration();
      final controller = mountController(config, mainIndicators: declaredMain());
      addTearDown(controller.dispose);
      // 传入新实例，模拟 getFlexiKlineConfig 返回新对象的实现。
      final fresh = config.getFlexiKlineConfig();

      controller.reloadFlexiKlineConfig(fresh);
      controller.showMainIndicator(mainKey);

      expect(
        fresh.mainIndicator.children,
        contains(mainKey),
        reason: 'reload 必须把运行时 indicator 接到新配置的 children Set 上，'
            '否则激活变更写进旧 Set，落盘内容会陈旧。',
      );
    });

    test('candleWidth 追平新配置', () {
      final config = FakeFlexiKlineConfiguration(shareConfigInstance: true);
      final controller = mountController(config);
      addTearDown(controller.dispose);
      final shared = config.getFlexiKlineConfig();
      final target = controller.candleWidth + 3;
      // 模拟对侧缩放结束后写回共享配置。
      shared.setting = shared.setting.copyWith(candleWidth: target);

      controller.reloadFlexiKlineConfig();

      expect(
        controller.candleWidth,
        target,
        reason: '_candleWidth 是 init 时对 settingConfig 的字段快照，须由 reload 重设。',
      );
    });

    test('reload 不回灌主区尺寸', () {
      final config = FakeFlexiKlineConfiguration(shareConfigInstance: true);
      final controller = mountController(config);
      addTearDown(controller.dispose);
      final shared = config.getFlexiKlineConfig();
      final sizeBefore = controller.mainSize;
      // 模拟对侧窗口写入了不同的主区尺寸。
      shared.mainIndicator.size = Size(sizeBefore.width + 50, sizeBefore.height + 50);

      controller.reloadFlexiKlineConfig();

      expect(
        controller.mainSize,
        sizeBefore,
        reason: '主区尺寸是窗口局部状态，共享配置时不应被对侧覆盖。',
      );
    });

    test('reload 不改变 computed slot 布局', () {
      final config = FakeFlexiKlineConfiguration(shareConfigInstance: true);
      final controller = mountController(config, subIndicators: declaredSub());
      addTearDown(controller.dispose);
      final capacityBefore = controller.computedDataCapacity;
      final slotBefore = controller.getComputedDataIndex(subKey);

      controller.reloadFlexiKlineConfig();

      expect(controller.computedDataCapacity, capacityBefore);
      expect(controller.getComputedDataIndex(subKey), slotBefore);
    });

    test('未挂载时 reload 只替换配置，不触碰绘制树', () {
      final config = FakeFlexiKlineConfiguration(mainChildren: {mainKey});
      final controller = FlexiKlineController(configuration: config);
      addTearDown(controller.dispose);

      expect(controller.reloadFlexiKlineConfig, returnsNormally);

      // mount 后仍按配置恢复激活集合。
      controller.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: declaredMain(),
        subIndicators: const [],
      );
      controller.initState();
      expect(controller.mainIndicatorKeys, contains(mainKey));
    });

    test('共享配置的两个 Controller 无需落盘即可互相追平', () {
      final config = FakeFlexiKlineConfiguration(shareConfigInstance: true);
      final a = mountController(config, mainIndicators: declaredMain(), subIndicators: declaredSub());
      final b = mountController(config, mainIndicators: declaredMain(), subIndicators: declaredSub());
      addTearDown(a.dispose);
      addTearDown(b.dispose);

      a.showMainIndicator(mainKey);
      a.showSubIndicator(subKey);
      b.reloadFlexiKlineConfig();

      expect(config.savedConfigs, isEmpty, reason: '同步不应依赖落盘。');
      expect(b.mainIndicatorKeys, contains(mainKey));
      expect(b.subIndicatorKeys, contains(subKey));
    });

    test('多个 Controller 依次 reload 幂等，配置不被中间态污染', () {
      final config = FakeFlexiKlineConfiguration(shareConfigInstance: true);
      final a = mountController(config, mainIndicators: declaredMain(), subIndicators: declaredSub());
      final b = mountController(config, mainIndicators: declaredMain(), subIndicators: declaredSub());
      final c = mountController(config, mainIndicators: declaredMain(), subIndicators: declaredSub());
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      addTearDown(c.dispose);

      a.showMainIndicator(mainKey);
      a.showSubIndicator(subKey);
      b.reloadFlexiKlineConfig();
      c.reloadFlexiKlineConfig();

      expect(b.mainIndicatorKeys, contains(mainKey));
      expect(c.mainIndicatorKeys, contains(mainKey));
      expect(b.subIndicatorKeys, contains(subKey));
      expect(c.subIndicatorKeys, contains(subKey));
    });

    test('副区超容时 reload 收敛，不逐次轮转', () {
      const capacity = 2;
      final subKeys = [computedKey(1), computedKey(2), computedKey(3)];
      final config = FakeFlexiKlineConfiguration(shareConfigInstance: true);
      final controller = FlexiKlineController(
        configuration: config,
        subIndicatorMaxCount: capacity,
      );
      addTearDown(controller.dispose);
      controller.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: [for (final key in subKeys) TestComputedIndicator(key: key)],
      );
      controller.initState();
      // 激活到超出容量，触发队首驱逐。
      for (final key in subKeys) {
        controller.showSubIndicator(key);
      }
      final settled = controller.subIndicatorKeys.toSet();

      controller.reloadFlexiKlineConfig();
      final afterFirst = controller.subIndicatorKeys.toSet();
      controller.reloadFlexiKlineConfig();
      final afterSecond = controller.subIndicatorKeys.toSet();

      expect(settled, hasLength(capacity));
      expect(
        afterFirst,
        settled,
        reason: '驱逐后配置若仍留着被驱逐的 key，subToShow 会恒非空，'
            '每次 reload 补一个又驱逐一个，副区可见指标逐次轮转。',
      );
      expect(afterSecond, settled);
    });

    test('fixed 布局下 reload 不把临时尺寸写成持久尺寸', () {
      const persisted = Size(400, 300);
      final config = FakeFlexiKlineConfiguration(
        shareConfigInstance: true,
        mainIndicatorDefaultSize: persisted,
      );
      final controller = FlexiKlineController(
        configuration: config,
        initialLayoutMode: FlexiLayoutMode.fixed,
      );
      addTearDown(controller.dispose);
      controller.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: const [],
      );
      controller.initState();
      final shared = config.getFlexiKlineConfig();
      final persistedBefore = shared.mainIndicator.size;
      // fixed 下画布尺寸只进 _tmpSize，不写 indicator.size。
      controller.setFixedLayoutMode(Size(persisted.width, persisted.height + 100));

      controller.reloadFlexiKlineConfig();

      expect(
        shared.mainIndicator.size,
        persistedBefore,
        reason: 'reload 取 indicator.size 而非 MainPaintObject.size（后者是 '
            '`_tmpSize ?? indicator.size`），否则 fixed 的临时尺寸会被写成持久尺寸。',
      );
    });

    test('共享配置时各 Controller 的运行时主区尺寸互不影响', () {
      final config = FakeFlexiKlineConfiguration(shareConfigInstance: true);
      final a = mountController(config);
      final b = mountController(config);
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      final sizeBefore = b.mainSize;

      a.setMainSize(Size(sizeBefore.width + 40, sizeBefore.height + 40));

      expect(
        b.mainSize,
        sizeBefore,
        reason: '组合 A 的核心保护：copyWith 隔离 size，一个窗口的布局不串改另一个。',
      );
    });
  });

  /// [SettingConfig] 是 const 构造、原样存值，越界修正都在 `SettingBinding` 的 getter 里。
  group('v2.5.0/FlexiKlineController/config-clamp', () {
    test('candleMinWidth 不小于 1', () {
      final controller = mountController(FakeFlexiKlineConfiguration());
      addTearDown(controller.dispose);

      controller.updateSettingConfig((c) => c.copyWith(candleMinWidth: 0, candleFixedSpacing: null));

      expect(controller.candleMinWidth, 1);
      expect(controller.candleMaxWidth, greaterThanOrEqualTo(controller.candleMinWidth));
    });

    /// 触摸端缩放是加法（`candleWidth + dxGrowth` 再 clamp 到 `candleMinWidth`），所以下界
    /// 归零时蜡烛宽度会精确落到 0；未配 `candleFixedSpacing` 时间距按宽度派生也一起归零，
    /// `candleActualWidth` 于是为 0。滚轮那条路是乘法，只会趋零、够不到 0。
    ///
    /// 断言取根因（宽度与实际宽度非零）而不是崩溃：`candleActualWidth == 0` 会让按宽度推算
    /// 蜡烛数量的循环不收敛，驱动绘制时实测抛 StackOverflowError，但本用例不跑绘制。
    test('candleMinWidth 归零不会让 candleActualWidth 归零', () {
      final controller = mountController(FakeFlexiKlineConfiguration());
      addTearDown(controller.dispose);
      controller.updateSettingConfig((c) => c.copyWith(candleMinWidth: 0, candleFixedSpacing: null));

      // 一路缩到下界，逐步逼近而不是一次跳过去，确保真的踩在 clamp 上。
      final data = GestureData.scale(Offset.zero, position: ScalePosition.middle);
      for (var i = 1; i <= 30; i++) {
        data.update(Offset.zero, newScale: 1.0 - i * 0.03);
        controller.onChartScale(data);
      }

      expect(controller.candleWidth, greaterThan(0));
      expect(controller.candleActualWidth, greaterThan(0));
    });
  });
}
