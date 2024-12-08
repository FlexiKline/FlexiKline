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
import '../utils/platform_util.dart';
import 'non_touch_gesture_detector.dart';
import 'touch_gesture_detector.dart';

typedef MagnifierDecorationShapBuilder = ShapeBorder Function(
  BuildContext context,
  BorderSide side,
);

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
    this.drawToolbarInitHeight = 50,
    this.magnifierDecorationShapBuilder,
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

  /// 用于计算[drawToolbar]初始展示的位置向对于canvas底部的位置.
  final double drawToolbarInitHeight;

  /// 是否自动适配所在布局约束.
  /// 在可以动态调整窗口大小的设备上, 此值为true, 将会动态适配窗口的调整; 否则, 请自行控制.
  /// 非移动设备默认为true.
  final bool autoAdaptLayout;

  /// 是否是触摸设备.
  final bool isTouchDevice;

  /// 绘制点指针放大镜DecorationShape.
  final MagnifierDecorationShapBuilder? magnifierDecorationShapBuilder;

  /// 支持的主区指标配置列表构造器

  /// 支持的副区指标配置列表构造器

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

    widget.controller.canvasSizeChangeListener.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (widget.controller.drawState.isEditing) {
          _updateDrawToolbarPosition(_position);
        }
        setState(() {});
      });
    });
  }

  @override
  void didUpdateWidget(covariant FlexiKlineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller.logd('View didUpdateWidget');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller.logd('View didChangeDependencies');
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
    final canvasRect = widget.controller.canvasRect;
    final canvasSize = canvasRect.size;
    return Container(
      alignment: widget.alignment,
      width: canvasRect.width,
      height: canvasRect.height,
      decoration: widget.decoration,
      foregroundDecoration: widget.foregroundDecoration,
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
          _buildMagnifier(context, canvasRect),
          _buildDrawToolbar(context, canvasSize),
          Positioned.fromRect(
            rect: widget.controller.mainRect,
            child: _buildMainForgroundView(context),
          ),
        ],
      ),
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

  bool _updateDrawToolbarPosition(Offset newPosition) {
    final size = _drawToolbarKey.currentContext?.size;
    if (size != null && !size.isEmpty) {
      final canvasRect = widget.controller.canvasRect;
      _position = Offset(
        newPosition.dx.clamp(0, canvasRect.right - size.width),
        newPosition.dy.clamp(0, canvasRect.bottom - size.height),
      );
      return true;
    }
    return false;
  }

  /// 绘制DrawToolBar
  Widget _buildDrawToolbar(BuildContext context, Size canvasSize) {
    if (widget.drawToolbar == null) return const SizedBox.shrink();
    if (_position == Offset.infinite) {
      /// 初始位置为当前canvas区域左下角.
      /// TODO: 从缓存获取上次的位置
      _position = Offset(0, canvasSize.height - widget.drawToolbarInitHeight);
    }
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: ValueListenableBuilder(
        valueListenable: widget.controller.drawStateListener,
        builder: (context, state, child) {
          return Visibility(
            visible: state.isEditing,
            child: GestureDetector(
              onPanUpdate: (DragUpdateDetails details) {
                if (_updateDrawToolbarPosition(_position + details.delta)) {
                  setState(() {});
                }
              },
              onPanEnd: (event) {
                /// TODO: 将位置持久化到本地
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

  /// 放大镜
  Widget _buildMagnifier(BuildContext context, Rect drawRect) {
    final config = widget.controller.drawConfig.magnifier;
    // Web平台暂不支持放大镜; TODO: 后续适配
    if (PlatformUtil.isWeb || !config.enable || config.size.isEmpty) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder(
      valueListenable: widget.controller.drawPointerListener,
      builder: (context, pointer, child) {
        bool visible = false;
        final pointerOffset = pointer?.offset;
        Offset focalPosition = Offset.zero;
        AlignmentGeometry alignment = AlignmentDirectional.topStart;
        EdgeInsets margin = config.margin;
        if (pointerOffset != null && pointerOffset.isFinite) {
          visible = true;
          Offset position;
          if (pointerOffset.dx > drawRect.width * 0.5) {
            alignment = AlignmentDirectional.topStart;
            position = config.size.center(margin.topLeft);
            position = Offset(
              drawRect.left + position.dx,
              drawRect.top + position.dy,
            );
          } else {
            alignment = AlignmentDirectional.topEnd;
            final valueTxtWidth =
                widget.controller.drawState.object?.valueTicksSize?.width ?? 0;
            margin = margin.copyWith(right: margin.right + valueTxtWidth);
            position = Offset(
              drawRect.right - margin.right - config.size.width / 2,
              drawRect.top + margin.top + config.size.height / 2,
            );
          }
          focalPosition = pointerOffset - position;
        }

        return Visibility(
          key: const ValueKey('MagnifierVisibility'),
          visible: visible,
          child: Container(
            key: const ValueKey('MagnifierContainer'),
            alignment: alignment,
            margin: margin,
            child: RawMagnifier(
              key: const ValueKey('KlineRawMagnifier'),
              decoration: MagnifierDecoration(
                opacity: config.decorationOpactity,
                shadows: config.decorationShadows,
                shape: widget.magnifierDecorationShapBuilder?.call(
                      context,
                      config.shapeSide,
                    ) ??
                    CircleBorder(side: config.shapeSide),
              ),
              size: config.size,
              focalPointOffset: focalPosition,
              magnificationScale: config.magnificationScale,
            ),
          ),
        );
      },
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
  }) : super(repaint: controller.repaintChart);

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
    if (!controller.isDrawVisibility) return;

    controller.drawStateAxisTicksText(canvas, size);
    try {
      /// 保存画布状态
      canvas.save();

      canvas.clipRect(controller.mainRect);

      controller.paintDraw(canvas, size);
    } finally {
      canvas.restore();
    }
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
