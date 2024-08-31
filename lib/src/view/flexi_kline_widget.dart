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

import 'package:flexi_kline/src/view/overlay_draw_box.dart';
import 'package:flutter/material.dart';

import '../kline_controller.dart';
import '../utils/platform_util.dart';
import 'non_touch_gesture_detector.dart';
import 'overlay_draw_gesture_detector.dart';
import 'touch_gesture_detector.dart';

class FlexiKlineWidget extends StatefulWidget {
  FlexiKlineWidget({
    super.key,
    required this.controller,
    this.alignment,
    this.decoration,
    this.foregroundDecoration,
    this.mainForegroundViewBuilder,
    this.mainBackgroundView,
    bool? autoAdaptLayout,
    bool? isTouchDevice,
    this.onDoubleTap,
    this.drawToolbar,
  })  : isTouchDevice = isTouchDevice ?? PlatformUtil.isTouch,
        autoAdaptLayout = autoAdaptLayout ?? !PlatformUtil.isMobile;

  final FlexiKlineController controller;
  final AlignmentGeometry? alignment;
  final BoxDecoration? decoration;
  final Decoration? foregroundDecoration;
  final WidgetBuilder? mainForegroundViewBuilder;
  final Widget? mainBackgroundView;
  final GestureTapCallback? onDoubleTap;
  final Widget? drawToolbar;

  /// 是否自动适配所在布局约束.
  /// 在可以动态调整窗口大小的设备上, 此值为true, 将会动态适配窗口的调整; 否则, 请自行控制.
  /// 非移动设备默认为true.
  final bool autoAdaptLayout;

  /// 是否是触摸设备.
  final bool isTouchDevice;

  @override
  State<FlexiKlineWidget> createState() => _FlexiKlineWidgetState();
}

class _FlexiKlineWidgetState extends State<FlexiKlineWidget> {
  /// 绘制工具条globalKey: 用于获取其大小
  final GlobalKey _drawToolbarKey = GlobalKey();

  /// 绘制工具条位置
  Offset _position = Offset.infinite;

  @override
  void initState() {
    super.initState();

    widget.controller.initState();

    widget.controller.sizeChangeListener.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.autoAdaptLayout) {
      return LayoutBuilder(
        builder: (context, constraints) {
          widget.controller.adaptLayoutChange(constraints.biggest);
          return _buildKlineContainer(context);
        },
      );
    } else {
      return _buildKlineContainer(context);
    }
  }

  Widget _buildKlineContainer(BuildContext context) {
    return Container(
      alignment: widget.alignment,
      width: widget.controller.canvasWidth,
      height: widget.controller.canvasHeight,
      decoration: widget.decoration,
      foregroundDecoration: widget.foregroundDecoration,
      child: _buildKlineView(context),
      // child: widget.isTouchDevice
      //     ? TouchGestureDetector(
      //         controller: widget.controller,
      //         onDoubleTap: widget.onDoubleTap,
      //         child: _buildKlineView(context),
      //       )
      //     : NonTouchGestureDetector(
      //         controller: widget.controller,
      //         onDoubleTap: widget.onDoubleTap,
      //         child: _buildKlineView(context),
      //       ),
    );
  }

  ///
  /// TODO: 考虑重新组合grid, indicator, cross, draw图层
  /// 1. grid: 不经常变化
  /// 2. indicator: 经常变化
  /// 3. cross / draw: 偶尔变化
  Widget _buildKlineView(BuildContext context) {
    final canvasSize = widget.controller.canvasRect.size;
    return Stack(
      children: <Widget>[
        if (widget.mainBackgroundView != null)
          Positioned.fromRect(
            rect: widget.controller.mainRect,
            child: widget.mainBackgroundView!,
          ),
        RepaintBoundary(
          key: const ValueKey('GridAndChartLayer'),
          child: CustomPaint(
            size: canvasSize,
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
            size: canvasSize,
            painter: DrawPainter(
              controller: widget.controller,
            ),
            foregroundPainter: CrossPainter(
              controller: widget.controller,
            ),
            isComplex: true,
          ),
        ),
        widget.isTouchDevice
            ? TouchGestureDetector(
                key: const ValueKey('TouchGestureDetector'),
                controller: widget.controller,
                onDoubleTap: widget.onDoubleTap,
              )
            : NonTouchGestureDetector(
                key: const ValueKey('NonTouchGestureDetector'),
                controller: widget.controller,
                onDoubleTap: widget.onDoubleTap,
              ),
        Positioned.fromRect(
          rect: widget.controller.mainRect,
          child: _buildMainForgroundView(context),
        ),
        OverlayDrawBox(
          key: const ValueKey('OverlayDrawBox'),
          controller: widget.controller,
          child: OverlayDrawGestureDetector(
            key: const ValueKey('OverlayDrawGestureDetector'),
            controller: widget.controller,
            isTouchDevice: widget.isTouchDevice,
            child: ConstrainedBox(
              constraints: BoxConstraints.tight(canvasSize),
            ),
          ),
        ),
        _buildDrawToolbar(context),
      ],
    );
  }

  Widget _buildMainForgroundView(BuildContext context) {
    if (widget.mainForegroundViewBuilder != null) {
      return widget.mainForegroundViewBuilder!(context);
    }

    return ValueListenableBuilder(
      valueListenable: widget.controller.candleRequestListener,
      builder: (context, request, child) {
        return Offstage(
          offstage: !request.state.showLoading,
          child: Center(
            key: const ValueKey('loadingView'),
            child: SizedBox.square(
              dimension: widget.controller.settingConfig.loading.size,
              child: CircularProgressIndicator(
                strokeWidth:
                    widget.controller.settingConfig.loading.strokeWidth,
                backgroundColor:
                    widget.controller.settingConfig.loading.background,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.controller.settingConfig.loading.valueColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 绘制DrawToolBar
  Widget _buildDrawToolbar(BuildContext context) {
    if (widget.drawToolbar == null) return const SizedBox.shrink();
    if (_position == Offset.infinite) {
      /// 初始位置为当前canvas区域高度的一半
      _position = Offset(0, widget.controller.canvasRect.height / 2);
    }
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: ValueListenableBuilder(
        valueListenable: widget.controller.isDrawingLinstener,
        builder: (context, value, child) {
          return Visibility(
            visible: value,
            child: GestureDetector(
              onPanUpdate: (DragUpdateDetails details) {
                /// 计算drawToolbar在canvasRect中的位置; 保证其始终在canvasRect中
                final size = _drawToolbarKey.currentContext?.size ?? Size.zero;
                final canvasRect = widget.controller.canvasRect;
                _position = _position + details.delta;
                _position = Offset(
                  _position.dx.clamp(0, canvasRect.right - size.width),
                  _position.dy.clamp(0, canvasRect.bottom - size.height),
                );
                setState(() {});
              },
              onPanEnd: (event) {
                /// 是否持久化到本地?
              },
              child: SizedBox(
                key: _drawToolbarKey,
                child: widget.drawToolbar,
              ),
            ),
          );
        },
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
  }) : super(repaint: controller.repaintDraw);

  final FlexiKlineController controller;

  @override
  void paint(Canvas canvas, Size size) {
    controller.paintDraw(canvas, size);
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
