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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../extension/functions_ext.dart';
import '../extension/geometry_ext.dart';
import '../framework/chart/indicator.dart';
import '../framework/draw/overlay.dart';
import '../utils/algorithm_util.dart';
import 'gesture_detector_widget.dart';
import 'non_touch_gesture_owner.dart';

class NonTouchGestureDetector extends GestureDetectorWidget {
  const NonTouchGestureDetector({
    super.key,
    required super.controller,
    super.onDoubleTap,
  });

  @override
  GestureDetectorState<NonTouchGestureDetector> createState() => _NonTouchGestureDetectorState();
}

class _NonTouchGestureDetectorState extends GestureDetectorState<NonTouchGestureDetector> {
  @override
  String get logTag => 'NonTouchGesture';

  // focus node to capture keyboard events
  final FocusNode _keyboardFocusNode = FocusNode();

  /// 通道 S 的 X 轴 scale session: [initPosition] 必须一轮内稳定,
  /// `onChartScaleEnd()` 要做 `_setCandleWidth(sync: true)` 与 loadMore 检查。
  _ScaleSession? _scaleSession;

  /// 通道 P 的触控板 session: 持有捏合 scale 数据和 [pinching] 标志。
  /// 与 [_scaleSession] 独立——通道 S 无 pointer session，通道 P 有 start/end 生命周期，
  /// 混用是旧实现双重消费的来源之一。
  _TrackpadSession? _trackpad;

  /// 指针最新位置，非空即代表指针在图表内（hover 跟随中）。
  Offset? _hoverPosition;

  /// 一次拖动 session: 归属在 onPanStart 判定一次, 全程不变。
  /// 取代原 _panData + _isObjectDragging: 「谁在拖」由 owner 表达。
  _DragSession? _drag;

  final ValueNotifier<MouseCursor> _mouseCursor = ValueNotifier(SystemMouseCursors.precise);

  @override
  void initState() {
    super.initState();
    if (gestureConfig.supportKeyboardShortcuts) {
      // controller 在 widget 树 build 时已经 mounted, 直接注册即可。
      // 同时监听 lifecycle 以应对 hot-reload 等重建场景。
      controller.drawStateListenable.addListener(_updateKeyboardFocus);
      controller.isChartZoomingListenable.addListener(_updateKeyboardFocus);
    }
  }

  /// Draw 或 zoom 激活时请求键盘焦点，两者都退出时释放。
  void _updateKeyboardFocus() {
    final needFocus = switch (drawState) {
          Drawing() || Editing() => true,
          _ => false,
        } ||
        controller.isChartZooming;

    if (needFocus && !_keyboardFocusNode.hasFocus) {
      _keyboardFocusNode.requestFocus();
    } else if (!needFocus && _keyboardFocusNode.hasFocus) {
      _keyboardFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _scaleSession?.dispose();
    _scaleSession = null;
    _trackpad = null;
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (gestureConfig.supportKeyboardShortcuts) {
      return KeyboardListener(
        key: const ValueKey('NonTouchKeyboradListener'),
        focusNode: _keyboardFocusNode,
        autofocus: false, // 后续支持更多组合按键时, 再考虑放开
        onKeyEvent: onKeyEvent,
        child: buildGestureDetectorView(context),
      );
    }
    return buildGestureDetectorView(context);
  }

  Widget buildGestureDetectorView(BuildContext context) {
    return Listener(
      key: const ValueKey('NonTouchListener'),
      behavior: HitTestBehavior.translucent,

      /// 鼠标滚轮与 Web 触控板: 纵向占优缩放, 横向占优平移。见 [onPointerSignal]。
      onPointerSignal: onPointerSignal,

      /// 触控板的平移、缩放和旋转手势
      onPointerPanZoomStart: onPointerPanZoomStart,
      onPointerPanZoomUpdate: onPointerPanZoomUpdate,
      onPointerPanZoomEnd: onPointerPanZoomEnd,

      /// 指针取消: 仅用于回滚 PaintObject 拖动.
      /// [onPanEnd] 在指针被取消时同样会派发(见 monodrag.dart 的 accepted 分支),
      /// 无法从 [DragEndDetails] 区分, 故在此先行回滚, 避免把中断当成提交.
      onPointerCancel: onPointerCancel,

      /// 右键按下: 退出 Y 轴缩放。
      onPointerDown: onPointerDown,
      child: ValueListenableBuilder(
        valueListenable: _mouseCursor,
        builder: (context, cursor, child) => MouseRegion(
          cursor: cursor,
          hitTestBehavior: HitTestBehavior.translucent,

          /// Cross平移
          onEnter: onEnter,
          onHover: onHover,
          onExit: onExit,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,

            /// 按下即作为平移起点: [onPanStart] 收到 PointerDown 位置而非手势识别时刻位置,
            /// PaintObject 才能按用户实际按下的点命中小尺寸把手.
            /// Flutter 随后会补发一次携带识别前位移的 [onPanUpdate], 累积位移不丢.
            dragStartBehavior: DragStartBehavior.down,

            /// 点击
            onTapUp: onTapUp,

            /// 双击
            onDoubleTap: widget.onDoubleTap,

            /// 按下平移
            onPanStart: onPanStart,
            onPanUpdate: onPanUpdate.throttleOnFps,
            onPanEnd: onPanEnd,
          ),
        ),
      ),
    );
  }

