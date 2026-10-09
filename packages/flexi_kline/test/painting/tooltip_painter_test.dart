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

import 'package:flexi_kline/src/painting/tooltip_painter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _style = TextStyle(fontSize: 10, height: 1.2);
const _padding = EdgeInsets.all(4);

TooltipRow _row(String label, String value, {TextStyle? valueStyle}) =>
    (label: label, labelStyle: null, value: value, valueStyle: valueStyle);

List<Paragraph> _paragraphs(RecordingCanvas canvas) => [
  for (final i in canvas.invocations)
    if (i.memberName == #drawParagraph) i.positionalArguments[0] as Paragraph,
];

void main() {
  late TooltipPainter painter;
  setUp(() => painter = TooltipPainter());
  tearDown(() => painter.dispose());

  ({Rect bounds, List<Rect> rows}) paint(
    RecordingCanvas canvas,
    List<TooltipRow> rows, {
    Offset anchor = const Offset(10, 10),
    Alignment align = Alignment.topLeft,
    Rect? bounds,
    double? minContentWidth,
    double maxContentWidth = double.infinity,
  }) => painter.paint(
    canvas,
    rows,
    style: _style,
    anchor: anchor,
    align: align,
    bounds: bounds,
    spacing: 8,
    minContentWidth: minContentWidth,
    maxContentWidth: maxContentWidth,
    backgroundColor: const Color(0xFFF2F2F2),
    radius: const BorderRadius.all(Radius.circular(4)),
    padding: _padding,
  );

  test('卡片宽为 label 列 + spacing + value 列 + padding, 各行横向撑满卡片', () {
    final canvas = RecordingCanvas();
    final card = paint(canvas, [_row('Open', '1.00'), _row('Close', '123.45')]);

    final p = _paragraphs(canvas);
    expect(p, hasLength(4));
    final labelWidth = [p[0].longestLine, p[2].longestLine].reduce((a, b) => a > b ? a : b);
    final valueWidth = [p[1].longestLine, p[3].longestLine].reduce((a, b) => a > b ? a : b);
    expect(card.bounds.width, closeTo(labelWidth + 8 + valueWidth + _padding.horizontal, 0.01));
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

  test('空列表不画任何东西', () {
    final canvas = RecordingCanvas();
    final card = paint(canvas, const []);
    expect(card.bounds, Rect.zero);
    expect(card.rows, isEmpty);
    expect(canvas.invocations, isEmpty);
  });
}
