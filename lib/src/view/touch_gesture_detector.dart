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

import '../config/gesture_config/gesture_config.dart';
import '../extension/geometry_ext.dart';
import '../extension/functions_ext.dart';
import '../framework/chart/indicator.dart';
import '../framework/draw/overlay.dart';
import '../framework/logger.dart';
import '../kline_controller.dart';
import '../model/gesture_data.dart';
import '../utils/algorithm_util.dart';

class TouchGestureDetector extends StatefulWidget {
  const TouchGestureDetector({
    super.key,
    required this.controller,
    this.onDoubleTap,
    // this.child,
  });

  final FlexiKlineController controller;
  final GestureTapCallback? onDoubleTap;
  // @Deprecated('无用, 会影响手势响应范围')
  // final Widget? child;

  @override
  State<TouchGestureDetector> createState() => _TouchGestureDetectorState();
}

class _TouchGestureDetectorState extends State<TouchGestureDetector>
    with TickerProviderStateMixin, KlineLog {
  AnimationController? animationController;

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
  bool isSweeped = false;

  @override
  String get logTag => 'TouchGesture';

  FlexiKlineController get controller => widget.controller;

  GestureConfig get gestureConfig => widget.controller.gestureConfig;

  DrawState get drawState => controller.drawState;

  @override
  void initState() {
    super.initState();
    loggerDelegate = controller.loggerDelegate;
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

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

        /// 子组件
        child: ValueListenableBuilder(
          valueListenable: controller.canvasSizeChangeListener,
          builder: (context, canvasSize, child) => SizedBox(
            width: canvasSize.width,
            height: canvasSize.height,
            child: Stack(children: [
              ValueListenableBuilder(
                valueListenable: controller.chartZoomSlideBarRectListener,
                builder: (context, rect, child) => Positioned.fromRect(
                  rect: rect,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragDown: onVerticalDragDown,
                    onVerticalDragStart: onVerticalDragStart,
                    onVerticalDragUpdate: onVerticalDragUpdate.throttleOnFps,
                    onVerticalDragEnd: onVerticalDragEnd,
                    onVerticalDragCancel: onVerticalDragEnd,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void onPointerDown(PointerDownEvent event) {
    final position = event.localPosition;
    if (controller.isDrawVisibility && drawState.isOngoing) {
      // TODO: 优化Drawing的处理
    } else if (controller.isCrossing) {
      // TODO: 优化Crossing的处理
    } else if (_zoomData == null &&
        controller.isStartZoomChart &&
        controller.mainRect.include(position)) {
      logd("onPointerDown position:$position");
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
          logi(
            'onPointerMove currently in drawing, need clear the gesture arena!',
          );
          isSweeped = true;
          GestureBinding.instance.gestureArena.sweep(event.pointer);
          if (pointerOffset.isFinite) {
            _tapData = GestureData.pan(pointerOffset);
          }
        }

        if (_tapData == null) return;
        Offset newOffset = _tapData!.offset + event.delta;
        // final mainRect = controller.mainRect;
        // if (!mainRect.include(newOffset)) {
        //   newOffset = newOffset.clamp(mainRect);
        // }
        controller.onDrawUpdate(_tapData!..update(newOffset));
      }
    } else if (controller.isCrossing) {
      if (!isSweeped) {
        logi(
          'onPointerMove currently in crossing, need clear the gesture arena!',
        );
        isSweeped = true;
        GestureBinding.instance.gestureArena.sweep(event.pointer);
      }

      if (_tapData == null) return;
      Offset newOffset = _tapData!.offset + event.delta;
      final canvasRect = controller.canvasRect;
      if (!canvasRect.include(newOffset)) {
        newOffset = newOffset.clamp(canvasRect);
      }
      controller.onCrossUpdate(_tapData!..update(newOffset));
    } else if (controller.isStartZoomChart && _moveData != null) {
      if (!isSweeped) {
        logi(
          'onPointerMove currently in zooming, need clear the gesture arena!',
        );
        isSweeped = true;
        GestureBinding.instance.gestureArena.sweep(event.pointer);
      }

      Offset newOffset = _moveData!.offset + event.delta;
      controller.onChartMove(_moveData!..update(newOffset));
    }
  }

  void onPointerUp(PointerUpEvent event) {
    if (isSweeped) {
      isSweeped = false;
    }
    _moveData = null;
  }

  void onPointerCancel(PointerCancelEvent event) {
    if (isSweeped) {
      isSweeped = false;
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
            logd("onTapUp draw(drawing) confirm pointer:$pointerOffset");
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
            logd("onTapUp draw(editing) switch object:$object");
            controller.onDrawSelect(object);
          } else {
            logd("onTapUp draw(editing) confirm offset:$offset");
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
      }
    }

    if (!controller.isCrossing) {
      // 这里检测是否命中指标图定制位置
      final ret = controller.onTap(details.localPosition);
      if (ret) {
        logd("onTapUp handled! :$details");
        return;
      }
    }

    logd("onTapUp cross start details:$details");
    _tapData = GestureData.tap(details.localPosition);
    final ret = controller.onCrossStart(_tapData!);
    if (!ret) {
      _tapData?.end();
      _tapData = null;
    }
  }

  /// 平移/缩放开始.
  void onScaleStart(ScaleStartDetails details) {
    if (_panScaleData != null && !_panScaleData!.isEnd) {
      // 如果上次平移或缩放, 还没有结束, 不允许开始.
      logd('onPanStart Currently still ongoing, ignore!!!');
      return;
    }

    if (controller.isDrawVisibility && drawState.isOngoing) {
      if (drawState.isDrawing) {
        // 未完成的暂不允许移动
        return;
      }
      if (drawState.object?.lock == true) return;
      logd("onScaleStart draw > details:$details");
      _panScaleData = GestureData.pan(details.localFocalPoint);
      final result = controller.onDrawMoveStart(_panScaleData!);
      if (!result) {
        _panScaleData?.end();
        _panScaleData = null;
      }
    } else if (_panScaleData?.isScale == true || details.pointerCount > 1) {
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
      logd("onScaleStart scale $position focal:${details.localFocalPoint}");
      _panScaleData = GestureData.scale(
        details.localFocalPoint,
        position: position,
      );
    } else {
      logd("onScaleStart pan focal:${details.localFocalPoint}");
      _panScaleData = GestureData.pan(details.localFocalPoint);
    }
  }

  /// 平移/缩放中...
  void onScaleUpdate(ScaleUpdateDetails details) {
    if (_panScaleData == null) {
      logd("onScaleUpdate panScaleData is empty! details:$details");
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
    } else if (_panScaleData!.isPan) {
      _panScaleData!.update(
        details.localFocalPoint.clamp(controller.canvasRect),
        newScale: details.scale,
      );
      controller.onChartMove(_panScaleData!);
    } else if (_panScaleData!.isScale) {
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
    }
  }

  /// 平移/缩放结束.
  void onScaleEnd(ScaleEndDetails details) {
    if (_panScaleData == null) {
      logd("onScaleEnd panScaledata and ticker is empty! > details:$details");
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
      logd("onScaleEnd scale. ${details.pointerCount}");
      if (details.pointerCount <= 0) {
        _panScaleData?.end();
        _panScaleData = null;
      }
      controller.onChartScaleEnd();
      // 如果是scale操作, 不需要惯性平移, 直接return
      // 为了防止缩放后的平移, 延时结束.
      // Future.delayed(const Duration(milliseconds: 200), () {
      //   logd("onScaleEnd scale.");
      //   _panScaleData?.end();
      //   _panScaleData = null;
      // });

      /// 检查并加载更多蜡烛数据
      controller.checkAndLoadMoreCandlesWhenPanEnd();
      return;
    }

    // <0: 负数代表从右向左滑动.
    // >0: 正数代表从左向右滑动.
    final velocity = details.velocity.pixelsPerSecond.dx;

    if (!gestureConfig.isInertialPan ||
        controller.curKlineData.isEmpty ||
        (velocity < 0 && !controller.canPanRTL) ||
        (velocity > 0 && !controller.canPanLTR)) {
      logd("onScaleEnd currently can not pan!");
      _panScaleData?.end();
      _panScaleData = null;

      /// 检查并加载更多蜡烛数据
      controller.checkAndLoadMoreCandlesWhenPanEnd();
      return;
    }

    final tolerance = gestureConfig.tolerance;

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
      logd("onScaleEnd currently not need for inertial movement!");
      _panScaleData?.end();
      _panScaleData = null;

      /// 检查并加载更多蜡烛数据
      controller.checkAndLoadMoreCandlesWhenPanEnd();
      return;
    }

    /// 检查并加载更多蜡烛数据
    controller.checkAndLoadMoreCandlesWhenPanEnd(
      panDistance: panDistance,
      panDuration: panDuration,
    );

    logi('onScaleEnd inertial movement, velocity:$velocity => $tolerance');

    animationController?.dispose();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: panDuration),
    );

    final animation = Tween(begin: 0.0, end: panDistance)
        .chain(CurveTween(curve: tolerance.curve))
        .animate(animationController!);

    final initDx = _panScaleData!.offset.dx;
    animation.addListener(() {
      // logd('onScaleEnd move> ${DateTime.now().millisecond} animation.value:${animation.value}');
      if (_panScaleData != null) {
        _panScaleData!.update(Offset(
          initDx + animation.value,
          _panScaleData!.offset.dy,
        ));
        controller.onChartMove(_panScaleData!);
      }
    }.throttleOnFps);

    animationController?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _panScaleData?.end();
        _panScaleData = null;
      }
    });

    animationController?.forward();
  }

  /// 长按
  ///
  /// 如果当前正在crossing中时, 不触发后续的长按逻辑.
  void onLongPressStart(LongPressStartDetails details) {
    if (!gestureConfig.supportLongPress || controller.isCrossing) {
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
      }
    } else if (!controller.isCrossing && controller.onGridMoveStart(details.localPosition)) {
      logd("onLongPressStart move > details:$details");
      _longData = GestureData.long(details.localPosition);
    } else {
      logd("onLongPressStart cross > details:$details");
      _longData = GestureData.long(details.localPosition);
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

  void onVerticalDragDown(DragDownDetails details) {
    if (controller.onChartZoomStart(details.localPosition)) {
      logd("onVerticalDragDown zoom > details:$details");
      _zoomData = GestureData.zoom(details.localPosition);
    }
  }

  void onVerticalDragStart(DragStartDetails details) {
    if (controller.onChartZoomStart(details.localPosition)) {
      logd("onVerticalDragStart zoom  ${DateTime.now().millisecond} > details:$details");
      if ((controller.isDrawVisibility && drawState.isOngoing) || controller.isCrossing) {
        _zoomData = null;
        return;
      }
      _zoomData = GestureData.zoom(details.localPosition);
    }
  }

  void onVerticalDragUpdate(DragUpdateDetails details) {
    if (_zoomData == null) return;
    // logd('onVerticalDragUpdate zoom ${DateTime.now().millisecond} > $details');
    _zoomData!.update(details.localPosition);
    controller.onChartZoomUpdate(_zoomData!);
  }

  void onVerticalDragEnd([DragEndDetails? details]) {
    logd('onVerticalDragEnd zoom ${DateTime.now().millisecond} > $details');
    controller.onChartZoomEnd();
    _zoomData?.end();
    _zoomData = null;
  }
}