  /// 通道 S: 滚轮与 Web 触控板。
  ///
  /// 按 [InteractiveViewer._receivedPointerSignal] 的模式: 每个 signal 事件自成一次
  /// 完整手势, 无定时器、无 session。注册 [PointerSignalResolver] 消歧——不消费就不注册,
  /// 这是放行外层 [Scrollable] 滚动的唯一机制。
  ///
  /// 一个事件只做一件事: 先按方向分出平移与缩放, 再由归属把缩放分给 Y 轴或 X 轴。
  void onPointerSignal(PointerSignalEvent event) {
    final position = event.localPosition;
    if (!controller.canvasRect.include(position)) return;

    // 只认这两种 signal, 且排在归属之前: [NonTouchGestureOwner.resolveAt] 含 hitTest,
    // 为注定不消费的事件跑它是白费。
    final scroll = event is PointerScrollEvent ? event.scrollDelta : null;
    final pinch = event is PointerScaleEvent ? event.scale : null;
    if (scroll == null && pinch == null) return;

    // 方向要在意图之前判: 横滑是平移, 不属于任何缩放意图, 也就没有灵敏度标定可言。
    // 捏合只有比值、没有方向, 恒走纵向路径。
    final horizontal = scroll != null && scroll.dx.abs() >= scroll.dy.abs() * _kPanDominanceRatio;

    final owner = NonTouchGestureOwner.resolveAt(controller, position);
    final intent = owner.signalIntent(controller, horizontal: horizontal);
    if (intent == null) return; // 不注册 = 放行外层 Scrollable

    // [amount] 的口径随意图变: 缩放是比值, 平移是像素。`scroll!` 安全: `panX` 蕴含
    // `horizontal`, 缩放只在 `pinch == null` 时才求值 dy, 两者都蕴含 scroll 非空。
    final double amount;
    switch (intent) {
      case SignalIntent.panX:
        // 1:1 与外层 [Scrollable] 同口径(它也直接用 scrollDelta), 横滑与页面滚动手感一致。
        // 取负: dx > 0 是视口朝新数据走, 对应 paintDxOffset 减小。方向由测试固定。
        amount = -scroll!.dx;
      // 滚动取指数是为了加法性: `exp(a·k) × exp(b·k) == exp((a+b)·k)`, 碎事件与整格事件累乘到
      // 同一总倍数, 两种设备手感自动一致。捏合的 `scale` 本身就是比值, 再过一遍曲线是恒等变换,
      // 白做; 真要调只能加阻尼指数, 而指数取多少得看真机数据。
      case SignalIntent.zoomY:
        amount = pinch ?? math.exp(-scroll!.dy * controller.signalZoomCoeffPerPixel);
      case SignalIntent.scaleX:
        amount = pinch ?? math.exp(-scroll!.dy / gestureConfig.signalScaleFactor);
    }
    // 只可能是 dx 与 dy 同为 0 的空事件——它满足横向占优判据却没有位移。缩放的比值恒为正。
    if (amount == 0) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      stopPositionAnimation();
      switch (intent) {
        case SignalIntent.zoomY:
          controller.onChartZoomStep(amount);
        case SignalIntent.scaleX:
          _applyScaleStep(position, amount);
        case SignalIntent.panX:
          final panned = controller.onChartPanStep(amount);
          // 指针没动、底下的蜡烛换了, 同一个屏幕位置得按新的 startCandleDx 重新吸附, 否则读数
          // 停在旧蜡烛上。放在手势层是因为 [ChartBinding.onChartPanStep] 拿不到指针位置, 与
          // [onPanUpdate] 的 chart 分支同一分工。
          if (panned) {
            _hoverPosition = position;
            controller.onCrossUpdate(position);
          }
      }
    });
  }

  /// 通道 S 的 X 轴缩放: 用可重置 [Timer] 管理 session, 每个事件重置倒计时。
  void _applyScaleStep(Offset position, double factor) {
    var session = _scaleSession;
    if (session == null) {
      session = _ScaleSession(resolveScalePosition(position.dx));
      _scaleSession = session;
    }
    // 每个事件重置倒计时: 快速连续滚动不会在中途被提前清理(旧实现的缺陷)。
    session.resetIdleTimer(gestureConfig.scaleSessionTimeout, _endScaleSession);

    // 单次比值口径: 每个 signal 事件自成一次完整缩放, 直接乘。
    controller.onChartScaleTo(factor, position: session.position, focalDx: position.dx);
  }

  void _endScaleSession() {
    _scaleSession?.dispose();
    _scaleSession = null;
    controller.onChartScaleEnd();

    /// 检查并加载更多蜡烛数据
    controller.checkAndLoadMoreCandlesWhenPanEnd();
  }

  /// 鼠标Hover进入事件.
  void onEnter(PointerEnterEvent event) {
    if (controller.isStartDragGrid) return;
    final offset = event.localPosition;
    // if (!controller.canvasRect.include(offset)) return;

    if (_hoverPosition != null && controller.isDrawVisible && drawState.isOngoing) {
      logd('onEnter draw: $event');
      if (drawState.object?.pointer != null) {
        drawState.object!.onUpdateDrawPoint(drawState.object!.pointer!, offset);
      }
      _hoverPosition = offset;
    } else {
      logd('onEnter cross: $event');
      _hoverPosition = offset;
      controller.onCrossFollow(offset);
    }
  }

  /// 鼠标Hover事件.
  /// onMouseHover _TransformedPointerHoverEvent#1614b(position: Offset(86.5, 343.6))
  void onHover(PointerHoverEvent event) {
    final offset = event.localPosition;
    _hoverPosition = offset;

    final owner = NonTouchGestureOwner.resolveAt(controller, offset);
    _mouseCursor.value = owner.hoverCursor;

    switch (owner) {
      case NonTouchGestureOwner.drawDrawing:
        final pointer = drawState.pointer;
        if (pointer != null && pointer.offset.isFinite) {
          if (controller.isCrossing) controller.requestCancelCross();
          controller.onDrawUpdate(offset);
        }

      case NonTouchGestureOwner.drawEditing:
        // 已完成的 DrawObject 由平移([_drag])修正, hover 不参与.
        return;

      case NonTouchGestureOwner.zoomSlider:
        controller.requestCancelCross();

      case NonTouchGestureOwner.gridResize:
        controller.requestCancelCross();

      case NonTouchGestureOwner.paintObject:
      case NonTouchGestureOwner.chart:
        // 跟随语义: 未开则开、已开则只移动十字线。开启与更新的分工连同「已开时走轻量路径」
        // 的理由都收在 [CrossBinding.onCrossFollow] 内部, 手势层不重复判 isCrossing。
        controller.onCrossFollow(offset);
    }
  }

  /// 鼠标Hover退出事件.
  void onExit(PointerExitEvent event) {
    controller.requestCancelCross();
    logd('onExit $event');

    if (_hoverPosition == null) return;
    if (controller.isDrawVisible && drawState.isOngoing) {
      // 当处在绘制中状态时, 不清理hover指针数据.
      return;
    }
    _hoverPosition = null;
  }

  /// 点击
  void onTapUp(TapUpDetails details) {
    if (controller.isDrawVisible) {
      switch (drawState) {
        case Drawing():
          final offset = drawState.pointerOffset ?? details.localPosition;
          if (offset.isFinite) {
            logd('onTapUp draw(drawing) confirm pointer:$offset');
            _hoverPosition = offset;
            controller.onDrawConfirm(offset);
            if (controller.isCrossing) {
              controller.requestCancelCross();
            }
          }
          return;
        case Editing():
          final offset = details.localPosition;
          final object = controller.hitTestDrawObject(offset);
          if (object != null && object != drawState.object) {
            logd('onTapUp draw(editing) switch object:$object');
            controller.onDrawSelect(object);
          } else {
            logd('onTapUp draw(editing) confirm offset:$offset');
            _hoverPosition = offset;
            controller.onDrawConfirm(offset);
            // 指针仍在图表内, 确认后让十字线跟上来。
            controller.onCrossFollow(offset);
          }
          return;
        case Exited():
          if (controller.drawConfig.allowSelectWhenExit) {
            final object = controller.hitTestDrawObject(details.localPosition);
            if (object != null) {
              logd('onTapUp draw(exited) select object:$object');
              controller.onDrawSelect(object);
              return;
            }
          }
          break;
        case Prepared():
          final object = controller.hitTestDrawObject(details.localPosition);
          if (object != null) {
            logd('onTapUp draw(prepared) select object:$object');
            controller.onDrawSelect(object);
            return;
          }
          break;
      }
    }

    // 这里检测是否命中指标图定制位置
    final ret = controller.onTap(details.localPosition);
    if (ret) {
      logd('onTapUp handled! :$details');
      return;
    }
  }

  /// 平移开始.
  void onPanStart(DragStartDetails details) {
    // 触控板捏合期间抑制 pan: 这是通道 P 与通道 D 唯一的耦合点。
    // DragGestureRecognizer 会自动把 PointerPanZoomUpdateEvent.panDelta 当拖动增量,
    // 不抑制会导致捏合时图表同时平移。
    if (_trackpad?.pinching == true) return;

    if (_drag != null) {
      // 如果上次平移或缩放, 还没有结束, 不允许开始.
      logd('onPanStart Currently still panning, ignore!!!');
      return;
    }
    // 由 [DragStartBehavior.down] 保证: 这是 PointerDown 位置, 不含手势识别前的位移.
    final position = details.localPosition;
    final owner = NonTouchGestureOwner.resolveAt(controller, position);

    switch (owner) {
      case NonTouchGestureOwner.drawDrawing:
        // 未完成的暂不允许移动
        return;

      case NonTouchGestureOwner.drawEditing:
        if (drawState.object?.lock == true) return;
        logd('onPanStart draw > details:$details');
        if (!controller.onDrawMoveStart(position)) return;
        controller.requestCancelCross();
        _drag = _DragSession(owner, position);

      case NonTouchGestureOwner.paintObject:
        // PaintObject 优先按落点认领拖动.
        logd('onPanStart paintObject drag local:$position');
        if (!controller.onPaintObjectDragStart(position)) return;
        stopPositionAnimation();
        _drag = _DragSession(owner, position);
        _mouseCursor.value = owner.dragCursor(controller);

      case NonTouchGestureOwner.gridResize:
        logd('onPanStart gridResize local:$position');
        if (!controller.onGridResizeStart(position)) return;
        stopPositionAnimation();
        controller.requestCancelCross();
        _drag = _DragSession(owner, position);
        _mouseCursor.value = owner.dragCursor(controller);

      case NonTouchGestureOwner.zoomSlider:
        // zoomSlider 的拖动暂不接入 _drag。
        return;

      case NonTouchGestureOwner.chart:
        logd('onPanStart pan local:$position');
        stopPositionAnimation();
        _drag = _DragSession(owner, position);
        // 缩放态下同一条平移路径会额外消费 dy, 但那由 [ChartBinding.onChartMove] 按
        // `isChartZooming` 判断, 与手势数据的类型无关; 这里只换光标提示可拖动的方向。
        _mouseCursor.value = owner.dragCursor(controller);
    }
  }

  /// 平移中...
  void onPanUpdate(DragUpdateDetails details) {
    // 触控板捏合期间抑制 pan: 捏合可能在拖动已开始之后才被检测到(scale 变化需要
    // 越过阈值), 此时必须放弃本轮已建立的 _drag session 并回滚位移。
    if (_trackpad?.pinching == true) {
      if (_drag != null && _drag!.owner == NonTouchGestureOwner.chart) {
        stopPositionAnimation();
        _drag = null;
        // 重置 smoothFactor 但不触发惯性——这不是正常结束, 是中途让出。
        controller.onPanEnd();
        _mouseCursor.value = SystemMouseCursors.precise;
      }
      return;
    }

    final drag = _drag;
    if (drag == null) {
      logd('onPanUpdate no drag session! details:$details');
      return;
    }

    switch (drag.owner) {
      case NonTouchGestureOwner.paintObject:
        // 不做区域钳制: 是否限制在图表内由绘制对象自行决定.
        final position = details.localPosition;
        controller.onPaintObjectDragUpdate(position, position - drag.last);
        drag.last = position;

      case NonTouchGestureOwner.drawEditing:
        final position = details.localPosition.clamp(controller.mainRect);
        controller.onDrawMoveUpdate(position, position - drag.last);
        drag.last = position;

      case NonTouchGestureOwner.chart:
        final position = details.localPosition.clamp(controller.canvasRect);
        controller.onChartMove(
          position - drag.last,
          smoothFactor: gestureConfig.tolerance.effectivePanSmoothFactor,
        );
        drag.last = position;
        controller.onCrossUpdate(position);

      case NonTouchGestureOwner.gridResize:
        final position = details.localPosition;
        controller.onGridResizeUpdate(position.dy - drag.last.dy);
        drag.last = position;

      case NonTouchGestureOwner.drawDrawing:
      case NonTouchGestureOwner.zoomSlider:
        // 这些归属在 onPanStart 里已返回，不可能到这里。
        break;
    }
  }

  /// 平移结束.
  void onPanEnd(DragEndDetails details) {
    final drag = _drag;
    if (drag == null) {
      logd('onPanEnd no drag session! details:$details');
      return;
    }

    switch (drag.owner) {
      case NonTouchGestureOwner.paintObject:
        logd('onPanEnd paintObject drag end.');
        controller.onPaintObjectDragEnd();
        _drag = null;
        _mouseCursor.value = SystemMouseCursors.precise;
        // 拖动的是绘制对象而非蜡烛图: 不做惯性平移, 也不检查 loadMore.
        return;

      case NonTouchGestureOwner.drawEditing:
        controller.onDrawMoveEnd();
        _drag = null;
        return;

      case NonTouchGestureOwner.chart:
        // <0: 从右向左滑动; >0: 从左向右滑动.
        final velocity = details.velocity.pixelsPerSecond.dx;
        final inertial = resolveInertialPan(velocity, canceled: drag.canceled);

        if (inertial == null) {
          logd('onPanEnd no inertial movement, velocity:$velocity canceled:${drag.canceled}');
          _drag = null;
          controller.onPanEnd();
          _mouseCursor.value = SystemMouseCursors.precise;
          controller.checkAndLoadMoreCandlesWhenPanEnd();
          return;
        }

        final (:distance, :duration) = inertial;
        controller.checkAndLoadMoreCandlesWhenPanEnd(panDistance: distance, panDuration: duration);
        logi('onPanEnd inertial movement, velocity:$velocity distance:$distance duration:$duration');

        final from = drag.last.dx;
        animateToPosition(
          from,
          from + distance,
          panDuration: Duration(milliseconds: duration),
          tolerance: gestureConfig.tolerance,
          onCompleted: () {
            _drag = null;
            controller.onPanEnd();

            _mouseCursor.value = SystemMouseCursors.precise;
          },
        );

      case NonTouchGestureOwner.gridResize:
        logd('onPanEnd gridResize end.');
        controller.onGridResizeEnd();
        _drag = null;
        _mouseCursor.value = SystemMouseCursors.precise;
        return;

      case NonTouchGestureOwner.drawDrawing:
      case NonTouchGestureOwner.zoomSlider:
        // 这些归属在 onPanStart 里已返回，不可能到这里。
        break;
    }
  }

  /// 通道 P: 原生触控板手势开始。
  ///
  /// 只取捏合分量, pan 分量由 [GestureDetector] 的通道 D 兜住(免费拿 velocity tracker
  /// 惯性)。[_trackpad] 与 [_scaleSession] 独立, 不共用字段。
  void onPointerPanZoomStart(PointerPanZoomStartEvent event) {
    final offset = event.localPosition;
    if (!controller.canvasRect.include(offset)) {
      logw('onPointerPanZoomStart $offset is not in the canvas.');
      return;
    }

    if (gestureConfig.enableScale) {
      stopPositionAnimation();
      logd('onPointerPanZoomStart $event > ${event.localPosition}');
      _trackpad = _TrackpadSession(resolveScalePosition(offset.dx));
    }
  }

  /// 通道 P: 原生触控板手势更新。
  ///
  /// pinching 判定用**累积偏离阈值**而非帧间变化量: `(event.scale - 1.0).abs()` 超过
  /// [_kPinchThreshold] 才置位。双指横滑时 scale 围绕 1.0 微波动(通常 < 0.02), 不会越过
  /// 0.05 的阈值; 真正的捏合会使 scale 快速偏离 1.0(放大到 1.1、缩小到 0.9)。
  void onPointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    final session = _trackpad;
    if (session == null) {
      logd('onPointerPanZoomUpdate trackpad is empty! $event ${event.scale}');
      return;
    }

    if (!gestureConfig.enableScale) return;

    // 累积偏离判定: PanZoomStart 时 scale 恒为 1.0, 真正的捏合会持续偏离。
    if (!session.pinching && (event.scale - 1.0).abs() > _kPinchThreshold) {
      session.pinching = true;
    }

    if (session.pinching) {
      // 阈值判在 raw 口径, 增量传 decelerated 口径: 两个口径各有用途, 不能合并成一个字段。
      if ((event.scale - session.lastRawScale).abs() > 0.001) {
        session.lastRawScale = event.scale;
        final newScale = scaledDecelerate(event.scale);
        // 累积比例口径: 传帧间增量, 由 onChartScaleBy 加到蜡烛宽度上。
        controller.onChartScaleBy(
          newScale - session.lastScale,
          position: session.position,
          focalDx: event.localPosition.dx,
        );
        session.lastScale = newScale;
      }
    }
  }

  /// 通道 P: 原生触控板手势结束。[pinching] 随 session 销毁自动清零。
  void onPointerPanZoomEnd(PointerPanZoomEndEvent event) {
    final session = _trackpad;
    if (session == null) {
      logd('onPointerPanZoomEnd trackpad is empty! > event:$event');
      return;
    }

    logd('onPointerPanZoomEnd pinching:${session.pinching} ${event.localPosition}');
    if (session.pinching) {
      controller.onChartScaleEnd();
    }
    _trackpad = null;
  }

  /// 右键按下: 退出 Y 轴缩放。
  ///
  /// 用 [Listener.onPointerDown] 而非 [GestureDetector.onSecondaryTap] 以避免与
  /// pan recognizer 的竞技场冲突。只处理 secondary button, primary 留给 GestureDetector。
  void onPointerDown(PointerDownEvent event) {
    if (event.buttons == kSecondaryMouseButton && controller.isChartZooming) {
      logd('onPointerDown secondary > exit zoom');
      controller.exitChartZoom();
    }
  }

  void onPointerCancel(PointerCancelEvent event) {
    logd('onPointerCancel $event');
    final drag = _drag;
    if (drag == null) return;

    if (drag.owner == NonTouchGestureOwner.paintObject) {
      // 立刻回滚, 不能等 [onPanEnd]: 那里会把中断当成一次提交。
      controller.onPaintObjectDragCancel();
      _drag = null;
      _mouseCursor.value = SystemMouseCursors.precise;
      return;
    }

    // 其余归属留给各自的 [onPanEnd] 收尾, 这里只记下事实。
    drag.canceled = true;
  }

  void onKeyEvent(KeyEvent event) {
    if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        logd('onKeyEvent > ESC');
        // 优先退出 zoom; 其次退出 draw。
        if (controller.isChartZooming) {
          controller.exitChartZoom();
        } else if (drawState.isOngoing) {
          controller.prepareDraw(force: true);
        }
      }
    }
  }
}

