import 'package:flutter/material.dart';

import '../kline_controller.dart';
import 'gesture_view.dart';

class KlineWidget extends StatefulWidget {
  const KlineWidget({super.key, required this.controller});

  final KlineController controller;

  @override
  State<KlineWidget> createState() => _KlineWidgetState();
}

class _KlineWidgetState extends State<KlineWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.onSizeChange = () {
      setState(() {});
    };
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.controller.canvasWidth,
      height: widget.controller.canvasHeight,
      decoration: const BoxDecoration(
        color: Color.fromARGB(179, 243, 220, 220),
      ),
      // color: Colors.redAccent,
      child: GestureView(
        controller: widget.controller,
        child: Stack(
          children: <Widget>[
            // GridBgView(controller: widget.controller),
            RepaintBoundary(
              key: const ValueKey('MainRectPaint'),
              child: CustomPaint(
                size: Size(
                  widget.controller.mainRectWidth,
                  widget.controller.mainRectHeight,
                ),
                painter: GridPainter(
                  controller: widget.controller,
                ),
                foregroundPainter: KlinePainter(
                  controller: widget.controller,
                ),
                isComplex: true,
              ),
            ),
            Positioned(
              left: widget.controller.subRect.left,
              top: widget.controller.subRect.top,
              width: widget.controller.subRectWidth,
              height: widget.controller.subRectHeight,
              child: RepaintBoundary(
                key: const ValueKey('SubRectPaint'),
                child: Container(
                  width: widget.controller.mainRectWidth,
                  height: widget.controller.mainRectHeight,
                  color: Colors.grey,
                ),
              ),
            ),
            RepaintBoundary(
              key: const ValueKey('PriceCrossPaint'),
              child: CustomPaint(
                size: Size(
                  widget.controller.canvasRect.width,
                  widget.controller.canvasRect.height,
                ),
                painter: PriceCrossPainter(
                  controller: widget.controller,
                ),
                isComplex: true,
              ),
            ),
            // GestureView(
            //   controller: widget.controller,
            // )
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  GridPainter({
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
  }) : super(repaint: controller.repaintCross);

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
