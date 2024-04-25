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

class FlexiKlineWidget extends StatefulWidget {
  const FlexiKlineWidget({
    super.key,
    required this.controller,
    this.decoration,
    this.foregroundDecoration,
    this.loadingView,
  });

  final FlexiKlineController controller;
  final BoxDecoration? decoration;
  final Decoration? foregroundDecoration;
  final Widget? loadingView;

  @override
  State<FlexiKlineWidget> createState() => _FlexiKlineWidgetState();
}

class _FlexiKlineWidgetState extends State<FlexiKlineWidget> {
  bool loading = false;
  @override
  void initState() {
    super.initState();
    widget.controller.onSizeChange = () {
      setState(() {});
    };
    widget.controller.onLoading = (isLoading) {
      if (loading != isLoading) {
        loading = isLoading;
        setState(() {});
      }
    };

    widget.controller.initBinding();
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
      decoration: widget.decoration,
      foregroundDecoration: widget.foregroundDecoration,
      child: GestureView(
        controller: widget.controller,
        child: Stack(
          children: <Widget>[
            RepaintBoundary(
              key: const ValueKey('MainRectPaint'),
              child: CustomPaint(
                size: Size(
                  widget.controller.canvasWidth,
                  widget.controller.canvasHeight,
                ),
                painter: GridBackgroundPainter(
                  controller: widget.controller,
                ),
                foregroundPainter: IndicatorChartPainter(
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
                painter: DrawPainter(
                  controller: widget.controller,
                ),
                foregroundPainter: CrossPainter(
                  controller: widget.controller,
                ),
                isComplex: true,
              ),
            ),
            Positioned.fromRect(
              rect: widget.controller.mainRect,
              child: Offstage(
                offstage: !loading,
                child: widget.loadingView ??
                    Center(
                      child: SizedBox.square(
                        dimension: widget.controller.loadingProgressSize,
                        child: CircularProgressIndicator(
                          strokeWidth:
                              widget.controller.loadingProgressStrokeWidth,
                          backgroundColor:
                              widget.controller.loadingProgressBackgroundColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.controller.loadingProgressValueColor,
                          ),
                        ),
                      ),
                    ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class GridBackgroundPainter extends CustomPainter {
  GridBackgroundPainter({
    required this.controller,
  }) : super(repaint: controller.repaintGridBg);

  final FlexiKlineController controller;

  @override
  void paint(Canvas canvas, Size size) {
    controller.paintGridBg(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

class IndicatorChartPainter extends CustomPainter {
  IndicatorChartPainter({
    required this.controller,
  }) : super(repaint: controller.repaintIndicatorChart);

  final FlexiKlineController controller;

  @override
  void paint(Canvas canvas, Size size) {
    controller.calculateCandleDrawIndex();

    controller.paintChart(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

class DrawPainter extends CustomPainter {
  DrawPainter({
    required this.controller,
  }) : super();

  final FlexiKlineController controller;

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: 待实现
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

class CrossPainter extends CustomPainter {
  CrossPainter({
    required this.controller,
  }) : super(repaint: controller.repaintCross);

  final FlexiKlineController controller;

  @override
  void paint(Canvas canvas, Size size) {
    controller.paintCross(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
