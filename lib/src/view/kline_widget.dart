import 'package:flutter/widgets.dart';

class KlineWidget extends StatefulWidget {
  const KlineWidget({super.key});

  @override
  State<KlineWidget> createState() => _KlineWidgetState();
}

class _KlineWidgetState extends State<KlineWidget> {
  Size size = Size.zero;
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.loose(size),
      child: Stack(
        children: <Widget>[
          RepaintBoundary(
            child: CustomPaint(
              size: size,
              // painter: KlinePainter(controller: widget.controller),
              isComplex: true,
            ),
          ),
        ],
      ),
    );
  }
}
