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

/// GridConfig 配置说明:
///
/// 如果指定[dragLine]时:
/// 1. 当拖拽中时, 使用[dragLine]绘制预拖拽的指标图的底部边线.
/// 2. 当未拖拽时, 使用[drawLine]绘制其lenght指定长度的线. 其中线类型为实线, 颜色不透明度为[draggingBgOpacity], 且位于指标图底部线居中位置.
///
/// 如果未指定:
/// 1. 默认会根据[dragHitTestMinDistance]计算可拖拽区域, 并使用[theme.dragBg]进行填充.
/// 2. 当拖拽中时, 使用[draggingBgOpacity]不透明度填充.
/// 3. 当未拖拽时, 使用[dragBgOpacity]不透明度填充.
///
@CopyWith()
@FlexiConfigSerializable
class GridConfig {
  const GridConfig({
    this.show = true,
    this.horizontal = const GridAxis(),
    this.vertical = const GridAxis(),
    this.isAllowDragIndicatorHeight = true,
    this.dragHitTestMinDistance = 10,
    this.draggingBgOpacity = 0.1,
    this.dragBgOpacity = 0,
    this.dragLine,
    this.dragLineOpacity = 0.1,
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

  /// 移动指标图表高度时的拖拽线配置, 颜色会用[theme.dragBg]替换
  final LineConfig? dragLine;

  ///
  final double dragLineOpacity;

  /// 拖拽中区域背景颜色[theme.dragBg]不透明度
  final double draggingBgOpacity;

  /// 拖拽区域默认背景颜色[theme.dragBg]不透明度
  final double dragBgOpacity;

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
