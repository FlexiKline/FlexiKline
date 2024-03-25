import 'package:flutter/material.dart';
import 'package:kline/src/view/grid_bg_view.dart';

import '../kline_controller.dart';
import 'gesture_view.dart';

class KlineWidget extends StatefulWidget {
  const KlineWidget({super.key, required this.controller});

  final KlineController controller;

  @override
  State<KlineWidget> createState() => _KlineWidgetState();
}

class _KlineWidgetState extends State<KlineWidget> {
  Size size = Size.zero;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.controller.mainRectWidth,
      height: widget.controller.mainRectHeight,
      decoration: const BoxDecoration(
        color: Color.fromARGB(179, 243, 220, 220),
      ),
      // color: Colors.redAccent,
      child: Stack(
        children: <Widget>[
          GridBgView(controller: widget.controller),
          RepaintBoundary(
            key: const ValueKey('KlinePaint'),
            child: CustomPaint(
              size: Size(
                widget.controller.mainRectWidth,
                widget.controller.mainRectHeight,
              ),
              painter: KlinePainter(
                controller: widget.controller,
              ),
              isComplex: true,
            ),
          ),
          RepaintBoundary(
            key: const ValueKey('PriceCrossPaint'),
            child: CustomPaint(
              size: Size(
                widget.controller.mainRectWidth,
                widget.controller.mainRectHeight,
              ),
              painter: PriceCrossPainter(
                controller: widget.controller,
              ),
              isComplex: true,
            ),
          ),
          GestureView(
            controller: widget.controller,
          )
        ],
      ),
    );
  }
}

class KlinePainter extends CustomPainter {
  KlinePainter({
    required this.controller,
  }) : super(repaint: controller.repaintCandle);

  final KlineController controller;

  @override
  void paint(Canvas canvas, Size size) {
    controller.paintCandle(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

class PriceCrossPainter extends CustomPainter {
  PriceCrossPainter({
    required this.controller,
  }) : super(repaint: controller.repaintPriceCross);

  final KlineController controller;

  @override
  void paint(Canvas canvas, Size size) {
    controller.paintPriceCross(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
