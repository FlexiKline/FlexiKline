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

/// 集成测试：多 KlineData 下的 computed slot 容量对齐。
///
/// 声明新增 computed 指标（slot 容量高水位增长）时，
/// [SettingBinding.updateIndicators] 应触发 `syncComputedSlotCapacity`：
/// 1. 当前 KlineData 的已有蜡烛按新容量扩容（不再越界丢数据）；
/// 2. 其余缓存 KlineData 因指标声明已变、slot 值陈旧，被丢弃，下次切换重载。
library;

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _specA = KlineSpec(symbol: 'AAA', interval: FlexiTimeInterval(1, TimeUnit.day));
const _specB = KlineSpec(symbol: 'BBB', interval: FlexiTimeInterval(1, TimeUnit.day));

List<CandleModel> _candles(int n) => List.generate(
      n,
      (i) => CandleModel(
        timestamp: 1000 + i * 86400000,
        open: Decimal.fromInt(100 + i),
        high: Decimal.fromInt(110 + i),
        low: Decimal.fromInt(90 + i),
        close: Decimal.fromInt(105 + i),
        volume: Decimal.fromInt(1000 + i),
      ),
    );

void main() {
  group('v2.2.0/FlexiKlineController/computed_slot_capacity', () {
    testWidgets('新增 computed 指标后：当前数据扩容，其余缓存被丢弃', (tester) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);

      const c0 = ComputedIndicatorKey('c0');
      const c1 = ComputedIndicatorKey('c1');
      const c2 = ComputedIndicatorKey('c2');

      final oldSub = [
        TestComputedIndicator(key: c0),
        TestComputedIndicator(key: c1),
      ];

      // 挂载 specA，声明 2 个 computed 指标 → 容量 2。
      // mount 前的 updateKlineData 只入队 waiting，可安全 await。
      final ctrl = scene.controller;
      await scene.initWithData(_specA, _candles(3), subIndicators: oldSub);
      ctrl.flushPendingKlineData();
      await tester.pumpAndSettle();

      expect(ctrl.computedDataCapacity, 2);

      // 切到 specB 并加载数据 → B 成为当前，A 进缓存。
      // mount 后 updateKlineData 走异步 scheduleTask，不能直接 await（需靠 pump 驱动）。
      ctrl.switchKlineData(_specB);
      unawaited(ctrl.updateKlineData(_specB, _candles(3)));
      await tester.pumpAndSettle();

      // 当前 B 的蜡烛按容量 2 定长。
      expect(ctrl.klineData.get(0)?.slotCount, 2);

      // 新增第 3 个 computed 指标 c2 → 容量增长到 3，触发 syncComputedSlotCapacity。
      ctrl.updateIndicators(
        oldCandle: TestCandleIndicator(),
        newCandle: TestCandleIndicator(),
        oldTime: TestTimeIndicator(),
        newTime: TestTimeIndicator(),
        oldMainIndicators: const [],
        newMainIndicators: const [],
        oldSubIndicators: oldSub,
        newSubIndicators: [
          ...oldSub,
          TestComputedIndicator(key: c2),
        ],
      );

      // 容量已升至 3。
      expect(ctrl.computedDataCapacity, 3);

      // 当前数据（B）已扩容：新高位 slot 2 不再越界。
      final candle = ctrl.klineData.get(0);
      expect(candle?.slotCount, 3);
      expect(candle?.checkIndex(ctrl.getComputedDataIndex(c2)!), isTrue);

      // 其余缓存（A）已被丢弃：再切回 specA 命中不到缓存，返回 false。
      final hitCacheA = ctrl.switchKlineData(_specA, useCacheFirst: true);
      expect(hitCacheA, isFalse, reason: 'specA 缓存应已被 syncComputedSlotCapacity 丢弃');
    });
  });
}
