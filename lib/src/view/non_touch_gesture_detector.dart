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
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../constant.dart';
import '../extension/functions_ext.dart';
import '../extension/geometry_ext.dart';
import '../framework/chart/indicator.dart';
import '../framework/draw/overlay.dart';
import '../model/gesture_data.dart';
import '../utils/algorithm_util.dart';
import 'gesture_detector_widget.dart';

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

  /// 缩放监听数据
  GestureData? _scaleData;

  /// Cross平移监听数据
  GestureData? _hoverData;

  /// 平移监听数据
  GestureData? _panData;

  /// 长按监听数据
  GestureData? _longData;

  /// PaintObject 是否已认领本次拖动.
  /// 认领期间蜡烛图不平移、不更新 cross, 松手也不做惯性平移.
  bool _isObjectDragging = false;

  final _mouseCursor = ValueNotifier(SystemMouseCursors.precise);

  void setCursorToPrecise() {
    _mouseCursor.value = SystemMouseCursors.precise;
  }

  void setCursorToZoom() {
    _mouseCursor.value = SystemMouseCursors.resizeUpDown;
  }

  void setCursorToClick() {
    _mouseCursor.value = SystemMouseCursors.click;
  }

  void setCursorToGrabbing() {
    _mouseCursor.value = SystemMouseCursors.grabbing;
  }

  void setCursorToMove() {
    _mouseCursor.value = SystemMouseCursors.move;
  }

  void setCursorToNone() {
    _mouseCursor.value = SystemMouseCursors.none;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.drawStateListenable.addListener(() {
        /// 控制指针形状
        switch (drawState) {
          case Editing():
            setCursorToClick();
          case Drawing():
          case Prepared():
          case Exited():
            setCursorToPrecise();
        }

        if (gestureConfig.supportKeyboardShortcuts) {
          /// 控制KeyboardListener的焦点获取与释放
          switch (drawState) {
            case Drawing():
            case Editing():
              if (!_keyboardFocusNode.hasFocus) {
                _keyboardFocusNode.requestFocus();
              }
              break;
            case Prepared():
            case Exited():
              if (_keyboardFocusNode.hasFocus) {
                _keyboardFocusNode.unfocus();
              }
              // FocusManager.instance.primaryFocus?.unfocus();
              break;
          }
        }
      });
    });
  }

  @override
  void dispose() {
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

      /// 鼠标设备滚轴滚动进行缩放,
      /// 在Web中:
      ///   1. 触控板双指同时向上/下进行缩放;
      ///   2. 触控板双指同时向左/右进行平移(惯性?)
      onPointerSignal: onPointerSignal,

      /// 触控板的平移、缩放和旋转手势
      onPointerPanZoomStart: onPointerPanZoomStart,
      onPointerPanZoomUpdate: onPointerPanZoomUpdate,
      onPointerPanZoomEnd: onPointerPanZoomEnd,

      /// 指针取消: 仅用于回滚 PaintObject 拖动.
      /// [onPanEnd] 在指针被取消时同样会派发(见 monodrag.dart 的 accepted 分支),
      /// 无法从 [DragEndDetails] 区分, 故在此先行回滚, 避免把中断当成提交.
      onPointerCancel: onPointerCancel,
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

            /// 长按
            onLongPressStart: onLongPressStart,
            onLongPressMoveUpdate: onLongPressMoveUpdate.throttleOnFps,
            onLongPressEnd: onLongPressEnd,
          ),
        ),
      ),
    );
  }

  /// 鼠标设备滚轴滚动进行缩放,
  /// 在Web中:
  ///   1. 触控板双指同时向上/下进行缩放;
  ///   2. 触控板双指同时向左/右进行平移(惯性?)
  ///zp::: web onPointerSignal _TransformedPointerScaleEvent#e6ea9(position: Offset(462.0, 177.0))
  void onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final offset = event.localPosition;
      if (!controller.canvasRect.include(offset)) {
        logw('onPointerSignal $offset is not in the canvas.');
        _scaleData?.end();
        _scaleData = null;
      }

      final scrollDelta = event.scrollDelta;
      final dx = scrollDelta.dx.abs();
      final dy = scrollDelta.dy.abs();
      if (dy > 1 && dy > dx) {
        // 说明可能是(鼠标滚轴或触控板双指)向上向下进行缩放

        /// 纵向缩放图表(zoom)
        if (gestureConfig.enableZoom && controller.chartZoomSlideBarRect.include(offset)) {
          // 如果命中ZommSlideBar区域, 即代表要进行缩放图表
          stopPositionAnimation();
          if (!controller.isChartZooming && controller.onChartZoomStart(offset)) {
            Future.delayed(const Duration(milliseconds: 1000), () {
              assert(() {
                logd('onPointerSignal V>Zoom onChartZoomEnd()');
                return true;
              }());
              // 由于没有开始结束事件回调, 此处1秒后执行缩放结束动作-检查.
              controller.onChartZoomEnd();
            });
          }

          assert(() {
            logd('onPointerSignal V>Zoom $offset, $scrollDelta');
            return true;
          }());
          controller.onChartZoomUpdate(GestureData.zoom(
            offset,
            delta: Offset(
              scrollDelta.dx,
              scrollDelta.dy.sign * scaledDecelerate(dy),
            ),
          ));
          return;
        }

        /// 横向缩放图表(scale)，与触摸缩放手势一致受 [GestureConfig.enableScale] 约束.
        if (gestureConfig.enableScale) {
          if (_scaleData == null) {
            /// 转换滚轮为touch设备的缩放速度[0 ~ 1 ~ n]
            _scaleData = GestureData.signal(
              offset,
              position: _resolveScalePosition(offset),
            );

            /// 由于没有开始结束事件回调, 此处1秒后将[_scaleData]置空, 重新开始测量位置.
            Future.delayed(const Duration(milliseconds: 1000), () {
              assert(() {
                logd(
                  'onPointerSignal V>Scale clean _scaleData${_scaleData?.initPosition}',
                );
                return true;
              }());
              _scaleData?.end();
              _scaleData = null;
              controller.onChartScaleEnd();

              /// 检查并加载更多蜡烛数据
              controller.checkAndLoadMoreCandlesWhenPanEnd();
            });
          }

          final newScale = scaledSingal(
            scrollDelta.dy,
            gestureConfig.scaleSpeed,
          );

          assert(() {
            logd('onPointerSignal V>Scale $offset, $scrollDelta, $newScale');
            return true;
          }());

          if (newScale != null) {
            stopPositionAnimation();
            _scaleData!.update(offset, newScale: newScale);
            controller.onChartScale(_scaleData!);
          }
        }
      } else if (dx > 1 && dx > dy) {
        // 说明可能是触控板的双指横向移动操作
        assert(() {
          logd('onPointerSignal H> $offset, $scrollDelta,');
          return true;
        }());
      }
    }
  }

  /// 解析缩放的锚定位置：[ScalePosition.auto] 按 [offset] 所在的三分之一区域就近锚定。
  ///
  /// 不缓存：非触摸端每次滚轮或触控板手势都是独立的一段，没有触摸端那种「一轮 pointer
  /// session 内锚点不得改变」的约束。
  ScalePosition _resolveScalePosition(Offset offset) {
    final configured = gestureConfig.scalePosition;
    if (configured != ScalePosition.auto) return configured;
    final third = controller.canvasRect.width / 3;
    if (offset.dx < third) return ScalePosition.left;
    if (offset.dx > third + third) return ScalePosition.right;
    return ScalePosition.middle;
  }

  /// 鼠标Hover进入事件.
  void onEnter(PointerEnterEvent event) {
    if (controller.isStartDragGrid) return;
    final offset = event.localPosition;
    // if (!controller.canvasRect.include(offset)) return;

    if (_hoverData != null && controller.isDrawVisible && drawState.isOngoing) {
      logd('onEnter draw: $event');
      if (drawState.object?.pointer != null) {
        drawState.object!.onUpdateDrawPoint(drawState.object!.pointer!, offset);
      }
      _hoverData!.update(offset);
    } else {
      logd('onEnter cross: $event');
      _hoverData = GestureData.hover(offset);
      controller.onCrossStart(_hoverData!, force: true);
    }
  }

  /// 鼠标Hover事件.
  /// onMouseHover _TransformedPointerHoverEvent#1614b(position: Offset(86.5, 343.6))
  void onHover(PointerHoverEvent event) {
    // if (_hoverData == null) return;
    final offset = event.localPosition;
    _hoverData ??= GestureData.hover(offset);

    if (controller.isDrawVisible && drawState.isOngoing) {
      if (drawState.isEditing) {
        // 已完成的 DrawObject 由平移([_panData])或长按([_longData])事件修正, hover 不参与.
        return;
      }
      final pointer = drawState.pointer;
      if (pointer != null && pointer.offset.isFinite) {
        if (controller.isCrossing) controller.requestCancelCross();
        // final mainRect = controller.mainRect;
        // if (!mainRect.include(offset)) {
        //   offset = offset.clamp(mainRect);
        // }
        _hoverData!.update(offset);
        controller.onDrawUpdate(_hoverData!);
        return;
      }
    } else if (gestureConfig.enableZoom && controller.chartZoomSlideBarRect.include(offset)) {
      controller.requestCancelCross();
      setCursorToZoom();
      return;
    }

    if (!controller.isCrossing) {
      setCursorToPrecise();
      controller.onCrossStart(_hoverData!, force: true);
    } else {
      _hoverData!.update(offset);
      controller.onCrossUpdate(_hoverData!);
    }
  }

  /// 鼠标Hover退出事件.
  void onExit(PointerExitEvent event) {
    controller.requestCancelCross();
    logd('onExit $event');

    if (_hoverData == null) return;
    if (controller.isDrawVisible && drawState.isOngoing) {
      // 当处在绘制中状态时, 不清理hover指针数据.
      return;
    }
    _hoverData?.end();
    _hoverData = null;
  }

  /// 点击
  void onTapUp(TapUpDetails details) {
    if (controller.isDrawVisible) {
      switch (drawState) {
        case Drawing():
          final offset = drawState.pointerOffset ?? details.localPosition;
          if (offset.isFinite) {
            logd('onTapUp draw(drawing) confirm pointer:$offset');
            _hoverData = GestureData.tap(offset);
            controller.onDrawConfirm(_hoverData!);
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
            _hoverData = GestureData.tap(offset);
            controller.onDrawConfirm(_hoverData!);
            if (!controller.isCrossing) {
              controller.onCrossStart(_hoverData!);
            }
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

  /// 放弃当前 PaintObject 拖动并清理其手势数据. 未在拖动时为空操作.
  void _cancelObjectDragging() {
    if (!_isObjectDragging) return;
    _isObjectDragging = false;
    controller.onPaintObjectDragCancel();
    _panData?.end();
    _panData = null;
    setCursorToPrecise();
  }

  /// 平移开始.
  void onPanStart(DragStartDetails details) {
    if (_panData != null && !_panData!.isEnd) {
      // 如果上次平移或缩放, 还没有结束, 不允许开始.
      logd('onPanStart Currently still panning, ignore!!!');
      return;
    }
    // 由 [DragStartBehavior.down] 保证: 这是 PointerDown 位置, 不含手势识别前的位移.
    final position = details.localPosition;
    if (controller.isDrawVisible && drawState.isOngoing) {
      if (drawState.isDrawing) {
        // 未完成的暂不允许移动
        return;
      }
      if (drawState.object?.lock == true) return;
      logd('onPanStart draw > details:$details');
      _panData = GestureData.pan(position);
      final result = controller.onDrawMoveStart(_panData!);
      if (!result) {
        _panData?.end();
        _panData = null;
      }
    } else if (controller.onPaintObjectDragStart(position)) {
      // PaintObject 优先按落点认领拖动.
      logd('onPanStart paintObject drag local:$position');
      stopPositionAnimation();
      setCursorToGrabbing();
      _panData = GestureData.pan(position);
      _isObjectDragging = true;
    } else {
      logd('onPanStart pan local:$position');
      stopPositionAnimation();
      // 缩放态下同一条平移路径会额外消费 dy, 但那由 [ChartBinding.onChartMove] 按
      // `isChartZooming` 判断, 与手势数据的类型无关; 这里只换光标提示可拖动的方向。
      if (controller.isChartZooming) {
        setCursorToMove();
      } else {
        setCursorToGrabbing();
      }
      _panData = GestureData.pan(position);
    }
  }

  /// 平移中...
  void onPanUpdate(DragUpdateDetails details) {
    if (_panData == null) {
      logd('onPanUpdate panData is empty! details:$details');
      return;
    }
    // assert(() {
    //   logd('onPanUpdate move> ${DateTime.now().millisecond} > $details');
    //   return true;
    // }());
    if (_isObjectDragging) {
      // 不做区域钳制: 是否限制在图表内由绘制对象自行决定.
      _panData!.update(details.localPosition);
      controller.onPaintObjectDragUpdate(_panData!);
    } else if (controller.isDrawVisible && drawState.isOngoing) {
      _panData!.update(details.localPosition.clamp(controller.mainRect));
      controller.onDrawMoveUpdate(_panData!);
    } else {
      _panData!.update(details.localPosition.clamp(controller.canvasRect));
      controller.onChartMove(
        _panData!,
        gestureConfig.tolerance.effectivePanSmoothFactor,
      );
      controller.onCrossUpdate(_panData!);
    }
  }

  /// 平移结束.
  void onPanEnd(DragEndDetails details) {
    if (_panData == null) {
      logd('onPanEnd panData is empty! details:$details');
      return;
    }

    if (_isObjectDragging) {
      logd('onPanEnd paintObject drag end.');
      _isObjectDragging = false;
      controller.onPaintObjectDragEnd();
      _panData?.end();
      _panData = null;
      setCursorToPrecise();
      // 拖动的是绘制对象而非蜡烛图: 不做惯性平移, 也不检查 loadMore.
      return;
    }

    if (controller.isDrawVisible && drawState.isOngoing) {
      controller.onDrawMoveEnd();
      _panData?.end();
      _panData = null;
      return;
    } else if (_panData!.isMove) {
      _panData?.end();
      _panData = null;
      controller.onPanEnd();
      setCursorToPrecise();
      return;
    }

    // <0: 从右向左滑动; >0: 从左向右滑动.
    final velocity = details.velocity.pixelsPerSecond.dx;
    final tolerance = gestureConfig.tolerance;
    final panDistance = velocity * tolerance.distanceFactor;
    final panDuration = calcuInertialPanDuration(panDistance, maxDuration: tolerance.maxDuration);
    final canInertialPan = gestureConfig.enableInertialPan &&
        controller.klineData.isNotEmpty &&
        !(velocity < 0 && !controller.canPanRTL) &&
        !(velocity > 0 && !controller.canPanLTR) &&
        // 平移距离为 0 或不足 1ms, 无需继续平移.
        panDistance.abs() >= precisionError &&
        panDuration > 1;

    if (!canInertialPan) {
      logd('onPanEnd no inertial movement, velocity:$velocity distance:$panDistance');
      _panData?.end();
      _panData = null;
      controller.onPanEnd();
      setCursorToPrecise();
      controller.checkAndLoadMoreCandlesWhenPanEnd();
      return;
    }

    controller.checkAndLoadMoreCandlesWhenPanEnd(panDistance: panDistance, panDuration: panDuration);
    logi('onPanEnd inertial movement, velocity:$velocity distance:$panDistance duration:$panDuration');

    animateToPosition(
      _panData!.offset.dx,
      _panData!.offset.dx + panDistance,
      panDuration: Duration(milliseconds: panDuration),
      tolerance: tolerance,
      onCompleted: () {
        _panData?.end();
        _panData = null;
        controller.onPanEnd();

        setCursorToPrecise();
      },
    );
  }

  void onPointerPanZoomStart(PointerPanZoomStartEvent event) {
    final offset = event.localPosition;
    if (!controller.canvasRect.include(offset)) {
      logw('onPointerPanZoomStart $offset is not in the canvas.');
      _scaleData?.end();
      _scaleData = null;
      return;
    }

    if (gestureConfig.enableScale) {
      stopPositionAnimation();
      logd('onPointerPanZoomStart $event > ${event.localPosition}');
      _scaleData = GestureData.scale(
        offset,
        position: _resolveScalePosition(offset),
      );
    }
  }

  /// 触控板事件更新
  /// [Flutter Trackpad Gestures](https://docs.google.com/document/d/1oRvebwjpsC3KlxN1gOYnEdxtNpQDYpPtUFAkmTUe-K8/edit?resourcekey=0-pt4_T7uggSTrsq2gWeGsYQ)
  /// 支持平台: iPadOs, MacOs, ChromeOs, Windows, Linux,
  /// 注: Web不支持.
  /// [PointerPanZoomUpdateEvent] 将包含一些额外字段，用于表示平移、缩放和旋转手势的组合。
  ///   手势的总平移偏移量
  ///   final Offset pan;
  ///   自上一个事件以来平移偏移量的变化量
  ///   final Offset panDelta;
  ///   手势的缩放比例
  ///   final double scale;
  ///   到目前为止手势旋转的弧度量
  ///   final double rotation;
  void onPointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (_scaleData == null) {
      logd('onPointerPanZoomUpdate scaleData is empty! $event ${event.scale}');
      return;
    }

    if (gestureConfig.enableScale && _scaleData!.isScale) {
      final newScale = scaledDecelerate(event.scale);
      final change = event.scale - _scaleData!.scale;
      // assert(() {
      //   logd(
      //     "onPointerPanZoomUpdate scale ${event.scale}>$newScale change:$change",
      //   );
      //   return true;
      // }());
      if (change.abs() > 0.01) {
        _scaleData!.update(
          event.localPosition,
          newScale: newScale,
        );
        controller.onChartScale(_scaleData!);
      }
    }
  }

  void onPointerPanZoomEnd(PointerPanZoomEndEvent event) {
    if (_scaleData == null) {
      logd('onPointerPanZoomEnd scaledata is empty! > event:$event');
      return;
    }

    if (_scaleData!.isScale) {
      logd('onPointerPanZoomEnd scale. ${event.localPosition}');
      _scaleData?.end();
      _scaleData = null;
      controller.onChartScaleEnd();
    }
  }

  /// 长按
  void onLongPressStart(LongPressStartDetails details) {
    if (!gestureConfig.enableLongPress) {
      logd('onLongPressStart ignore! > longPress disabled');
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
      } else {
        setCursorToNone();
      }
    } else if (controller.onGridResizeStart(details.localPosition)) {
      _longData = GestureData.long(details.localPosition);
      controller.requestCancelCross();
      setCursorToNone();
    } else {
      logd('onLongPressStart cross > details:$details');
      controller.requestCancelCross();
      _longData = GestureData.long(details.localPosition);
      final result = controller.onCrossStart(_longData!);
      if (!result) {
        _longData?.end();
        _longData = null;
      } else {
        setCursorToNone();
      }
    }
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    final data = _longData;
    if (!gestureConfig.enableLongPress || data == null) return;
    // 三条分支共用同一份长按数据, 位置更新与分派无关, 提到分支之前.
    data.update(details.localPosition);
    if (controller.isDrawVisible && drawState.isOngoing) {
      controller.onDrawMoveUpdate(data);
    } else if (controller.isStartDragGrid) {
      controller.onGridResizeUpdate(data);
    } else {
      controller.onCrossUpdate(data);
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
      if (drawState.isEditing) setCursorToClick();
    } else if (controller.isStartDragGrid) {
      controller.onGridResizeEnd();
      setCursorToPrecise();
    } else {
      // 长按结束, 尝试取消Cross事件.
      controller.requestCancelCross();
      setCursorToPrecise();
    }

    _longData?.end();
    _longData = null;
  }

  void onPointerCancel(PointerCancelEvent event) {
    logd('onPointerCancel $event');
    // 回滚正在进行的 PaintObject 拖动, 避免 [onPanEnd] 把中断当成提交.
    _cancelObjectDragging();
  }

  void onKeyEvent(KeyEvent event) {
    if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        // ESC按键
        logd('onKeyEvent > ESC');
        if (drawState.isOngoing) {
          controller.prepareDraw(force: true);
        }
      }
    }
  }
}
