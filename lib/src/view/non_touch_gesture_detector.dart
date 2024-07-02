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

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../config/gesture_config/gesture_config.dart';
import '../extension/geometry_ext.dart';
import '../framework/common.dart';
import '../framework/logger.dart';
import '../kline_controller.dart';
import '../model/gesture_data.dart';

class NonTouchGestureDetector extends StatefulWidget {
  const NonTouchGestureDetector({
    super.key,
    required this.controller,
    required this.child,
  });

  final FlexiKlineController controller;
  final Widget child;

  @override
  State<NonTouchGestureDetector> createState() =>
      _NonTouchGestureDetectorState();
}

class _NonTouchGestureDetectorState extends State<NonTouchGestureDetector>
    with TickerProviderStateMixin, KlineLog {
  AnimationController? animationController;
  GestureData? _scaleData; // 缩放监听数据
  GestureData? _hoverData; // Cross平移监听数据
  GestureData? _panData; // 移动监听数据

  @override
  String get logTag => 'NonTouch';

  FlexiKlineController get controller => widget.controller;

  GestureConfig get gestureConfig => widget.controller.gestureConfig;

  @override
  void initState() {
    super.initState();
    loggerDelegate = controller.loggerDelegate;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
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
      child: MouseRegion(
        /// Cross平移
        // onEnter: onEnter,
        // onHover: onHover,
        // onExit: onExit,
        child: GestureDetector(
          /// 双击
          onDoubleTap: controller.onDoubleTap,

          /// 按下平移
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,

          /// 移动 缩放
          // onScaleStart: onScaleStart,
          // onScaleUpdate: onScaleUpdate,
          // onScaleEnd: onScaleEnd,
          // trackpadScrollCausesScale: true,

          /// 子组件
          child: widget.child,
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
      if (controller.canvasRect.include(offset)) {
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
          _scaleData = GestureData.scale(
            offset,
            position: position,
          );
        }
        logd(
            'onPointerSignal2 ${event.localPosition}, ${event.scrollDelta}, ${event.down}');

        // _scaleData!.update(newOffset)
      } else {
        _scaleData?.end();
        _scaleData = null;
      }
    }
  }

  void onEnter(PointerEnterEvent event) {
    logd('onEnter $event');
    _hoverData = GestureData.hover(event.localPosition);
  }

  void onExit(PointerExitEvent event) {
    logd('onExit $event');
    controller.cancelCross();
    _hoverData?.end();
    _hoverData = null;
  }

  /// 鼠标Hover事件.
  /// onMouseHover _TransformedPointerHoverEvent#1614b(position: Offset(86.5, 343.6))
  void onHover(PointerHoverEvent event) {
    logd('onHover $event');
    final offset = event.localPosition;
    if (controller.canvasRect.include(offset)) {
      _hoverData!.update(offset);
      controller.handleMove(_hoverData!);
    }
  }

  /// 平移开始.
  ///zp::: web onPanStart DragStartDetails(Offset(232.7, 278.0))
  void onPanStart(DragStartDetails details) {
    logd('onPanStart $details');
    if (_panData != null && _panData!.isEnd) {
      // 如果上次平移或缩放, 还没有结束, 不允许开始.
      return;
    }
    _panData = GestureData.pan(details.localPosition);
  }

  /// 平移中.
  ///zp::: web onPanUpdate DragUpdateDetails(Offset(4.2, 0.0))
  void onPanUpdate(DragUpdateDetails details) {
    logd('onPanUpdate $details');
    if (_panData == null) {
      logd('onPanUpdate panData is empty! details:$details');
      return;
    }

    _panData!.update(details.localPosition.clamp(controller.canvasRect));
    controller.handleMove(_panData!);
  }

  /// 平移结束.
  ///zp::: web onPanEnd DragEndDetails(Velocity(0.0, 0.0))
  void onPanEnd(DragEndDetails details) {
    if (_panData == null) {
      logd("onPanEnd panData is empty! details:$details");
      return;
    }

    // <0: 负数代表从右向左滑动.
    // >0: 正数代表从左向右滑动.
    final velocity = details.velocity.pixelsPerSecond.dx;

    if (!controller.gestureConfig.isInertialPan ||
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
    final panDuration =
        (math.log(math.max(1, velocity.abs())) * tolerance.maxDuration / 10)
            .round()
            .clamp(0, tolerance.maxDuration);

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
        controller.handleMove(_panData!);
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
    logd('onPointerPanZoomStart $event');
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
    logd('onPointerPanZoomUpdate $event');
  }

  void onPointerPanZoomEnd(PointerPanZoomEndEvent event) {
    logd('onPointerPanZoomEnd $event');
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
}
