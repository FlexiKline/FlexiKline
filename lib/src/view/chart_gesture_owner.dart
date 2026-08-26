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

  /// 该归属的移动是否由 `Listener.onPointerMove` 直接驱动。
  ///
  /// 为真时 Scale 回调只负责抢占竞技场，不参与驱动，`onScaleStart` / `onScaleUpdate`
  /// 必须整体让开；为假（draw editing / PaintObject）时才走 Scale 的三段回调。
  bool get isPointerMoveDriven => switch (this) {
        zoomSlider || zoomingMove || drawDrawing || cross => true,
        drawEditing || paintObject => false,
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
