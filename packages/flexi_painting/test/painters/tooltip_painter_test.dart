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

/// [TooltipPainter] 的摆放、两列排版、逐行命中区与跨帧缓存。
library;

import 'dart:ui' show Paragraph;

import 'package:flexi_painting/src/painters/tooltip_painter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart' show MainAxisAlignment;
import 'package:flutter_test/flutter_test.dart';

import '../recording_canvas.dart';

const _style = TextStyle(fontSize: 10, height: 1.2);
const _padding = EdgeInsets.all(4);
const _decoration = ShapeDecoration(
  color: Color(0xFFF2F2F2),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
);

TooltipRow _row(String label, String value, {TextStyle? valueStyle}) =>
    (label: label, labelStyle: null, value: value, valueStyle: valueStyle);

List<Paragraph> _paragraphs(RecordingCanvas canvas) => [
  for (final i in canvas.invocations)
    if (i.memberName == #drawParagraph) i.positionalArguments[0] as Paragraph,
];

double _maxWidth(Iterable<Paragraph> paragraphs) =>
    paragraphs.map((e) => e.longestLine).reduce((a, b) => a > b ? a : b);

/// 最宽一行: label + spacing + value; p 中偶数下标为 label、奇数为 value。
double _widestRow(List<Paragraph> p) => [
  for (var i = 0; i < p.length; i += 2) p[i].longestLine + 8 + p[i + 1].longestLine,
].reduce((a, b) => a > b ? a : b);

/// 两列各取最大宽再相加: 最宽 label + spacing + 最宽 value。
double _columnSum(List<Paragraph> p) =>
    _maxWidth([for (var i = 0; i < p.length; i += 2) p[i]]) +
    8 +
    _maxWidth([for (var i = 1; i < p.length; i += 2) p[i]]);

void main() {
  late TooltipPainter painter;
  setUp(() => painter = TooltipPainter());
  tearDown(() => painter.dispose());

  ({Rect bounds, List<Rect> rows}) paint(
    RecordingCanvas canvas,
    List<TooltipRow> rows, {
    Offset anchor = const Offset(10, 10),
    Alignment align = Alignment.topLeft,
    MainAxisAlignment alignment = MainAxisAlignment.spaceBetween,
    Rect? bounds,
    double? minContentWidth,
    double maxContentWidth = double.infinity,
    ShapeDecoration? decoration = _decoration,
  }) => painter.paint(
    canvas,
    rows,
    style: _style,
    anchor: anchor,
    align: align,
    bounds: bounds,
    spacing: 8,
    alignment: alignment,
    minContentWidth: minContentWidth,
    maxContentWidth: maxContentWidth,
    decoration: decoration,
    padding: _padding,
  );

  test('卡片宽为最宽一行 label + spacing + value + padding, 各行横向撑满卡片', () {
    final canvas = RecordingCanvas();
    final card = paint(canvas, [_row('Open', '1.00'), _row('Close', '123.45')]);

    final p = _paragraphs(canvas);
    expect(p, hasLength(4));
    expect(card.bounds.width, closeTo(_widestRow(p) + _padding.horizontal, 0.01));
    expect(card.bounds.topLeft, const Offset(10, 10));
    expect(card.rows, hasLength(2));
    for (final row in card.rows) {
      expect(row.left, card.bounds.left);
      expect(row.right, card.bounds.right);
    }
    expect(card.rows.first.top, card.bounds.top + _padding.top);
    expect(card.rows.last.bottom, card.bounds.bottom - _padding.bottom);
    // 背景走 RoundedRectangleBorder 的 drawRRect 快路径, 大小即卡片。
    expect(canvas.rrectBounds.single, card.bounds);
  });

  test('卡片宽由最宽一行决定而非两列最大宽相加, 每行两列净距不小于 spacing', () {
    final canvas = RecordingCanvas();
    // 最宽 label 行与最宽 value 行分属两行: 两列各取最大再相加会明显过宽。
    final card = paint(canvas, [_row('LongLabel', '1'), _row('L', '123456')]);

    final p = _paragraphs(canvas);
    expect(card.bounds.width, closeTo(_widestRow(p) + _padding.horizontal, 0.01));
    expect(_columnSum(p), greaterThan(_widestRow(p)));

    // 行内间距: label 右缘到 value 左缘不小于 spacing; label 左对齐、value 右对齐不变。
    for (var i = 0; i < 2; i++) {
      final labelRight = canvas.paragraphOffsets[i * 2].dx + p[i * 2].longestLine;
      final valueLeft = canvas.paragraphOffsets[i * 2 + 1].dx;
      expect(valueLeft - labelRight, greaterThanOrEqualTo(8 - 0.01));
    }
  });

  test('spaceAround(借用): 按最宽 label + spacing + 最宽 value 定宽, 两端对齐', () {
    final canvas = RecordingCanvas();
    final card = paint(
      canvas,
      [_row('LongLabel', '1'), _row('L', '123456')],
      alignment: MainAxisAlignment.spaceAround,
    );

    final p = _paragraphs(canvas);
    expect(card.bounds.width, closeTo(_columnSum(p) + _padding.horizontal, 0.01));
    // value 仍右对齐到卡片内容区右边。
    for (var i = 0; i < 2; i++) {
      final valueRight = canvas.paragraphOffsets[i * 2 + 1].dx + p[i * 2 + 1].longestLine;
      expect(valueRight, closeTo(card.bounds.right - _padding.right, 0.01));
    }
  });

  test('spaceEvenly: 不支持, 降级为 spaceBetween 绘制', () {
    final canvasEvenly = RecordingCanvas();
    final cardEvenly = paint(
      canvasEvenly,
      [_row('LongLabel', '1'), _row('L', '123456')],
      alignment: MainAxisAlignment.spaceEvenly,
    );
    final canvasBetween = RecordingCanvas();
    final cardBetween = paint(
      canvasBetween,
      [_row('LongLabel', '1'), _row('L', '123456')],
      alignment: MainAxisAlignment.spaceBetween,
    );
    expect(cardEvenly.bounds.width, closeTo(cardBetween.bounds.width, 0.01));
    for (var i = 0; i < canvasEvenly.paragraphOffsets.length; i++) {
      expect(canvasEvenly.paragraphOffsets[i], canvasBetween.paragraphOffsets[i]);
    }
  });

  test('start: label+spacing+value 整体左对齐, 余量留尾部', () {
    final canvas = RecordingCanvas();
    final card = paint(
      canvas,
      [_row('LongLabel', '1'), _row('L', '123456')],
      alignment: MainAxisAlignment.start,
    );

    final p = _paragraphs(canvas);
    for (var i = 0; i < 2; i++) {
      final labelDx = canvas.paragraphOffsets[i * 2].dx;
      final valueDx = canvas.paragraphOffsets[i * 2 + 1].dx;
      // label 贴内容区左缘; value 紧跟 label 右缘 + spacing。
      expect(labelDx, closeTo(card.bounds.left + _padding.left, 0.01));
      expect(valueDx, closeTo(labelDx + p[i * 2].longestLine + 8, 0.01));
    }
  });

  test('end: label+spacing+value 整体右对齐, value 贴内容区右缘', () {
    final canvas = RecordingCanvas();
    final card = paint(
      canvas,
      [_row('LongLabel', '1'), _row('L', '123456')],
      alignment: MainAxisAlignment.end,
    );

    final p = _paragraphs(canvas);
    for (var i = 0; i < 2; i++) {
      final labelDx = canvas.paragraphOffsets[i * 2].dx;
      final valueDx = canvas.paragraphOffsets[i * 2 + 1].dx;
      // value 贴内容区右缘; label 右缘与 value 左缘净距恰为 spacing。
      expect(valueDx + p[i * 2 + 1].longestLine, closeTo(card.bounds.right - _padding.right, 0.01));
      expect(valueDx - (labelDx + p[i * 2].longestLine), closeTo(8, 0.01));
    }
  });

  test('center: label+spacing+value 整体居中, 中缝保底 spacing', () {
    final canvas = RecordingCanvas();
    final card = paint(
      canvas,
      [_row('LongLabel', '1'), _row('L', '123456')],
      alignment: MainAxisAlignment.center,
    );

    final p = _paragraphs(canvas);
    for (var i = 0; i < 2; i++) {
      final labelDx = canvas.paragraphOffsets[i * 2].dx;
      final valueDx = canvas.paragraphOffsets[i * 2 + 1].dx;
      final valueRight = valueDx + p[i * 2 + 1].longestLine;
      // 中缝保底 spacing; 两侧余量对称: 内容区左缘到 label 左缘 == value 右缘到内容区右缘。
      expect(valueDx - (labelDx + p[i * 2].longestLine), greaterThanOrEqualTo(8 - 0.01));
      expect(labelDx - (card.bounds.left + _padding.left),
          closeTo(card.bounds.right - _padding.right - valueRight, 0.01));
    }
  });

  test('value 列右对齐到卡片内容区右边', () {
    final canvas = RecordingCanvas();
    final card = paint(canvas, [_row('A', '1'), _row('B', '123456')]);
    final values = [canvas.paragraphOffsets[1], canvas.paragraphOffsets[3]];
    final paragraphs = _paragraphs(canvas);
    for (final (i, offset) in values.indexed) {
      final right = offset.dx + paragraphs[i * 2 + 1].longestLine;
      expect(right, closeTo(card.bounds.right - _padding.right, 0.01));
    }
  });

  test('topRight 对齐并夹取进 bounds', () {
    final canvas = RecordingCanvas();
    const bounds = Rect.fromLTWH(0, 0, 300, 200);
    final card = paint(
      canvas,
      [_row('A', '1')],
      anchor: const Offset(400, -20),
      align: Alignment.topRight,
      bounds: bounds,
    );
    expect(card.bounds.right, bounds.right);
    expect(card.bounds.top, bounds.top);
  });

  test('minContentWidth 撑开, maxContentWidth 只压缩 value 列', () {
    final rows = [_row('A', '1')];
    final wide = paint(RecordingCanvas(), rows, minContentWidth: 200);
    expect(wide.bounds.width, 200 + _padding.horizontal);

    final long = [_row('A', '1234567890123456789012345678901234567890')];
    final natural = paint(RecordingCanvas(), long).bounds.width;
    final clipped = paint(RecordingCanvas(), long, maxContentWidth: 80);
    expect(natural, greaterThan(80 + _padding.horizontal));
    expect(clipped.bounds.width, 80 + _padding.horizontal);
  });

  test('第二帧内容不变时复用同一组 Paragraph(不重建、不重排)', () {
    final rows = [
      _row('Open', '1.00'),
      _row('Chg', '+0.5', valueStyle: _style.copyWith(color: const Color(0xFF00FF00))),
    ];
    final first = RecordingCanvas();
    paint(first, rows);
    final second = RecordingCanvas();
    paint(second, rows);
    final a = _paragraphs(first);
    final b = _paragraphs(second);
    expect(b, hasLength(a.length));
    for (var i = 0; i < a.length; i++) {
      expect(identical(a[i], b[i]), isTrue, reason: 'row painter $i was rebuilt');
    }
  });

  test('行样式进 key: 只换某行颜色不影响其它行的缓存', () {
    const green = TextStyle(color: Color(0xFF00FF00));
    const red = TextStyle(color: Color(0xFFFF0000));
    final first = RecordingCanvas();
    paint(first, [_row('Open', '1.00'), _row('Chg', '+0.5', valueStyle: green)]);
    final second = RecordingCanvas();
    paint(second, [_row('Open', '1.00'), _row('Chg', '+0.5', valueStyle: red)]);
    final a = _paragraphs(first);
    final b = _paragraphs(second);
    expect(identical(a[0], b[0]) && identical(a[1], b[1]), isTrue, reason: '未变的行应命中');
    expect(identical(a[3], b[3]), isFalse, reason: '换色的 value 应重建');
  });

  test('行数超过默认容量时扩容: 同一帧前面的行不被后面的行淘汰', () {
    final rows = [for (var i = 0; i < 20; i++) _row('L$i', 'V$i')];
    final first = RecordingCanvas();
    paint(first, rows);
    final paragraphs = _paragraphs(first);
    expect(paragraphs.toSet(), hasLength(40), reason: '每行各自的 label / value paragraph');

    final second = RecordingCanvas();
    paint(second, rows);
    expect(_paragraphs(second), orderedEquals(paragraphs));
  });

  test('decoration 为 null 时只画文字, 不画背景', () {
    final canvas = RecordingCanvas();
    paint(canvas, [_row('A', '1')], decoration: null);
    expect(canvas.rrectBounds, isEmpty);
    expect(_paragraphs(canvas), hasLength(2));
  });

  test('decoration 带边框与阴影时按卡片矩形绘制', () {
    final canvas = RecordingCanvas();
    final card = paint(
      canvas,
      [_row('A', '1')],
      decoration: const ShapeDecoration(
        color: Color(0xFFF2F2F2),
        shadows: [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFF888888)),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
    );
    // 阴影与填充各一次 drawRRect, 边框一次 drawDRRect; 填充缩进半个边框宽。
    expect(canvas.rrectBounds, hasLength(2));
    expect(canvas.rrectBounds.last, card.bounds.deflate(0.5));
    expect(canvas.invocations.where((i) => i.memberName == #drawDRRect), hasLength(1));
  });

  test('空列表不画任何东西', () {
    final canvas = RecordingCanvas();
    final card = paint(canvas, const []);
    expect(card.bounds, Rect.zero);
    expect(card.rows, isEmpty);
    expect(canvas.invocations, isEmpty);
  });
}
