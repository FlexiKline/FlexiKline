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

import 'package:flutter/painting.dart';

import 'alignment.dart';
import 'borders.dart';
import 'paint_resource.dart';

/// [shape] 在 body 之外占的空间; 只有 [AnchoredBorder] 有外延。
EdgeInsets outsetsOf(ShapeBorder? shape) => shape is AnchoredBorder ? shape.outsets : EdgeInsets.zero;

/// 外延参与摆放与 [bounds] 夹取, 摆完再剥掉, 返回 body(尺寸为 [body], 不含外延)。
Rect placeBody(Size body, EdgeInsets outsets, Offset anchor, Alignment align, Rect? bounds) =>
    outsets.deflateRect(align.place(outsets.inflateSize(body), anchor, bounds));

/// 跨帧持有一个 ShapeDecoration 的 BoxPainter; decoration 不等或 AnchoredBorder 相对锚点变化时重建。
///
/// 绘制交给 ShapeDecoration 自己的 BoxPainter: 它按 rect 缓存轮廓、填充、渐变 shader 与阴影,
/// rect 不变时复用; RoundedRectangleBorder 走 drawRRect 快路径。LabelPainter 与 ImagePainter 共用。
final class DecorationPainter implements PaintResource {
  ShapeDecoration? _source;
  BoxPainter? _box;

  /// [_box] 实际使用的形状(AnchoredBorder 时是 anchorTo 之后的)。
  ShapeBorder? _shape;

  /// [_box] 对应的锚点, 相对 body 左上角: 标签整体平移、未被夹取时它不变, BoxPainter 跨帧复用。
  Offset? _anchor;

  /// 画背景与边框, 返回本帧实际使用的形状(AnchoredBorder 时是 anchorTo 之后的), 供调用方裁切。
  ///
  /// [anchor] 是绝对坐标, 只有 AnchoredBorder 用到。[decoration] 为 null 时释放 BoxPainter、不画、返回 null。
  ShapeBorder? paint(Canvas canvas, ShapeDecoration? decoration, Rect body, Offset anchor) {
    if (decoration == null) {
      reset();
      return null;
    }
    if (!identical(decoration, _source)) {
      if (decoration != _source) _disposeBox();
      // 值相等也换成新实例: 调用方之后持续传它时走 identical 快路径, 不必每帧深比较。
      _source = decoration;
    }
    final shape = decoration.shape;
    if (shape is AnchoredBorder) {
      final local = anchor - body.topLeft;
      if (local != _anchor) {
        _disposeBox();
        _anchor = local;
      }
    }
    var box = _box;
    if (box == null) {
      var source = decoration;
      if (shape is AnchoredBorder) {
        final anchored = _shape = shape.anchorTo(_anchor!);
        // ShapeDecoration 没有 copyWith, 按原字段重建。
        source = ShapeDecoration(
          color: decoration.color,
          image: decoration.image,
          gradient: decoration.gradient,
          shadows: decoration.shadows,
          shape: anchored,
        );
      }
      box = _box = source.createBoxPainter(_noop);
    }
    // textDirection 必须给: BorderRadiusDirectional 等方向相关的形状 resolve 时断言非空。
    box.paint(canvas, body.topLeft, ImageConfiguration(size: body.size, textDirection: TextDirection.ltr));
    return _shape ?? shape;
  }

  /// createBoxPainter 对 onChanged 做非空断言, 必须传; 它只在 DecorationImage 异步加载完成时回调,
  /// 持有者没有自行请求重绘的通道, 图片随下一帧画出。
  static void _noop() {}

  void _disposeBox() {
    _box?.dispose();
    _box = null;
    _shape = null;
    _anchor = null;
  }

  @override
  void reset() {
    _disposeBox();
    _source = null;
  }

  @override
  void dispose() => reset();
}
