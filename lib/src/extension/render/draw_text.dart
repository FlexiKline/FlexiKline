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

import 'package:flutter/painting.dart';

import '../../config/text_area_config/text_area_config.dart';
import '../geometry_ext.dart';
import 'types.dart';

extension FlexiDrawTextExt on Canvas {
  /// 绘制文本
  Size drawText({
    ///绘制启始坐标位置
    required Offset offset,

    /// X轴上的绘制方向: 以offset为原点, 向左向右绘制; 以及居中绘制
    DrawDirection drawDirection = DrawDirection.ltr,

    /// 可绘制区域大小
    /// 主要用于边界矫正, 当绘制超出边界区域时, 会主动反向调整, 以保证内容区域完全展示. 如为null: 则不做边界矫正.
    /// 1. 当绘制方向DrawDirection.ltr, 检测超出drawableSize右边界, 会主动向左调整offset xAxis偏移量, 且不超过左边界, 以保证内容区域完全展示.
    /// 2. 当绘制方向DrawDirection.rtl, 检测超出drawableSize左边界, 会主动向右调整offset xAxis偏移量, 且不超过右边界, 以保证内容区域完全展示.
    /// 3. 当绘制高度超出drawableSize规定高度时, 会主动向上调整offset yAxis轴偏移量, 且不超过上边界, 以保证内容区域完全展示.
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
    BorderRadius? borderRadius,
    BorderSide? borderSide,
    EdgeInsets? padding,
  }) {
    if (text?.isNotEmpty != true && textSpan == null) {
      return Size.zero;
    }

    final textPainter = TextPainter(
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

    Size containerSize = textPainter.size;

    final hasPadding = padding != null && padding.collapsedSize.nonzero;
    if (hasPadding) {
      containerSize += Offset(padding.horizontal, padding.vertical);
    }

    if (drawableRect != null) {
      final dy = math.max(
        drawableRect.top,
        math.min(offset.dy, drawableRect.bottom),
      );
      double dx;
      switch (drawDirection) {
        case DrawDirection.ltr:
          dx = math.max(
            drawableRect.left,
            math.min(offset.dx, drawableRect.right - containerSize.width),
          );
          break;
        case DrawDirection.center:
          dx = math.max(
            drawableRect.left,
            math.min(offset.dx, drawableRect.right - containerSize.width / 2),
          );
          break;
        case DrawDirection.rtl:
          dx = math.max(
            drawableRect.left,
            math.min(
              drawableRect.right - containerSize.width,
              offset.dx - containerSize.width,
            ),
          );
          break;
      }

      offset = Offset(dx, dy);
    } else {
      if (drawDirection.isrtl) {
        offset = Offset(
          offset.dx - containerSize.width,
          offset.dy,
        );
      } else if (drawDirection.isCenter) {
        offset = Offset(
          offset.dx - containerSize.width / 2,
          offset.dy,
        );
      }
    }

    final isDrawBg = backgroundColor != null && backgroundColor.a != 0;
    final isDrawBorder = borderSide != null && borderSide.color.a != 0 && borderSide.width > 0;
    if (hasPadding || isDrawBg || isDrawBorder) {
      final Path path = Path();
      if (borderRadius != null) {
        path.addRRect(RRect.fromLTRBAndCorners(
          offset.dx,
          offset.dy,
          offset.dx + containerSize.width,
          offset.dy + containerSize.height,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        ));
      } else {
        path.addRRect(RRect.fromLTRBR(
          offset.dx,
          offset.dy,
          offset.dx + containerSize.width,
          offset.dy + containerSize.height,
          const Radius.circular(0),
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
            ..color = borderSide.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderSide.width,
        );
      }

      if (hasPadding) offset += Offset(padding.left, padding.top);
    }

    textPainter.paint(this, offset);

    return containerSize;
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

    /// 文本内容的背景区域设置
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
      maxLines: textConfig.maxLines,
      textWidth: textConfig.textWidth,
      minWidth: textConfig.minWidth ?? 0.0,
      maxWidth: textConfig.maxWidth ?? double.infinity,
      // 文本区域
      backgroundColor: backgroundColor ?? textConfig.background,
      borderRadius: borderRadius ?? textConfig.borderRadius,
      borderSide: borderSide ?? textConfig.border,
      padding: padding ?? textConfig.padding,
    );
  }
}
