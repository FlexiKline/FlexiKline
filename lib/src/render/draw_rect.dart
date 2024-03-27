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
    /// 主要用于边界矫正, 当前超出边界区域时, 会主动反向调整, 以保证内容区域完全展示. 如为null: 则不做边界矫正.
    /// 1. 在向offset右边绘制时, 检测超出画板右边绘制区域时, 会主动向左调整offset偏移量, 以保证内容区域完全展示.
    /// 2. 在向offset下边绘制时, 检测已超过底部绘制区域时, 会主动向上调整offset偏移量, 以保证内容区域完全展示.
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
