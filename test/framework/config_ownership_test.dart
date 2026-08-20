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

/// 配置所有权契约：FlexiKlineConfig 是运行时状态的实时镜像。
///
/// 锁定 manager 与配置之间的隐式约定，这些约定是多 Controller 共享配置
/// （横竖屏、多 K 线同页）时 `reloadFlexiKlineConfig` 能追平的前提。
library;

import 'dart:math';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  group('v2.4.0/IndicatorPaintObjectManager/config-ownership', () {
    test('运行时 indicator 与配置共享同一 children Set', () {
      final scene = ManagerScenario(Random(0))
        ..declareMain([direct(1)])
        ..mount();
      final manager = scene.manager;

      expect(
        identical(
          manager.mainPaintObject.indicator.children,
          manager.flexiKlineConfig.mainIndicator.children,
        ),
        isTrue,
        reason: 'MainPaintObjectIndicator.copyWith 对 children 传引用、构造函数不复制，'
            '主区激活集合因此实时写入配置。若改为复制，共享配置的其他 Controller '
            '将读不到本侧的激活变更，reloadFlexiKlineConfig 会失效。',
      );
    });

    test('mount 挂载 candle 时一并写入配置的 children', () {
      final scene = ManagerScenario(Random(0))..mount();

      expect(
        scene.manager.flexiKlineConfig.mainIndicator.children,
        contains(candleIndicatorKey),
        reason: 'candle 经 appendPaintObject 挂载，会写入共享的 children。'
            'reloadFlexiKlineConfig 因此必须显式排除 candleIndicatorKey，'
            '否则来自旧版持久化（不含 candle）的配置会把它判为待隐藏。',
      );
    });

    test('主区激活与隐藏实时同步到配置，无需落盘', () {
      final scene = ManagerScenario(Random(0))
        ..declareMain([direct(1)])
        ..mount();
      final manager = scene.manager;
      final key = directKey(1);

      expect(manager.flexiKlineConfig.mainIndicator.children, isNot(contains(key)));

      scene.activateMain(key);
      expect(manager.flexiKlineConfig.mainIndicator.children, contains(key));

      manager.removeMainPaintObject(key);
      expect(manager.flexiKlineConfig.mainIndicator.children, isNot(contains(key)));
    });

    test('副区超容驱逐队首时，配置同步摘除被驱逐的 key', () {
      const capacity = 2;
      final scene = ManagerScenario(Random(0), subMax: capacity)
        ..declareSub([computed(1), computed(2), computed(3)])
        ..mount();
      final manager = scene.manager;

      scene
        ..activateSub(computedKey(1))
        ..activateSub(computedKey(2))
        // 队列已满，激活第三个会驱逐队首 computed_1。
        ..activateSub(computedKey(3));

      expect(manager.subIndicatorKeys, hasLength(capacity));
      expect(
        manager.flexiKlineConfig.sub,
        manager.subIndicatorKeys.toSet(),
        reason: '配置是激活集合的实时镜像。被驱逐的 key 留在配置里会让 sub 超出队列容量，'
            'reload 的差异永不收敛（每次补一个又驱逐一个），并把超容集合写进持久化。',
      );
    });

    test('显式隐藏能清除历史持久化里残留的副区 key', () {
      final scene = ManagerScenario(Random(0))
        ..declareSub([computed(1)])
        ..mount();
      final manager = scene.manager;
      final stale = computedKey(1);
      // 模拟旧版本落盘留下的、不在绘制队列里的 key。
      manager.flexiKlineConfig.sub.add(stale);

      manager.removeSubPaintObject(stale);

      expect(manager.flexiKlineConfig.sub, isNot(contains(stale)));
    });

    test('副区激活与隐藏同样实时同步到配置', () {
      final scene = ManagerScenario(Random(0))
        ..declareSub([computed(1)])
        ..mount();
      final manager = scene.manager;
      final key = computedKey(1);

      expect(manager.flexiKlineConfig.sub, isNot(contains(key)));

      scene.activateSub(key);
      expect(manager.flexiKlineConfig.sub, contains(key));

      manager.removeSubPaintObject(key);
      expect(manager.flexiKlineConfig.sub, isNot(contains(key)));
    });

    test('声明移除时同样从配置的 children 摘除', () {
      final scene = ManagerScenario(Random(0))
        ..declareMain([direct(1)])
        ..mount();
      final manager = scene.manager;
      final key = directKey(1);
      scene.activateMain(key);

      manager.disposeMainPaintObject(key);

      expect(manager.flexiKlineConfig.mainIndicator.children, isNot(contains(key)));
    });
  });
}
