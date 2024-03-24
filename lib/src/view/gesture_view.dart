import 'package:flutter/material.dart';

import '../kline_controller.dart';

class GestureView extends StatefulWidget {
  const GestureView({super.key, required this.controller});

  final KlineController controller;

  @override
  State<GestureView> createState() => _GestureViewState();
}

class _GestureViewState extends State<GestureView>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    widget.controller.setTicker(this);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}
