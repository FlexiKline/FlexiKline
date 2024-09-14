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

import '../../framework/serializers.dart';
import '../point_config/point_config.dart';
import '../line_config/line_config.dart';
import '../text_area_config/text_area_config.dart';

part 'draw_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class DrawConfig {
  DrawConfig({
    this.enable = true,
    required this.crosspoint,
    required this.crosshair,
    required this.drawPoint,
    required this.drawLine,
    required this.tickText,
    required this.spacing,
    this.gapBackground = Colors.transparent,
  });

  /// 是否启用Draw Overlay功能开关
  final bool enable;

  /// 绘制十字线交叉点配置
  final PointConfig crosspoint;

  /// 十字线配置
  final LineConfig crosshair;

  /// 选择绘制点配置
  final PointConfig drawPoint;

  /// 默认绘制线的样式配置
  final LineConfig drawLine;

  /// 刻度文案配置
  final TextAreaConfig tickText;

  /// onCross时, 刻度[tickText]与绘制边界的间距.
  final double spacing;

  /// 两个时间刻度之间的背景色
  final Color gapBackground;

  factory DrawConfig.fromJson(Map<String, dynamic> json) =>
      _$DrawConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DrawConfigToJson(this);
}
