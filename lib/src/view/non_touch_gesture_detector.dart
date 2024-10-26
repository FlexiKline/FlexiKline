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
  AnimationController? animationController;

  /// 缩放监听数据
  GestureData? _scaleData;

  /// Cross平移监听数据
  GestureData? _hoverData;

  /// 平移监听数据
  GestureData? _panData;

  /// 长按监听数据
  GestureData? _longData;

  @override
  String get logTag => 'NonTouchGesture';

  FlexiKlineController get controller => widget.controller;

  GestureConfig get gestureConfig => widget.controller.gestureConfig;

  DrawState get drawState => controller.drawState;

  @override
  void initState() {
    super.initState();
    loggerDelegate = controller.loggerDelegate;
    // widget.controller.
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
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
      child: MouseRegion(
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

      final dx = event.scrollDelta.dx.abs();
      final dy = event.scrollDelta.dy.abs();
      if (dy > 1 && dy > dx) {
        // 说明可能是(鼠标滚轴或触控板双指)向上向下进行缩放
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
                'onPointerSignal V> clean _scaleData${_scaleData?.initPosition}',
              );
              return true;
            }());
            _scaleData?.end();
            _scaleData = null;

            /// 检查并加载更多蜡烛数据
            controller.checkAndLoadMoreCandlesWhenPanEnd();
          });
        }

        final newScale = scaledSingal(
          event.scrollDelta.dy,
          gestureConfig.scaleSpeed,
        );

        assert(() {
          logd('onPointerSignal V> $offset, ${event.scrollDelta}, $newScale');
          return true;
        }());

        if (newScale != null) {
          _scaleData!.update(offset, newScale: newScale);
          controller.scaleChart(_scaleData!);
        }
      } else if (dx > 1 && dx > dy) {
        // 说明可能是触控板的双指横向移动操作
        assert(() {
          logd('onPointerSignal H> $offset, ${event.scrollDelta},');
          return true;
        }());
      }
    }
  }

  /// 鼠标Hover进入事件.
  void onEnter(PointerEnterEvent event) {
    final offset = event.localPosition;
    if (!controller.canvasRect.include(offset)) return;

    logd('onEnter $event');
    if (_hoverData != null && drawState.isOngoing) {
      drawState.object?.pointer?.offset = offset; // TODO: 待优化.
      _hoverData!.update(offset);
    } else {
      _hoverData = GestureData.hover(offset);
      controller.startCross(_hoverData!, force: true);
    }
  }

  /// 鼠标Hover事件.
  /// onMouseHover _TransformedPointerHoverEvent#1614b(position: Offset(86.5, 343.6))
  void onHover(PointerHoverEvent event) {
    if (_hoverData == null) return;
    Offset offset = event.localPosition;

    if (drawState.isOngoing) {
      if (drawState.isEditing) {
        /// 已完成的DrawObject, 通过[_panData]或[_longData]事件数据更新.
        return;
      }
      final pointer = drawState.pointer;
      if (pointer != null && pointer.offset.isFinite) {
        if (controller.isCrossing) controller.cancelCross();
        // final mainRect = controller.mainRect;
        // if (!mainRect.include(offset)) {
        //   offset = offset.clamp(mainRect);
        // }
        _hoverData ??= GestureData.hover(offset);
        _hoverData!.update(offset);
        controller.onDrawUpdate(_hoverData!);
        return;
      }
    }

    if (!controller.canvasRect.include(offset)) return;
    // assert(() {
    //   logd('onHover cross $event');
    //   return true;
    // }());

    _hoverData!.update(offset);
    if (!controller.isCrossing) {
      controller.startCross(_hoverData!, force: true);
    } else {
      controller.updateCross(_hoverData!);
    }
  }

  /// 鼠标Hover退出事件.
  void onExit(PointerExitEvent event) {
    controller.cancelCross();
    logd('onExit $event');

    if (_hoverData == null) return;
    if (drawState.isOngoing) {
      // 当处在绘制中状态时, 不清理hover指针数据.
      return;
    }
    _hoverData?.end();
    _hoverData = null;
  }

  /// 点击
  void onTapUp(TapUpDetails details) {
    if (drawState.isOngoing) {
      logd("onTapUp draw confirm details:$details");
      final tapData = GestureData.tap(details.localPosition);
      final ret = controller.onDrawConfirm(tapData);
      if (ret && controller.isCrossing) {
        controller.cancelCross();
      }
      tapData.end();
      return;
    } else if (drawState.isPrepared ||
        controller.drawConfig.allowSelectWhenExit) {
      // 只有在准备状态时或配置中指定[allowSelectWhenExit]时, 进行命中测试
      final object = controller.hitTestDrawObject(details.localPosition);
      if (object != null) {
        logd("onTapUp draw select object:$object");
        controller.onDrawSelect(object);
        return;
      }
    }
  }

  /// 平移开始.
  void onPanStart(DragStartDetails details) {
    if (_panData != null && !_panData!.isEnd) {
      // 如果上次平移或缩放, 还没有结束, 不允许开始.
      logd('onPanStart Currently still panning, ignore!!!');
      return;
    }
    if (drawState.isOngoing) {
      if (drawState.isDrawing) {
        // 未完成的暂不允许移动
        return;
      }
      logd("onPanStart draw > details:$details");
      _panData = GestureData.pan(details.localPosition);
      final result = controller.onDrawMoveStart(_panData!);
      if (!result) {
        _panData?.end();
        _panData = null;
      }
    } else {
      logd('onPanStart pan local:${details.localPosition}');
      _panData = GestureData.pan(details.localPosition);
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
    if (drawState.isOngoing) {
      _panData!.update(details.localPosition.clamp(controller.mainRect));
      controller.onDrawMoveUpdate(_panData!);
    } else {
      _panData!.update(details.localPosition.clamp(controller.canvasRect));
      controller.moveChart(_panData!);
    }
  }

  /// 平移结束.
  void onPanEnd(DragEndDetails details) {
    if (_panData == null) {
      logd("onPanEnd panData is empty! details:$details");
      return;
    }

    if (drawState.isOngoing) {
      controller.onDrawMoveEnd();
      _panData?.end();
      _panData = null;
      return;
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
        controller.moveChart(_panData!);
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
        controller.scaleChart(_scaleData!);
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
    }
  }

  /// 长按
  ///
  /// 如果当前正在crossing中时, 不触发后续的长按逻辑.
  void onLongPressStart(LongPressStartDetails details) {
    if (!gestureConfig.supportLongPress || controller.isCrossing) {
      logd("onLongPressStart ignore! > crossing:${controller.isCrossing}");
      return;
    }
    logd("onLongPressStart > details:$details");
    if (drawState.isOngoing) {
      if (drawState.isDrawing) {
        // 未完成的暂不允许移动
        return;
      }
      _longData = GestureData.long(details.localPosition);
      final result = controller.onDrawMoveStart(_longData!);
      if (!result) {
        _longData?.end();
        _longData = null;
      }
    } else {
      // assert(() {
      //   logd("onLongPressStart cross > details:$details");
      //   return true;
      // }());
      _longData = GestureData.long(details.localPosition);
      final result = controller.startCross(_longData!);
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
    if (drawState.isOngoing) {
      _longData!.update(details.localPosition);
      controller.onDrawMoveUpdate(_longData!);
    } else {
      _longData!.update(details.localPosition);
      controller.updateCross(_longData!);
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
    if (drawState.isOngoing) {
      controller.onDrawMoveEnd();
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
}
