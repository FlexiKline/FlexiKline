import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../kline_controller.dart';
import '../utils/export.dart';

class GestureView extends StatefulWidget {
  const GestureView({
    super.key,
    required this.controller,
    required this.child,
  });

  final KlineController controller;
  final Widget child;

  @override
  State<GestureView> createState() => _GestureViewState();
}

class _GestureViewState extends State<GestureView>
    with TickerProviderStateMixin, KlineLog {
  @override
  String get logTag => '';
  @override
  bool get isDebug => widget.controller.debug;

  bool isSweeped = false;

  @override
  void initState() {
    super.initState();
    widget.controller.setTicker(this);
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
        onTapUp: widget.controller.onTapUp,

        /// 移动 缩放
        onScaleStart: widget.controller.onScaleStart,
        onScaleUpdate: widget.controller.onScaleUpdate,
        onScaleEnd: widget.controller.onScaleEnd,

        /// 长按
        onLongPressStart: widget.controller.onLongPressStart,
        onLongPressMoveUpdate: widget.controller.onLongPressMoveUpdate,
        onLongPressEnd: widget.controller.onLongPressEnd,

        /// 子组件
        child: widget.child,
      ),
    );
  }

  // void onPointerDown(PointerDownEvent event) {}

  void onPointerMove(PointerMoveEvent event) {
    if (widget.controller.isCrossing) {
      if (!isSweeped) {
        logd(
          'onPointerMove currently in crossing, need clear the gesture arena!',
        );
        isSweeped = true;
        GestureBinding.instance.gestureArena.sweep(event.pointer);
      }
      widget.controller.onPointerMove(event);
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
}
