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
import 'package:flexi_kline/src/config/export.dart';

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
    this.isAllowDragIndicatorHeight = true,
    this.dragHitTestMinDistance = 10,
    this.dragLine,
    // 全局默认的刻度值配置.
    required this.ticksText,
  });

  final bool show;
  final GridAxis horizontal;
  final GridAxis vertical;

  /// 是否允许通过拖拽Grid线移动指标图表
  final bool isAllowDragIndicatorHeight;

  /// 移动指标图表时, 命中测试的最小距离偏差
  final double dragHitTestMinDistance;

  /// 移动指标图表高度时的拖拽线配置
  final LineConfig? dragLine;

  /// 全局默认的刻度值文本配置.
  final TextAreaConfig ticksText;

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
    this.line = const LineConfig(
      type: LineType.solid,
      dashes: [2, 2],
      paint: PaintConfig(strokeWidth: 0.5),
    ),
  });

  final bool show;
  final int count;
  final LineConfig line;

  factory GridAxis.fromJson(Map<String, dynamic> json) =>
      _$GridAxisFromJson(json);

  Map<String, dynamic> toJson() => _$GridAxisToJson(this);
}
