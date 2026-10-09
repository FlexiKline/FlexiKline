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

/// 整帧绘制基线(设计 v2 第十二节场景 3 平移、4 多指标平移、6 cross): 阶段 2 在旧绘制实现上留基线, 阶段 3 重跑对比。
///
/// - base = [CandleIndicator] + [TimeIndicator]; multi 再加 3 主区 combine + 4 副区 [_BenchLineIndicator]
///   (核心包不依赖 flexi_kline_indicators, 用它对标 MA / BOLL: 3 条折线 + 一行 tips, 不含计算);
/// - 500 根斜坡蜡烛, 平移时区间与刻度文本随之变化; 画布宽 400, 蜡烛宽 7 与 2 两档。
///
/// 口径: `PictureRecorder` 只测 Dart 侧录制, 不含 raster; host JIT 只适合同机前后对比;
/// 取 [_rounds] 轮最快一轮, 因为预热、GC 与调度只会让某轮变慢。
@Tags(['benchmark'])
library;

import 'dart:math' as math;
import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_formatter/flexi_formatter.dart' show formatPrice;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'PAINT-FRAME-BENCH', interval: FlexiTimeInterval(1, TimeUnit.minute));

const _canvasWidth = 400.0;
const _frames = 300;
const _rounds = 7;

class _BenchLineIndicator extends DirectIndicator {
  _BenchLineIndicator(String id, {required super.paintMode})
    : super(
        key: DirectIndicatorKey('bench_line_$id'),
        height: 80,
        padding: const EdgeInsets.only(top: 14, bottom: 2),
        autoActivate: true,
      );

  static const colors = [Color(0xFFFFB74D), Color(0xFF03A9F4), Color(0xFF9C27B0)];
  static const tipsStyle = TextStyle(fontSize: 10, height: 1.2);

  /// 用于校验 7 个指标都参与了绘制。
  static int paintCount = 0;

  @override
  DirectPaintObject<DirectIndicator> createPaintObject() => _BenchLinePaintObject();
}

