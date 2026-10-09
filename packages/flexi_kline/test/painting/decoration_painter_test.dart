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

import 'package:flexi_kline/src/painting/decoration_painter.dart';
import 'package:flexi_kline/src/painting/export.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';
import 'painting_doubles.dart';

const _red = Color(0xFFFF0000);
const _blue = Color(0xFF0000FF);
const _rounded = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4)));
const _bubble = BubbleBorder(borderRadius: BorderRadius.all(Radius.circular(4)), arrowSize: Size(10, 6));

void main() {
  const body = Rect.fromLTWH(10, 20, 40, 18);

  late DecorationPainter painter;
  late RecordingCanvas canvas;

  setUp(() {
    painter = DecorationPainter();
    canvas = RecordingCanvas();
  });

  tearDown(() => painter.dispose());

  group('BoxPainter 缓存', () {
    test('同一 decoration 实例跨帧只 createBoxPainter 一次, body 平移不重建', () {
      final decoration = ProbeDecoration();
      for (var i = 0; i < 3; i++) {
        painter.paint(canvas, decoration, body.shift(Offset(i * 10, 0)), Offset.zero);
      }
      expect(decoration.counts.created, 1);
      expect(decoration.counts.disposed, 0);
      expect(canvas.rrectBounds, [body, body.shift(const Offset(10, 0)), body.shift(const Offset(20, 0))]);
    });

    test('值相等的另一个实例换进来不重建', () {
      final a = ProbeDecoration();
      final b = ProbeDecoration();
      expect(identical(a, b), isFalse);
      expect(a, b);
      painter.paint(canvas, a, body, Offset.zero);
      painter.paint(canvas, b, body, Offset.zero);
      painter.paint(canvas, b, body, Offset.zero);
      expect(a.counts.created, 1);
      expect(a.counts.disposed, 0);
      expect(b.counts.created, 0);
    });

    test('decoration 值不等时释放旧的再建新的, 用新颜色绘制', () {
      final red = ProbeDecoration();
      final blue = ProbeDecoration(color: _blue);
      painter.paint(canvas, red, body, Offset.zero);
      canvas.clear();
      painter.paint(canvas, blue, body, Offset.zero);
      expect(red.counts.disposed, 1);
      expect(blue.counts.created, 1);
      final paint = canvas.invocations.firstWhere((i) => i.memberName == #drawRRect).positionalArguments[1] as Paint;
      expect(paint.color, _blue);
    });

    test('decoration 为 null: 释放旧 BoxPainter、不画、返回 null; 再传原 decoration 时重建', () {
      final decoration = ProbeDecoration();
      painter.paint(canvas, decoration, body, Offset.zero);
      canvas.clear();
      expect(painter.paint(canvas, null, body, Offset.zero), isNull);
      expect(decoration.counts.disposed, 1);
      expect(canvas.invocations, isEmpty);

      painter.paint(canvas, decoration, body, Offset.zero);
      expect(decoration.counts.created, 2);
    });

    test('AnchoredBorder: 相对锚点不变时复用, 变化时重建', () {
      final probe = ProbeBorder();
      final decoration = ShapeDecoration(color: _red, shape: probe);
      const first = Rect.fromLTWH(81, 76, 38, 18);
      painter.paint(canvas, decoration, first, const Offset(100, 100));
      // body 与 anchor 同步平移: 相对锚点恒为 (19, 24)。
      painter.paint(canvas, decoration, first.shift(const Offset(50, -20)), const Offset(150, 80));
      expect(probe.anchors, [const Offset(19, 24)]);

      // body 被夹到左边界, 锚点相对位置变了。
      painter.paint(canvas, decoration, const Rect.fromLTWH(0, 76, 38, 18), const Offset(2, 100));
      expect(probe.anchors, [const Offset(19, 24), const Offset(2, 24)]);
    });

    test('reset 与 dispose 各自释放 BoxPainter; reset 后可继续使用', () {
      final decoration = ProbeDecoration();
      painter.paint(canvas, decoration, body, Offset.zero);
      painter.reset();
      expect(decoration.counts.disposed, 1);
      painter.paint(canvas, decoration, body, Offset.zero);
      expect(decoration.counts.created, 2);

      final other = ProbeDecoration();
      final local = DecorationPainter();
      local.paint(canvas, other, body, Offset.zero);
      local.dispose();
      expect(other.counts.disposed, 1);
    });
  });

  group('返回形状', () {
    test('非 AnchoredBorder: 原样返回 decoration.shape', () {
      const decoration = ShapeDecoration(color: _red, shape: _rounded);
      expect(identical(painter.paint(canvas, decoration, body, Offset.zero), decoration.shape), isTrue);
    });

    test('BubbleBorder: 返回 anchorTo(anchor - body.topLeft) 之后的形状, 跨帧复用时仍返回它', () {
      const decoration = ShapeDecoration(color: _red, shape: _bubble);
      const anchor = Offset(30, 44);
      final shape = painter.paint(canvas, decoration, body, anchor);
      expect(shape, _bubble.anchorTo(anchor - body.topLeft));
      expect(painter.paint(canvas, decoration, body, anchor), shape);
    });
  });

  test('纯色圆角矩形落在 body 上', () {
    painter.paint(canvas, const ShapeDecoration(color: _red, shape: _rounded), body, Offset.zero);
    expect(canvas.rrectBounds.single, body);
  });

  test('BorderRadiusDirectional 按 ltr 解析, 不断言', () {
    const decoration = ShapeDecoration(
      color: _red,
      shape: RoundedRectangleBorder(
        side: BorderSide(width: 1),
        borderRadius: BorderRadiusDirectional.only(topStart: Radius.circular(4)),
      ),
    );
    expect(() => painter.paint(canvas, decoration, body, Offset.zero), returnsNormally);
    expect((canvas.invocations.first.positionalArguments[0] as RRect).tlRadius, const Radius.circular(4));
  });
}
