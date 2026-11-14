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

import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('roundedShapeDecoration', () {
    const red = Color(0xFFFF0000);
    const gradient = LinearGradient(colors: [Color(0xFF00FF00), Color(0xFF0000FF)]);
    const side = BorderSide(color: red);

    test('全部为空时返回 null', () {
      expect(roundedShapeDecoration(), isNull);
    });

    test('渐变优先于背景色', () {
      final decoration = roundedShapeDecoration(color: red, gradient: gradient)!;
      expect(decoration.color, isNull);
      expect(decoration.gradient, gradient);
    });

    test('有边框和边框渐变时用 GradientRoundedRectangleBorder, 否则用 RoundedRectangleBorder', () {
      const radius = BorderRadius.all(Radius.circular(6));
      final gradientBorder = roundedShapeDecoration(border: side, borderRadius: radius, borderGradient: gradient)!;
      expect(
        gradientBorder.shape,
        const GradientRoundedRectangleBorder(side: side, borderRadius: radius, gradient: gradient),
      );

      final noBorder = roundedShapeDecoration(color: red, borderGradient: gradient)!;
      expect(noBorder.shape, const RoundedRectangleBorder());
    });
  });

  group('bubbleShapeDecoration', () {
    const side = BorderSide(color: Color(0xFFFF0000));
    const radius = BorderRadius.all(Radius.circular(4));
    const shadows = [BoxShadow(color: Color(0x33000000), blurRadius: 4)];
    const gradient = LinearGradient(colors: [Color(0xFF00FF00), Color(0xFF0000FF)]);

    test('参数分别进入 ShapeDecoration 与 BubbleBorder, 箭头指向给定方向', () {
      final bubble = bubbleShapeDecoration(
        direction: AxisDirection.left,
        arrowSize: const Size(8, 4),
        arrowRadius: 1,
        color: const Color(0xFFF2F2F2),
        shadows: shadows,
        side: side,
        borderRadius: radius,
      );
      expect(bubble.color, const Color(0xFFF2F2F2));
      expect(bubble.shadows, shadows);
      expect(
        bubble.shape,
        const BubbleBorder(
          side: side,
          borderRadius: radius,
          direction: AxisDirection.left,
          arrowSize: Size(8, 4),
          arrowRadius: 1,
        ),
      );
    });

    test('背景渐变与描边渐变分别放在装饰与气泡边框上', () {
      final bubble = bubbleShapeDecoration(
        direction: AxisDirection.down,
        gradient: gradient,
        side: side,
        borderRadius: radius,
        borderGradient: gradient,
      );
      expect(bubble.color, isNull);
      expect(bubble.gradient, gradient);
      expect((bubble.shape as BubbleBorder).gradient, gradient);
    });
  });
}
