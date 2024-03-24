import 'package:flutter/material.dart';

import '../kline_controller.dart';

class PriceOrderView extends StatelessWidget {
  const PriceOrderView({
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
        painter: PriceOrderPainter(
          controller: controller,
        ),
        isComplex: true,
      ),
    );
  }
}

class PriceOrderPainter extends CustomPainter {
  PriceOrderPainter({
    required this.controller,
  }) : super(repaint: controller.repaintPriceOrder);

  final KlineController controller;

  @override
  void paint(Canvas canvas, Size size) {
    controller.paintPriceOrder(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
