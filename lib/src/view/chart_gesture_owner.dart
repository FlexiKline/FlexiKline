// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/painting.dart';

import '../extension/geometry_ext.dart';
import '../kline_controller.dart';

/// 一次触摸序列在落点阶段确定的业务归属。
enum ChartGestureOwner {
  zoomSlider,
  zoomingMove,
  drawDrawing,
  drawEditing,
  cross,
  paintObject;

  /// 该归属是否要求长按让开竞技场。
  ///
  /// 这两种归属在 `onLongPressStart` 里本就是空操作：crossing 中长按被整体忽略，未
  /// 完成的绘制不允许长按移动。驱动收敛到 `onScaleUpdate` 之后，长按赢下竞技场就等于
  /// 把整个序列变成零响应 —— Scale 被 reject，而长按自己什么也不做。
  ///
  /// 其余四种各有自己的长按路径（draw editing 长按即进入移动态；zoom slider 在落点就
  /// 已抢占；缩放态平移与 PaintObject 落到 grid resize / cross），不在此列。
  bool get suppressesLongPress => switch (this) {
        cross || drawDrawing => true,
        zoomSlider || zoomingMove || drawEditing || paintObject => false,
      };
}

/// 使用第一指按下位置判定落点归属，不认领目标或改变业务状态。
ChartGestureOwner? resolveLandedGestureOwner(
  FlexiKlineController controller,
  Offset position,
) {
  final immediateOwner = resolveImmediateGestureOwner(controller, position);
  if (immediateOwner != null) return immediateOwner;
  if (controller.isChartZooming && controller.mainRect.include(position)) {
    return ChartGestureOwner.zoomingMove;
  }
  if (controller.isDrawVisible && controller.drawState.isDrawing && controller.drawState.pointerOffset != null) {
    return ChartGestureOwner.drawDrawing;
  }
  if (controller.hitTestDrawObjectDrag(position)) {
    return ChartGestureOwner.drawEditing;
  }
  if (controller.isCrossing) {
    return ChartGestureOwner.cross;
  }
  if (controller.hitTestPaintObjectDrag(position)) {
    return ChartGestureOwner.paintObject;
  }
  return null;
}

/// 解析必须在 PointerDown 事件分发结束前抢占的专属控件归属。
ChartGestureOwner? resolveImmediateGestureOwner(
  FlexiKlineController controller,
  Offset position,
) {
  if (controller.gestureConfig.enableZoom && controller.chartZoomSlideBarRect.include(position)) {
    return ChartGestureOwner.zoomSlider;
  }
  return null;
}

/// 解析落点归属的位移锚点：驱动坐标恒为 `锚点 + 第一指总位移`。
///
/// 不用逐帧累加增量：`onScaleUpdate` 挂了 `throttleOnFps`，节流窗口内的中间调用会被
/// 直接丢弃，累加写法会随之丢掉位移。锚点固定、位移取第一指的按下点到最新点，丢帧
/// 只降低采样密度，不改变落点。
///
/// 返回 null 表示锚点已失效（目标在 PointerDown 与 onScaleStart 之间消失），调用方应
/// 降级为图表兜底而非废掉整个手势。
Offset? resolveGestureOwnerAnchor(
  FlexiKlineController controller,
  ChartGestureOwner owner,
  Offset downPosition,
) {
  switch (owner) {
    case ChartGestureOwner.drawDrawing:
      // 锚点是绘制点而不是手指: 两者本就允许有偏移(命中容差、磁吸校正)，
      // 拖动要平移的是绘制点。
      final pointerOffset = controller.drawState.pointerOffset;
      if (pointerOffset == null || !pointerOffset.isFinite) return null;
      return pointerOffset;
    case ChartGestureOwner.cross:
      // 读 crossOffset 而非上一次 onTapUp 留下的手势数据: 它是 cross 的权威状态,
      // 于是 tap 与长按两种进入方式共用同一个锚点来源。
      return controller.crossOffset;
    case ChartGestureOwner.zoomSlider:
    case ChartGestureOwner.zoomingMove:
    case ChartGestureOwner.drawEditing:
    case ChartGestureOwner.paintObject:
      return downPosition;
  }
}
