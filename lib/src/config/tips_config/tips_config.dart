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
import '../../framework/serializers.dart';

part 'tips_config.g.dart';

@CopyWith()
/// 指标图顶部提示文本配置
@FlexiConfigSerializable
class TipsConfig {
  const TipsConfig({
    this.label = '',
    this.precision,
    this.style = const TextStyle(
      fontSize: defaulTextSize,
      color: Colors.black,
      overflow: TextOverflow.ellipsis,
      height: defaultTipsTextHeight,
    ),
  });

  TipsConfig.style({
    this.label = '',
    this.precision,
    Color color = Colors.black,
    double fontSize = 10,
    TextOverflow overflow = TextOverflow.ellipsis,
    double height = defaultTipsTextHeight,
    String? fontFamily,
    FontWeight? fontWeight,
    TextBaseline? textBaseline,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
  }) : style = TextStyle(
          color: color,
          fontSize: fontSize,
          overflow: overflow,
          height: height,
          fontFamily: fontFamily,
          fontWeight: fontWeight,
          textBaseline: textBaseline,
          decoration: decoration,
          decorationColor: decorationColor,
          decorationStyle: decorationStyle,
        );

  final String label;
  final int? precision;
  final TextStyle style;

  // 如果未指定精度, 使用默认精度4
  int get p => precision ?? defaultPrecision;

  // 获取展示精度; 如果precision未指定, 使用def值.
  int getP(int def) => precision ?? def;

  Color get color => style.color ?? Colors.black;

  double get textHeight => textSize * (style.height ?? defaultTextHeight);

  double get textSize => style.fontSize ?? defaulTextSize;

  factory TipsConfig.fromJson(Map<String, dynamic> json) =>
      _$TipsConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TipsConfigToJson(this);
}
