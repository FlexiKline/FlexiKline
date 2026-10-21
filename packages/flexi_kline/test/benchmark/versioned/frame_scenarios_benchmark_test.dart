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

/// 整帧补充场景: 缩放、可见根数与指标数的规模曲线、实时行情、首帧; 装配与口径同 `paint_frame`。
@Tags(['benchmark'])
library;

import 'dart:ui' show Canvas, PictureRecorder;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';
import 'bench_chart.dart';

const _rounds = 7;
const _firstFrameRounds = 15;

/// 规模曲线用的宽画布: 400 根需要的蜡烛宽仍在最小宽 1 之上。
const _wideCanvas = 1200.0;

void main() {
  final report = BenchReport(
    'frame_scenarios',
    config: {'frames': benchFrames, 'rounds': _rounds, 'firstFrameRounds': _firstFrameRounds},
  );
  tearDownAll(report.write);

  Future<void> measure(
    WidgetTester tester,
    FlexiKlineController controller,
    String name,
    void Function(int i, Canvas canvas) frame, {
    Map<String, Object?> meta = const {},
  }) async {
    report.measure(
      name,
      benchFramesBody(frame),
      rounds: _rounds,
      perRound: benchFrames,
      meta: {'visible': visibleCandles(controller), ...meta},
    );
    await tester.pump();
    controller.dispose();
  }

  void paintChart(FlexiKlineController controller, Canvas canvas) =>
      controller.paintChart(canvas, controller.canvasRect.size);

  for (final multi in const [false, true]) {
    final setup = multi ? 'multi' : 'base';
    final main = multi ? 3 : 0;
    final sub = multi ? 4 : 0;

    testWidgets('zoom / $setup', (tester) async {
      final controller = await mountBenchChart(tester, main: main, sub: sub);
      // 蜡烛宽每 60 帧在 2 与 10 之间往返一次。
      await measure(tester, controller, 'zoom/$setup', (i, canvas) {
        final phase = (i % 60) / 30;
        final target = 2 + 8 * (phase <= 1 ? phase : 2 - phase);
        controller.onChartScaleTo(target / controller.candleWidth, position: ScalePosition.right, focalDx: 0);
        paintChart(controller, canvas);
      });
    });

    testWidgets('realtime / $setup', (tester) async {
      final controller = await mountBenchChart(tester, main: main, sub: sub);
      // 每帧推一次最新蜡烛的 tick, 每 10 帧收盘并开一根新蜡烛。
      await measure(tester, controller, 'realtime/$setup', (i, canvas) {
        final latest = controller.klineData.latest!;
        final ts = i % 10 == 9 ? latest.ts + benchSpec.interval.milliseconds : latest.ts;
        final close = latest.close.toDouble() + ((i % 7) - 3) * 0.5;
        controller.updateLatestKlineData(benchSpec, [
          CandleModel(timestamp: ts, open: close, high: close + 3, low: close - 3, close: close, volume: 100),
        ]);
        paintChart(controller, canvas);
      });
    });

    testWidgets('first-frame / $setup', (tester) async {
      final candles = benchCandles();
      final controllers = <FlexiKlineController>[];
      report.measure(
        'first-frame/$setup',
        () => controllers.add(createBenchChart(main: main, sub: sub, candles: candles)),
        rounds: _firstFrameRounds,
        unit: 'us',
      );
      await tester.pump();
      for (final c in controllers) {
        c.dispose();
      }
    });
  }

  for (final target in const [40, 140, 400]) {
    testWidgets('scale / candles $target', (tester) async {
      final controller = await mountBenchChart(tester, width: _wideCanvas);
      final width = controller.mainChartWidth / target / (1 + 1 / controller.settingConfig.spacingCandleParts);
      controller.onChartScaleTo(width / controller.candleWidth, position: ScalePosition.right, focalDx: 0);
      paintChart(controller, Canvas(PictureRecorder()));
      expect(visibleCandles(controller), closeTo(target, target * 0.15), reason: '前置：可见根数接近目标档');
      await measure(
        tester,
        controller,
        'scale/candles-$target',
        (i, c) => panFrame(controller, i, c),
        meta: {'candleWidth': controller.candleWidth},
      );
    });
  }

  for (final count in const [0, 3, 7, 14]) {
    testWidgets('scale / indicators $count', (tester) async {
      // 副区最多 4 个(defaultSubIndicatorMaxCount): 先放满主区 3 个、再放副区, 超出部分回到主区。
      final sub = (count - 3).clamp(0, 4);
      final controller = await mountBenchChart(tester, main: count - sub, sub: sub);
      BenchLineIndicator.paintCount = 0;
      paintChart(controller, Canvas(PictureRecorder()));
      expect(BenchLineIndicator.paintCount, count, reason: '前置：$count 个测试指标都要参与绘制');
      await measure(tester, controller, 'scale/indicators-$count', (i, c) => panFrame(controller, i, c));
    });
  }
}
