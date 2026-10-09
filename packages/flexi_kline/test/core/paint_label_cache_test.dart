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

/// 核心包各绘制调用点接到 painting 之后的跨帧缓存: 内容不变的第二帧不格式化、不重建 Paragraph。
///
/// 观察点有两层: 可覆写的格式器(刻度、时间、draw 刻度)直接数调用次数; 格式化写死在调用点里的
/// (价格标签、tooltip)看 drawParagraph 收到的 Paragraph 是否同一实例 —— TextPainter 换了文本或
/// 重排都会生成新的 Paragraph。只覆盖 controller 绘制入口, 不覆盖手势与 Widget 层。
library;

import 'dart:ui' show Paragraph;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'LABEL-CACHE', interval: FlexiTimeInterval(1, TimeUnit.minute));

class _CountingTimeIndicator extends TimeIndicator {
  _CountingTimeIndicator() : super();

  int formatted = 0;

  @override
  TimePaintObject createPaintObject() => _CountingTimePaintObject();
}

class _CountingTimePaintObject extends TimePaintObject<_CountingTimeIndicator> {
  @override
  String formatTimeLabel(FlexiCandleModel model, ITimeInterval interval) {
    indicator.formatted++;
    return super.formatTimeLabel(model, interval);
  }
}

class _CountingDrawObject extends TestDrawObject {
  _CountingDrawObject(super.overlay, super.config);

  static int timeFormatted = 0;
  static int valueFormatted = 0;

  @override
  String formatTimeTicksText(int ts, [TimeUnit? unit]) {
    timeFormatted++;
    return super.formatTimeTicksText(ts, unit);
  }

  @override
  String formatValueTicksText(FlexiNum value, {int precision = 0}) {
    valueFormatted++;
    return super.formatValueTicksText(value, precision: precision);
  }
}

List<Paragraph> _paragraphs(RecordingCanvas canvas) => [
  for (final i in canvas.invocations)
    if (i.memberName == #drawParagraph) i.positionalArguments[0] as Paragraph,
];

void main() {
  late FlexiKlineController chart;
  late _CountingTimeIndicator time;

  setUp(() {
    time = _CountingTimeIndicator();
    chart = FlexiKlineController(configuration: FakeFlexiKlineConfiguration());
    chart.switchKlineData(_spec);
    // 价格恒定: 平移、重绘不改变 minMax, 刻度值逐帧相同。
    chart.replaceKlineData(_spec, genFlatCandleList());
    chart.mountIndicators(
      candle: CandleIndicator(showCountdown: false),
      time: time,
      mainIndicators: const [],
      subIndicators: const [],
    );
    chart.initState();
    chart.setAdaptLayoutMode(width: 400);
    chart.flushPendingKlineData();
  });

  tearDown(() => chart.dispose());

  Future<RecordingCanvas> paintChart(WidgetTester tester) async {
    final canvas = RecordingCanvas();
    chart.paintChart(canvas, chart.canvasRect.size);
    await tester.pump();
    return canvas;
  }

  testWidgets('静止的第二帧: 刻度、时间轴、最高最低价与最新价全部复用上一帧的 Paragraph', (tester) async {
    // 首帧用初值 latestPriceLabelOffsetX = 0 判断最新价是否在视区内, 第二帧起才用实测宽度; 跳过这次切换。
    await paintChart(tester);
    final first = _paragraphs(await paintChart(tester));
    final formatted = time.formatted;
    final second = _paragraphs(await paintChart(tester));

    expect(first.length, greaterThan(5), reason: '前置条件: 这一帧确实画了一批标签');
    expect(formatted, greaterThan(0));
    expect(second, orderedEquals(first));
    expect(time.formatted, formatted, reason: '时间刻度命中时不应再格式化');
  });

  testWidgets('时间刻度按实测高度在时间轴区域内垂直居中', (tester) async {
    final canvas = await paintChart(tester);
    final timeRect = chart.timeRect;
    final paragraphs = _paragraphs(canvas);
    final centers = [
      for (final (i, offset) in canvas.paragraphOffsets.indexed)
        if (timeRect.contains(offset)) offset.dy + paragraphs[i].height / 2,
    ];
    expect(centers, isNotEmpty);
    for (final center in centers) {
      expect(center, closeTo(timeRect.center.dy, 0.01));
    }
  });

  testWidgets('cross 静止的第二帧: Y 刻度、时间与 tooltip 复用上一帧的 Paragraph', (tester) async {
    await paintChart(tester);
    chart.onCrossToggle(chart.mainRect.center);
    Future<List<Paragraph>> paintCross() async {
      final canvas = RecordingCanvas();
      chart.paintCross(canvas, chart.canvasRect.size);
      await tester.pump();
      return _paragraphs(canvas);
    }

    final first = await paintCross();
    final formatted = time.formatted;
    final second = await paintCross();

    expect(first.length, greaterThan(4), reason: '前置条件: tooltip 与两个刻度都画了');
    expect(second, orderedEquals(first));
    expect(time.formatted, formatted);
  });

  testWidgets('draw 刻度: 同一点位的第二帧不格式化、不重建', (tester) async {
    chart.registerDrawObjectBuilder(testDrawLineType, (overlay, config) => _CountingDrawObject(overlay, config));
    await paintChart(tester);
    final main = chart.mainRect;
    chart.startDraw(testDrawLineType, isInitPointer: false);
    chart.onDrawConfirm(main.center.translate(-40, -20));
    chart.onDrawUpdate(main.center.translate(40, 20));

    Future<List<Paragraph>> paintTicks() async {
      final canvas = RecordingCanvas();
      chart.drawStateAxisTicksText(canvas, chart.canvasRect.size);
      await tester.pump();
      return _paragraphs(canvas);
    }

    _CountingDrawObject.timeFormatted = _CountingDrawObject.valueFormatted = 0;
    final first = await paintTicks();
    final counts = (_CountingDrawObject.timeFormatted, _CountingDrawObject.valueFormatted);
    final second = await paintTicks();

    expect(first, hasLength(4), reason: '前置条件: 两个时间刻度 + 两个价值刻度');
    expect(counts.$1, 2);
    expect(counts.$2, 2);
    expect(second, orderedEquals(first));
    expect((_CountingDrawObject.timeFormatted, _CountingDrawObject.valueFormatted), counts);
  });
}
