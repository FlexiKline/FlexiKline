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
import '../paint_config/paint_config.dart';
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
    required this.drawLine,
    this.useDrawLineColor = true,
    required this.drawPoint,
    required this.tickText,
    required this.spacing,
    this.ticksGapBgOpacity = 0.1,
    this.hitTestMinDistance = 20,
    this.magnifierConfig = const MagnifierConfig(),
    this.drawParams = const DrawParams(),
  });

  /// 是否启用Draw Overlay功能开关
  final bool enable;

  /// 绘制十字线交叉点配置, 优先使用[getCrosspointConfig]
  final PointConfig crosspoint;

  /// 十字线配置, 优先使用[getCrosshairConfig]
  final LineConfig crosshair;

  /// 默认绘制线的样式配置
  final LineConfig drawLine;

  /// 绘制[drawPoint]和[tickText]刻度时, 是否始终使用[drawLine]指定的颜色.
  final bool useDrawLineColor;

  /// 选择绘制点配置, 优先使用[getDrawPointConfig]
  final PointConfig drawPoint;

  /// 刻度文案配置, 优先使用[getTickTextConfig]
  final TextAreaConfig tickText;

  /// onCross时, 刻度[tickText]与绘制边界的间距.
  final double spacing;

  /// 两个刻度之间的背景色不透明度
  final double ticksGapBgOpacity;

  /// 命中测试最小距离.
  /// 当前位置到Overlay线距离如果小于等于[hitTestMinDistance], 即命中.
  final double hitTestMinDistance;

  /// 放大镜配置
  final MagnifierConfig magnifierConfig;

  /// 绘制Overlay的Object时所需要的参数集
  final DrawParams drawParams;

  TextAreaConfig get priceLineText {
    return drawParams.priceText ?? tickText;
  }

  TextAreaConfig get angleRadText {
    return drawParams.angleText ?? tickText;
  }

  PointConfig getCrosspointConfig(Color? color) {
    if (useDrawLineColor && color != null) {
      return crosspoint.copyWith(
        color: color,
        borderColor: color.withOpacity(crosspoint.borderColor?.opacity ?? 0),
      );
    }
    return crosspoint;
  }

  LineConfig getCrosshairConfig(Color? color) {
    if (useDrawLineColor && color != null) {
      return crosshair.copyWith(
        paint: crosshair.paint.copyWith(color: color),
      );
    }
    return crosshair;
  }

  Paint? getTicksGapBgPaint(Color? color) {
    if (useDrawLineColor && color != null) {
      return Paint()
        ..color = color.withOpacity(ticksGapBgOpacity)
        ..style = PaintingStyle.fill;
    } else if (tickText.background != null && tickText.background!.alpha != 0) {
      return Paint()
        ..color = tickText.background!.withOpacity(ticksGapBgOpacity)
        ..style = PaintingStyle.fill;
    }
    return null;
  }

  TextAreaConfig getTickTextConfig(Color? color) {
    if (useDrawLineColor && color != null) {
      return tickText.copyWith(background: color);
    }
    return tickText;
  }

  PointConfig getDrawPointConfig(Color? color) {
    if (useDrawLineColor && color != null) {
      return drawPoint.copyWith(borderColor: color);
    }
    return drawPoint;
  }

  factory DrawConfig.fromJson(Map<String, dynamic> json) =>
      _$DrawConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DrawConfigToJson(this);
}
