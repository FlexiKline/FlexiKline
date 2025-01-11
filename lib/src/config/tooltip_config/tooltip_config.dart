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
import 'package:flutter/painting.dart';

import '../../framework/serializers.dart';

part 'tooltip_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class TooltipConfig {
  const TooltipConfig({
    this.show = true,

    /// tooltip 区域设置
    required this.margin,
    required this.padding,
    required this.radius,

    /// tooltip 文本设置
    required this.style,
  });

  final bool show;

  /// tooltip 区域设置
  final EdgeInsets margin;
  final EdgeInsets padding;
  final BorderRadius radius;

  /// tooltip 文本设置
  /// 注: style的颜色由FKTheme.tooltipTextColor替换.
  final TextStyle style;

  // TooltipConfig of({Color? textColor}) {
  //   if (style.color == textColor) {
  //     return this;
  //   }
  //   return copyWith(
  //     style: style.copyWith(color: textColor),
  //   );
  // }

  factory TooltipConfig.fromJson(Map<String, dynamic> json) =>
      _$TooltipConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TooltipConfigToJson(this);
}
