// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
                  widget.controller.canvasWidth,
                  widget.controller.canvasHeight,
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
            RepaintBoundary(
              key: const ValueKey('PriceCrossPaint'),
              child: CustomPaint(
                size: Size(
                  widget.controller.canvasWidth,
                  widget.controller.canvasHeight,
                ),
                painter: PriceCrossPainter(
                  controller: widget.controller,
                ),
                isComplex: true,
              ),
            ),
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
    controller.calculateCandleDrawIndex();

    controller.paintMainChart(canvas, size);
    controller.paintSubChart(canvas, size);
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
