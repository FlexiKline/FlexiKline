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
import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/painting.dart';

import '../../constant.dart';
import '../../extension/style_ext.dart';
import '../../framework/serializers.dart';
import '../gradient_config/gradient_config.dart';

part 'tooltip_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class TooltipConfig {
  const TooltipConfig({
    this.show = true,

    /// tooltip 区域设置
    required this.margin,
    required this.padding,
    this.spacing = 2,
    this.hitTestMargin = 2,

    /// tooltip 文本设置
    required this.style,

    /// 卡片装饰
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.gradient,
    this.borderGradient,
    this.shadows,
  });

  final bool show;

  /// tooltip 区域设置
  final EdgeInsets margin;
  final EdgeInsets padding;

  /// tooltip 两列之间的间距
  final double spacing;

  /// 扩大 Tooltip 行点击命中区域；向四周各扩展 [hitTestMargin] 逻辑像素。
  /// 仅影响点击检测，不影响绘制布局。
  final double hitTestMargin;

  /// tooltip 文本设置
  /// 注: style的颜色由FKTheme.tooltipTextColor替换.
  final TextStyle style;

  /// 卡片背景色, 为 null 时用主题的 tooltipBg。
  final Color? backgroundColor;

  /// 卡片边框; 主题不提供 Tooltip 边框色, 颜色需在此写明。
  final BorderSide? border;
  final BorderRadius? borderRadius;

  /// 背景渐变, 优先于 [backgroundColor]; 动态渐变以背景色为基色。
  final GradientConfig? gradient;

  /// 边框渐变, 只在 [border] 非空时生效, 以边框色为基色。
  final GradientConfig? borderGradient;
  final List<BoxShadow>? shadows;

  /// 确保文本颜色不为空
  TooltipConfig ensure(Color? themeTextColor) {
    if (style.color.isValid || themeTextColor.isInvalid) {
      return this;
    }
    return copyWith(
      style: style.copyWith(
        color: style.color.or(themeTextColor),
      ),
    );
  }

  factory TooltipConfig.fromJson(Map<String, dynamic> json) => _$TooltipConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TooltipConfigToJson(this);
}

extension TooltipConfigDecoration on TooltipConfig {
  /// 卡片的背景与边框, 主题背景色只在 [TooltipConfig.backgroundColor] 未指定时兜底。
  ///
  /// 按配置实例单项记忆: 主题色不变时返回 identical 的结果; Expando 弱持有, 随配置回收。
  ShapeDecoration? toDecoration({Color? backgroundColor}) {
    final memo = _decorationMemo[this];
    if (memo != null && memo.backgroundColor == backgroundColor) return memo.decoration;
    final bg = this.backgroundColor ?? backgroundColor;
    final border = this.border;
    final decoration = roundedShapeDecoration(
      color: bg,
      border: border,
      borderRadius: borderRadius,
      // 动态渐变以背景色为基色, 没有背景色时不画。
      gradient: bg == null && gradient?.isDynamic == true
          ? null
          : gradient?.createGradient(baseColor: bg ?? transparent),
      borderGradient: border == null ? null : borderGradient?.createGradient(baseColor: border.color),
      shadows: shadows,
    );
    _decorationMemo[this] = (backgroundColor: backgroundColor, decoration: decoration);
    return decoration;
  }
}

typedef _DecorationMemo = ({Color? backgroundColor, ShapeDecoration? decoration});

final _decorationMemo = Expando<_DecorationMemo>('TooltipConfig.toDecoration');
