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

/// 行内图片。排版时占一个 [size] 的框, 由 LabelPainter 在框内补画。
///
/// 与 WidgetSpan 不同, 尺寸由自身给出, 不需要先 `TextPainter.setPlaceholderDimensions`。
final class ImageSpan extends PlaceholderSpan {
  const ImageSpan(this.image, this.size, {super.alignment = ui.PlaceholderAlignment.middle, super.baseline});

  final ui.Image image;
  final Size size;

  @override
  void build(
    ui.ParagraphBuilder builder, {
    TextScaler textScaler = TextScaler.noScaling,
    List<PlaceholderDimensions>? dimensions,
  }) {
    builder.addPlaceholder(size.width, size.height, alignment, baseline: baseline);
  }

  @override
  bool visitChildren(InlineSpanVisitor visitor) => visitor(this);

  @override
  bool visitDirectChildren(InlineSpanVisitor visitor) => true;

  @override
  InlineSpan? getSpanForPositionVisitor(TextPosition position, Accumulator offset) {
    if (position.offset == offset.value) return this;
    offset.increment(1);
    return null;
  }

  @override
  int? codeUnitAtVisitor(int index, Accumulator offset) {
    final localOffset = index - offset.value;
    assert(localOffset >= 0);
    offset.increment(1);
    return localOffset == 0 ? PlaceholderSpan.placeholderCodeUnit : null;
  }

  /// 图片换了实例或尺寸、对齐变化都要重排: 占位框尺寸与位置由它们决定。
  @override
  RenderComparison compareTo(InlineSpan other) {
    if (identical(this, other)) return RenderComparison.identical;
    if (other is! ImageSpan ||
        !identical(image, other.image) ||
        size != other.size ||
        alignment != other.alignment ||
        baseline != other.baseline) {
      return RenderComparison.layout;
    }
    return RenderComparison.identical;
  }

  /// PlaceholderSpan 的默认实现是 `assert(false, ...)`, 而 `TextPainter.text` setter 会递归校验,
  /// 不覆写则一赋值就断言失败; ImageSpan 自带尺寸、不依赖 WidgetSpan 的布局协议, 恒为有效。
  @override
  bool debugAssertIsValid() => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageSpan &&
          identical(image, other.image) &&
          size == other.size &&
          alignment == other.alignment &&
          baseline == other.baseline;

  @override
  int get hashCode => Object.hash(identityHashCode(image), size, alignment, baseline);
}
