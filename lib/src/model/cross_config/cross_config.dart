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
import '../../extension/render/common.dart';
import '../../framework/serializers.dart';

part 'cross_config.g.dart';

@FlexiConfigSerializable
class CrossConfig {
  CrossConfig({
    this.enable = true,
    this.crosshair = const Crosshair(),
    this.point = const CrossPoint(),
    this.tickText = const CrossTickText(),
  });

  final bool enable;
  final Crosshair crosshair;
  final CrossPoint point;
  final CrossTickText tickText;

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

@FlexiConfigSerializable
class Crosshair {
  const Crosshair({
    this.width = 0.5,
    this.color = Colors.black,
    this.type = LineType.dashed,
    this.dashes = const [3, 3],
  });

  final double width;
  final Color color;
  final LineType type;
  final List<double> dashes;

  factory Crosshair.fromJson(Map<String, dynamic> json) =>
      _$CrosshairFromJson(json);

  Map<String, dynamic> toJson() => _$CrosshairToJson(this);
}

@FlexiConfigSerializable
class CrossPoint {
  const CrossPoint({
    this.radius = 2,
    this.width = 6,
    this.color = Colors.black,
  });

  final double radius;
  final double width;
  final Color color;

  factory CrossPoint.fromJson(Map<String, dynamic> json) =>
      _$CrossPointFromJson(json);

  Map<String, dynamic> toJson() => _$CrossPointToJson(this);
}

@FlexiConfigSerializable
class CrossTickText {
  const CrossTickText({
    this.style = const TextStyle(
      fontSize: defaulTextSize,
      color: Colors.white,
      overflow: TextOverflow.ellipsis,
      height: defaultTextHeight,
    ),
    this.background = Colors.black,
    this.padding = const EdgeInsets.all(2),
    this.border = BorderSide.none,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(2),
    ),
  });

  final TextStyle style;
  final Color background;
  final EdgeInsets padding;
  final BorderSide border;
  final BorderRadius borderRadius;

  factory CrossTickText.fromJson(Map<String, dynamic> json) =>
      _$CrossTickTextFromJson(json);

  Map<String, dynamic> toJson() => _$CrossTickTextToJson(this);
}