class _BenchLinePaintObject extends DirectPaintObject<_BenchLineIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => klineData.calculateMinmax(start, end);

  /// 第 [j] 条线取 close 上下错开的值, 让三条线分开。
  FlexiNum _valueOf(FlexiCandleModel m, int j) => m.close + FlexiNum.fromNum((j - 1) * 2);

  @override
  void paint(Canvas canvas, Size size) {
    _BenchLineIndicator.paintCount++;
    final start = klineData.start;
    final end = math.min(klineData.end + 1, klineData.length);
    final startOffset = startCandleDx - candleWidthHalf;
    for (int j = 0; j < _BenchLineIndicator.colors.length; j++) {
      final points = <Offset>[];
      for (int i = start; i < end; i++) {
        points.add(Offset(startOffset - (i - start) * candleActualWidth, valueToDy(_valueOf(klineData[i], j))));
      }
      canvas.drawPath(
        Path()..addPolygon(points, false),
        Paint()
          ..color = _BenchLineIndicator.colors[j]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) {
    model ??= offsetToCandle(offset);
    if (model == null) return null;
    final children = <TextSpan>[
      for (int j = 0; j < _BenchLineIndicator.colors.length; j++)
        TextSpan(
          text: formatPrice(
            _valueOf(model, j).toDecimal(),
            precision: klineData.precision,
            prefix: 'L$j: ',
            suffix: '  ',
          ),
          style: _BenchLineIndicator.tipsStyle.copyWith(color: _BenchLineIndicator.colors[j]),
        ),
    ];
    tipsRect ??= drawableRect;
    return canvas.drawText(
      offset: tipsRect.topLeft,
      textSpan: TextSpan(children: children),
      drawableRect: tipsRect,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}

void main() {
  Future<FlexiKlineController> mountChart(WidgetTester tester, {required bool multi, double? candleWidth}) async {
    final controller = FlexiKlineController(configuration: FakeFlexiKlineConfiguration());
    controller.switchKlineData(_spec);
    controller.replaceKlineData(_spec, genRampCandleList(count: 500, high: 1000, spread: 14, slope: 0.5));
    controller.mountIndicators(
      candle: CandleIndicator(),
      time: TimeIndicator(),
      mainIndicators: [
        if (multi)
          for (final id in const ['m1', 'm2', 'm3']) _BenchLineIndicator(id, paintMode: PaintMode.combine),
      ],
      subIndicators: [
        if (multi)
          for (final id in const ['s1', 's2', 's3', 's4']) _BenchLineIndicator(id, paintMode: PaintMode.alone),
      ],
    );
    controller.initState();
    controller.setAdaptLayoutMode(width: _canvasWidth);
    controller.flushPendingKlineData();
    if (candleWidth != null) {
      controller.onChartScaleTo(candleWidth / controller.candleWidth, position: ScalePosition.right, focalDx: 0);
    }
    controller.paintChart(Canvas(PictureRecorder()), controller.canvasRect.size);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    return controller;
  }

  int bestMicros(void Function() body) {
    var best = -1;
    for (int r = 0; r < _rounds; r++) {
      final sw = Stopwatch()..start();
      body();
      sw.stop();
      if (best < 0 || sw.elapsedMicroseconds < best) best = sw.elapsedMicroseconds;
    }
    return best;
  }

  /// 预热一轮后计时, 打印每帧微秒数。
  Future<void> measure(
    WidgetTester tester,
    FlexiKlineController controller, {
    required String label,
    required void Function(int i, Canvas canvas) frame,
  }) async {
    void body() {
      for (int i = 0; i < _frames; i++) {
        frame(i, Canvas(PictureRecorder()));
      }
    }

    body();
    final micros = bestMicros(body);
    // paintChart 每帧排 post-frame 回调, 泵掉再 dispose。
    await tester.pump();
    debugPrint(
      'paint_frame_bench[$label]: ${(micros / _frames).toStringAsFixed(1)}us/frame '
      '(visible ${controller.klineData.end - controller.klineData.start} candles, '
      'candleWidth ${controller.candleWidth})',
    );
    controller.dispose();
  }

  /// 场景 3 / 4。
  void panFrame(FlexiKlineController controller, int i, Canvas canvas) {
    controller.onChartMove(Offset((i ~/ 50).isEven ? 3 : -3, 0));
    final size = controller.canvasRect.size;
    controller.paintChart(canvas, size);
    controller.paintDraw(canvas, size);
  }

  /// 场景 6：slow 多帧落在同一根蜡烛内, fast 每帧跨一根蜡烛。
  void crossFrame(FlexiKlineController controller, int i, Canvas canvas, {required bool fast}) {
    final rect = controller.mainRect;
    final step = fast ? controller.candleActualWidth : 1.0;
    final dx = rect.left + 40 + (i % 40) * step;
    final dy = rect.top + 40 + (i % 60);
    controller.onCrossUpdate(Offset(dx, dy));
    controller.paintCross(canvas, controller.canvasRect.size);
  }

  for (final multi in const [false, true]) {
    final setup = multi ? 'multi(3main+4sub)' : 'base';
    for (final candleWidth in const [7.0, 2.0]) {
      testWidgets('pan / $setup / candleWidth $candleWidth', (tester) async {
        final controller = await mountChart(tester, multi: multi, candleWidth: candleWidth);
        if (multi) {
          _BenchLineIndicator.paintCount = 0;
          controller.paintChart(Canvas(PictureRecorder()), controller.canvasRect.size);
          expect(_BenchLineIndicator.paintCount, 7, reason: '前置：7 个测试指标都要参与绘制');
        }
        await measure(
          tester,
          controller,
          label: 'pan / $setup / cw $candleWidth',
          frame: (i, canvas) => panFrame(controller, i, canvas),
        );
      });
    }

    for (final fast in const [false, true]) {
      final speed = fast ? 'fast' : 'slow';
      testWidgets('cross $speed / $setup', (tester) async {
        final controller = await mountChart(tester, multi: multi);
        final rect = controller.mainRect;
        expect(controller.onCrossToggle(rect.center), isTrue, reason: '前置：cross 要打开');
        await measure(
          tester,
          controller,
          label: 'cross $speed / $setup',
          frame: (i, canvas) => crossFrame(controller, i, canvas, fast: fast),
        );
      });
    }
  }
}
