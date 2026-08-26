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

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../constant.dart';
import '../extension/functions_ext.dart';
import '../extension/geometry_ext.dart';
import '../framework/chart/indicator.dart';
import '../framework/draw/overlay.dart';
import '../model/gesture_data.dart';
import '../utils/algorithm_util.dart';
import 'chart_scale_gesture_recognizer.dart';
import 'gesture_detector_widget.dart';

class TouchGestureDetector extends GestureDetectorWidget {
  const TouchGestureDetector({
    super.key,
    required super.controller,
    super.onDoubleTap,
  });

  @override
  GestureDetectorState<TouchGestureDetector> createState() => _TouchGestureDetectorState();
}

class _TouchGestureDetectorState extends GestureDetectorState<TouchGestureDetector> {
  /// 平移/缩放监听数据
  GestureData? _panScaleData;

  /// 缩放主区图表事件监听数据
  GestureData? _zoomData;

  /// 移动图表监听数据
  GestureData? _moveData;

  /// Cross平移/触发/监听数据
  GestureData? _tapData;

  /// 长按监听数据
  GestureData? _longData;

  /// 是否已清理过手势竞技场(解决手势冲突), 避免重复操作.
  /// 作用域为单次 pointer 会话（PointerDown → PointerUp/Cancel），
  /// 由 [_pointerEnd] 重置. 仅适用于单指独占路径（crossing/drawing/zoom/move）.
  bool isSweeped = false;

  /// 当前活跃的指针数量，用于检测多指触摸状态.
  int _activePointerCount = 0;

  /// 当前 pointer 会话中第一指的按下位置。
  ///
  /// Scale 手势会在移动超过触摸容差后才触发 onStart，PaintObject 需要用原始按下位置命中。
  ({int pointer, Offset position})? _primaryDown;

  /// zoom slider 拖拽是否已正式开始（通过了最小距离检查且 onChartZoomStart 返回 true）
  bool _isZoomStarted = false;

  /// 当前 Scale 手势是否已由 PaintObject 路径认领。
  ///
  /// 即使 Controller 因失选等原因提前取消业务拖动，本次手势结束前仍保持认领，
  /// 避免中途转为蜡烛图平移、惯性平移或 loadMore。
  bool _isObjectDragGesture = false;

  @override
  String get logTag => 'TouchGesture';

