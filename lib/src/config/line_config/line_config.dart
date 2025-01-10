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

import '../../extension/render/common.dart';
import '../../framework/serializers.dart';
import '../paint_config/paint_config.dart';

part 'line_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class LineConfig {
  const LineConfig({
    this.type = LineType.solid,
    this.length,
    this.dashes = const [3, 3],
    this.paint = const PaintConfig(strokeWidth: 0.5),
  });

  /// 线类型
  final LineType type;

  /// 线长
  final double? length;

  /// 虚线dashes
  final List<double> dashes;

  /// 画笔
  final PaintConfig paint;

  LineConfig of({Color? paintColor}) {
    if (paintColor == null || paintColor == paint.color) return this;
    return copyWith(paint: paint.of(color: paintColor));
  }

  Paint get linePaint => paint.paint;

  factory LineConfig.fromJson(Map<String, dynamic> json) =>
      _$LineConfigFromJson(json);

  Map<String, dynamic> toJson() => _$LineConfigToJson(this);
}
