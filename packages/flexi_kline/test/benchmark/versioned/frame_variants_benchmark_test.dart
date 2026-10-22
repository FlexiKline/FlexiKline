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

/// 整帧变体: 价格轴缩放、分隔线拖动、蜡烛样式与 accurate 计算模式; 装配与口径同 `paint_frame`。
///
/// 这些路径与默认平移不同: 缩放态有独立的区间与裁剪, 空心 / OHLC / 折线各走一条绘制路径,
/// accurate 下坐标换算走 Decimal。
@Tags(['benchmark'])
library;

import 'dart:ui' show Canvas, Offset;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/benchmark/bench_harness.dart';
import 'bench_chart.dart';

const _rounds = 7;

void main() {
  final report = BenchReport('frame_variants', config: {'frames': benchFrames, 'rounds': _rounds});
  tearDownAll(report.write);

  Future<void> measure(
    WidgetTester tester,
    FlexiKlineController controller,
    String name,
    void Function(int i, Canvas canvas) frame,
  ) async {
    report.measure(
      name,
      benchFramesBody(frame),
      rounds: _rounds,
      perRound: benchFrames,
      meta: {'visible': visibleCandles(controller)},
    );
    await tester.pump();
    controller.dispose();
  }

  for (final multi in const [false, true]) {
    final setup = multi ? 'multi' : 'base';
    final main = multi ? 3 : 0;
    final sub = multi ? 4 : 0;

    testWidgets('zoom / $setup', (tester) async {
      final controller = await mountBenchChart(tester, main: main, sub: sub, zoom: true);
      final bar = controller.chartZoomSlideBarRect;
      expect(controller.onChartZoomStart(bar.center), isTrue, reason: '前置：要在价格轴热区开始缩放');
      // 手指在按下点上下 60px 内往返, 每 60 帧一个来回。
      await measure(tester, controller, 'zoom/$setup', (i, canvas) {
        final phase = (i % 60) / 30;
        controller.onChartZoomUpdate(bar.center.dy - 60 + 120 * (phase <= 1 ? phase : 2 - phase));
        controller.paintChart(canvas, controller.canvasRect.size);
      });
    });

    testWidgets('accurate / $setup', (tester) async {
      final controller = await mountBenchChart(tester, main: main, sub: sub, computeMode: ComputeMode.accurate);
      expect(controller.klineData.computeMode, ComputeMode.accurate, reason: '前置：数据要是 accurate 模式');
      await measure(tester, controller, 'accurate/$setup', (i, c) => panFrame(controller, i, c));
    });
  }

  testWidgets('resize / multi', (tester) async {
    final controller = await mountBenchChart(tester, main: 3, sub: 4, resize: true);
    final line = Offset(controller.mainRect.center.dx, controller.mainRect.bottom);
    expect(controller.onGridResizeStart(line), isTrue, reason: '前置：要命中主区下方的分隔线');
    final height = controller.mainRect.height;
    controller.onGridResizeUpdate(2);
    expect(controller.mainRect.height, isNot(height), reason: '前置：拖动分隔线要改变主区高度');
    // 每 30 帧换一次方向, 每帧 2px; 网格与图表都随高度重排。
    await measure(tester, controller, 'resize/multi', (i, canvas) {
      controller.onGridResizeUpdate((i ~/ 30).isEven ? 2 : -2);
      final size = controller.canvasRect.size;
      controller.paintGrid(canvas, size);
      controller.paintChart(canvas, size);
    });
  });

  for (final (name, type) in const [
    ('hollow', FlexiChartType.barHollow),
    ('ohlc', FlexiChartType.barOhlc),
    ('line', FlexiChartType.lineNormal),
  ]) {
    testWidgets('candles / $name', (tester) async {
      final controller = await mountBenchChart(tester, candleWidth: 2, chartType: type);
      await measure(tester, controller, 'candles/$name/cw2', (i, c) => panFrame(controller, i, c));
    });
  }
}
