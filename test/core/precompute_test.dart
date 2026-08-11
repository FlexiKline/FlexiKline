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

/// 集成测试：参数变化时 manager 上报 recompute（实际重算由计算引擎驱动）。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  group('v2.2.0/precompute', () {
    test('配置变化且 shouldRecompute=true 时上报 recompute', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      const key = ComputedIndicatorKey('spy_1');

      final config = FakeFlexiKlineConfiguration(mainChildren: {key});
      final m = IndicatorPaintObjectManager(configuration: config);
      final oldInd = SpyComputedIndicator(key: key, log: log, recompute: true);
      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [oldInd],
        subIndicators: const [],
        context: ctx,
      );

      final newInd = SpyComputedIndicator(key: key, log: log, recompute: true);
      final result = m.updateIndicators(
        context: ctx,
        oldCandle: TestCandleIndicator(),
        newCandle: TestCandleIndicator(),
        oldTime: TestTimeIndicator(),
        newTime: TestTimeIndicator(),
        oldMainIndicators: [oldInd],
        newMainIndicators: [newInd],
        oldSubIndicators: const [],
        newSubIndicators: const [],
      );

      expect(
        result.recompute,
        contains(key),
        reason: 'shouldRecompute=true 时应上报该 key 需重算',
      );
      expect(result.slotLayoutChanged, isFalse);
    });

    test('shouldRecompute=false 时不上报 recompute', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      const key = ComputedIndicatorKey('spy_2');

      final config = FakeFlexiKlineConfiguration(mainChildren: {key});
      final m = IndicatorPaintObjectManager(configuration: config);
      final oldInd = SpyComputedIndicator(key: key, log: log, recompute: false);
      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [oldInd],
        subIndicators: const [],
        context: ctx,
      );

      final newInd = SpyComputedIndicator(key: key, log: log, recompute: false);
      final result = m.updateIndicators(
        context: ctx,
        oldCandle: TestCandleIndicator(),
        newCandle: TestCandleIndicator(),
        oldTime: TestTimeIndicator(),
        newTime: TestTimeIndicator(),
        oldMainIndicators: [oldInd],
        newMainIndicators: [newInd],
        oldSubIndicators: const [],
        newSubIndicators: const [],
      );

      expect(
        result.recompute,
        isEmpty,
        reason: 'shouldRecompute=false 时不应上报重算',
      );
      expect(result.slotLayoutChanged, isFalse);
    });

    test('删除 A 并新增 B 复用 slot 时上报 slot layout 变化', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      const oldKey = ComputedIndicatorKey('old');
      const newKey = ComputedIndicatorKey('new');
      final manager = IndicatorPaintObjectManager(
        configuration: FakeFlexiKlineConfiguration(mainChildren: {oldKey}),
      );
      final oldIndicator = SpyComputedIndicator(key: oldKey, log: log);
      manager.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [oldIndicator],
        subIndicators: const [],
        context: ctx,
      );
      final oldSlot = manager.getComputedDataIndex(oldKey);
      final newIndicator = SpyComputedIndicator(key: newKey, log: log);

      final result = manager.updateIndicators(
        context: ctx,
        oldCandle: TestCandleIndicator(),
        newCandle: TestCandleIndicator(),
        oldTime: TestTimeIndicator(),
        newTime: TestTimeIndicator(),
        oldMainIndicators: [oldIndicator],
        newMainIndicators: [newIndicator],
        oldSubIndicators: const [],
        newSubIndicators: const [],
      );

      expect(manager.getComputedDataIndex(newKey), oldSlot);
      expect(result.slotLayoutChanged, isTrue);
    });
  });
}
