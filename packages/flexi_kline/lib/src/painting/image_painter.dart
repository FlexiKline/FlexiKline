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

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'decoration_painter.dart';
import 'image_style.dart';
import 'paint_resource.dart';

/// 带背景与边框的图片绘制器。
///
/// 不持有 image: ui.Image 的加载与释放归调用方, 且须在绘制完成后才释放。跨帧只持有装饰的 BoxPainter。
final class ImagePainter implements PaintResource {
  final DecorationPainter _decoration = DecorationPainter();

  /// 画图片, 返回容器矩形(含 padding, 不含 AnchoredBorder 的外延); 摆放与夹取同 LabelPainter.paint。
  ///
  /// 图片经 [paintImage] 画进 `style.padding.deflateRect(body)`, 按 [ImageStyle.fit] 适配、居中;
  /// [image] 宽或高为 0、或 [ImageStyle.size] 为空时只画装饰。
  ///
  /// 裁切: [ImageStyle.clip] 为 false 或没有 decoration 时不裁切; 圆角矩形在 padding 盖住圆角与
  /// 边框内收时跳过, 否则 clipRRect; 其他形状按内轮廓 clipPath(AnchoredBorder 用对准后的形状)。
  Rect paint(
    Canvas canvas,
    ui.Image image, {
    required ImageStyle style,
    required Offset anchor,
    Alignment align = Alignment.topLeft,
    Rect? bounds,
  }) {
    final decoration = style.decoration;
    final body = placeBody(style.padding.inflateSize(style.size), outsetsOf(decoration?.shape), anchor, align, bounds);
    final shape = _decoration.paint(canvas, decoration, body, anchor);
    if (style.size.isEmpty || image.width == 0 || image.height == 0) return body;

    final dst = style.padding.deflateRect(body);
    if (!style.clip || shape == null || !_needsClip(shape, style.padding)) {
      _paintImage(canvas, image, dst, style);
    } else {
      canvas.save();
      // finally 保证裁切或绘制抛异常时 save 栈仍平衡, 不把裁切泄漏给后续绘制。
      try {
        if (shape is RoundedRectangleBorder) {
          // 与 RoundedRectangleBorder.getInnerPath 同一个 RRect, 走 clipRRect 快路径。
          canvas.clipRRect(shape.borderRadius.resolve(TextDirection.ltr).toRRect(body).deflate(shape.side.strokeInset));
        } else {
          canvas.clipPath(shape.getInnerPath(body, textDirection: TextDirection.ltr));
        }
        _paintImage(canvas, image, dst, style);
      } finally {
        canvas.restore();
      }
    }
    return body;
  }

  void _paintImage(Canvas canvas, ui.Image image, Rect rect, ImageStyle style) => paintImage(
    canvas: canvas,
    rect: rect,
    image: image,
    fit: style.fit,
    colorFilter: style.colorFilter,
    opacity: style.opacity,
    filterQuality: style.filterQuality,
    isAntiAlias: true,
  );

  @override
  void reset() => _decoration.reset();

  @override
  void dispose() => _decoration.dispose();
}

/// 图片区是否可能越出 [shape] 的内轮廓; 非圆角矩形一律裁切。
///
/// 圆角矩形的内轮廓是 body 内缩 strokeInset(inside 整线宽、center 半线宽、outside 与无边框为 0)。
/// 每个角都满足「半径 + strokeInset ≤ 该角两个方向的 padding」时图片必然落在其内。
/// 判定用名义半径, 刻意保守: 多裁只多一次 save/clip。
bool _needsClip(ShapeBorder shape, EdgeInsets padding) {
  if (shape is! RoundedRectangleBorder) return true;
  final inset = shape.side.strokeInset;
  final r = shape.borderRadius.resolve(TextDirection.ltr);
  bool covered(Radius radius, double horizontal, double vertical) =>
      radius.x + inset <= horizontal && radius.y + inset <= vertical;
  return !(covered(r.topLeft, padding.left, padding.top) &&
      covered(r.topRight, padding.right, padding.top) &&
      covered(r.bottomRight, padding.right, padding.bottom) &&
      covered(r.bottomLeft, padding.left, padding.bottom));
}
