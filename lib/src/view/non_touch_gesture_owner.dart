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

import 'package:flutter/services.dart';

import '../extension/geometry_ext.dart';
import '../kline_controller.dart';

/// 非触摸端某个位置的业务归属。
///
/// 声明顺序即优先级，判据越精确越优先：
/// 排他模式(drawDrawing) → 命中具体对象(drawEditing, paintObject) →
/// 窄带区域(gridResize) → 宽带区域(zoomSlider) → 全局兜底(chart)
///
/// 与触摸端 [TouchGestureOwner] 不合并: 两端输入能力不同, 枚举必然不同 ——
/// 非触摸端没有 `cross` 归属(hover 时 cross 是默认显示状态, 不参与拖动竞争),
/// 也没有 `chartScale`/`chartPan` 二分(X 缩放来自滚轮与捏合, 不来自拖动),
/// 因此不需要触摸端那套方向锥 + 指间距的兜底消歧。
enum NonTouchGestureOwner {
  drawDrawing,
  drawEditing,
  paintObject,
  gridResize,
  zoomSlider,
  chart;

  /// 判定 [position] 的归属。恒有返回值, [chart] 为兜底。
  ///
  /// 必须无副作用: hover 每帧都会调用。判据必须与真正的认领入口同源
  /// (`hitTestDrawObjectDrag` ↔ `onDrawMoveStart`,
  ///  `hitTestPaintObjectDrag` ↔ `onPaintObjectDragStart`,
  ///  `hitTestGridResize`      ↔ `onGridResizeStart`)。
  ///
  /// 同源允许单向偏差: 归属层可以比认领入口**更严格**(见 [_hitTestGridResize] 的 dx
  /// 约束), 不可以更宽松 —— 更宽松会白抢一次手势(归属说归我、认领入口却拒绝, 于是整段
  /// 手势零响应), 更严格只是少抢, 那是设计意图。
  static NonTouchGestureOwner resolveAt(
    FlexiKlineController controller,
    Offset position,
  ) {
    if (controller.isDrawVisible && controller.drawState.isDrawing && controller.drawState.pointerOffset != null) {
      return drawDrawing;
    }
    if (controller.hitTestDrawObjectDrag(position)) return drawEditing;
    if (controller.hitTestPaintObjectDrag(position)) return paintObject;
    if (_hitTestGridResize(controller, position)) return gridResize;
    if (controller.gestureConfig.enableZoom && controller.chartZoomSlideBarRect.include(position)) {
      return zoomSlider;
    }
    return chart;
  }

  /// 分隔线命中带本身是全宽的([Rect.hitTestBottom] 只比较 dy), 在归属层收窄到内容区:
  /// 价格轴上的纵向拖动语义是缩放价格轴, 不是调面板高度。
  ///
  /// 收窄写在这里而不是 [GridBinding.onGridResizeStart]: 后者两端共用, 改它会连带
  /// 改掉触摸端长按 resize 的命中范围。
  static bool _hitTestGridResize(
    FlexiKlineController controller,
    Offset position,
  ) {
    if (position.dx > controller.mainChartRect.right) return false;
    return controller.hitTestGridResize(position);
  }

  /// hover 时的光标 —— 「如果在这里按下, 会发生什么」的视觉表达。
  MouseCursor get hoverCursor => switch (this) {
        drawDrawing => SystemMouseCursors.precise,
        drawEditing => SystemMouseCursors.click,
        paintObject => SystemMouseCursors.grab,
        gridResize => SystemMouseCursors.resizeRow,
        zoomSlider => SystemMouseCursors.resizeUpDown,
        chart => SystemMouseCursors.precise,
      };

  /// 拖动期间的光标。
  ///
  /// [chart] 需要 controller: 缩放态下纵向拖动是有意义的操作, 用 [move] 提示双向可拖。
  MouseCursor dragCursor(FlexiKlineController controller) => switch (this) {
        drawDrawing => SystemMouseCursors.precise,
        drawEditing || paintObject => SystemMouseCursors.grabbing,
        gridResize => SystemMouseCursors.resizeRow,
        zoomSlider => SystemMouseCursors.move,
        chart => controller.isChartZooming ? SystemMouseCursors.move : SystemMouseCursors.grabbing,
      };

  /// 本归属对滚轮/捏合的意图; null 表示不消费 —— 调用方据此**不注册**
  /// [PointerSignalResolver], 事件因而放行给外层可滚动容器。
  ///
  /// [horizontal] 是「横向位移占优」, 由调用方从事件读出后传入: 方向是事件属性、不是位置
  /// 属性, 归属层不认识 [PointerSignalEvent]。两者在这里合成动作, 「归属 → 动作」因此仍只
  /// 有这一处映射, 放行也仍只有 `null` 这一个信号。
  ///
  /// [SignalIntent.panX] 不受 [GestureConfig.enableScale] 约束: 平移图表是基本操作, 直接
  /// 拖动同样没有开关, 横滑只是多一种触发方式。
  SignalIntent? signalIntent(
    FlexiKlineController controller, {
    required bool horizontal,
  }) {
    final config = controller.gestureConfig;
    if (this == zoomSlider) {
      if (horizontal) return null; // 价格轴上横滑没有图表语义
      return config.enableZoom ? SignalIntent.zoomY : null;
    }
    if (horizontal) return SignalIntent.panX;
    return config.enableScale ? SignalIntent.scaleX : null;
  }
}

/// 滚轮与捏合的意图。[zoomY] 与 [scaleX] 的量是比值, [panX] 的量是像素位移。
enum SignalIntent { zoomY, scaleX, panX }
