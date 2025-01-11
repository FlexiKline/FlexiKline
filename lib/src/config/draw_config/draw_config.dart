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

import '../../framework/serializers.dart';
import '../magnifier_config/magnifier_config.dart';
import '../point_config/point_config.dart';
import '../line_config/line_config.dart';
import '../text_area_config/text_area_config.dart';

part 'draw_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class DrawConfig {
  const DrawConfig({
    this.enable = true,
    this.allowSelectWhenExit = true,
    required this.crosspoint,
    required this.crosshair,
    required this.drawLine,
    // this.useDrawLineColor = true,
    required this.drawPoint,
    required this.ticksText,
    required this.spacing,
    this.ticksGapBgOpacity = 0.1,
    this.hitTestMinDistance = 10,
    this.magnetMinDistance = 10,
    this.magnifier = const MagnifierConfig(),
  });

  /// 是否启用Draw Overlay功能开关
  final bool enable;

  /// 当绘制状态是退出时, 是否允许选择已绘制的Overlay.
  final bool allowSelectWhenExit;

  /// 指针点配置
  final PointConfig crosspoint;

  /// 指针十字线配置
  final LineConfig crosshair;

  /// 默认绘制线的样式配置
  final LineConfig drawLine;

  // /// 绘制[drawPoint]和[ticksText]刻度时, 是否始终使用[drawLine]指定的颜色.
  // final bool useDrawLineColor;

  /// 选择绘制点配置
  final PointConfig drawPoint;

  /// 刻度文案配置
  final TextAreaConfig ticksText;

  /// onCross时, 刻度[ticksText]与绘制边界的间距.
  final double spacing;

  /// 两个刻度之间的背景色不透明度
  final double ticksGapBgOpacity;

  /// 命中测试最小距离.
  /// 当前位置到Overlay绘制线距离如果小于等于[hitTestMinDistance], 即命中.
  final double hitTestMinDistance;

  /// 磁吸模式(weak)下，最小吸附距离
  final double magnetMinDistance;

  /// 放大镜配置
  final MagnifierConfig magnifier;

  factory DrawConfig.fromJson(Map<String, dynamic> json) =>
      _$DrawConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DrawConfigToJson(this);
}
