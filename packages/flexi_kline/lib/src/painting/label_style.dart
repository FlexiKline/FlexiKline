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

/// 标签的完整外观: 排版参数 + 内边距 + 装饰。不可变, 按值比较。
@immutable
final class LabelStyle {
  const LabelStyle({
    this.text = const TextStyle(),
    this.textAlign = TextAlign.start,
    this.strutStyle,
    this.maxLines,
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    this.padding = EdgeInsets.zero,
    this.decoration,
  });

  final TextStyle text;
  final TextAlign textAlign;
  final StrutStyle? strutStyle;
  final int? maxLines;

  /// 排版宽度区间, 与 TextPainter.layout 同义; 固定宽度写成 minWidth == maxWidth。
  ///
  /// 不设单独的 width 字段: 它与 maxWidth 语义重叠, 且旧 textWidth 会绕开 bounds 导致溢出。
  /// 实际排版时与本次调用的约束(如 bounds 推出的可用宽度)取交集, minWidth 夹到上限以内。
  final double minWidth;
  final double maxWidth;

  final EdgeInsets padding;

  /// 背景与形状; null 不画背景。形状为 AnchoredBorder 时外延参与摆放。
  final ShapeDecoration? decoration;

  /// 排版相关字段是否相同; 只有它们变化才需要丢弃排版缓存。
  bool sameLayout(LabelStyle other) =>
      text == other.text &&
      textAlign == other.textAlign &&
      strutStyle == other.strutStyle &&
      maxLines == other.maxLines &&
      minWidth == other.minWidth &&
      maxWidth == other.maxWidth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabelStyle && sameLayout(other) && padding == other.padding && decoration == other.decoration;

  @override
  int get hashCode => Object.hash(text, textAlign, strutStyle, maxLines, minWidth, maxWidth, padding, decoration);

  /// 派生变体。参数为 null 表示沿用原值, 因此不能借此清除 [decoration] / [strutStyle] / [maxLines]。
  LabelStyle copyWith({
    TextStyle? text,
    TextAlign? textAlign,
    StrutStyle? strutStyle,
    int? maxLines,
    double? minWidth,
    double? maxWidth,
    EdgeInsets? padding,
    ShapeDecoration? decoration,
  }) => LabelStyle(
    text: text ?? this.text,
    textAlign: textAlign ?? this.textAlign,
    strutStyle: strutStyle ?? this.strutStyle,
    maxLines: maxLines ?? this.maxLines,
    minWidth: minWidth ?? this.minWidth,
    maxWidth: maxWidth ?? this.maxWidth,
    padding: padding ?? this.padding,
    decoration: decoration ?? this.decoration,
  );
}
