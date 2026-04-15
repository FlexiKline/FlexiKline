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

import '../../constant.dart';
import '../../extension/style_ext.dart';
import '../../framework/serializers.dart';

part 'point_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class PointConfig {
  const PointConfig({
    this.radius = 2,
    this.width = 2,
    this.color,
    this.borderWidth,
    this.borderColor,
  });

  final double radius;
  final double width;
  final Color? color;

  /// 点的边框配置
  final double? borderWidth;
  final Color? borderColor;

  /// 确保画笔颜色不为空
  PointConfig ensure({Color? themeColor, Color? themeBorderColor}) {
    if ((color.isValid || themeColor.isInvalid) && (borderColor.isValid || themeBorderColor.isInvalid)) {
      return this;
    }
    return copyWith(
      color: color.or(themeColor),
      borderColor: borderColor.or(themeBorderColor),
    );
  }

  /// 获取画笔(考虑颜色)
  Paint getPaint(Color themeColor) => Paint()
    ..color = color.ensure(themeColor)
    ..strokeWidth = width
    ..style = PaintingStyle.fill;

  /// 获取画笔(使用 paint color 或 transparent)
  Paint get paint => Paint()
    ..color = color ?? transparent
    ..strokeWidth = width
    ..style = PaintingStyle.fill;

  Paint? get borderPaint {
    if (borderWidth != null && borderWidth! > 0 && borderColor != null && borderColor!.a != 0) {
      return Paint()
        ..color = borderColor!
        ..strokeWidth = borderWidth!
        ..style = PaintingStyle.stroke;
    }
    return null;
  }

  factory PointConfig.fromJson(Map<String, dynamic> json) => _$PointConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PointConfigToJson(this);
}
