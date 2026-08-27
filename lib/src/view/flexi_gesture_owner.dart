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

/// 一次触摸序列的业务归属，及其全部判定入口。
///
/// 前六项是**落点归属**：由第一指落点与既有业务状态决定，`PointerDown` 一次判定。
/// 后两项是**兜底归属**：图表整体操作没有落点特征，判据是方向与指间距变化，必须等位移
/// 积累出可信样本才能判。
///
/// **声明顺序即优先级**，按「判据越精确越优先，同精度时有跟手焦点的排他模式优先」排：
/// 排他模式（drawDrawing、cross）→ 命中具体对象（drawEditing、paintObject）→ 区域性辅助
/// 操作（zoomSlider、zoomingMove，判据只有「落点在不在某个 Rect 里」）→ 全局兜底。
enum FlexiGestureOwner {
  drawDrawing,
  drawEditing,
  cross,
  paintObject,
  zoomSlider,
  zoomingMove,
  chartScale,
  chartPan;

  /// 用第一指按下位置判定落点归属，优先级即下面的判定顺序。
  ///
  /// 必须无副作用：每次 `PointerDown` 都会走一遍，包括最终只是点击或长按的手势。判据也
  /// 必须与真正的认领入口同源（`hitTestDrawObjectDrag` ↔ `onDrawMoveStart`，
  /// `hitTestPaintObjectDrag` ↔ `onPaintObjectDragStart`），否则会白抢一次手势。
  ///
  /// zoom 族排在末位而非首位：`chartZoomSlideBarRect` 是价格轴那一整条全高隐形热区，
  /// `isChartZooming` 又是粘性状态且 `zoomingMove` 的领地是整个 `mainRect`——排在前面就会
  /// 截走已进入模式或已命中对象的手势（表现为「十字线已显示，拖动却把整个图表拖走」）。
  ///
  /// [FlexiScaleGestureRecognizer] 的落点即抢占也问这个函数（`== zoomSlider`），不走单独的
  /// 旁路入口：抢占与归属同源，才不会出现「为 zoom 抢下竞技场、却由别人驱动」。
  static FlexiGestureOwner? resolveLanded(FlexiKlineController controller, Offset position) {
    if (controller.isDrawVisible && controller.drawState.isDrawing && controller.drawState.pointerOffset != null) {
      return drawDrawing;
    }
    if (controller.hitTestDrawObjectDrag(position)) return drawEditing;
    if (controller.isCrossing) return cross;
    if (controller.hitTestPaintObjectDrag(position)) return paintObject;
    if (controller.gestureConfig.enableZoom && controller.chartZoomSlideBarRect.include(position)) {
      return zoomSlider;
    }
    if (controller.isChartZooming && controller.mainRect.include(position)) return zoomingMove;
    return null;
  }

  /// 落点无归属时，按第一指累计位移 [delta] 与指间距变化 [spanDelta] 判定图表整体操作。
  ///
  /// 指间距优先于方向：双指横向张开时第一指也是横向位移，反过来会把缩放误判成平移。
  /// 单指 [spanDelta] 恒为 0，方向判定是这套逻辑的退化情形而非特例。
  ///
  /// [hitSlop] 是外层可滚动容器的裁决阈值，两条判据的样本都不足时返回 null 让给外层。
  /// 放弃不等于不响应：`ScaleGestureRecognizer` 仍会在原生 `panSlop` 自我 accept。
  static FlexiGestureOwner? resolveChartFallback(
    FlexiKlineController controller, {
    required Offset delta,
    required double spanDelta,
    required double hitSlop,
  }) {
    final config = controller.gestureConfig;
    // 缩放判据与外层同量纲: 外层看「一指移动了多远」, 这里看「两指相对移动了多远」。
    // [spanDelta] 是各指到质心的平均距离之差, 两指时为指间距变化的一半, 故 × 2 还原
    // (三指以上不严格成立, 当前只有两指捏合是真实场景)。不能拿 `kScaleSlop` 比 [hitSlop]:
    // 两者同为 18 但量纲差一倍, 实际要求 36px 而外层只要 18px, 一指锚定的捏合必输。
    if (config.enableScale && spanDelta.abs() * 2 > hitSlop * config.scaleClaimSlopFactor) {
      return chartScale;
    }
    if (delta.distance <= hitSlop) return null;
    if (delta.dx.abs() > delta.dy.abs() * config.panClaimRatio) return chartPan;
    return null;
  }

  /// 本归属的位移锚点，驱动坐标恒为「锚点 + 第一指总位移」。
  ///
  /// 不逐帧累加增量：`onScaleUpdate` 的节流会丢弃窗口内的中间调用，累加会随之丢位移。
  ///
  /// 返回 null 表示没有落点锚点——目标在 `PointerDown` 与 `onScaleStart` 之间消失，或本身
  /// 就是兜底归属（位置来源是多指质心）——调用方应降级为图表兜底。
  Offset? resolveAnchor(FlexiKlineController controller, Offset downPosition) {
    switch (this) {
      case drawDrawing:
        // 锚点是绘制点而非手指: 两者本就允许有偏移(命中容差、磁吸校正)。
        final pointerOffset = controller.drawState.pointerOffset;
        if (pointerOffset == null || !pointerOffset.isFinite) return null;
        return pointerOffset;
      case drawEditing:
        return downPosition;
      case cross:
        // crossOffset 是 cross 的权威状态, tap 与长按两种进入方式共用同一个锚点来源。
        return controller.crossOffset;
      case paintObject:
      case zoomSlider:
      case zoomingMove:
        return downPosition;
      case chartScale:
      case chartPan:
        return null;
    }
  }

  /// 是否为图表整体操作的兜底归属。
  ///
  /// 兜底族没有落点目标可认领，位置来源又是多指质心，两条都与落点族相反，因此不走落点
  /// 路径（锚点、认领、驱动、收尾）。
  bool get isChartFallback => switch (this) {
        chartScale || chartPan => true,
        drawDrawing || drawEditing || cross || paintObject || zoomSlider || zoomingMove => false,
      };

  /// 是否要求长按让开竞技场。
  ///
  /// 这两项在 `onLongPressStart` 里本就是空操作（crossing 中长按被整体忽略，未完成的绘制
  /// 不允许长按移动），而长按赢下竞技场会把 Scale 一起 reject，于是整段手势零响应。其余
  /// 归属各有自己的长按路径，不能让开。
  bool get suppressesLongPress => switch (this) {
        drawDrawing || cross => true,
        drawEditing || paintObject || zoomSlider || zoomingMove || chartScale || chartPan => false,
      };
}
