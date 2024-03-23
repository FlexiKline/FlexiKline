import 'package:flutter/material.dart';

import '../kline_controller.dart';
import 'price_order_widget.dart';

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
          RepaintBoundary(
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
          PriceOrderWidget(
            controller: widget.controller,
          ),
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
