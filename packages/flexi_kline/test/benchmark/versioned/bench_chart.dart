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

/// 整帧 benchmark 的共用装配: `paint_frame` 与 `frame_scenarios` 两个 suite 共用, 版本对照时一并 overlay。
///
/// - base = [CandleIndicator] + [TimeIndicator]; multi 再加 3 主区 combine + 4 副区 [BenchLineIndicator]
///   (核心包不依赖 flexi_kline_indicators, 用它对标 MA / BOLL: 3 条折线 + 一行 tips, 不含计算);
/// - 500 根斜坡蜡烛, 平移时区间与刻度文本随之变化。
///
/// 只用 `v2.5.6-monorepo` 上也存在的 API, 改动后须在基线 worktree 上编译一次。
library;

import 'dart:math' as math;
import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_formatter/flexi_formatter.dart' show formatPrice;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const benchSpec = KlineSpec(symbol: 'PAINT-FRAME-BENCH', interval: FlexiTimeInterval(1, TimeUnit.minute));

const benchCanvasWidth = 400.0;

/// 每轮帧数; 轮数由各 suite 决定。
const benchFrames = 300;

class BenchLineIndicator extends DirectIndicator {
  BenchLineIndicator(String id, {required super.paintMode})
    : super(
        key: DirectIndicatorKey('bench_line_$id'),
        height: 80,
        padding: const EdgeInsets.only(top: 14, bottom: 2),
        autoActivate: true,
      );

  static const colors = [Color(0xFFFFB74D), Color(0xFF03A9F4), Color(0xFF9C27B0)];
  static const tipsStyle = TextStyle(fontSize: 10, height: 1.2);

  /// 用于校验指标都参与了绘制。
  static int paintCount = 0;

  @override
  DirectPaintObject<DirectIndicator> createPaintObject() => _BenchLinePaintObject();
}

class _BenchLinePaintObject extends DirectPaintObject<BenchLineIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => klineData.calculateMinmax(start, end);

  /// 第 [j] 条线取 close 上下错开的值, 让三条线分开。
  FlexiNum _valueOf(FlexiCandleModel m, int j) => m.close + FlexiNum.fromNum((j - 1) * 2);

  @override
  void paint(Canvas canvas, Size size) {
    BenchLineIndicator.paintCount++;
    final start = klineData.start;
    final end = math.min(klineData.end + 1, klineData.length);
    final startOffset = startCandleDx - candleWidthHalf;
    for (int j = 0; j < BenchLineIndicator.colors.length; j++) {
      final points = <Offset>[];
      for (int i = start; i < end; i++) {
        points.add(Offset(startOffset - (i - start) * candleActualWidth, valueToDy(_valueOf(klineData[i], j))));
      }
      canvas.drawPath(
        Path()..addPolygon(points, false),
        Paint()
          ..color = BenchLineIndicator.colors[j]
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
      for (int j = 0; j < BenchLineIndicator.colors.length; j++)
        TextSpan(
          text: formatPrice(
            _valueOf(model, j).toDecimal(),
            precision: klineData.precision,
            prefix: 'L$j: ',
            suffix: '  ',
          ),
          style: BenchLineIndicator.tipsStyle.copyWith(color: BenchLineIndicator.colors[j]),
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

/// 500 根斜坡蜡烛, 价格逐根下降, 平移时区间与刻度文本随之变化。
List<CandleModel> benchCandles() => genRampCandleList(count: 500, high: 1000, spread: 14, slope: 0.5);

/// 不经 Widget 装配一个可直接调绘制入口的 controller。
///
/// [main] / [sub] 是叠加的 [BenchLineIndicator] 个数(base = 0/0, multi = 3/4)。
FlexiKlineController createBenchChart({
  int main = 0,
  int sub = 0,
  double? candleWidth,
  double width = benchCanvasWidth,
  List<CandleModel>? candles,
}) {
  final controller = FlexiKlineController(configuration: FakeFlexiKlineConfiguration());
  controller.switchKlineData(benchSpec);
  controller.replaceKlineData(benchSpec, candles ?? benchCandles());
  controller.mountIndicators(
    candle: CandleIndicator(),
    time: TimeIndicator(),
    mainIndicators: [for (int i = 0; i < main; i++) BenchLineIndicator('m$i', paintMode: PaintMode.combine)],
    subIndicators: [for (int i = 0; i < sub; i++) BenchLineIndicator('s$i', paintMode: PaintMode.alone)],
  );
  controller.initState();
  controller.setAdaptLayoutMode(width: width);
  controller.flushPendingKlineData();
  if (candleWidth != null) {
    controller.onChartScaleTo(candleWidth / controller.candleWidth, position: ScalePosition.right, focalDx: 0);
  }
  controller.paintChart(Canvas(PictureRecorder()), controller.canvasRect.size);
  return controller;
}

/// [createBenchChart] 后泵掉首帧排下的 post-frame 回调。
Future<FlexiKlineController> mountBenchChart(
  WidgetTester tester, {
  int main = 0,
  int sub = 0,
  double? candleWidth,
  double width = benchCanvasWidth,
}) async {
  final controller = createBenchChart(main: main, sub: sub, candleWidth: candleWidth, width: width);
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  return controller;
}

int visibleCandles(FlexiKlineController controller) => controller.klineData.end - controller.klineData.start;

/// 每 50 帧换一次方向, 每帧 3px。
void panFrame(FlexiKlineController controller, int i, Canvas canvas) {
  controller.onChartMove(Offset((i ~/ 50).isEven ? 3 : -3, 0));
  final size = controller.canvasRect.size;
  controller.paintChart(canvas, size);
  controller.paintDraw(canvas, size);
}

/// slow 多帧落在同一根蜡烛内, fast 每帧跨一根蜡烛。
void crossFrame(FlexiKlineController controller, int i, Canvas canvas, {required bool fast}) {
  final rect = controller.mainRect;
  final step = fast ? controller.candleActualWidth : 1.0;
  final dx = rect.left + 40 + (i % 40) * step;
  final dy = rect.top + 40 + (i % 60);
  controller.onCrossUpdate(Offset(dx, dy));
  controller.paintCross(canvas, controller.canvasRect.size);
}

/// 跑 [benchFrames] 帧, 每帧一张新的 [PictureRecorder] 画布。
void Function() benchFramesBody(void Function(int i, Canvas canvas) frame) => () {
  for (int i = 0; i < benchFrames; i++) {
    frame(i, Canvas(PictureRecorder()));
  }
};
