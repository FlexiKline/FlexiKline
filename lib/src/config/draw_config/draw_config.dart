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
import '../draw_params/draw_params.dart';
import '../magnifier_config/magnifier_config.dart';
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
    this.gapBackground = const Color(0x00000000),
    this.hitTestMinDistance = 20,
    this.magnifierConfig = const MagnifierConfig(),
    this.drawParams = const DrawParams(),
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

  /// 命中测试最小距离.
  /// 当前位置到Overlay线距离如果小于等于[hitTestMinDistance], 即命中.
  final double hitTestMinDistance;

  /// 放大镜配置
  final MagnifierConfig magnifierConfig;

  /// 绘制Overlay的Object时所需要的参数集
  final DrawParams drawParams;

  Paint get gapBgPaint => Paint()
    ..color = gapBackground
    ..style = PaintingStyle.fill
    ..strokeWidth = 6;

  TextAreaConfig get priceLineText {
    return drawParams.priceText ?? tickText;
  }

  TextAreaConfig get angleRadText {
    return drawParams.angleText ?? tickText;
  }

  factory DrawConfig.fromJson(Map<String, dynamic> json) =>
      _$DrawConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DrawConfigToJson(this);
}
