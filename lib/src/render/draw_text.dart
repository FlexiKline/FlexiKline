import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'common.dart';

extension DrawTextExt on Canvas {
  /// 绘制文本
  Size drawText({
    ///绘制启始坐标位置
    required Offset offset,

    /// X轴上的绘制方向: 以offset为原点, 向左向右绘制.
    DrawDirection drawDirection = DrawDirection.ltr,

    /// 文本区域的边界margin, 在贴近绘制边界时, 增加一定的margin友好展示.
    // double drawMargin = 0,
    // EdgeInsets? margin,

    /// 可绘制区域大小
    /// 主要用于边界矫正, 当前超出边界区域时, 会主动反向调整, 以保证内容区域完全展示. 如为null: 则不做边界矫正.
    /// 1. 在向offset右边绘制时, 检测超出画板右边绘制区域时, 会主动向左调整offset偏移量, 以保证内容区域完全展示.
    /// 2. 在向offset下边绘制时, 检测已超过底部绘制区域时, 会主动向上调整offset偏移量, 以保证内容区域完全展示.
    Size? drawableSize,

    /// 文本,样式设置. (注: text与children必须设置一个, 否则不绘制)
    String? text,
    TextStyle? style,
    InlineSpan? inlineSpan,
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
    if (text?.isNotEmpty != true && inlineSpan == null) {
      return Size.zero;
    }

    TextPainter textPainter = TextPainter(
      text: inlineSpan ??
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
