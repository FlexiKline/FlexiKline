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

import '../foundation/paint_resource.dart';
import '../painters/raw_image_span.dart';
import 'icon_shape.dart';

/// [shape] 栅格化后的位图缓存, 用作画布标签里的行内 [RawImageSpan]。
///
/// 只缓存当前颜色的一张位图, 换色时释放旧图; 需要多种颜色同时显示时各建一个实例。
final class ShapeImage implements PaintResource {
  ShapeImage(this.shape, this.size, {this.rasterScale = 4}) : assert(!size.isEmpty), assert(rasterScale > 0);

  final IconShape shape;

  /// 逻辑尺寸, 即 [span] 占位框的大小。
  final Size size;

  /// 位图相对 [size] 的倍率; 默认 4, 覆盖到 4x 屏仍清晰。
  final double rasterScale;

  Color? _color;
  ui.Image? _image;

  /// [color] 下的位图; 颜色不变时返回同一实例。
  ui.Image of(Color color) {
    final cached = _image;
    if (cached != null && _color == color) return cached;
    cached?.dispose();

    final recorder = ui.PictureRecorder();
    shape.paint(Canvas(recorder)..scale(rasterScale), size, color);
    final picture = recorder.endRecording();
    try {
      _image = picture.toImageSync((size.width * rasterScale).ceil(), (size.height * rasterScale).ceil());
    } finally {
      picture.dispose();
    }
    _color = color;
    return _image!;
  }

  /// 以 [size] 占位的行内图片。
  RawImageSpan span(Color color, {ui.PlaceholderAlignment alignment = ui.PlaceholderAlignment.middle}) =>
      RawImageSpan(of(color), size, alignment: alignment);

  @override
  void reset() {
    _image?.dispose();
    _image = null;
    _color = null;
  }

  @override
  void dispose() => reset();
}
