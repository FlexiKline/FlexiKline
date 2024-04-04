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

extension DrawTextExt on Canvas {
  /// 绘制文本
  Size drawText({
    ///绘制启始坐标位置
    required Offset offset,

    /// X轴上的绘制方向: 以offset为原点, 向左向右绘制; 以及居中绘制
    DrawDirection drawDirection = DrawDirection.ltr,

    /// 文本区域的边界margin, 在贴近绘制边界时, 增加一定的margin友好展示.
    // double drawMargin = 0,
    // EdgeInsets? margin,

    /// 可绘制区域大小
    /// 主要用于边界矫正, 当绘制超出边界区域时, 会主动反向调整, 以保证内容区域完全展示. 如为null: 则不做边界矫正.
    /// 1. 当绘制方向DrawDirection.ltr, 检测超出drawableSize右边界, 会主动向左调整offset xAxis偏移量, 且不超过左边界, 以保证内容区域完全展示.
    /// 2. 当绘制方向DrawDirection.rtl, 检测超出drawableSize左边界, 会主动向右调整offset xAxis偏移量, 且不超过右边界, 以保证内容区域完全展示.
    /// 3. 当绘制高度超出drawableSize规定高度时, 会主动向上调整offset yAxis轴偏移量, 且不超过上边界, 以保证内容区域完全展示.
    Size? drawableSize,

    /// 文本,样式设置. (注: text与textSpan必须设置一个, 否则不绘制)
    String? text,
    InlineSpan? textSpan,
    TextStyle? style,
    TextAlign textAlign = TextAlign.left,
    TextDirection textDirection = TextDirection.ltr,
    int? maxLines,
    TextScaler textScaler = TextScaler.noScaling,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    double? textWidth, // 文本所占的固定宽度, 不指定, 由minWidth与maxWidth来决定.
    double minWidth = 0.0,
    double maxWidth = double.infinity,

    /// 文本内容的背景区域设置
    Color backgroundColor = Colors.transparent,
    double radius = 0,
    BorderRadius? borderRadius,
    EdgeInsets padding = EdgeInsets.zero,
    Color borderColor = Colors.transparent,
    double borderWidth = 0,
  }) {
    if (text?.isNotEmpty != true && textSpan == null) {
      return Size.zero;
    }

    TextPainter textPainter = TextPainter(
      text: textSpan ??
          TextSpan(
            text: text,
            style: style,
          ),
      textAlign: textAlign,
      textDirection: textDirection,
      maxLines: maxLines,
      textScaler: textScaler,
      textWidthBasis: textWidthBasis,
    );

    textPainter.layout(
      minWidth: textWidth ?? minWidth,
      maxWidth: textWidth ?? maxWidth,
    );

    Size paintSize = textPainter.size;
    paintSize += Offset(
      padding.horizontal,
      padding.vertical,
    );

    if (drawableSize != null) {
      double dy = math.max(
        0,
        math.min(offset.dy, drawableSize.height - paintSize.height),
      );

      double dx;
      if (drawDirection.isltr) {
        dx = math.max(
          0,
          math.min(offset.dx, drawableSize.width - paintSize.width),
        );
      } else if (drawDirection.isCenter) {
        dx = math.max(
          0,
          math.min(offset.dx, drawableSize.width - paintSize.width / 2),
        );
      } else {
        // 从右向左
        dx = math.max(
          0,
          math.min(
            drawableSize.width - paintSize.width,
            offset.dx - paintSize.width,
          ),
        );
      }

      offset = Offset(dx, dy);
    } else {
      if (drawDirection.isrtl) {
        offset = Offset(
          offset.dx - paintSize.width,
          offset.dy,
        );
      } else if (drawDirection.isCenter) {
        offset = Offset(
          offset.dx - paintSize.width / 2,
          offset.dy,
        );
      }
    }

    final isDrawBg = backgroundColor.alpha != 0;
    final isDrawBorder = borderColor.alpha != 0 && borderWidth > 0;
    if (!padding.collapsedSize.isEmpty || isDrawBg || isDrawBorder) {
      // if (margin != null && margin.isNonNegative) {
      //   final x = drawDirection.isltr ? -margin.right : margin.left;
      //   final y = isUpward ? margin.bottom : -margin.top;
      //   offset = Offset(
      //     offset.dx + x,
      //     offset.dy + y,
      //   );
      //   margin = null;
      // }

      final Path path = Path();
      if (borderRadius != null) {
        path.addRRect(RRect.fromLTRBAndCorners(
          offset.dx,
          offset.dy,
          offset.dx + paintSize.width,
          offset.dy + paintSize.height,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        ));
      } else {
        path.addRRect(RRect.fromLTRBR(
          offset.dx,
          offset.dy,
          offset.dx + paintSize.width,
          offset.dy + paintSize.height,
          Radius.circular(radius),
        ));
      }

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

      offset += Offset(padding.left, padding.top);
    }

    // if (margin != null && margin.isNonNegative) {
    //   final x = drawDirection.isltr ? -margin.right : margin.left;
    //   final y = isUpward ? -margin.bottom : margin.top;
    //   offset = Offset(
    //     offset.dx + x,
    //     offset.dy + y,
    //   );
    // }

    textPainter.paint(this, offset);

    return paintSize;
  }
}
