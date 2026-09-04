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

/// 回归测试：`_panSmoothFactor` 在所有中断路径上归位到 1.0。
///
/// 覆盖层级：controller 的 `onChartMove` / `onPanEnd` / `paintChart`。
/// 不覆盖：手势识别、GestureDetector 派发——那些只能靠 widget 测试或真机验证。
///
/// 核心不变量：`onPanEnd()` 归位 `_panSmoothFactor` 到 1.0 后，下一帧 minMax 回到精确值。
///
/// smooth 的可观测差异需要至少两帧连续 smoothFactor < 1.0 且可见范围在帧间变化：
/// 首帧 smooth 无旧缓存，`_smoothMinMax` 从 `_minMax` 起插值结果等于精确值；
/// 第二帧 smooth 从上一帧的 `_smoothMinMax` 向新 `_minMax` 插值，才能产生滞后。
@TestOn('vm')
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'SMOOTH-TEST', interval: FlexiTimeInterval(1, TimeUnit.day));

/// 阶梯蜡烛：第 i 根的中心价格 = base + i * step。
List<CandleModel> _stairCandles({
  int count = 200,
  double base = 100,
  double step = 10,
  double spread = 5,
  int latestTimestamp = 12000000,
  int intervalMs = 60000,
}) {
  return List.generate(count, (index) {
    final center = base + index * step;
    return CandleModel(
      timestamp: latestTimestamp - index * intervalMs,
      open: center - spread / 2,
      high: center + spread,
      low: center - spread,
      close: center + spread / 2,
      volume: 1000,
    );
  });
}

/// 当前生效区间的上端：主图区顶边对应的价格。
double _rangeMax(FlexiKlineController chart) {
  return chart.dyToCandleValue(chart.mainChartRect.top, check: false)!.toDouble();
}

void main() {
  group('v2.5.0/panSmoothFactor/归位', () {
    late FlexiKlineController chart;

    Future<void> arrange(WidgetTester tester) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      await scene.initWithData(
        _spec,
        _stairCandles(count: 200),
        canvasWidth: 400,
        candle: TestCandleIndicator(visibleMinMaxFromData: true),
      );
      chart = scene.controller;
      chart.flushPendingKlineData();
      await paintChartFrame(tester, chart);
    }

    /// 连续两帧 smoothFactor=0.15 平移，使 _smoothMinMax 产生可观测的滞后。
    /// 返回第二帧的 rangeMax（插值态）。
    Future<double> enterSmoothState(WidgetTester tester) async {
      // 帧 1：大幅平移, factor=0.15 → 首帧无旧缓存，值等于精确值，但建立了 _smoothMinMax
      chart.onChartMove(const Offset(100, 0), smoothFactor: 0.15);
      await paintChartFrame(tester, chart);

      // 帧 2：继续大幅平移, factor=0.15 → _smoothMinMax 从帧 1 的旧值向新目标插值，产生滞后
      chart.onChartMove(const Offset(100, 0), smoothFactor: 0.15);
      await paintChartFrame(tester, chart);

      return _rangeMax(chart);
    }

    testWidgets('onPanEnd 后 Y 轴区间跳到精确值，不再走插值', (tester) async {
      await arrange(tester);
      final smoothedMax = await enterSmoothState(tester);

      // 归位
      chart.onPanEnd();
      await paintChartFrame(tester, chart);

      final preciseMax = _rangeMax(chart);

      // 连续帧不变（已收敛）
      await paintChartFrame(tester, chart);
      expect(_rangeMax(chart), preciseMax, reason: '归位后连续帧不变');

      // 插值态的 rangeMax 与精确态不同
      expect(smoothedMax, isNot(closeTo(preciseMax, 0.01)), reason: 'smooth 态与精确态的 rangeMax 应有可观测差异');
    });

    testWidgets('不调 onPanEnd 则继续平移仍走插值', (tester) async {
      await arrange(tester);
      final smoothedMax1 = await enterSmoothState(tester);

      // 不调 onPanEnd，第三帧继续平移 factor=0.15
      chart.onChartMove(const Offset(30, 0), smoothFactor: 0.15);
      await paintChartFrame(tester, chart);
      final smoothedMax2 = _rangeMax(chart);

      // 归位
      chart.onPanEnd();
      await paintChartFrame(tester, chart);
      final preciseMax = _rangeMax(chart);

      // 反向断言：归位前至少有一帧与精确值不同
      expect(smoothedMax1 != preciseMax || smoothedMax2 != preciseMax, isTrue, reason: 'smoothFactor<1 期间至少有一帧与精确态不同');
    });

    testWidgets('连续多帧中断归位：模拟惯性动画打断', (tester) async {
      await arrange(tester);

      // 连续 8 帧 factor=0.15 平移（模拟惯性动画）
      for (var i = 0; i < 8; i++) {
        chart.onChartMove(const Offset(25, 0), smoothFactor: 0.15);
        await paintChartFrame(tester, chart);
      }

      final beforeReset = _rangeMax(chart);

      // 中断归位
      chart.onPanEnd();
      await paintChartFrame(tester, chart);

      final afterReset = _rangeMax(chart);

      // 连续帧不变
      await paintChartFrame(tester, chart);
      expect(_rangeMax(chart), afterReset, reason: '归位后连续帧不变');

      // 归位前后的值不同（8 帧 smooth 累积的滞后应相当显著）
      expect(beforeReset, isNot(closeTo(afterReset, 0.01)), reason: '归位前（插值滞后态）与归位后（精确态）的区间应不同');
    });
  });
}
