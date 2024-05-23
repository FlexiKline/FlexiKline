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

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';

import '../../constant.dart';
import '../../extension/export.dart';
import '../../framework/serializers.dart';

part 'text_area_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class TextAreaConfig {
  const TextAreaConfig({
    /// 文本样式
    this.style = const TextStyle(
      fontSize: defaulTextSize,
      color: Colors.black,
      overflow: TextOverflow.ellipsis,
      height: defaultTextHeight,
    ),
    this.textAlign = TextAlign.start,
    this.strutStyle,
    this.textWidth,
    this.minWidth,
    this.maxWidth,
    this.maxLines,

    /// Area区域设置
    this.background,
    this.padding,
    this.border,
    this.borderRadius,
  });

  /// 文本样式
  final TextStyle style;
  final TextAlign textAlign;
  final StrutStyle? strutStyle;
  final double? textWidth;
  final double? minWidth;
  final double? maxWidth;
  final int? maxLines;

  /// Area区域设置
  final Color? background;
  final EdgeInsets? padding;
  final BorderSide? border;
  final BorderRadius? borderRadius;

  double get areaHeight {
    return (style.totalHeight ?? 0) + (padding?.vertical ?? 0);
  }

  double get textHeight => textSize * (style.height ?? defaultTextHeight);

  double get textSize => style.fontSize ?? defaulTextSize;

  factory TextAreaConfig.fromJson(Map<String, dynamic> json) =>
      _$TextAreaConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TextAreaConfigToJson(this);
}
