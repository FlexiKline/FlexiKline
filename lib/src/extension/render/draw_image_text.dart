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
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../geometry_ext.dart';
import './draw_image.dart';

import 'types.dart';

extension FlexiDrawImageText on Canvas {
  /// 绘制图片区域.
  /// 返回[image]在canvas中的实际绘制区域.
  Rect drawImageText({
    ///绘制启始坐标位置
    required Offset offset,

    /// 绘制图片配置
    required ui.Image image,
    required Size imgSize,
    // 针对[image]的裁剪区域
    Rect? srcRect,
    // 是否裁切: 仅在[borderRadius]有效时, 按[borderRadius]裁切.
    bool isClip = true,
    Paint? imagePaint,

    /// 图文绘制顺序: true: 图在前; false: 文在前.
    bool drawImageFirst = true,

    /// 图片与文本在垂直对齐方式: 居中对齐, 上对齐, 下对齐.
    YAxisAlign yAxisAlign = YAxisAlign.center,

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

    /// X轴上的绘制方向: 以offset为原点, 向左向右绘制; 以及居中绘制
    DrawDirection drawDirection = DrawDirection.ltr,

    /// 可绘制区域大小
    /// 主要用于边界矫正, 当绘制超出边界区域时, 会主动反向调整, 以保证内容区域完全展示. 如为null: 则不做边界矫正.
    /// 1. 当绘制方向DrawDirection.ltr, 检测超出drawableSize右边界, 会主动向左调整offset xAxis偏移量, 且不超过左边界, 以保证内容区域完全展示.
    /// 2. 当绘制方向DrawDirection.rtl, 检测超出drawableSize左边界, 会主动向右调整offset xAxis偏移量, 且不超过右边界, 以保证内容区域完全展示.
    /// 3. 当绘制高度超出drawableSize规定高度时, 会主动向上调整offset yAxis轴偏移量, 且不超过上边界, 以保证内容区域完全展示.
    Rect? drawableRect,

    /// 图文间距
    double spacing = 0,

    /// 图文内容的背景区域设置
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BorderSide? borderSide,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    if (text?.isNotEmpty != true && textSpan == null) {
      return drawImageView(
        offset: offset,
        image: image,
        imgSize: imgSize,
        srcRect: srcRect,
        isClip: isClip,
        imagePaint: imagePaint,
        drawDirection: drawDirection,
        drawableRect: drawableRect,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        padding: padding,
        borderSide: borderSide,
      );
    }

    // 最终在[canvas]中所绘制区域的坐标与大小
    Rect? result;

    final originImgSize = Size(image.width.toDouble(), image.height.toDouble());
    final isDrawImage = !(originImgSize.isEmpty || imgSize.isEmpty);
    Size containerSize = isDrawImage ? imgSize : Size.zero;

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
    final textSize = textPainter.size;

    spacing = spacing > 0 ? spacing : 0;
    containerSize = Size(
      containerSize.width + spacing + textSize.width,
      math.max(containerSize.height, textSize.height),
    );

    final hasPadding = padding.collapsedSize.nonzero;
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
    }

    result = offset & containerSize;
    if (hasPadding) offset += Offset(padding.left, padding.top);
    isClip = isClip && borderRadius != null && borderRadius.isValid;

    if (isClip) {
      save();
      clipRRect(RRect.fromRectAndCorners(
        result,
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
        bottomRight: borderRadius.bottomRight,
        bottomLeft: borderRadius.bottomLeft,
      ));
    }

    final imageSrc = srcRect ?? (Offset.zero & originImgSize);
    imagePaint ??= Paint()..isAntiAlias = true;
    final txtDy = yAxisAlign.distributeOffset(
      result.top + padding.top,
      result.bottom - padding.bottom,
      textSize.height,
    );
    final imgDy = yAxisAlign.distributeOffset(
      result.top + padding.top,
      result.bottom - padding.bottom,
      imgSize.height,
    );

    if (drawImageFirst) {
      final dst = Offset(offset.dx, imgDy) & imgSize;
      drawImageRect(image, imageSrc, dst, imagePaint);
      final textOffset = Offset(offset.dx + dst.width + spacing, txtDy);
      textPainter.paint(this, textOffset);
    } else {
      textPainter.paint(this, Offset(offset.dx, txtDy));
      final imgOffset = Offset(offset.dx + textSize.width + spacing, imgDy);
      final dst = imgOffset & imgSize;
      drawImageRect(image, imageSrc, dst, imagePaint);
    }

    if (isClip) {
      restore();
    }

    return result;
  }
}
