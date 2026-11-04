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

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'icon_shape.dart';

/// 把 [shape] 栅格化为图片, 供只接受 [ImageProvider] 的 API 使用(如 `Image`、`DecorationImage`)。
///
/// 按 [ImageConfiguration.devicePixelRatio] 栅格化; 缓存 key 为形状、尺寸、颜色与像素密度, 位图由 [ImageCache] 管理。
/// 在 Widget 中显示图标优先用 `ShapeIcon`: 矢量绘制, 不占图片缓存。
final class ShapeImageProvider extends ImageProvider<(IconShape, Size, Color, double)> {
  const ShapeImageProvider(this.shape, this.size, this.color);

  final IconShape shape;

  /// 逻辑尺寸; 位图像素尺寸为它乘以像素密度。
  final Size size;

  final Color color;

  @override
  Future<(IconShape, Size, Color, double)> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture((shape, size, color, configuration.devicePixelRatio ?? 1));

  @override
  ImageStreamCompleter loadImage((IconShape, Size, Color, double) key, ImageDecoderCallback decode) {
    final (shape, size, color, ratio) = key;
    final recorder = ui.PictureRecorder();
    shape.paint(Canvas(recorder)..scale(ratio), size, color);
    final picture = recorder.endRecording();
    try {
      final image = picture.toImageSync((size.width * ratio).ceil(), (size.height * ratio).ceil());
      return OneFrameImageStreamCompleter(SynchronousFuture(ImageInfo(image: image, scale: ratio)));
    } finally {
      picture.dispose();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ShapeImageProvider && other.shape == shape && other.size == size && other.color == color;

  @override
  int get hashCode => Object.hash(shape, size, color);
}