/// 捏合判定的累积偏离阈值: `(event.scale - 1.0).abs()` 超过此值才视为捏合。
///
/// 双指横滑时 scale 围绕 1.0 微波动(通常 < 0.02), 0.05 留 2.5 倍余量;
/// 真正捏合时 scale 快速偏离 1.0(放大到 1.1+、缩小到 0.9-), 识别延迟可忽略。
const _kPinchThreshold = 0.05;

/// 滚轮事件判为横向平移所需的横向占优比例: `|dx| >= |dy| × _kPanDominanceRatio`。
/// 取 2 即约 26.57° 的横向锥。
///
/// 不复用 [GestureConfig.panClaimRatio]: 那里的二分是「平移 vs 放弃给外层」, 这里是
/// 「平移 vs 缩放」, 两边都消费事件。暂用常量不开配置, 等真机反馈说 2:1 不合适再提升。
const _kPanDominanceRatio = 2;

/// 通道 D 的一次拖动 session：归属在 `onPanStart` 判定一次，全程不变。
class _DragSession {
  _DragSession(this.owner, this.last);

  final NonTouchGestureOwner owner;

  /// 上一帧位置：既是帧间增量的基准，也是惯性平移的起点。
  ///
  /// Controller API 只接受已算好的增量，差分基准因此归手势层持有。
  Offset last;

