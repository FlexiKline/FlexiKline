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

import 'package:flexi_kline/src/painting/export.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../recording_canvas.dart';

void main() {
  const radius = 4.0;
  const body = Rect.fromLTWH(20, 10, 100, 40);

  group('GradientRoundedRectangleBorder', () {
    const gradient = LinearGradient(colors: [Color(0xFF00FF00), Color(0xFF0000FF)]);
    const side = BorderSide(width: 2, color: Color(0xFFFF0000));
    const border = GradientRoundedRectangleBorder(
      side: side,
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      gradient: gradient,
    );

    test('按 strokeAlign 填充内外轮廓之间, 画笔挂 shader', () {
      final canvas = RecordingCanvas();
      border.paint(canvas, body);
      final args = canvas.invocations.single.positionalArguments;
      expect(canvas.invocations.single.memberName, #drawDRRect);
      expect((args[0] as RRect).outerRect, body);
      expect((args[1] as RRect).outerRect, body.deflate(2));
      expect((args[2] as Paint).shader, isNotNull);
    });

    test('线宽 0 画细线; 无边框时不画', () {
      final hairline = RecordingCanvas();
      border.copyWith(side: const BorderSide(width: 0)).paint(hairline, body);
      expect(hairline.rrectBounds, [body]);
      expect((hairline.invocations.single.positionalArguments[1] as Paint).shader, isNotNull);

      final none = RecordingCanvas();
      border.copyWith(side: BorderSide.none).paint(none, body);
      expect(none.invocations, isEmpty);
    });

    test('copyWith 与 scale 保留 gradient, 仍是 RoundedRectangleBorder', () {
      final copied = border.copyWith(borderRadius: BorderRadius.zero);
      expect(copied.gradient, gradient);
      expect(copied.side, side);
      expect(
        border.scale(2),
        const GradientRoundedRectangleBorder(
          side: BorderSide(width: 4, color: Color(0xFFFF0000)),
          borderRadius: BorderRadius.all(Radius.circular(radius * 2)),
          gradient: gradient,
        ),
      );
      expect(border, isA<RoundedRectangleBorder>());
    });

    test('== 区分渐变, 与同参的 RoundedRectangleBorder 不等', () {
      expect(border, border.copyWith());
      expect(border.hashCode, border.copyWith().hashCode);
      expect(
        border == border.copyWith(gradient: const LinearGradient(colors: [Color(0xFF000000), Color(0xFFFFFFFF)])),
        isFalse,
      );
      expect(
        border == const RoundedRectangleBorder(side: side, borderRadius: BorderRadius.all(Radius.circular(radius))),
        isFalse,
      );
    });
  });
}
