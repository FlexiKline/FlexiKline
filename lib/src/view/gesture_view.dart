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

import '../kline_controller.dart';

class GestureView extends StatefulWidget {
  const GestureView({
    super.key,
    required this.controller,
    required this.child,
  });

  final FlexiKlineController controller;
  final Widget child;

  @override
  State<GestureView> createState() => _GestureViewState();
}

class _GestureViewState extends State<GestureView>
    with TickerProviderStateMixin {
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
        widget.controller.logd(
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
