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

import 'decoration_painter.dart';
import 'image_span.dart';
import 'label_style.dart';
import 'paint_resource.dart';
import 'text_layout_cache.dart';

/// 带背景与边框的标签绘制器, 跨帧持有排版结果。
///
/// 对标 RenderParagraph: 持有者每帧照常传 style、key 与 build, 内部 diff;
/// 内容与样式都没变时不格式化、不排版、不分配。
final class LabelPainter implements PaintResource {
  LabelPainter({int capacity = 1}) : _text = TextLayoutCache(capacity: capacity);

  final TextLayoutCache _text;
  final DecorationPainter _decoration = DecorationPainter();
  final Paint _imagePaint = Paint();

  /// 画标签, 返回容器矩形(含 padding, 不含 AnchoredBorder 的外延)。
  ///
  /// [minWidth] 是容器(含 padding)的最小宽度, 用于与相邻标签对齐(如倒计时与最新价同宽);
  /// 与 bounds 推出的可用宽度一样, 属于本次调用的约束, 不进 style、不进 key。
  Rect paint(
    Canvas canvas,
    Object key, {
    Object Function()? build,
    required LabelStyle style,
    required Offset anchor,
    Alignment align = Alignment.topLeft,
    Rect? bounds,
    double minWidth = 0,
  }) {
    _text.configure(style);
    final decoration = style.decoration;
    final outsets = outsetsOf(decoration?.shape);
    final painter = _text.layout(
      key,
      build: build,
      minWidth: math.max(0.0, minWidth - style.padding.horizontal),
      maxWidth: bounds == null
          ? double.infinity
          : math.max(0.0, bounds.width - style.padding.horizontal - outsets.horizontal),
    );

    final body = placeBody(style.padding.inflateSize(painter.size), outsets, anchor, align, bounds);
    // 无条件调用: decoration 变成 null 时由它释放旧 BoxPainter。
    _decoration.paint(canvas, decoration, body, anchor);

    final origin = body.topLeft + style.padding.topLeft;
    painter.paint(canvas, origin);
    _paintImages(canvas, painter, origin);
    return body;
  }

  /// 按先序把 [ImageSpan] 与占位框一一对应补画; ellipsis 截断时框可能少于 span, 取完即停。
  void _paintImages(Canvas canvas, TextPainter painter, Offset origin) {
    final boxes = painter.inlinePlaceholderBoxes;
    if (boxes == null || boxes.isEmpty) return;
    var index = 0;
    painter.text!.visitChildren((span) {
      if (span is! PlaceholderSpan) return true;
      if (index >= boxes.length) return false;
      final box = boxes[index++];
      if (span is ImageSpan) {
        final image = span.image;
        canvas.drawImageRect(
          image,
          Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
          box.toRect().shift(origin),
          _imagePaint,
        );
      }
      return true;
    });
  }

  @override
  void reset() {
    _text.reset();
    _decoration.reset();
  }

  @override
  void dispose() {
    _text.dispose();
    _decoration.dispose();
  }
}
