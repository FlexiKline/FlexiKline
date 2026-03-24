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

import 'types.dart';

extension FlexiDrawImage on Canvas {
  /// 绘制图片区域.
  /// 返回[image]在canvas中的实际绘制区域.
  Rect drawImageView({
    /// 绘制启始坐标位置
    required Offset offset,

    /// 绘制图片配置
    required ui.Image image,
    required Size imgSize,
    // 针对[image]的裁剪区域
    Rect? srcRect,
    // 是否裁切: 仅在[borderRadius]有效时, 按[borderRadius]裁切.
    bool isClip = true,
    Paint? imagePaint,

    /// X轴上的绘制方向: 以offset为原点, 向左向右绘制.
    DrawDirection drawDirection = DrawDirection.ltr,

    /// 可绘制区域大小
    /// 主要用于边界矫正, 当绘制超出边界区域时, 会主动反向调整, 以保证内容区域完全展示. 如为null: 则不做边界矫正.
    /// 1. 当绘制方向DrawDirection.ltr, 检测超出drawableSize右边界, 会主动向左调整offset xAxis偏移量, 且不超过左边界, 以保证内容区域完全展示.
    /// 2. 当绘制方向DrawDirection.rtl, 检测超出drawableSize左边界, 会主动向右调整offset xAxis偏移量, 且不超过右边界, 以保证内容区域完全展示.
    /// 3. 当绘制高度超出drawableSize规定高度时, 会主动向上调整offset yAxis轴偏移量, 且不超过上边界, 以保证内容区域完全展示.
    Rect? drawableRect,

    /// [image]的背景区域设置
    Color? backgroundColor,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    BorderSide? borderSide,
  }) {
    final originImgSize = Size(image.width.toDouble(), image.height.toDouble());
    if (originImgSize.isEmpty || imgSize.isEmpty) {
      return offset & Size.zero;
    }

    // 最终在[canvas]中所绘制区域的坐标与大小
    Rect? result;

    Size viewSize = imgSize;
    final hasPadding = padding != null && padding.collapsedSize.nonzero;
    if (hasPadding) {
      viewSize += Offset(
        padding.horizontal,
        padding.vertical,
      );
    }

    // 矫正边界.
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
            math.min(offset.dx, drawableRect.right - viewSize.width),
          );
          break;
        case DrawDirection.center:
          dx = math.max(
            drawableRect.left,
            math.min(offset.dx, drawableRect.right - viewSize.width / 2),
          );
          break;
        case DrawDirection.rtl:
          dx = math.max(
            drawableRect.left,
            math.min(
              drawableRect.right - viewSize.width,
              offset.dx - viewSize.width,
            ),
          );
          break;
      }
      offset = Offset(dx, dy);
    } else {
      if (drawDirection.isrtl) {
        offset = Offset(
          offset.dx - viewSize.width,
          offset.dy,
        );
      } else if (drawDirection.isCenter) {
        offset = Offset(
          offset.dx - viewSize.width / 2,
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
          offset.dx + viewSize.width,
          offset.dy + viewSize.height,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        ));
      } else {
        path.addRRect(RRect.fromLTRBR(
          offset.dx,
          offset.dy,
          offset.dx + viewSize.width,
          offset.dy + viewSize.height,
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

      result = offset & viewSize;
      if (hasPadding) offset += Offset(padding.left, padding.top);
    }

    final src = srcRect ?? (Offset.zero & originImgSize);
    final dst = offset & imgSize;
    imagePaint ??= Paint()..isAntiAlias = true;
    result ??= dst;

    if (isClip && borderRadius != null && borderRadius.isValid) {
      save();
      clipRRect(RRect.fromRectAndCorners(
        result,
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
        bottomRight: borderRadius.bottomRight,
        bottomLeft: borderRadius.bottomLeft,
      ));
      drawImageRect(image, src, dst, imagePaint);
      restore();
    } else {
      drawImageRect(image, src, dst, imagePaint);
    }

    return result;
  }
}
