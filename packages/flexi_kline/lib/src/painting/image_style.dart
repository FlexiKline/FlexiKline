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

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// 单张图片的完整外观: 显示尺寸 + 内边距 + 装饰 + 图片绘制参数。不可变, 按值比较。
@immutable
final class ImageStyle {
  const ImageStyle({
    required this.size,
    this.fit = BoxFit.fill,
    this.padding = EdgeInsets.zero,
    this.decoration,
    this.clip = true,
    this.colorFilter,
    this.opacity = 1.0,
    this.filterQuality = FilterQuality.medium,
  });

  /// 图片显示尺寸(不含 padding)。
  final Size size;

  /// 图片在 [size] 内的适配方式; 默认 fill, 与旧 drawImageView(src → dst 拉伸)一致。对齐固定居中。
  final BoxFit fit;

  final EdgeInsets padding;

  /// 背景、边框与形状; null 不画背景, 也不裁切。形状为 AnchoredBorder 时外延参与摆放。
  final ShapeDecoration? decoration;

  /// 是否按 decoration.shape 的内轮廓裁切图片; 只在 [decoration] 非空时有效。
  final bool clip;

  final ColorFilter? colorFilter;
  final double opacity;
  final FilterQuality filterQuality;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageStyle &&
          size == other.size &&
          fit == other.fit &&
          padding == other.padding &&
          decoration == other.decoration &&
          clip == other.clip &&
          colorFilter == other.colorFilter &&
          opacity == other.opacity &&
          filterQuality == other.filterQuality;

  @override
  int get hashCode => Object.hash(size, fit, padding, decoration, clip, colorFilter, opacity, filterQuality);

  /// 派生变体。参数为 null 表示沿用原值, 因此不能借此清除 [decoration] / [colorFilter]。
  ImageStyle copyWith({
    Size? size,
    BoxFit? fit,
    EdgeInsets? padding,
    ShapeDecoration? decoration,
    bool? clip,
    ColorFilter? colorFilter,
    double? opacity,
    FilterQuality? filterQuality,
  }) => ImageStyle(
    size: size ?? this.size,
    fit: fit ?? this.fit,
    padding: padding ?? this.padding,
    decoration: decoration ?? this.decoration,
    clip: clip ?? this.clip,
    colorFilter: colorFilter ?? this.colorFilter,
    opacity: opacity ?? this.opacity,
    filterQuality: filterQuality ?? this.filterQuality,
  );
}
