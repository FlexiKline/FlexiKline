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

import 'package:flutter/material.dart';

import '../../constant.dart';
import '../../framework/serializers.dart';

part 'tooltip_config.g.dart';

@FlexiConfigSerializable
class TooltipConfig {
  TooltipConfig({
    this.show = true,

    /// tooltip 区域设置
    this.background = const Color(0xFFD6D6D6),
    this.margin = const EdgeInsets.only(
      left: 15,
      right: 65,
      top: 4,
    ),
    this.padding = const EdgeInsets.symmetric(
      horizontal: 4,
      vertical: 4,
    ),
    this.radius = const BorderRadius.all(Radius.circular(4)),

    /// tooltip 文本设置
    this.style = const TextStyle(
      fontSize: defaulTextSize,
      color: Colors.black,
      overflow: TextOverflow.ellipsis,
      height: defaultMultiTextHeight,
    ),
  });

  final bool show;

  /// tooltip 区域设置
  final Color background;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final BorderRadius radius;

  /// tooltip 文本设置
  final TextStyle style;

  factory TooltipConfig.fromJson(Map<String, dynamic> json) =>
      _$TooltipConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TooltipConfigToJson(this);
}
