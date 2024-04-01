import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GestureTest extends StatefulWidget {
  const GestureTest({super.key});

  @override
  State<GestureTest> createState() => _GestureTestState();
}

Size get drawableSize => Size(
      ScreenUtil().screenWidth,
      ScreenUtil().screenWidth * 2 / 3,
    );

class _GestureTestState extends State<GestureTest> {
  void logd(String msg) {
    debugPrint('zp::: GestureTest > $msg');
  }

  bool isTap = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      child: GestureDetector(
        onTapUp: onTapUp,
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        onScaleEnd: onScaleEnd,
        onLongPressStart: onLongPressStart,
        onLongPressMoveUpdate: onLongPressMoveUpdate,
        onLongPressEnd: onLongPressEnd,
        child: Container(
          width: drawableSize.width,
          height: drawableSize.height,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  void onPointerDown(PointerDownEvent event) {
    logd('onPointerDown isTap:$isTap');
    if (isTap) {
      logd('onPointerDown sweep(${event.pointer})');
      // GestureBinding.instance.gestureArena.hold(event.pointer);
      // GestureBinding.instance.gestureArena.sweep(event.pointer);
    }
  }

  void onPointerMove(PointerMoveEvent event) {
    logd('onPointerMove isTap:$isTap');
    if (isTap) {
      logd('onPointerMove sweep(${event.pointer})');
      // GestureBinding.instance.gestureArena.hold(event.pointer);
      GestureBinding.instance.gestureArena.sweep(event.pointer);
    }
  }

  void onPointerUp(PointerUpEvent event) {
    logd('onPointerUp isTap:$isTap');
    // GestureBinding.instance.gestureArena.release(event.pointer);
  }

  void onPointerCancel(PointerCancelEvent event) {
    logd('onPointerCancel isTap:$isTap');
    // GestureBinding.instance.gestureArena.release(event.pointer);
  }

  void onTapUp(TapUpDetails details) {
    logd('onTapUp isTap:$isTap');
    setState(() {
      isTap = !isTap;
    });
  }

  void onScaleStart(ScaleStartDetails details) {
    logd('onScaleStart');
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    logd('onScaleUpdate');
  }

  void onScaleEnd(ScaleEndDetails details) {
    logd('onScaleEnd');
  }

  void onLongPressStart(LongPressStartDetails details) {
    logd('onLongPressStart');
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    logd('onLongPressMoveUpdate');
  }

  void onLongPressEnd(LongPressEndDetails details) {
    logd('onLongPressEnd');
  }
}
