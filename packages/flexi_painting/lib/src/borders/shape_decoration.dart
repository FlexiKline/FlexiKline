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

import 'bubble_border.dart';
import 'gradient_rounded_rectangle_border.dart';

/// 合成圆角矩形的背景、边框与阴影; 全部为空时返回 null。
///
/// [gradient] 优先于 [color]。[borderGradient] 只在 [border] 非空时生效, 此时边框用 [GradientRoundedRectangleBorder]。
ShapeDecoration? roundedShapeDecoration({
  Color? color,
  BorderSide? border,
  BorderRadius? borderRadius,
  Gradient? gradient,
  Gradient? borderGradient,
  List<BoxShadow>? shadows,
}) {
  if (color == null && border == null && borderRadius == null && gradient == null && shadows == null) return null;
  final radius = borderRadius ?? BorderRadius.zero;
  return ShapeDecoration(
    // ShapeDecoration 断言 color 与 gradient 不能同时非空。
    color: gradient == null ? color : null,
    gradient: gradient,
    shadows: shadows,
    shape: border != null && borderGradient != null
        ? GradientRoundedRectangleBorder(side: border, borderRadius: radius, gradient: borderGradient)
        : RoundedRectangleBorder(side: border ?? BorderSide.none, borderRadius: radius),
  );
}

/// 背景 / 阴影放在 [ShapeDecoration] 上, 边框与箭头放在 [BubbleBorder] 上; [borderGradient] 为描边渐变。
ShapeDecoration bubbleShapeDecoration({
  required AxisDirection direction,
  Size arrowSize = const Size(10, 6),
  double arrowRadius = 0,
  Color? color,
  Gradient? gradient,
  List<BoxShadow>? shadows,
  BorderSide side = BorderSide.none,
  BorderRadius borderRadius = BorderRadius.zero,
  Gradient? borderGradient,
}) {
  return ShapeDecoration(
    color: color,
    gradient: gradient,
    shadows: shadows,
    shape: BubbleBorder(
      side: side,
      borderRadius: borderRadius,
      direction: direction,
      arrowSize: arrowSize,
      arrowRadius: arrowRadius,
      gradient: borderGradient,
    ),
  );
}
