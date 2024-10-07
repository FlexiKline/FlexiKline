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

import '../../config/point_config/point_config.dart';

extension DrawCircle on Canvas {
  /// 绘制一个带边框的圆点.
  void drawBorderCircle({
    ///绘制启始坐标位置
    required Offset offset,
    required double radius,
    required Paint paint,
    double? borderWidth,
    Color? borderColor,
    Paint? borderPaint,
  }) {
    if (offset.isInfinite) return;
    borderWidth ??= borderPaint?.strokeWidth;
    borderColor ??= borderPaint?.color;
    if (borderWidth != null &&
        borderWidth > 0 &&
        borderColor != null &&
        borderColor.alpha != 0) {
      drawCircle(
        offset,
        radius + borderWidth / 2,
        Paint()
          ..color = borderColor
          ..strokeWidth = borderWidth
          ..style = PaintingStyle.stroke,
      );
    }
    drawCircle(offset, radius, paint);
  }

  void drawCirclePoint(
    Offset offset,
    PointConfig point,
  ) {
    drawBorderCircle(
      offset: offset,
      radius: point.radius,
      paint: point.paint,
      borderWidth: point.borderWidth,
      borderColor: point.borderColor,
    );
  }
}
