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

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/painting.dart';

import '../../constant.dart';
import '../../extension/export.dart';
import '../../framework/serializers.dart';
import '../../painting/label_style.dart';
import '../gradient_config/gradient_config.dart';

part 'text_area_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class TextAreaConfig {
  const TextAreaConfig({
    /// 文本样式
    this.style = const TextStyle(
      fontSize: defaultTextSize,
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
    this.backgroundColor,
    this.padding,
    this.border,
    this.borderRadius,
    this.gradient,
    this.shadows,
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
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final BorderSide? border;
  final BorderRadius? borderRadius;

  /// 背景渐变, 与背景色互斥: 有渐变时背景色(含主题兜底)只作 baseColor; 未给 colors 又无背景色时不生效。
  final GradientConfig? gradient;

  /// 背景阴影; 模糊在 raster 线程逐帧执行, 只建议同屏个位数的标签(如最新价、气泡)使用, 不要挂在刻度上。
  final List<BoxShadow>? shadows;

  double get areaHeight {
    return (style.totalHeight ?? 0) + (padding?.vertical ?? 0);
  }

  double get textHeight => textSize * (style.height ?? defaultTextHeight);

  double get textSize => style.fontSize ?? defaultTextSize;

  /// 确保文本颜色、背景颜色和边框颜色兜底
  TextAreaConfig ensure({
    Color? themeTextColor,
    Color? themeBackgroundColor,
    Color? themeBorderColor,
  }) {
    final ensureTextColor = style.color.or(themeTextColor);
    final ensureBgColor = backgroundColor.or(themeBackgroundColor);
    final ensureBorderColor = border?.color.or(themeBorderColor);
    if (ensureTextColor == style.color && ensureBgColor == backgroundColor && ensureBorderColor == border?.color) {
      return this;
    }
    return copyWith(
      style: style.copyWith(color: ensureTextColor),
      backgroundColor: ensureBgColor,
      border: border?.copyWith(color: ensureBorderColor),
    );
  }

  factory TextAreaConfig.fromJson(Map<String, dynamic> json) => _$TextAreaConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TextAreaConfigToJson(this);
}

extension TextAreaConfigLabel on TextAreaConfig {
  /// 解析为 [LabelStyle], 主题色只在配置未指定时兜底。
  ///
  /// 按配置实例单项记忆(配置变化即新实例): 同一组主题色返回 identical 的结果; Expando 弱持有, 随配置回收。
  LabelStyle toLabelStyle({Color? textColor, Color? backgroundColor, Color? borderColor}) {
    final memo = _labelStyleMemo[this];
    if (memo != null &&
        memo.textColor == textColor &&
        memo.backgroundColor == backgroundColor &&
        memo.borderColor == borderColor) {
      return memo.style;
    }
    final style = _resolveLabelStyle(textColor, backgroundColor, borderColor);
    _labelStyleMemo[this] = (
      textColor: textColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      style: style,
    );
    return style;
  }

  LabelStyle _resolveLabelStyle(Color? textColor, Color? backgroundColor, Color? borderColor) {
    final bg = this.backgroundColor.or(backgroundColor);
    final side = border.ensure(borderColor);
    final gradient = this.gradient;
    // colors 已给定的渐变不依赖背景色。
    final resolvedGradient = gradient == null || (bg == null && gradient.isDynamic)
        ? null
        : gradient.createGradient(baseColor: bg ?? transparent);
    final hasDecoration = bg != null || side != null || borderRadius != null || gradient != null || shadows != null;
    return LabelStyle(
      text: style.ensure(textColor),
      textAlign: textAlign,
      strutStyle: strutStyle,
      maxLines: maxLines,
      minWidth: minWidth ?? 0,
      // 旧 textWidth 只作排版上限, 并入 maxWidth。
      maxWidth: math.min(textWidth ?? double.infinity, maxWidth ?? double.infinity),
      padding: padding ?? EdgeInsets.zero,
      decoration: !hasDecoration
          ? null
          : ShapeDecoration(
              // ShapeDecoration 断言 color 与 gradient 不能同时非空。
              color: gradient == null ? bg : null,
              gradient: resolvedGradient,
              shadows: shadows,
              shape: RoundedRectangleBorder(
                side: side ?? BorderSide.none,
                borderRadius: borderRadius ?? BorderRadius.zero,
              ),
            ),
    );
  }
}

typedef _LabelStyleMemo = ({Color? textColor, Color? backgroundColor, Color? borderColor, LabelStyle style});

final _labelStyleMemo = Expando<_LabelStyleMemo>('TextAreaConfig.toLabelStyle');
