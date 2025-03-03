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

import '../config/gesture_config/gesture_config.dart';
import '../extension/geometry_ext.dart';
import '../framework/chart/indicator.dart';
import '../framework/draw/overlay.dart';
import '../framework/logger.dart';
import '../kline_controller.dart';
import '../model/gesture_data.dart';
import '../utils/algorithm_util.dart';

class NonTouchGestureDetector extends StatefulWidget {
  const NonTouchGestureDetector({
    super.key,
    required this.controller,
    this.onDoubleTap,
    this.child,
  });

  final FlexiKlineController controller;
  final GestureTapCallback? onDoubleTap;
  final Widget? child;

  @override
  State<NonTouchGestureDetector> createState() =>
      _NonTouchGestureDetectorState();
}

class _NonTouchGestureDetectorState extends State<NonTouchGestureDetector>
    with TickerProviderStateMixin, KlineLog {
  @override
  String get logTag => 'NonTouchGesture';

  AnimationController? animationController;

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

  final _mouseCursor = ValueNotifier(SystemMouseCursors.precise);

  FlexiKlineController get controller => widget.controller;

  GestureConfig get gestureConfig => widget.controller.gestureConfig;

  DrawState get drawState => controller.drawState;

  void setCursorToPrecise() {
    _mouseCursor.value = SystemMouseCursors.precise;
  }

  void setCursorToZoom() {
    _mouseCursor.value = SystemMouseCursors.resizeUpDown;
  }

  void setCursorToClick() {
    _mouseCursor.value = SystemMouseCursors.click;
  }

  @override
  void initState() {
    super.initState();
    loggerDelegate = controller.loggerDelegate;
    if (gestureConfig.supportKeyboardShortcuts) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        controller.drawStateListener.addListener(() {
          switch (drawState) {
            case Drawing():
              if (!_keyboardFocusNode.hasFocus) {
                _keyboardFocusNode.requestFocus();
              }
            case Editing():
              if (!_keyboardFocusNode.hasFocus) {
                _keyboardFocusNode.requestFocus();
              }
            case Prepared():
              FocusManager.instance.primaryFocus?.unfocus();
            case Exited():
              FocusManager.instance.primaryFocus?.unfocus();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    animationController?.dispose();
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

      // onPointerMove: onPointerMove,
      // onPointerDown: onPointerDown,
      // onPointerCancel: onPointerCancel,
      child: ValueListenableBuilder(
        valueListenable: _mouseCursor,
        builder: (context, cursor, child) => MouseRegion(
          // cursor: SystemMouseCursors.resizeUpDown, //上下缩放
          // cursor: SystemMouseCursors.cell, // 粗十字
          // cursor: SystemMouseCursors.precise, // 细十字
          // cursor: SystemMouseCursors.progress, // wait:指针右下角有加载中.
          cursor: cursor,
          hitTestBehavior: HitTestBehavior.translucent,

          /// Cross平移
          onEnter: onEnter,
          onHover: onHover,
          onExit: onExit,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,

            /// 点击
            onTapUp: onTapUp,

            /// 双击
            onDoubleTap: widget.onDoubleTap,

            /// 按下平移
            onPanStart: onPanStart,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanEnd,

            /// 移动 缩放
            // onScaleStart: onScaleStart,
            // onScaleUpdate: onScaleUpdate,
            // onScaleEnd: onScaleEnd,
            // trackpadScrollCausesScale: true,

            /// 长按
            onLongPressStart: onLongPressStart,
            onLongPressMoveUpdate: onLongPressMoveUpdate,
            onLongPressEnd: onLongPressEnd,

            /// 子组件
            child: widget.child,
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
        if (controller.chartZoomSlideBarRect.include(offset)) {
          // 如果命中ZommSlideBar区域, 即代表要进行缩放图表
          if (!controller.isStartZoomChart &&
              controller.onChartZoomStart(offset, false)) {
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
            delta: scrollDelta,
          ));
          return;
        }

        /// 横向缩放图表(scale)
        if (_scaleData == null) {
          ScalePosition position = gestureConfig.scalePosition;
          if (position == ScalePosition.auto) {
            final third = controller.canvasRect.width / 3;
            if (offset.dx < third) {
              position = ScalePosition.left;
            } else if (offset.dx > (third + third)) {
              position = ScalePosition.right;
            } else {
              position = ScalePosition.middle;
            }
          }

          /// 转换滚轮为touch设备的缩放速度[0 ~ 1 ~ n]
          _scaleData = GestureData.signal(
            offset,
            position: position,
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
          _scaleData!.update(offset, newScale: newScale);
          controller.onChartScale(_scaleData!);
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

  /// 鼠标Hover进入事件.
  void onEnter(PointerEnterEvent event) {
    final offset = event.localPosition;
    if (!controller.canvasRect.include(offset)) return;

    if (_hoverData != null &&
        controller.isDrawVisibility &&
        drawState.isOngoing) {
      logd('onEnter draw: $event');
      if (drawState.object?.pointer != null) {
        drawState.object!.onUpdateDrawPoint(drawState.object!.pointer!, offset);
      }
      _hoverData!.update(offset);
    } else {
      logd('onEnter cross: $event');
      _hoverData = GestureData.hover(offset);
      setCursorToPrecise();
      controller.onCrossStart(_hoverData!, force: true);
    }
  }

  /// 鼠标Hover事件.
  /// onMouseHover _TransformedPointerHoverEvent#1614b(position: Offset(86.5, 343.6))
  void onHover(PointerHoverEvent event) {
    if (_hoverData == null) return;
    Offset offset = event.localPosition;

    if (controller.isDrawVisibility && drawState.isOngoing) {
      if (drawState.isEditing) {
        /// 已完成的DrawObject通过平移[_panScaleData]或长按[_longData]事件进行修正.
        setCursorToClick();
        return;
      }
      final pointer = drawState.pointer;
      if (pointer != null && pointer.offset.isFinite) {
        if (controller.isCrossing) controller.cancelCross();
        // final mainRect = controller.mainRect;
        // if (!mainRect.include(offset)) {
        //   offset = offset.clamp(mainRect);
        // }
        setCursorToPrecise();
        _hoverData!.update(offset);
        controller.onDrawUpdate(_hoverData!);
        return;
      }
    } else if (controller.chartZoomSlideBarRect.include(offset)) {
      controller.cancelCross();
      setCursorToZoom();
      return;
    }

    _hoverData!.update(offset);
    if (!controller.isCrossing) {
      setCursorToPrecise();
      controller.onCrossStart(_hoverData!, force: true);
    } else {
      controller.onCrossUpdate(_hoverData!);
    }
  }

  /// 鼠标Hover退出事件.
  void onExit(PointerExitEvent event) {
    controller.cancelCross();
    logd('onExit $event');

    if (_hoverData == null) return;
    if (controller.isDrawVisibility && drawState.isOngoing) {
      // 当处在绘制中状态时, 不清理hover指针数据.
      return;
    }
    _hoverData?.end();
    _hoverData = null;
  }

  /// 点击
  void onTapUp(TapUpDetails details) {
    if (controller.isDrawVisibility) {
      switch (drawState) {
        case Drawing():
          final offset = drawState.pointerOffset ?? details.localPosition;
          if (offset.isFinite) {
            logd("onTapUp draw(drawing) confirm pointer:$offset");
            _hoverData = GestureData.tap(offset);
            controller.onDrawConfirm(_hoverData!);
            if (drawState.isDrawing && controller.isCrossing) {
              controller.cancelCross(); // 如果仍在绘制中, 但是又处在crossing中时, 主动取消cross
            }
          }
          return;
        case Editing():
          final offset = details.localPosition;
          final object = controller.hitTestDrawObject(offset);
          if (object != null && object != drawState.object) {
            logd("onTapUp draw(editing) switch object:$object");
            controller.onDrawSelect(object);
          } else {
            logd("onTapUp draw(editing) confirm offset:$offset");
            _hoverData = GestureData.tap(offset);
            controller.onDrawConfirm(_hoverData!);
            if (!controller.isCrossing) {
              setCursorToPrecise();
              controller.onCrossStart(_hoverData!);
            }
          }
          return;
        case Exited():
          if (controller.drawConfig.allowSelectWhenExit) {
            final object = controller.hitTestDrawObject(details.localPosition);
            if (object != null) {
              logd("onTapUp draw(exited) select object:$object");
              controller.onDrawSelect(object);
              return;
            }
          }
          break;
        case Prepared():
          final object = controller.hitTestDrawObject(details.localPosition);
          if (object != null) {
            logd("onTapUp draw(prepared) select object:$object");
            controller.onDrawSelect(object);
            return;
          }
          break;
      }
    }

    // 这里检测是否命中指标图定制位置
    final ret = controller.onTap(details.localPosition);
    if (ret) {
      logd("onTapUp handled! :$details");
      return;
    }
  }

  /// 平移开始.
  void onPanStart(DragStartDetails details) {
    if (_panData != null && !_panData!.isEnd) {
      // 如果上次平移或缩放, 还没有结束, 不允许开始.
      logd('onPanStart Currently still panning, ignore!!!');
      return;
    }
    final position = details.localPosition;
    if (controller.isDrawVisibility && drawState.isOngoing) {
      if (drawState.isDrawing) {
        // 未完成的暂不允许移动
        return;
      }
      if (drawState.object?.lock == true) return;
      logd("onPanStart draw > details:$details");
      _panData = GestureData.pan(position);
      final result = controller.onDrawMoveStart(_panData!);
      if (!result) {
        _panData?.end();
        _panData = null;
      }
    } else {
      logd('onPanStart pan local:$position');
      if (controller.isStartZoomChart) {
        _panData = GestureData.move(position);
      } else {
        _panData = GestureData.pan(position);
      }
    }
  }

  /// 平移中...
  void onPanUpdate(DragUpdateDetails details) {
    if (_panData == null) {
      logd('onPanUpdate panData is empty! details:$details');
      return;
    }
    // assert(() {
    //   logd('onPanUpdate $details');
    //   return true;
    // }());
    if (controller.isDrawVisibility && drawState.isOngoing) {
      _panData!.update(details.localPosition.clamp(controller.mainRect));
      controller.onDrawMoveUpdate(_panData!);
    } else {
      _panData!.update(details.localPosition.clamp(controller.canvasRect));
      controller.onChartMove(_panData!);
      controller.onCrossUpdate(_panData!);
    }
  }

  /// 平移结束.
  void onPanEnd(DragEndDetails details) {
    if (_panData == null) {
      logd("onPanEnd panData is empty! details:$details");
      return;
    }

    if (controller.isDrawVisibility && drawState.isOngoing) {
      controller.onDrawMoveEnd();
      _panData?.end();
      _panData = null;
      return;
    } else if (_panData!.isMove) {
      _panData?.end();
      _panData = null;
    }

    // <0: 负数代表从右向左滑动.
    // >0: 正数代表从左向右滑动.
    final velocity = details.velocity.pixelsPerSecond.dx;

    if (!gestureConfig.isInertialPan ||
        controller.curKlineData.isEmpty ||
        (velocity < 0 && !controller.canPanRTL) ||
        (velocity > 0 && !controller.canPanLTR)) {
      logd("onPanEnd currently can not pan!");
      _panData?.end();
      _panData = null;

      /// 检查并加载更多蜡烛数据
      controller.checkAndLoadMoreCandlesWhenPanEnd();
      return;
    }

    final tolerance = controller.gestureConfig.tolerance;

    /// 确认继续平移时间 (利用log指数函数特点: 随着自变量velocity的增大，函数值的增长速度逐渐减慢)
    /// 测试当限定参数[tolerance.maxDuration]等于1000(1秒时), [velocity]带入后[duration]变化为:
    /// 100000 > 1151.29; 10000 > 921.03; 9000 > 910.49; 5000 > 851.71; 2000 > 760.09; 800 > 668.46; 100 > 460.51
    final panDuration = calcuInertialPanDuration(
      velocity,
      maxDuration: tolerance.maxDuration,
    );

    /// 惯性平移的最大距离.
    final panDistance = velocity * tolerance.distanceFactor;

    // 平移距离为0 或者 不足1ms, 无需继续平移
    if (panDistance == 0 || panDuration <= 1) {
      logd("onPanEnd currently not need for inertial movement!");
      _panData?.end();
      _panData = null;

      /// 检查并加载更多蜡烛数据
      controller.checkAndLoadMoreCandlesWhenPanEnd();
      return;
    }

    /// 检查并加载更多蜡烛数据
    controller.checkAndLoadMoreCandlesWhenPanEnd(
      panDistance: panDistance,
      panDuration: panDuration,
    );

    logi('onPanEnd inertial movement, velocity:$velocity => $tolerance');

    animationController?.dispose();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: panDuration),
    );

    final animation = Tween(begin: 0.0, end: panDistance)
        .chain(CurveTween(curve: tolerance.curve))
        .animate(animationController!);

    final initDx = _panData!.offset.dx;
    animation.addListener(() {
      // logd('onPanEnd animation.value:${animation.value}');
      if (_panData != null) {
        _panData!.update(Offset(
          initDx + animation.value,
          _panData!.offset.dy,
        ));
        controller.onChartMove(_panData!);
      }
    });

    animationController?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _panData?.end();
        _panData = null;
      }
    });

    animationController?.forward();
  }

  void onPointerPanZoomStart(PointerPanZoomStartEvent event) {
    final offset = event.localPosition;
    if (!controller.canvasRect.include(offset)) {
      logw('onPointerPanZoomStart $offset is not in the canvas.');
      _scaleData?.end();
      _scaleData = null;
    }

    logd('onPointerPanZoomStart $event > ${event.localPosition}');
    ScalePosition position = gestureConfig.scalePosition;
    if (position == ScalePosition.auto) {
      final third = controller.canvasRect.width / 3;
      if (offset.dx < third) {
        position = ScalePosition.left;
      } else if (offset.dx > (third + third)) {
        position = ScalePosition.right;
      } else {
        position = ScalePosition.middle;
      }
    }
    _scaleData = GestureData.scale(
      offset,
      position: position,
    );
  }

  /// 触控板事件更新
  /// [Flutter Trackpad Gestures](https://docs.google.com/document/d/1oRvebwjpsC3KlxN1gOYnEdxtNpQDYpPtUFAkmTUe-K8/edit?resourcekey=0-pt4_T7uggSTrsq2gWeGsYQ)
  /// 支持平台: iPadOs, MacOs, ChromeOs, Windows, Linux,
  /// 注: Web不支持.
  /// [PointerPanZoomUpdateEvent] 将包含一些额外字段，用于表示平移、缩放和旋转手势的组合。
  /// /// 手势的总平移偏移量
  /// final Offset pan;
  /// /// 自上一个事件以来平移偏移量的变化量
  /// final Offset panDelta;
  /// /// 手势的缩放比例
  /// final double scale;
  /// /// 到目前为止手势旋转的弧度量
  /// final double rotation;
  void onPointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (_scaleData == null) {
      logd("onPointerPanZoomUpdate scaleData is empty! $event ${event.scale}");
      return;
    }

    if (_scaleData!.isScale) {
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
      logd("onPointerPanZoomEnd scaledata is empty! > event:$event");
      return;
    }

    if (_scaleData!.isScale) {
      logd("onPointerPanZoomEnd scale. ${event.localPosition}");
      _scaleData?.end();
      _scaleData = null;
      controller.onChartScaleEnd();
    }
  }

  /// 长按
  ///
  /// 如果当前正在crossing中时, 不触发后续的长按逻辑.
  void onLongPressStart(LongPressStartDetails details) {
    if (!gestureConfig.supportLongPress) {
      logd("onLongPressStart ignore! > crossing:${controller.isCrossing}");
      return;
    }

    if (controller.isDrawVisibility && drawState.isOngoing) {
      if (drawState.isDrawing) {
        // 未完成的暂不允许移动
        return;
      }
      if (drawState.object?.lock == true) return;
      logd("onLongPressStart draw > details:$details");
      _longData = GestureData.long(details.localPosition);
      final result = controller.onDrawMoveStart(_longData!);
      if (!result) {
        _longData?.end();
        _longData = null;
      } else {
        setCursorToPrecise();
      }
    } else if (controller.onGridMoveStart(details.localPosition)) {
      _longData = GestureData.long(details.localPosition);
      controller.cancelCross();
    } else {
      logd("onLongPressStart cross > details:$details");
      controller.cancelCross();
      _longData = GestureData.long(details.localPosition);
      setCursorToPrecise();
      final result = controller.onCrossStart(_longData!);
      if (!result) {
        _longData?.end();
        _longData = null;
      }
    }
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!gestureConfig.supportLongPress || _longData == null) {
      return;
    }
    // assert(() {
    //   logd("onLongPressMoveUpdate > details:$details");
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
    if (!gestureConfig.supportLongPress || _longData == null) {
      logd("onLongPressEnd ignore! > details:$details");
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

  void onScaleStart(ScaleStartDetails details) {
    logd('onScaleStart $details');
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    logd('onScaleUpdate $details');
  }

  void onScaleEnd(ScaleEndDetails details) {
    logd('onScaleEnd $details');
  }

  void onPointerMove(PointerMoveEvent event) {
    logd('onPointerMove $event');
  }

  void onPointerDown(PointerDownEvent event) {
    logd('onPointerDown $event');
  }

  void onPointerCancel(PointerCancelEvent event) {
    logd('onPointerCancel $event');
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
