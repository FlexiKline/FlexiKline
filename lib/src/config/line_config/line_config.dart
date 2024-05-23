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

import '../../extension/render/common.dart';
import '../../framework/serializers.dart';

part 'line_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class LineConfig {
  const LineConfig({
    this.type = LineType.solid,
    this.color = Colors.black,
    this.length,
    this.width = 0.5,
    this.dashes = const [3, 3],
  });

  final LineType type;
  final Color color;
  final double? length;
  final double width;
  final List<double> dashes;

  Paint get linePaint => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;

  factory LineConfig.fromJson(Map<String, dynamic> json) =>
      _$LineConfigFromJson(json);

  Map<String, dynamic> toJson() => _$LineConfigToJson(this);
}
