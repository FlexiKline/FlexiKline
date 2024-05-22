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

import '../../config/text_area_config/text_area_config.dart';
import '../geometry_ext.dart';
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
    @Deprecated("建议使用drawableRect来代替") Size? drawableSize,
    Rect? drawableRect,

    /// 文本,样式设置. (注: text与textSpan必须设置一个, 否则不绘制)
    String? text,
    InlineSpan? textSpan,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign textAlign = TextAlign.start,
    TextDirection textDirection = TextDirection.ltr,
    int? maxLines,
    TextScaler textScaler = TextScaler.noScaling,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    double? textWidth, // 文本所占的固定宽度, 不指定, 由minWidth与maxWidth来决定.
    double minWidth = 0.0,
    double maxWidth = double.infinity,

    /// 文本内容的背景区域设置
    Color? backgroundColor,
    @Deprecated('废弃的, 请使用borderRadius') double radius = 0,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    @Deprecated('废弃的, 请使用borderSide') Color borderColor = Colors.transparent,
    @Deprecated('废弃的, 请使用borderSide') double borderWidth = 0,
    BorderSide? borderSide,
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
      strutStyle: strutStyle,
    );

    textPainter.layout(
      minWidth: textWidth ?? minWidth,
      maxWidth: textWidth ?? maxWidth,
    );

    Size paintSize = textPainter.size;

    final hasPadding = padding != null && padding.collapsedSize.nonzero;
    if (hasPadding) {
      paintSize += Offset(
        padding.horizontal,
        padding.vertical,
      );
    }

    if (drawableRect != null) {
      double dy = math.max(
        drawableRect.top,
        math.min(offset.dy, drawableRect.bottom),
      );
      double dx;
      switch (drawDirection) {
        case DrawDirection.ltr:
          dx = math.max(
            drawableRect.left,
            math.min(offset.dx, drawableRect.right - paintSize.width),
          );
          break;
        case DrawDirection.center:
          dx = math.max(
            drawableRect.left,
            math.min(offset.dx, drawableRect.right - paintSize.width / 2),
          );
          break;
        case DrawDirection.rtl:
          dx = math.max(
            drawableRect.left,
            math.min(
              drawableRect.right - paintSize.width,
              offset.dx - paintSize.width,
            ),
          );
          break;
      }

      offset = Offset(dx, dy);
    } else if (drawableSize != null) {
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

    final isDrawBg = backgroundColor != null && backgroundColor.alpha != 0;
    final isDrawBorder = (borderColor.alpha != 0 && borderWidth > 0) ||
        (borderSide != null &&
            borderSide.color.alpha != 0 &&
            borderSide.width > 0);
    if (hasPadding || isDrawBg || isDrawBorder) {
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
            ..color = borderSide?.color ?? borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderSide?.width ?? borderWidth,
        );
      }

      if (padding != null) offset += Offset(padding.left, padding.top);
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

  Size drawTextArea({
    ///绘制启始坐标位置
    required Offset offset,

    /// X轴上的绘制方向: 以offset为原点, 向左向右绘制; 以及居中绘制
    DrawDirection drawDirection = DrawDirection.ltr,

    /// 可绘制区域大小
    Rect? drawableRect,

    /// 文本,样式设置. (注: text与textSpan必须设置一个, 否则不绘制)
    String? text,
    InlineSpan? textSpan,

    /// 文本区域配置
    required TextAreaConfig textConfig,
    // 如textConfig未指定, 备选
    int maxLines = 1,
    double minWidth = 0,
    double maxWidth = double.infinity,
    // 如指定, 首先使用
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BorderSide? borderSide,
    EdgeInsets? padding,
  }) {
    return drawText(
      offset: offset,
      drawDirection: drawDirection,
      drawableRect: drawableRect,
      text: text,
      textSpan: textSpan,
      // 文本
      style: textConfig.style,
      strutStyle: textConfig.strutStyle,
      textAlign: textConfig.textAlign,
      maxLines: textConfig.maxLines ?? 1,
      textWidth: textConfig.textWidth,
      minWidth: textConfig.minWidth ?? minWidth,
      maxWidth: textConfig.maxWidth ?? maxWidth,
      // 文本区域
      backgroundColor: backgroundColor ?? textConfig.background,
      borderRadius: borderRadius ?? textConfig.borderRadius,
      borderSide: borderSide ?? textConfig.border,
      padding: padding ?? textConfig.padding,
    );
  }
}
