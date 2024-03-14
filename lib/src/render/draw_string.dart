import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

extension StringDraw on Canvas {
  Size drawString({
    required String string,
    required double fontSize,
    required Color fontColor,

    /// 绘制的起始位置，alignment都是相对于这个位置来生效
    required Offset offset,

    /// 相对起始位置的布局
    AlignmentGeometry alignment = Alignment.bottomRight,

    /// 字号
    FontWeight fontWeight = FontWeight.w400,

    /// 字体背景
    Color? backgroundColor,

    /// 背景圆角
    double? backgroundRadius,

    /// 相对绘制背景的padding
    EdgeInsets padding = EdgeInsets.zero,

    /// 最小绘制宽度
    double? minWidth,

    /// 设置这个值，会自动选择合适的位置，不超出范围,否则就按照给定offset渲染
    Rect? renderBox,
    Offset offsetToOrigin = Offset.zero,
  }) {
    if (string.isEmpty) return Size.zero;

    final TextSpan span = TextSpan(
      text: string,
      style: TextStyle(
        fontSize: fontSize,
        color: fontColor,
        fontWeight: fontWeight,
      ),
    );
    final TextPainter textPainter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    Offset startOffset = offset + offsetToOrigin;
    Size paintSize = textPainter.size +
        Offset(
          padding.left + padding.right,
          padding.top + padding.bottom,
        );

    double? leftOffset;
    if (minWidth != null && paintSize.width < minWidth) {
      leftOffset = (minWidth - paintSize.width) / 2;
      paintSize = Size(minWidth, paintSize.height);
    }

    /// 确定起始位置
    if (alignment == Alignment.bottomCenter) {
      startOffset = Offset(
        startOffset.dx - paintSize.width / 2,
        startOffset.dy,
      );
    } else if (alignment == Alignment.bottomLeft) {
      startOffset = Offset(
        startOffset.dx - paintSize.width,
        startOffset.dy,
      );
    } else if (alignment == Alignment.bottomRight) {
      startOffset = Offset(
        startOffset.dx,
        startOffset.dy,
      );
    } else if (alignment == Alignment.center) {
      startOffset = Offset(
        startOffset.dx - paintSize.width / 2,
        startOffset.dy - paintSize.height / 2,
      );
    } else if (alignment == Alignment.centerRight) {
      startOffset = Offset(
        startOffset.dx,
        startOffset.dy - paintSize.height / 2,
      );
    } else if (alignment == Alignment.centerLeft) {
      startOffset = Offset(
        startOffset.dx - paintSize.width,
        startOffset.dy - paintSize.height / 2,
      );
    } else if (alignment == Alignment.topCenter) {
      startOffset = Offset(
        startOffset.dx - paintSize.width / 2,
        startOffset.dy - paintSize.height,
      );
    } else if (alignment == Alignment.topRight) {
      startOffset = Offset(
        startOffset.dx,
        startOffset.dy - paintSize.height,
      );
    } else if (alignment == Alignment.topLeft) {
      startOffset = Offset(
        startOffset.dx - paintSize.width,
        startOffset.dy - paintSize.height,
      );
    }

    if (renderBox != null) {
      double dx = startOffset.dx;
      if (dx < renderBox.left) {
        dx = renderBox.left;
      } else if (dx + paintSize.width > renderBox.right) {
        dx = (renderBox.right - paintSize.width)
            .clamp(renderBox.left, renderBox.right)
            .toDouble();
      }
      double dy = startOffset.dy;
      if (dy < renderBox.top) {
        dy = renderBox.top;
      } else if (dy + paintSize.height > renderBox.bottom) {
        dy = (renderBox.bottom - paintSize.height)
            .clamp(renderBox.top, renderBox.bottom)
            .toDouble();
      }
      startOffset = Offset(dx, dy);
    }

    /// 绘制背景
    if (backgroundColor != null) {
      final Paint paint = Paint()..color = backgroundColor;
      final Rect rect = Rect.fromLTWH(
        startOffset.dx,
        startOffset.dy,
        paintSize.width,
        paintSize.height,
      );
      if (backgroundRadius != null) {
        final RRect rRect = RRect.fromRectAndRadius(
          rect,
          Radius.circular(backgroundRadius),
        );
        drawRRect(rRect, paint);
      } else {
        drawRect(rect, paint);
      }
    }

    textPainter.paint(
      this,
      startOffset + Offset(padding.left + (leftOffset ?? 0), padding.top),
    );
    return paintSize;
  }

  void drawMutableString(
    Offset offset,
    List<String> texts,
    List<Color> colors,
    double fontSize,
    double maxWidth,
    TextAlign align, {
    Color? backgroundColor,
    double height = 1.0,
  }) {
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: align,
        fontSize: fontSize,
        height: height,
      ),
    );
    Paint? background;
    if (backgroundColor != null) {
      background = Paint()..color = backgroundColor;
    }
    for (int i = 0; i < texts.length; i++) {
      builder.pushStyle(ui.TextStyle(
        color: colors[i],
        background: background,
      ));
      builder.addText(texts[i]);
    }
    final ui.ParagraphConstraints constraints = ui.ParagraphConstraints(
      width: maxWidth,
    );
    final ui.Paragraph paragraph = builder.build()..layout(constraints);
    drawParagraph(paragraph, offset);
  }
}
