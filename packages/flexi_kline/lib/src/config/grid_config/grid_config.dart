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
import '../text_area_config/text_area_config.dart';

part 'grid_config.g.dart';

/// GridConfig 配置说明:
///
/// grid 层只负责**边框、pane 分隔线与拖拽**。网格线本身归各指标 —— 主区横线是价格刻度线、
/// 竖线是几何参考线, 都由 `CandleBaseIndicator.horizontalGrid` / `verticalGrid` 配置。
/// [horizontal] 与 [vertical] 因此只剩边框语义, 类型是 [GridBorder]。显隐由这两者各自的
/// `show` 表达, 没有总开关 —— 那与「两个方向都关」完全等价, 且它管不到拖拽热区。
///
/// 如果指定[dragLine]时:
/// 1. 当拖拽中时, 使用[dragLine]绘制预拖拽的指标图的底部边线.
/// 2. 当未拖拽时, 使用[dragLine]绘制其length指定长度的线. 其中线类型为实线, 颜色不透明度为[draggingBgOpacity], 且位于指标图底部线居中位置.
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
    this.horizontal = const GridBorder(),
    this.vertical = const GridBorder(),
    this.isAllowDragIndicatorHeight = false,
    this.dragHitTestMinDistance = 10,
    this.draggingBgOpacity = 0.1,
    this.dragBgOpacity = 0,
    this.dragLine = const LineConfig(
      type: LineType.dashed,
      dashes: [3, 5],
      length: 20,
      paint: PaintConfig(
        strokeWidth: 2,
      ),
    ),
    this.dragLineOpacity = 0.1,
    // 全局默认的刻度值配置.
    this.ticksText = const TextAreaConfig(
      style: TextStyle(
        fontSize: defaultTextSize,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      ),
      textAlign: TextAlign.end,
      padding: EdgeInsets.symmetric(horizontal: 2),
    ),
  });

  /// 主区顶边框与各 pane 底部分隔线。
  ///
  /// 分隔线也算相邻两个 pane 的边框, 因此与顶边框共用同一配置。
  final GridBorder horizontal;

  /// 左右边框, 贯穿主区到副区底。
  final GridBorder vertical;

  /// 是否允许通过拖拽Grid线移动指标图表
  final bool isAllowDragIndicatorHeight;

  /// 移动指标图表时, 命中测试的最小距离偏差
  final double dragHitTestMinDistance;

  /// 移动指标图表高度时的拖拽线配置, 颜色会用[theme.dragBg]替换
  final LineConfig? dragLine;

  /// 拖拽时, 被选中的区域顶部与底部线条的颜色不透明度
  final double dragLineOpacity;

  /// 拖拽中区域背景颜色[theme.dragBg]不透明度
  final double draggingBgOpacity;

  /// 拖拽区域默认背景颜色[theme.dragBg]不透明度
  final double dragBgOpacity;

  /// 全局默认的刻度值文本配置.
  final TextAreaConfig ticksText;

  factory GridConfig.fromJson(Map<String, dynamic> json) => _$GridConfigFromJson(json);

  Map<String, dynamic> toJson() => _$GridConfigToJson(this);
}

/// 单个方向的 grid 边框配置。
///
/// 由 `GridAxis` 更名而来: grid 层不再拥有任何轴, 只剩边框与 pane 分隔线, 原先的 `count`
/// 与 `tickMode` 随网格线一起下沉到指标(见 `GridAxisConfig`)。**JSON 键未变**, 因此旧的
/// 持久化配置照常还原, 只是多余的 `count` 被忽略。
@CopyWith()
@FlexiConfigSerializable
class GridBorder {
  const GridBorder({
    this.show = true,
    this.line = const LineConfig(
      type: LineType.solid,
      dashes: [2, 2],
      paint: PaintConfig(strokeWidth: defaultAuxiliaryLineWidth),
    ),
  });

  final bool show;

  final LineConfig line;

  factory GridBorder.fromJson(Map<String, dynamic> json) => _$GridBorderFromJson(json);

  Map<String, dynamic> toJson() => _$GridBorderToJson(this);
}
