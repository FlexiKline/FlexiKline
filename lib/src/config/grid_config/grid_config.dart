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

part 'grid_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class GridConfig {
  const GridConfig({
    this.show = true,
    this.horizontal = const GridAxis(),
    this.vertical = const GridAxis(),
  });

  final bool show;
  final GridAxis horizontal;
  final GridAxis vertical;

  factory GridConfig.fromJson(Map<String, dynamic> json) =>
      _$GridConfigFromJson(json);

  Map<String, dynamic> toJson() => _$GridConfigToJson(this);
}

@CopyWith()
@FlexiConfigSerializable
class GridAxis {
  const GridAxis({
    this.show = true,
    this.count = 5,
    this.width = 0.5,
    this.color = const Color(0xffE9EDF0),
    this.type = LineType.solid,
    this.dashes = const [2, 2],
  });

  final bool show;
  final int count;
  final double width;
  final Color color;
  final LineType type;
  final List<double> dashes;

  Paint get paint => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;

  factory GridAxis.fromJson(Map<String, dynamic> json) =>
      _$GridAxisFromJson(json);

  Map<String, dynamic> toJson() => _$GridAxisToJson(this);
}
