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

  /// zoom slider 拖拽是否已正式开始（通过了最小距离检查且 onChartZoomStart 返回 true）
  bool _isZoomStarted = false;

  @override
  String get logTag => 'TouchGesture';

  @override
  Widget build(BuildContext context) {
    return Listener(
      key: const ValueKey('TouchListener'),
      behavior: HitTestBehavior.translucent,
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,

        /// 点击
        onTapUp: onTapUp,

        /// 双击
        onDoubleTap: widget.onDoubleTap,

        /// 移动 缩放
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate.throttleOnFps,
        onScaleEnd: onScaleEnd,

        /// 长按
        onLongPressStart: onLongPressStart,
        onLongPressMoveUpdate: onLongPressMoveUpdate.throttleOnFps,
        onLongPressEnd: onLongPressEnd,

        child: const SizedBox.expand(),
      ),
    );
  }

  void onPointerDown(PointerDownEvent event) {
    if (++_activePointerCount == 2) {
      controller.setMultiTouch(true);
    }
    final position = event.localPosition;
    if (controller.isDrawVisibility && drawState.isOngoing) {
      // 优化Drawing的处理
    } else if (controller.isCrossing) {
      // 优化Crossing的处理
    } else if (gestureConfig.enableZoom && _zoomData == null && controller.chartZoomSlideBarRect.include(position)) {
      logd('onPointerDown zoom > position:$position');
      _zoomData = GestureData.zoom(position);
    } else if (_zoomData == null && controller.isStartZoomChart && controller.mainRect.include(position)) {
      logd('onPointerDown position:$position');
      _moveData = GestureData.move(position);
    }
  }

  /// 原始移动
  /// 当原始移动时, 当前如果正处在crossing或drawing中时, 发生冲突, 清理手势竞技场, 响应Cross/Draw指针平移事件
  void onPointerMove(PointerMoveEvent event) {
    if (controller.isDrawVisibility && drawState.isOngoing) {
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
          _isZoomStarted = true;
        }
      } else {
        controller.onChartZoomUpdate(_zoomData!);
      }
    } else if (controller.isStartZoomChart && _moveData != null) {
      if (!isSweeped) {
        logi('onPointerMove currently in zooming, need clear the gesture arena!');
        isSweeped = true;
        GestureBinding.instance.gestureArena.sweep(event.pointer);
      }

      final newOffset = _moveData!.offset + event.delta;
      controller.onChartMove(_moveData!..update(newOffset));
    }
  }

  void onPointerUp(PointerUpEvent event) => _pointerEnd(event);

  void onPointerCancel(PointerCancelEvent event) => _pointerEnd(event);

  void _pointerEnd(PointerEvent event) {
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
    _moveData = null;
  }

  /// 点击
  void onTapUp(TapUpDetails details) {
    if (controller.isDrawVisibility) {
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

    if (controller.isDrawVisibility && drawState.isOngoing) {
      if (drawState.isDrawing) {
        // 未完成的暂不允许移动
        return;
      }
      if (drawState.object?.lock == true) return;
      logd('onScaleStart draw > details:$details');
      _panScaleData = GestureData.pan(details.localFocalPoint);
      final result = controller.onDrawMoveStart(_panScaleData!);
      if (!result) {
        _panScaleData?.end();
        _panScaleData = null;
      }
    } else if (gestureConfig.enableScale && details.pointerCount > 1) {
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
    if (controller.isDrawVisibility && drawState.isOngoing) {
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

    if (controller.isDrawVisibility && drawState.isOngoing) {
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
        controller.curKlineData.isEmpty ||
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

    if (controller.isDrawVisibility && drawState.isOngoing) {
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
    } else if (!controller.isCrossing && controller.onGridMoveStart(details.localPosition)) {
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
    if (controller.isDrawVisibility && drawState.isOngoing) {
      _longData!.update(details.localPosition);
      controller.onDrawMoveUpdate(_longData!);
    } else if (controller.isStartDragGrid) {
      _longData!.update(details.localPosition);
      controller.onGridMoveUpdate(_longData!);
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
    if (controller.isDrawVisibility && drawState.isOngoing) {
      controller.onDrawMoveEnd();
    } else if (controller.isStartDragGrid) {
      controller.onGridMoveEnd();
    } else {
      // 长按结束, 尝试取消Cross事件.
      controller.cancelCross();
    }
    _longData?.end();
    _longData = null;
  }
}
