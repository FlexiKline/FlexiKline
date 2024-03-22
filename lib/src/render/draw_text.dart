import 'dart:math' as math;
import 'package:flutter/material.dart';

enum DrawDirection {
  /// The draw flows from right to left.
  rtl,

  /// The draw flows from left to right.
  ltr,
}

extension DrawTextExt on Canvas {
  /// 绘制文本
  Size drawText({
    ///绘制启始坐标位置
    required Offset offset,

    /// X轴上的绘制方向: 以offset为原点, 向左向进制绘制.
    DrawDirection drawDirection = DrawDirection.ltr,

    // TextDirection
    /// 画布总宽度,
    /// 注: 如果提供, 在向offset右边绘制时, 检测超出画板右边绘制区域时, 会主动向左调整offset偏移量, 以保证内容区域完全展示.
    double? canvasWidth,

    /// 文本,样式设置. (注: text与children必须设置一个, 否则不绘制)
    String? text,
    TextStyle? style,
    List<TextSpan>? children,
    TextAlign textAlign = TextAlign.left,
    TextDirection textDirection = TextDirection.ltr,
    int? maxLines,
    TextScaler textScaler = TextScaler.noScaling,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    double? textWidth, // 文本所占的固定宽度, 不指定, 由minWidth与maxWidth来决定.
    double minWidth = 0.0,
    double maxWidth = double.infinity,

    // 文本内容的背景区域设置
    Color backgroundColor = Colors.transparent,
    double borderRadius = 0,
    EdgeInsets padding = EdgeInsets.zero,
    Color borderColor = Colors.transparent,
    double borderWidth = 0,
  }) {
    if (text?.trim().isNotEmpty != true && children?.isNotEmpty != true) {
      return Size.zero;
    }

    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
        children: children,
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

    if (drawDirection == DrawDirection.rtl) {
      offset = Offset(
        math.max(0, offset.dx - paintSize.width),
        offset.dy,
      );
    } else if (canvasWidth != null &&
        offset.dx + paintSize.width > canvasWidth) {
      // 如果内容区域超出画布右边界. 向左调整offset
      offset = Offset(
        math.max(0, canvasWidth - paintSize.width),
        offset.dy,
      );
    }

    final isDrawBg = backgroundColor.alpha != 0;
    final isDrawBorder = borderColor.alpha != 0 && borderWidth > 0;
    if (!padding.collapsedSize.isEmpty || isDrawBg || isDrawBorder) {
      final Path path = Path();
      path.addRRect(
        RRect.fromLTRBR(
          offset.dx,
          offset.dy,
          offset.dx + paintSize.width,
          offset.dy + paintSize.height,
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

      offset += Offset(padding.left, padding.top);
    }

    textPainter.paint(this, offset);

    return paintSize;
  }
}
