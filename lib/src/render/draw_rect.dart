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

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'common.dart';

extension DrawRect on Canvas {
  /// 绘制一个背景区域.
  Offset drawRectBackground({
    ///绘制启始坐标位置
    required Offset offset,
    required Size size,

    /// X轴上的绘制方向: 以offset为原点, 向左向右绘制.
    DrawDirection drawDirection = DrawDirection.ltr,

    /// 区域边界margin
    EdgeInsets? margin,

    /// 可绘制区域大小
    /// 主要用于边界矫正, 当绘制超出边界区域时, 会主动反向调整, 以保证内容区域完全展示. 如为null: 则不做边界矫正.
    /// 1. 当绘制方向DrawDirection.ltr, 检测超出drawableSize右边界, 会主动向左调整offset xAxis偏移量, 且不超过左边界, 以保证内容区域完全展示.
    /// 2. 当绘制方向DrawDirection.rtl, 检测超出drawableSize左边界, 会主动向右调整offset xAxis偏移量, 且不超过右边界, 以保证内容区域完全展示.
    /// 3. 当绘制高度超出drawableSize规定高度时, 会主动向上调整offset yAxis轴偏移量, 且不超过上边界, 以保证内容区域完全展示.
    Size? drawableSize,

    /// 背景
    Color backgroundColor = Colors.transparent,
    double borderRadius = 0,
    Color borderColor = Colors.transparent,
    double borderWidth = 0,
  }) {
    final isDrawBg = backgroundColor.alpha != 0;
    final isDrawBorder = borderColor.alpha != 0 && borderWidth > 0;
    if (size.isEmpty && !isDrawBg && !isDrawBorder) {
      return offset;
    }

    if (margin != null && margin.isNonNegative) {
      size += Offset(margin.horizontal, margin.vertical);
    }

    // 矫正边界.
    if (drawableSize != null) {
      double dy = math.max(
        0,
        math.min(offset.dy, drawableSize.height - size.height),
      );

      double dx;
      if (drawDirection.isltr) {
        dx = math.max(
          0,
          math.min(offset.dx, drawableSize.width - size.width),
        );
      } else {
        // 从右向左
        dx = math.max(
          0,
          math.min(
            drawableSize.width - size.width,
            offset.dx - size.width,
          ),
        );
      }

      offset = Offset(dx, dy);
    }

    if (margin != null && margin.isNonNegative) {
      final x = drawDirection.isltr ? margin.left : margin.right;
      offset = Offset(
        offset.dx + x,
        offset.dy + margin.top,
      );
      size = Size(
        size.width - margin.horizontal,
        size.height - margin.vertical,
      );
    }

    final Path path = Path();
    path.addRRect(
      RRect.fromLTRBR(
        offset.dx,
        offset.dy,
        offset.dx + size.width,
        offset.dy + size.height,
        Radius.circular(borderRadius),
      ),
    );

    if (isDrawBg) {
      drawPath(
        path,
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.fill
          ..strokeWidth = 1,
      );
    }

    if (isDrawBorder) {
      drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }

    // 如果参数offset在绘制过程中被矫正了, 为下一步返回其值.
    return offset;
  }
}
