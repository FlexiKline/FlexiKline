import 'package:flutter/material.dart';

import '../kline_controller.dart';

class CrossView extends StatelessWidget {
  const CrossView({
    super.key,
    required this.controller,
  });

  final KlineController controller;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(
          controller.mainRectWidth,
          controller.mainRectHeight,
        ),
        painter: CrossPainter(
          controller: controller,
        ),
        isComplex: true,
      ),
    );
  }
}

class CrossPainter extends CustomPainter {
  CrossPainter({
    required this.controller,
  }) : super(repaint: controller.repaintPriceOrder);

  final KlineController controller;

  @override
  void paint(Canvas canvas, Size size) {
    controller.paintCross(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
