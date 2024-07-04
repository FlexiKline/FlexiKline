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
import 'package:flutter/material.dart';

import '../config/gesture_config/gesture_config.dart';
import '../extension/geometry_ext.dart';
import '../framework/common.dart';
import '../framework/logger.dart';
import '../kline_controller.dart';
import '../model/gesture_data.dart';
import '../utils/algorithm_util.dart';

class TouchGestureDetector extends StatefulWidget {
  const TouchGestureDetector({
    super.key,
    required this.controller,
    this.onDoubleTap,
    required this.child,
  });

  final FlexiKlineController controller;
  final GestureTapCallback? onDoubleTap;
  final Widget child;

  @override
  State<TouchGestureDetector> createState() => _TouchGestureDetectorState();
}

class _TouchGestureDetectorState extends State<TouchGestureDetector>
    with TickerProviderStateMixin, KlineLog {
  AnimationController? animationController;

  /// 平移/缩放监听数据
  GestureData? _panScaleData;

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

  @override
  void initState() {
    super.initState();
    loggerDelegate = controller.loggerDelegate;
    // widget.controller.isAllowCrossGestureCoexist = true;
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      child: GestureDetector(
        /// 点击
        onTapUp: onTapUp,

        /// 双击
        onDoubleTap: widget.onDoubleTap,

        /// 移动 缩放
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        onScaleEnd: onScaleEnd,

        /// 长按
        onLongPressStart: onLongPressStart,
        onLongPressMoveUpdate: onLongPressMoveUpdate,
        onLongPressEnd: onLongPressEnd,

        /// 子组件
        child: widget.child,
      ),
    );
  }

  // void onPointerDown(PointerDownEvent event) {}

  /// 原始移动
  /// 当原始移动时, 当前如果正处在crossing中, 发生冲突, 清理手势竞技场, 响应Cross平移事件
  void onPointerMove(PointerMoveEvent event) {
    if (controller.isCrossing) {
      if (!isSweeped) {
        logi(
          'onPointerMove currently in crossing, need clear the gesture arena!',
        );
        isSweeped = true;
        GestureBinding.instance.gestureArena.sweep(event.pointer);
      }

      if (_tapData == null) return;
      // logd('onPointerMove position:${event.position}, delta:${event.delta}');
      Offset newOffset = _tapData!.offset + event.delta;
      if (!controller.canvasRect.include(newOffset)) {
        newOffset = newOffset.clamp(controller.canvasRect);
      }
      _tapData!.update(newOffset);
      controller.updateCross(_tapData!);
    }
  }

  void onPointerUp(PointerUpEvent event) {
    if (isSweeped) {
      isSweeped = false;
    }
  }

  void onPointerCancel(PointerCancelEvent event) {
    if (isSweeped) {
      isSweeped = false;
    }
  }

  /// 点击
  ///
  void onTapUp(TapUpDetails details) {
    logd("onTapUp details:$details");
    _tapData = GestureData.tap(details.localPosition);
    final ret = controller.startCross(_tapData!);
    if (!ret) {
      _tapData?.end();
      _tapData = null;
    }
  }

  /// 移动 缩放
  ///
  void onScaleStart(ScaleStartDetails details) {
    if (_panScaleData != null && !_panScaleData!.isEnd) {
      // 如果上次平移或缩放, 还没有结束, 不允许开始.
      logd('onPanStart Currently still panning or zooming, ignore!!!');
      return;
    }

    if (_panScaleData?.isScale == true || details.pointerCount > 1) {
      ScalePosition position =
          _panScaleData?.initPosition ?? gestureConfig.scalePosition;
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
      assert(() {
        logd("onScaleStart scale $position focal:${details.localFocalPoint}");
        return true;
      }());
      _panScaleData = GestureData.scale(
        details.localFocalPoint,
        position: position,
      );
    } else {
      assert(() {
        logd("onScaleStart pan focal:${details.localFocalPoint}");
        return true;
      }());
      _panScaleData = GestureData.pan(details.localFocalPoint);
    }
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    if (_panScaleData == null) {
      logd("onScaleUpdate panScaleData is empty! details:$details");
      return;
    }

    if (_panScaleData!.isPan) {
      _panScaleData!.update(
        details.localFocalPoint.clamp(controller.canvasRect),
        newScale: details.scale,
      );
      controller.moveChart(_panScaleData!);
    } else if (_panScaleData!.isScale) {
      final newScale = scaledDecelerate(details.scale);
      final change = details.scale - _panScaleData!.scale;
      assert(() {
        logd("onScaleUpdate scale ${details.scale}>$newScale change:$change");
        return true;
      }());
      if (change.abs() > 0.01) {
        _panScaleData!.update(
          details.localFocalPoint,
          newScale: newScale,
        );
        controller.scaleChart(_panScaleData!);
      }
    }
  }

  void onScaleEnd(ScaleEndDetails details) {
    if (_panScaleData == null) {
      logd("onScaleEnd panScaledata and ticker is empty! > details:$details");
      return;
    }

    if (_panScaleData!.isScale) {
      logd("onScaleEnd scale. ${details.pointerCount}");
      if (details.pointerCount <= 0) {
        _panScaleData?.end();
        _panScaleData = null;
      }
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
      // logd('onScaleEnd animation.value:${animation.value}');
      if (_panScaleData != null) {
        _panScaleData!.update(Offset(
          initDx + animation.value,
          _panScaleData!.offset.dy,
        ));
        controller.moveChart(_panScaleData!);
      }
    });

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
    if (!gestureConfig.supportLongPressOnTouchDevice || controller.isCrossing) {
      logd("onLongPressStart ignore! > crossing:${controller.isCrossing}");
      return;
    }
    logd("onLongPressStart > details:$details");
    _longData = GestureData.long(details.localPosition);
    controller.startCross(_longData!);
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!gestureConfig.supportLongPressOnTouchDevice || _longData == null) {
      return;
    }
    assert(() {
      logd("onLongPressMoveUpdate > details:$details");
      return true;
    }());
    _longData!.update(details.localPosition);
    controller.updateCross(_longData!);
  }

  void onLongPressEnd(LongPressEndDetails details) {
    if (!gestureConfig.supportLongPressOnTouchDevice || _longData == null) {
      logd("onLongPressEnd ignore! > details:$details");
      return;
    }
    logd("onLongPressEnd details:$details");
    // 长按结束, 尝试取消Cross事件.
    controller.cancelCross();
    _longData?.end();
    _longData = null;
  }
}
