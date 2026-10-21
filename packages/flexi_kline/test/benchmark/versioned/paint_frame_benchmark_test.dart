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

/// 整帧绘制基线: 平移、多指标平移与 cross; 装配见 `bench_chart.dart`, 画布宽 400, 蜡烛宽 7 与 2 两档。
///
/// 口径: `PictureRecorder` 只测 Dart 侧录制, 不含 raster; host JIT 只适合同机前后对比;
/// 每场景 [_rounds] 轮、每轮 [benchFrames] 帧, 取最快一轮(预热、GC 与调度只会让某轮变慢)。
@Tags(['benchmark'])
library;

import 'dart:ui' show Canvas, PictureRecorder;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';
import 'bench_chart.dart';

const _rounds = 7;

void main() {
  final report = BenchReport(
    'paint_frame',
    config: {'frames': benchFrames, 'rounds': _rounds, 'canvasWidth': benchCanvasWidth},
  );
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
      meta: {'visible': visibleCandles(controller), 'candleWidth': controller.candleWidth},
    );
    // paintChart 每帧排 post-frame 回调, 泵掉再 dispose。
    await tester.pump();
    controller.dispose();
  }

  for (final multi in const [false, true]) {
    final setup = multi ? 'multi' : 'base';
    for (final candleWidth in const [7.0, 2.0]) {
      testWidgets('pan / $setup / candleWidth $candleWidth', (tester) async {
        final controller = await mountBenchChart(
          tester,
          main: multi ? 3 : 0,
          sub: multi ? 4 : 0,
          candleWidth: candleWidth,
        );
        if (multi) {
          BenchLineIndicator.paintCount = 0;
          controller.paintChart(Canvas(PictureRecorder()), controller.canvasRect.size);
          expect(BenchLineIndicator.paintCount, 7, reason: '前置：7 个测试指标都要参与绘制');
        }
        await measure(tester, controller, 'pan/$setup/cw${candleWidth.toInt()}', (i, c) => panFrame(controller, i, c));
      });
    }

    for (final fast in const [false, true]) {
      final speed = fast ? 'fast' : 'slow';
      testWidgets('cross $speed / $setup', (tester) async {
        final controller = await mountBenchChart(tester, main: multi ? 3 : 0, sub: multi ? 4 : 0);
        expect(controller.onCrossToggle(controller.mainRect.center), isTrue, reason: '前置：cross 要打开');
        await measure(tester, controller, 'cross/$setup/$speed', (i, c) => crossFrame(controller, i, c, fast: fast));
      });
    }
  }
}
