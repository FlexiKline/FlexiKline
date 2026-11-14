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

import 'package:flutter/painting.dart';

/// 描边用 [gradient] 着色的圆角矩形; 形状、填充与描边位置同 [RoundedRectangleBorder]。
///
/// 不参与形状插值: lerp 得到的是不带渐变的 RoundedRectangleBorder。
final class GradientRoundedRectangleBorder extends RoundedRectangleBorder {
  const GradientRoundedRectangleBorder({super.side, super.borderRadius, required this.gradient});

  /// 着色区域是传给 [paint] 的 rect。
  final Gradient gradient;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    final rrect = borderRadius.resolve(textDirection).toRRect(rect);
    final paint = Paint()..shader = gradient.createShader(rect, textDirection: textDirection);
    // 与 RoundedRectangleBorder 相同: 线宽 0 画细线, 否则按 strokeAlign 填充内外两条轮廓之间。
    if (side.width == 0) {
      canvas.drawRRect(rrect, paint..style = PaintingStyle.stroke);
    } else {
      canvas.drawDRRect(rrect.inflate(side.strokeOutset), rrect.deflate(side.strokeInset), paint);
    }
  }

  @override
  GradientRoundedRectangleBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
    Gradient? gradient,
  }) => GradientRoundedRectangleBorder(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
    gradient: gradient ?? this.gradient,
  );

  @override
  GradientRoundedRectangleBorder scale(double t) => GradientRoundedRectangleBorder(
    side: side.scale(t),
    borderRadius: borderRadius * t,
    gradient: gradient,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradientRoundedRectangleBorder &&
          side == other.side &&
          borderRadius == other.borderRadius &&
          gradient == other.gradient;

  @override
  int get hashCode => Object.hash(side, borderRadius, gradient);
}
