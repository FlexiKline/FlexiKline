import 'package:flutter/material.dart';

extension DrawTextExt on Canvas {
  /// 绘制文本
  Size drawText({
    required Offset offset, //绘制启始坐标位置

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

    final isDrawBg = backgroundColor.alpha != 0;
    final isDrawBorder = borderColor.alpha != 0 && borderWidth > 0;
    if (!padding.collapsedSize.isEmpty || isDrawBg || isDrawBorder) {
      final Path path = Path();
      paintSize += Offset(
        padding.horizontal,
        padding.vertical,
      );
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
