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

/// 集成测试：shouldRecompute 触发 compute
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  group('v2.2.0/precompute', () {
    test('配置变化且 shouldRecompute=true 时触发 compute', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      const key = ComputedIndicatorKey('spy_1');

      // mount 并激活（mainChildren 包含 key）
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

      // 清除 mount 阶段可能产生的 compute 记录
      log.clear();

      // 更新指标配置，shouldRecompute=true 应触发 compute
      final newInd = SpyComputedIndicator(key: key, log: log, recompute: true);
      m.updateIndicators(
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

      // compute 会被调用（即使 klineData 为空，Range(0,0)）
      expect(
        log.events.where((e) => e.startsWith('compute:')).isNotEmpty,
        isTrue,
        reason: 'shouldRecompute=true 时应触发 compute',
      );
    });

    test('shouldRecompute=false 时不触发 compute', () {
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

      log.clear();

      final newInd = SpyComputedIndicator(key: key, log: log, recompute: false);
      m.updateIndicators(
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
        log.events.where((e) => e.startsWith('compute:')).isEmpty,
        isTrue,
        reason: 'shouldRecompute=false 时不应触发 compute',
      );
    });
  });
}