  /// 本轮是否出现过 [PointerCancelEvent]。
  ///
  /// `DragGestureRecognizer` 在指针被取消时同样派发 `onPanEnd`，且无法从 [DragEndDetails]
  /// 区分，所以必须由外层 [Listener] 记下这个事实——它在命中路径中先于 `GestureBinding`
  /// 收到同一个事件，写入一定早于 `onPanEnd`。当前只有 chart 平移消费它（不做惯性平移）。
  bool canceled = false;
}

/// 通道 S 的 X 轴 scale session。
///
/// [position] 必须一轮内稳定（锚定三分区），且 [onChartScaleEnd] 要做
/// `_setCandleWidth(sync: true)` 与 loadMore 检查。所以 session 不能取消——改的只是用
/// **可重置 [Timer]** 替代 `Future.delayed`。
///
/// 不存缩放基准：signal 是单次比值口径，每个事件自成一次完整缩放。
class _ScaleSession {
  _ScaleSession(this.position);

  final ScalePosition position;
  Timer? _idleTimer;

  void resetIdleTimer(Duration timeout, VoidCallback onTimeout) {
    _idleTimer?.cancel();
    _idleTimer = Timer(timeout, onTimeout);
  }

  void dispose() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }
}

/// 通道 P 的触控板 session。
///
/// [pinching] 是通道 P 与通道 D 唯一的耦合点: 一旦 `event.scale` 累积偏离 1.0 超过
/// [_kPinchThreshold] 即置位, 本轮通道 D 的 [onPanStart] / [onPanUpdate] 看到它就
/// 直接返回, 避免捏合时图表同时平移。session 结束时 [_trackpad] 被置 null,
/// [pinching] 随之失效。
class _TrackpadSession {
  _TrackpadSession(this.position);

  final ScalePosition position;

  /// 一旦检测到捏合即置 true, 本轮不再放行通道 D 的 pan。
  bool pinching = false;

  /// 上一次的原始 `event.scale`，用于帧间变化量的阈值判定（raw 口径）。
  /// 初始 1.0: PanZoomStart 时 scale 恒为 1。
  double lastRawScale = 1.0;

  /// 上一次减速后的比例，`onChartScaleBy` 的增量基准（decelerated 口径）。
  ///
  /// 与 [lastRawScale] 是两个口径、两个用途：前者判「动没动」，后者算「动了多少」。
  double lastScale = 1.0;
}
