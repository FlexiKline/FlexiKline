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
import '../../extension/render/common.dart';
import '../../framework/serializers.dart';
import '../line_config/line_config.dart';
import '../text_area_config/text_area_config.dart';

part 'cross_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class CrossConfig {
  CrossConfig({
    this.enable = true,
    this.crosshair = const LineConfig(
      type: LineType.dashed,
      color: Colors.black,
      width: 0.5,
      dashes: [3, 3],
    ),
    this.point = const CrossPointConfig(),
    this.tickText = const TextAreaConfig(
      style: TextStyle(
        fontSize: defaulTextSize,
        color: Colors.white,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      ),
      background: Colors.black,
      padding: EdgeInsets.all(2),
      border: BorderSide.none,
      borderRadius: BorderRadius.all(
        Radius.circular(2),
      ),
    ),
    this.spacing = 1,
    this.showLatestTipsInBlank = true,
  });

  final bool enable;
  final LineConfig crosshair;
  final CrossPointConfig point;
  final TextAreaConfig tickText;
  final double spacing;

  /// onCross时, 当移动到空白区域时, Tips区域是否展示最新的蜡烛的Tips数据.
  bool showLatestTipsInBlank = true;

  Paint get crosshairPaint => Paint()
    ..color = crosshair.color
    ..style = PaintingStyle.stroke
    ..strokeWidth = crosshair.width;

  Paint get pointPaint => Paint()
    ..color = point.color
    ..strokeWidth = point.width
    ..style = PaintingStyle.fill;

  factory CrossConfig.fromJson(Map<String, dynamic> json) =>
      _$CrossConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CrossConfigToJson(this);
}

@CopyWith()
@FlexiConfigSerializable
class CrossPointConfig {
  const CrossPointConfig({
    this.radius = 2,
    this.width = 6,
    this.color = Colors.black,
  });

  final double radius;
  final double width;
  final Color color;

  factory CrossPointConfig.fromJson(Map<String, dynamic> json) =>
      _$CrossPointConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CrossPointConfigToJson(this);
}
