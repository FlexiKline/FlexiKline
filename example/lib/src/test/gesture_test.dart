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
    widget.createElement;
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
