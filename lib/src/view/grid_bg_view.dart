import 'package:flutter/material.dart';

import '../kline_controller.dart';

class GridBgView extends StatelessWidget {
  const GridBgView({super.key, required this.controller});

  final KlineController controller;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(
          controller.mainRectWidth,
          controller.mainRectHeight,
        ),
        painter: GridBgPainter(
          controller: controller,
        ),
        isComplex: true,
      ),
    );
  }
}

class GridBgPainter extends CustomPainter {
  GridBgPainter({
    required this.controller,
  }) : super(repaint: controller.repaintGridBg);

  final KlineController controller;

  @override
  void paint(Canvas canvas, Size size) {
    controller.paintGridBg(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
