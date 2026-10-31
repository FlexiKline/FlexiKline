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

import '../../support/support.dart';

class _TicksPaintObject extends CandleBasePaintObject<TestCandleIndicator> with PaintYAxisTicksOnCrossMixin {
  void bind(TestCandleIndicator indicator, PaintContext context) => mount(indicator, context);

  /// [formatTicksValue] 每次收到的刻度值。
  final List<FlexiNum> formatted = [];
  int crossFormatted = 0;

  double ticks(Canvas canvas, List<double> dys, {bool showTopTick = true, bool showBottomTick = true}) =>
      paintYAxisTicks(canvas, dys: dys, precision: 2, showTopTick: showTopTick, showBottomTick: showBottomTick);

  Size? crossTick(Canvas canvas, double dy) => paintYAxisTicksOnCross(canvas, Offset(10, dy), precision: 2);

  @override
  String formatTicksValue(FlexiNum value, {required int precision}) {
    formatted.add(value);
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

/// 高 [height]、区间 `[0, max]` 的主区蜡烛对象。
_TicksPaintObject _bound({double height = 200, num max = 100}) {
  final object = _TicksPaintObject();
  final context = FakePaintContext()..mainRect = Rect.fromLTWH(0, 0, 300, height);
  object.bind(TestCandleIndicator(height: height), context);
  object.setMinMax(MinMax(min: FlexiNum.zero, max: FlexiNum.fromNum(max)));
  return object;
}

void main() {
  late _TicksPaintObject object;

  setUp(() => object = _bound());

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
    expect(object.formatted, hasLength(3));
    final second = RecordingCanvas();
    object.ticks(second, dys);
    expect(object.formatted, hasLength(3));
    expect(_paragraphs(second), orderedEquals(_paragraphs(first)));
  });

  test('showTopTick / showBottomTick 控制边框刻度文本', () {
    final rect = object.drawableRect;
    final dys = [rect.top, rect.center.dy, rect.bottom];

    int paragraphsOf({required bool showTopTick, required bool showBottomTick}) {
      final canvas = RecordingCanvas();
      object.ticks(canvas, dys, showTopTick: showTopTick, showBottomTick: showBottomTick);
      return _paragraphs(canvas).length;
    }

    expect(paragraphsOf(showTopTick: false, showBottomTick: true), 2);
    expect(paragraphsOf(showTopTick: true, showBottomTick: true), 3);
    expect(paragraphsOf(showTopTick: false, showBottomTick: false), 1);
  });

  /// 区间 `[0, 11]`、高 100 时最顶刻度换算为 `100 - 11 × (100/11) = -1.42e-14`，浮点误差内越出
  /// `drawableRect.top`；带窗格归属检查的 `dyToValue` 会把它判成 null，刻度静默消失。
  test('刻度顶在 drawableRect 边界外的浮点误差内: 仍取得到值', () {
    final edge = _bound(height: 100, max: 11);
    final topDy = edge.valueToDy(FlexiNum.fromNum(11));
    expect(topDy, lessThan(edge.drawableRect.top), reason: '前置条件: 刻度必须真的越过边界');
    expect(topDy, closeTo(edge.drawableRect.top, 1e-9), reason: '前置条件: 越界量必须只是浮点误差');

    edge.ticks(RecordingCanvas(), [topDy]);

    expect(edge.formatted, hasLength(1));
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

  test('cross 指针 dy 不在本窗格时不画刻度', () {
    final canvas = RecordingCanvas();
    expect(object.crossTick(canvas, object.drawableRect.bottom + 50), isNull);
    expect(_paragraphs(canvas), isEmpty);
  });
}
