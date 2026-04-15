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
import '../../extension/render/types.dart';
import '../../framework/serializers.dart';
import '../line_config/line_config.dart';
import '../paint_config/paint_config.dart';
import '../point_config/point_config.dart';
import '../text_area_config/text_area_config.dart';
import '../tooltip_config/tooltip_config.dart';

part 'cross_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class CrossConfig {
  const CrossConfig({
    this.enable = true,
    this.crosshair = const LineConfig(
      paint: PaintConfig(
        strokeWidth: 0.5,
      ),
      type: LineType.dashed,
      dashes: [3, 3],
    ),
    this.crosspoint = const PointConfig(
      radius: 2,
      width: 0,
      borderWidth: 3,
    ),
    this.ticksText = const TextAreaConfig(
      style: TextStyle(
        fontSize: defaultTextSize,
        fontWeight: FontWeight.normal,
        height: defaultTipsTextHeight,
      ),
      padding: EdgeInsets.all(2),
      border: BorderSide.none,
      borderRadius: BorderRadius.all(
        Radius.circular(2),
      ),
      textAlign: TextAlign.end,
    ),
    this.spacing = 1,
    this.showLatestTipsInBlank = true,
    this.moveByCandleInBlank = false,
    this.tooltipConfig = const TooltipConfig(
      show: true,
      // tooltip 区域设置
      margin: EdgeInsets.only(
        left: 15,
        right: 65,
        top: 10,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      radius: BorderRadius.all(Radius.circular(6)),
      // tooltip 文本设置
      style: TextStyle(
        fontSize: defaultTextSize,
        overflow: TextOverflow.ellipsis,
        height: defaultMultiTextHeight,
      ),
    ),
  });

  final bool enable;
  final LineConfig crosshair;
  final PointConfig crosspoint;
  final TextAreaConfig ticksText;
  final TooltipConfig tooltipConfig;

  /// onCross时, 刻度[ticksText]与绘制边界的间距.
  final double spacing;

  /// onCross时, 当移动到空白区域时, Tips区域是否展示最新的蜡烛的Tips数据.
  final bool showLatestTipsInBlank;

  /// onCross时, 当移动到空白区域时, 是否继续按蜡烛宽度移动.
  final bool moveByCandleInBlank;

  factory CrossConfig.fromJson(Map<String, dynamic> json) => _$CrossConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CrossConfigToJson(this);
}
