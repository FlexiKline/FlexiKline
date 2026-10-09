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

/// Y 轴刻度与 cross 刻度接到 LabelPainter 之后的摆放与缓存。
///
/// 摆放按实测高度: 刻度标签底边落在刻度线上、cross 刻度垂直居中于指针, 都被夹取进 drawableRect。
library;

import 'dart:ui' show Paragraph;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

class _TicksPaintObject extends CandleBasePaintObject<TestCandleIndicator> with PaintYAxisTicksOnCrossMixin {
  void bind(TestCandleIndicator indicator, PaintContext context) => mount(indicator, context);

  int formatted = 0;
  int crossFormatted = 0;

  double ticks(Canvas canvas, List<double> dys) =>
      paintYAxisTicks(canvas, dys: dys, precision: 2, showTopTick: true, showBottomTick: true);

  Size? crossTick(Canvas canvas, double dy) => paintYAxisTicksOnCross(canvas, Offset(10, dy), precision: 2);

  @override
  String formatTicksValue(FlexiNum value, {required int precision}) {
    formatted++;
    return super.formatTicksValue(value, precision: precision);
  }

  @override
  String formatTicksValueOnCross(FlexiNum value, {required int precision}) {
    crossFormatted++;
    return super.formatTicksValueOnCross(value, precision: precision);
  }

  @override
  FlexiChartType resolveChartType() => FlexiChartType.barSolid;

  @override
  bool get hideMainIndicatorsInLineChartMode => false;

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

List<Paragraph> _paragraphs(RecordingCanvas canvas) => [
  for (final i in canvas.invocations)
    if (i.memberName == #drawParagraph) i.positionalArguments[0] as Paragraph,
];

void main() {
  late _TicksPaintObject object;

  setUp(() {
    object = _TicksPaintObject();
    final context = FakePaintContext()..mainRect = const Rect.fromLTWH(0, 0, 300, 200);
    object.bind(TestCandleIndicator(height: 200), context);
    object.setMinMax(MinMax(min: FlexiNum.zero, max: FlexiNum.fromNum(100)));
  });

  test('刻度标签底边落在刻度线上、右边贴 chartRect, 顶边的刻度被推回可见区', () {
    final canvas = RecordingCanvas();
    final rect = object.drawableRect;
    final padding = object.defTicksTextConfig.padding ?? EdgeInsets.zero;
    final width = object.ticks(canvas, [rect.top, 100, rect.bottom]);

    final paragraphs = _paragraphs(canvas);
    final offsets = canvas.paragraphOffsets;
    expect(paragraphs, hasLength(3));
    expect(width, greaterThan(0));
    // 顶边: 本应画在线之上, 被夹取到 drawableRect 内。
    expect(offsets[0].dy - padding.top, rect.top);
    // 中间与底边: 标签底边 = 刻度线 dy。
    expect(offsets[1].dy + paragraphs[1].height + padding.bottom, closeTo(100, 0.01));
    expect(offsets[2].dy + paragraphs[2].height + padding.bottom, closeTo(rect.bottom, 0.01));
  });

  test('刻度第二帧: 同值不再格式化, Paragraph 复用', () {
    final dys = [50.0, 100.0, 150.0];
    final first = RecordingCanvas();
    object.ticks(first, dys);
    expect(object.formatted, 3);
    final second = RecordingCanvas();
    object.ticks(second, dys);
    expect(object.formatted, 3);
    expect(_paragraphs(second), orderedEquals(_paragraphs(first)));
  });

  test('cross 刻度垂直居中于指针 dy, 同一 dy 的第二帧不再格式化', () {
    final first = RecordingCanvas();
    final size = object.crossTick(first, 100)!;
    final offset = first.paragraphOffsets.single;
    final paragraph = _paragraphs(first).single;
    final padding = object.crossConfig.ticksText.padding ?? EdgeInsets.zero;
    expect(offset.dy - padding.top + size.height / 2, closeTo(100, 0.01));
    expect(size.height, closeTo(paragraph.height + padding.vertical, 0.01));

    final second = RecordingCanvas();
    object.crossTick(second, 100);
    expect(object.crossFormatted, 1);
    expect(identical(_paragraphs(second).single, paragraph), isTrue);
  });
}
