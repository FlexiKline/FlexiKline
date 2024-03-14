import 'package:flutter/widgets.dart';

import '../controller/export.dart';
import '../core/export.dart';

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
                candleController: widget.controller.candleController,
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
  const KlinePainter({
    required this.candleController,
  }) : super(repaint: candleController);

  final CandleController candleController;

  @override
  void paint(Canvas canvas, Size size) {
    candleController.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    throw oldDelegate != this;
  }
}
