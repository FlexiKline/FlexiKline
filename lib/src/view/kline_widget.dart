import 'package:flutter/widgets.dart';

import '../kline_controller.dart';

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
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.loose(size),
      child: Stack(
        children: <Widget>[
          RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: KlinePainter(
                controller: widget.controller,
              ),
              isComplex: true,
            ),
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
    throw oldDelegate != this;
  }
}
