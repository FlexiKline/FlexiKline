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

part 'paint_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class PaintConfig {
  const PaintConfig({
    required this.color,
    required this.strokeWidth,
    this.style = PaintingStyle.stroke,
    this.blendMode = BlendMode.srcOver,
    this.isAntiAlias = true,
  });

  final Color color;
  final double strokeWidth;
  final PaintingStyle style;
  final BlendMode blendMode;
  final bool isAntiAlias;

  Paint get paint => Paint()
    ..color = color
    ..style = style
    ..blendMode = blendMode
    ..isAntiAlias = isAntiAlias
    ..strokeWidth = strokeWidth;

  factory PaintConfig.fromJson(Map<String, dynamic> json) =>
      _$PaintConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PaintConfigToJson(this);
}
