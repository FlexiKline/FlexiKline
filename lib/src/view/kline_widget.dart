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

import 'dart:developer';

import 'package:flutter/material.dart';

import '../kline_controller.dart';
import 'gesture_view.dart';

typedef MainForegroundViewBuilder = Widget Function(
  BuildContext context,
  bool isLoading,
);

class FlexiKlineWidget extends StatefulWidget {
  const FlexiKlineWidget({
    super.key,
    required this.controller,
    this.alignment,
    this.decoration,
    this.foregroundDecoration,
    this.mainforegroundViewBuilder,
    this.mainBackgroundView,
  });

  final FlexiKlineController controller;
  final AlignmentGeometry? alignment;
  final BoxDecoration? decoration;
  final Decoration? foregroundDecoration;
  final MainForegroundViewBuilder? mainforegroundViewBuilder;
  final Widget? mainBackgroundView;

  @override
  State<FlexiKlineWidget> createState() => _FlexiKlineWidgetState();
}

class _FlexiKlineWidgetState extends State<FlexiKlineWidget> {
  @override
  void initState() {
    super.initState();

    widget.controller.initState();

    widget.controller.sizeChnageListener.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: widget.alignment,
      width: widget.controller.canvasWidth,
      height: widget.controller.canvasHeight,
      decoration: widget.decoration,
      foregroundDecoration: widget.foregroundDecoration,
      child: GestureView(
        controller: widget.controller,
        child: Stack(
          children: <Widget>[
            if (widget.mainBackgroundView != null)
              Positioned.fromRect(
                rect: widget.controller.mainRect,
                child: widget.mainBackgroundView!,
              ),
            RepaintBoundary(
              key: const ValueKey('GridAndChartLayer'),
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
              key: const ValueKey('DrawAndCrossLayer'),
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
              child: ValueListenableBuilder(
                valueListenable: widget.controller.loadingListener,
                builder: (context, value, child) {
                  return _buildMainForgroundView(context, value);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMainForgroundView(BuildContext context, bool loading) {
    if (widget.mainforegroundViewBuilder != null) {
      return widget.mainforegroundViewBuilder!(context, loading);
    }

    return Offstage(
      offstage: !loading,
      child: Center(
        key: const ValueKey('loadingView'),
        child: SizedBox.square(
          dimension: widget.controller.settingConfig.loading.size,
          child: CircularProgressIndicator(
            strokeWidth: widget.controller.settingConfig.loading.strokeWidth,
            backgroundColor: widget.controller.settingConfig.loading.background,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.controller.settingConfig.loading.valueColor,
            ),
          ),
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
    Timeline.startSync("Flexi-PaintChart");

    try {
      /// 保存画布状态
      canvas.save();

      canvas.clipRect(controller.canvasRect);

      controller.calculateCandleDrawIndex();

      controller.paintChart(canvas, size);
    } finally {
      /// 恢复画布状态
      canvas.restore();
    }

    Timeline.finishSync();
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