  @override
  Widget build(BuildContext context) {
    // [RawGestureDetector] 不像 [GestureDetector] 那样自动注入 gestureSettings, 必须
    // 逐个识别器手动注入: 漏了会让所有识别器退回框架常量, 丢掉平台适配, 并让
    // [ChartScaleGestureRecognizer] 的抢占阈值按 kTouchSlop 而非设备值计算。
    final gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    return Listener(
      key: const ValueKey('TouchListener'),
      behavior: HitTestBehavior.translucent,
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      child: RawGestureDetector(
        behavior: HitTestBehavior.translucent,

        /// map 的插入顺序即竞技场加入顺序, 必须保持 Tap 在最前(与 [GestureDetector]
        /// 一致): [onPointerMove] 里 crossing / drawing / zoom slider / chart zooming
        /// 四条路径调的 `gestureArena.sweep` 是"第一个成员胜出", 改顺序会静默改变
        /// 这四条既有路径的胜者。
        gestures: <Type, GestureRecognizerFactory>{
          /// 点击
          TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(debugOwner: this),
            (instance) => instance
              ..onTapUp = onTapUp
              ..gestureSettings = gestureSettings,
          ),

          /// 双击
          DoubleTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
            () => DoubleTapGestureRecognizer(debugOwner: this),
            (instance) => instance
              ..onDoubleTap = widget.onDoubleTap
              ..gestureSettings = gestureSettings,
          ),

          /// 长按
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(debugOwner: this),
            (instance) => instance
              ..onLongPressStart = onLongPressStart
              ..onLongPressMoveUpdate = onLongPressMoveUpdate.throttleOnFps
              ..onLongPressEnd = onLongPressEnd
              ..gestureSettings = gestureSettings,
          ),

          /// 移动 缩放
          ChartScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<ChartScaleGestureRecognizer>(
            () => ChartScaleGestureRecognizer(
              debugOwner: this,
              claimSlopFactor: gestureConfig.dragClaimSlopFactor,
              hitTestDragStart: controller.hitTestPaintObjectDrag,
            ),
            (instance) => instance
              ..onStart = onScaleStart
              ..onUpdate = onScaleUpdate.throttleOnFps
              ..onEnd = onScaleEnd
              ..gestureSettings = gestureSettings,
          ),
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  void onPointerDown(PointerDownEvent event) {
    final pointerCount = ++_activePointerCount;
    if (pointerCount == 1) {
      _primaryDown = (pointer: event.pointer, position: event.localPosition);
    }
    if (pointerCount == 2) {
      controller.setMultiTouch(true);
      // 第二指落下即转为缩放语义, 放弃 PaintObject 拖动并回滚其未提交状态.
      _cancelObjectDragGesture();
    }
    final position = event.localPosition;
    if (controller.isDrawVisible && drawState.isOngoing) {
      // 优化Drawing的处理
    } else if (controller.isCrossing) {
      // 优化Crossing的处理
    } else if (gestureConfig.enableZoom && _zoomData == null && controller.chartZoomSlideBarRect.include(position)) {
      logd('onPointerDown zoom > position:$position');
      _zoomData = GestureData.zoom(position);
    } else if (_zoomData == null && controller.isChartZooming && controller.mainRect.include(position)) {
      logd('onPointerDown position:$position');
      _moveData = GestureData.move(position);
    }
  }

  /// 原始移动
  /// 当原始移动时, 当前如果正处在crossing或drawing中时, 发生冲突, 清理手势竞技场, 响应Cross/Draw指针平移事件
  void onPointerMove(PointerMoveEvent event) {
    if (controller.isDrawVisible && drawState.isOngoing) {
      if (drawState.isEditing) {
        /// 已完成的DrawObject通过平移[_panScaleData]或长按[_longData]事件进行修正.
        return;
      }
      final pointerOffset = drawState.pointerOffset;
      if (pointerOffset != null) {
        if (!isSweeped) {
          logi('onPointerMove currently in drawing, need clear the gesture arena!');
          isSweeped = true;
          GestureBinding.instance.gestureArena.sweep(event.pointer);
          if (pointerOffset.isFinite) {
            _tapData = GestureData.pan(pointerOffset);
          }
        }

        if (_tapData == null) return;
        final newOffset = _tapData!.offset + event.delta;
        // final mainRect = controller.mainRect;
        // if (!mainRect.include(newOffset)) {
        //   newOffset = newOffset.clamp(mainRect);
        // }
        controller.onDrawUpdate(_tapData!..update(newOffset));
      }
    } else if (controller.isCrossing) {
      if (!isSweeped) {
        logi('onPointerMove currently in crossing, need clear the gesture arena!');
        isSweeped = true;
        GestureBinding.instance.gestureArena.sweep(event.pointer);
      }

      if (_tapData == null) {
        logd('onPointerMove crossing but _tapData is null, skip');
        return;
      }
      Offset newOffset = _tapData!.offset + event.delta;
      final canvasRect = controller.canvasRect;
      if (!canvasRect.include(newOffset)) {
        newOffset = newOffset.clamp(canvasRect);
      }
      controller.onCrossUpdate(_tapData!..update(newOffset));
    } else if (_zoomData != null) {
      if (!isSweeped) {
        logi('onPointerMove currently in zoom slider, need clear the gesture arena!');
        isSweeped = true;
        GestureBinding.instance.gestureArena.sweep(event.pointer);
      }
      _zoomData!.update(event.localPosition);
      if (!_isZoomStarted) {
        if (_zoomData!.dyDelta.abs() >= gestureConfig.zoomStartMinDistance &&
            controller.onChartZoomStart(event.localPosition, false)) {
          cancelPositionAnimation();
          _isZoomStarted = true;
        }
      } else {
        controller.onChartZoomUpdate(_zoomData!);
      }
    } else if (controller.isChartZooming && _moveData != null) {
      if (!isSweeped) {
        logi('onPointerMove currently in zooming, need clear the gesture arena!');
        isSweeped = true;
        GestureBinding.instance.gestureArena.sweep(event.pointer);
      }

      final newOffset = _moveData!.offset + event.delta;
      cancelPositionAnimation();
      controller.onChartMove(_moveData!..update(newOffset));
    }
  }

  void onPointerUp(PointerUpEvent event) => _pointerEnd(event);

  void onPointerCancel(PointerCancelEvent event) => _pointerEnd(event);

  void _pointerEnd(PointerEvent event) {
    if (_primaryDown?.pointer == event.pointer) {
      _primaryDown = null;
    }
    if (_activePointerCount > 0) _activePointerCount--;
    if (_activePointerCount < 2) {
      controller.setMultiTouch(false);
    }
    if (isSweeped) {
      isSweeped = false;
    }
    if (_zoomData != null) {
      logd('_pointerEnd zoom end by ${event.runtimeType}');
      if (_isZoomStarted) {
        controller.onChartZoomEnd();
      }
      _zoomData?.end();
      _zoomData = null;
      _isZoomStarted = false;
    }
    if (event is PointerCancelEvent) {
      // 正常抬手时 [onScaleEnd] 已经收尾, 这里只兜底指针被取消的路径.
      _cancelObjectDragGesture();
    }
    _moveData = null;
  }

  /// 放弃当前 PaintObject 拖动并清理其手势数据. 未在拖动时为空操作.
  void _cancelObjectDragGesture() {
    if (!_isObjectDragGesture) return;
    _isObjectDragGesture = false;
    controller.onPaintObjectDragCancel();
    _panScaleData?.end();
    _panScaleData = null;
  }

  /// 点击
  void onTapUp(TapUpDetails details) {
    if (controller.isDrawVisible) {
      switch (drawState) {
        case Drawing():
          final pointerOffset = drawState.pointerOffset;
          if (pointerOffset != null && pointerOffset.isFinite) {
            logd('onTapUp draw(drawing) confirm pointer:$pointerOffset');
            _tapData = GestureData.tap(pointerOffset);
            controller.onDrawConfirm(_tapData!);
            if (drawState.isEditing) {
              _tapData?.end();
              _tapData = null;
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
            _tapData = GestureData.tap(offset);
            controller.onDrawConfirm(_tapData!);
            _tapData?.end();
            _tapData = null;
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
      }
    }

    // if (!controller.isCrossing) {
    // 这里检测是否命中指标图定制位置
    if (controller.onTap(details.localPosition)) {
      logd('onTapUp handled! :$details');
      return;
    }
    // }

    logd('onTapUp cross start details:$details');
    _tapData = GestureData.tap(details.localPosition);
    final ret = controller.onCrossStart(_tapData!);
    if (!ret) {
      _tapData?.end();
      _tapData = null;
    }
  }

  /// 平移/缩放开始.
  void onScaleStart(ScaleStartDetails details) {
    if (_zoomData != null || _moveData != null) {
      return;
    }

    if (_panScaleData != null && !_panScaleData!.isEnd) {
      // 如果上次平移或缩放, 还没有结束, 不允许开始.
      logd('onScaleStart Currently still ongoing, ignore!!!');
      return;
    }

    if (controller.isDrawVisible && drawState.isOngoing) {
      if (drawState.isDrawing) {
        // 未完成的暂不允许移动
        return;
      }
      if (drawState.object?.lock == true) return;
      logd('onScaleStart draw > details:$details');
      final currentPosition = details.localFocalPoint;
      final downPosition = details.pointerCount <= 1 ? _primaryDown?.position : null;
      _panScaleData = GestureData.pan(downPosition ?? currentPosition);
      final result = controller.onDrawMoveStart(_panScaleData!);
      if (!result) {
        _panScaleData?.end();
        _panScaleData = null;
      }
      return;
    }

    // PaintObject 优先按落点认领单指拖动; 多指仍归缩放.
    final currentPosition = details.localFocalPoint;
    final downPosition = details.pointerCount <= 1 ? _primaryDown?.position : null;
    if (downPosition != null && controller.onPaintObjectDragStart(downPosition)) {
      logd('onScaleStart paintObject drag down:$downPosition current:$currentPosition');
      cancelPositionAnimation();
      _isObjectDragGesture = true;
      _panScaleData = GestureData.pan(downPosition);
      return;
    }

    cancelPositionAnimation();
    if (gestureConfig.enableScale && details.pointerCount > 1) {
      ScalePosition position = _panScaleData?.initPosition ?? gestureConfig.scalePosition;
      if (position == ScalePosition.auto) {
        final third = controller.canvasRect.width / 3;
        final dx = details.localFocalPoint.dx;
        if (dx < third) {
          position = ScalePosition.left;
        } else if (dx > (third + third)) {
          position = ScalePosition.right;
        } else {
          position = ScalePosition.middle;
        }
      }
      logd('onScaleStart scale $position focal:${details.localFocalPoint}');
      _panScaleData = GestureData.scale(
        details.localFocalPoint,
        position: position,
      );
    } else {
      logd('onScaleStart pan focal:${details.localFocalPoint}');
      _panScaleData = GestureData.pan(details.localFocalPoint);
    }
  }

  /// 平移/缩放中...
  void onScaleUpdate(ScaleUpdateDetails details) {
    if (_panScaleData == null) {
      logd('onScaleUpdate panScaleData is empty! details:$details');
      return;
    }

    // logd('onScaleUpdate move> ${DateTime.now().millisecond} details:${details.localFocalPoint}');
    if (_isObjectDragGesture) {
      // 不做区域钳制: 是否限制在图表内由绘制对象自行决定.
      _panScaleData!.update(details.localFocalPoint);
      controller.onPaintObjectDragUpdate(_panScaleData!);
      return;
    }

    if (controller.isDrawVisible && drawState.isOngoing) {
      if (_panScaleData!.isPan) {
        _panScaleData!.update(
          details.localFocalPoint,
          newScale: details.scale,
        );
        controller.onDrawMoveUpdate(_panScaleData!);
      }
    } else if (gestureConfig.enableScale && _panScaleData!.isScale) {
      final newScale = scaledDecelerate(details.scale);
      final change = details.scale - _panScaleData!.scale;
      // assert(() {
      //   logd("onScaleUpdate scale ${details.scale}>$newScale change:$change");
      //   return true;
      // }());
      if (change.abs() > 0.01) {
        _panScaleData!.update(
          details.localFocalPoint,
          newScale: newScale,
        );
        controller.onChartScale(_panScaleData!);
      }
    } else if (_panScaleData!.isPan) {
      _panScaleData!.update(
        details.localFocalPoint.clamp(controller.canvasRect),
        newScale: details.scale,
      );
      controller.onChartMove(
        _panScaleData!,
        gestureConfig.tolerance.effectivePanSmoothFactor,
      );
    }
  }

  /// 平移/缩放结束.
  void onScaleEnd(ScaleEndDetails details) {
    if (_panScaleData == null) {
      logd('onScaleEnd panScaledata and ticker is empty! > details:$details');
      return;
    }

    if (_isObjectDragGesture) {
      logd('onScaleEnd paintObject drag end.');
      _isObjectDragGesture = false;
      controller.onPaintObjectDragEnd();
      _panScaleData?.end();
      _panScaleData = null;
      // 拖动的是绘制对象而非蜡烛图: 不做惯性平移, 也不检查 loadMore.
      return;
    }

    if (controller.isDrawVisible && drawState.isOngoing) {
      if (_panScaleData!.isPan) {
        controller.onDrawMoveEnd();
      }
      _panScaleData?.end();
      _panScaleData = null;
      return;
    }

    if (_panScaleData!.isScale) {
      logd('onScaleEnd scale. ${details.pointerCount}');
      _panScaleData?.end();
      _panScaleData = null;
      controller.onChartScaleEnd();

      /// 检查并加载更多蜡烛数据
      controller.checkAndLoadMoreCandlesWhenPanEnd();
      return;
    }

    // <0: 负数代表从右向左滑动.
    // >0: 正数代表从左向右滑动.
    final velocity = details.velocity.pixelsPerSecond.dx;

    if (!gestureConfig.enableInertialPan ||
        controller.klineData.isEmpty ||
        (velocity < 0 && !controller.canPanRTL) ||
        (velocity > 0 && !controller.canPanLTR)) {
      logd('onScaleEnd currently can not pan!');
      _panScaleData?.end();
      _panScaleData = null;
      controller.onPanEnd();

      /// 检查并加载更多蜡烛数据
      controller.checkAndLoadMoreCandlesWhenPanEnd();
      return;
    }

    final tolerance = gestureConfig.tolerance;

    /// 惯性平移的最大距离.
    final panDistance = velocity * tolerance.distanceFactor;

    final panDuration = calcuInertialPanDuration(
      panDistance,
      maxDuration: tolerance.maxDuration,
    );

    // 平移距离为0 或者 不足1ms, 无需继续平移
    if (panDistance.abs() < precisionError || panDuration <= 1) {
      logd('onScaleEnd currently not need for inertial movement!');
      _panScaleData?.end();
      _panScaleData = null;
      controller.onPanEnd();

      /// 检查并加载更多蜡烛数据
      controller.checkAndLoadMoreCandlesWhenPanEnd();
      return;
    }

    /// 检查并加载更多蜡烛数据
    controller.checkAndLoadMoreCandlesWhenPanEnd(
      panDistance: panDistance,
      panDuration: panDuration,
    );

    logi(
      'onScaleEnd inertial movement, velocity:$velocity, panDistance:$panDistance, panDuration:$panDuration',
    );

    animateToPosition(
      _panScaleData!.offset.dx,
      _panScaleData!.offset.dx + panDistance,
      panDuration: Duration(milliseconds: panDuration),
      tolerance: tolerance,
      onCompleted: () {
        _panScaleData?.end();
        _panScaleData = null;
        controller.onPanEnd();
      },
    );
  }

  /// 长按
  ///
  /// 如果当前正在crossing中时, 不触发后续的长按逻辑.
  void onLongPressStart(LongPressStartDetails details) {
    if (!gestureConfig.enableLongPress || controller.isCrossing) {
      logd('onLongPressStart ignore! > crossing:${controller.isCrossing}');
      return;
    }

    if (controller.isDrawVisible && drawState.isOngoing) {
      if (drawState.isDrawing) {
        // 未完成的暂不允许移动
        return;
      }
      if (drawState.object?.lock == true) return;
      logd('onLongPressStart draw > details:$details');
      _longData = GestureData.long(details.localPosition);
      final result = controller.onDrawMoveStart(_longData!);
      if (!result) {
        _longData?.end();
        _longData = null;
      }
    } else if (!controller.isCrossing && controller.onGridResizeStart(details.localPosition)) {
      logd('onLongPressStart move > details:$details');
      _longData = GestureData.long(details.localPosition);
    } else {
      logd('onLongPressStart cross > details:$details');
      _longData = GestureData.long(details.localPosition);
      final result = controller.onCrossStart(_longData!);
      if (!result) {
        _longData?.end();
        _longData = null;
      }
    }
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!gestureConfig.enableLongPress || _longData == null) {
      return;
    }
    // assert(() {
    //   logd(
    //     "onLongPressMoveUpdate ${DateTime.now().millisecond} > details:${details.localPosition}",
    //   );
    //   return true;
    // }());
    if (controller.isDrawVisible && drawState.isOngoing) {
      _longData!.update(details.localPosition);
      controller.onDrawMoveUpdate(_longData!);
    } else if (controller.isStartDragGrid) {
      _longData!.update(details.localPosition);
      controller.onGridResizeUpdate(_longData!);
    } else {
      _longData!.update(details.localPosition);
      controller.onCrossUpdate(_longData!);
    }
  }

  void onLongPressEnd(LongPressEndDetails details) {
    if (!gestureConfig.enableLongPress || _longData == null) {
      logd('onLongPressEnd ignore! > details:$details');
      return;
    }
    // assert(() {
    //   logd("onLongPressEnd details:$details");
    //   return true;
    // }());
    if (controller.isDrawVisible && drawState.isOngoing) {
      controller.onDrawMoveEnd();
    } else if (controller.isStartDragGrid) {
      controller.onGridResizeEnd();
    } else {
      // 长按结束, 尝试取消Cross事件.
      controller.requestCancelCross();
    }
    _longData?.end();
    _longData = null;
  }
}
