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

import 'dart:math' as math;
import 'dart:developer';

import 'package:flutter/material.dart';

import '../core/core.dart';
import '../extension/basic_type_ext.dart';
import '../extension/functions_ext.dart';
import '../extension/geometry_ext.dart';
import '../framework/configuration.dart';
import '../framework/logger.dart';
import '../kline_controller.dart';
import '../utils/platform_util.dart';
import 'non_touch_gesture_detector.dart';
import 'touch_gesture_detector.dart';

typedef MagnifierDecorationShapeBuilder = ShapeBorder Function(
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
    this.mainSize,
    this.mainForegroundViewBuilder,
    this.mainBackgroundView,
    bool? autoAdaptLayout,
    bool? isTouchDevice,
    this.onDoubleTap,
    this.drawToolbar,
    this.drawToolbarInitHeight = 50,
    this.keepDrawToolbarFullyVisible = true,
    this.magnifierDecorationShapeBuilder,
    this.exitZoomButtonBuilder,
    this.exitZoomButtonAlignment = AlignmentDirectional.bottomEnd,
    this.exitZoomButtonPadding = const EdgeInsetsDirectional.all(12),
  })  : isTouchDevice = isTouchDevice ?? PlatformUtil.isTouch,
        autoAdaptLayout = autoAdaptLayout ?? !PlatformUtil.isMobile;

  final FlexiKlineController controller;

  /// Container属性配置
  final AlignmentGeometry? alignment;
  final BoxDecoration? decoration;
  final Decoration? foregroundDecoration;

  /// 主区初始大小. 注: 仅在首次加载有效
  final Size? mainSize;

  /// 主区前台View构造器
  /// 用于扩展定制Loading/自定义按钮等
  final WidgetBuilder? mainForegroundViewBuilder;

  /// 主区后台View
  /// 用于扩展展示Logo/watermark等静态View
  final Widget? mainBackgroundView;

  /// 整个图表双击事件
  final GestureTapCallback? onDoubleTap;

  /// 绘制工具条仅在绘制完成或选中某个DrawOverlay时展示.
  final Widget? drawToolbar;

  /// 用于计算[drawToolbar]初始展示的位置向对于canvas底部的位置.
  final double drawToolbarInitHeight;

  /// 是否保持[drawToolbar]完全可见.
  final bool keepDrawToolbarFullyVisible;

  /// 是否自动适配所在布局约束.
  /// 在可以动态调整窗口大小的设备上, 此值为true, 将会动态适配窗口的调整; 否则, 请自行控制.
  /// 非移动设备默认为true.
  final bool autoAdaptLayout;

  /// 是否是触摸设备.
  final bool isTouchDevice;

  /// 绘制点指针放大镜DecorationShape.
  final MagnifierDecorationShapeBuilder? magnifierDecorationShapeBuilder;

  /// 自定义退出指标缩放按钮
  final WidgetBuilder? exitZoomButtonBuilder;

  /// 退出指标缩放按钮Alignment
  final AlignmentGeometry exitZoomButtonAlignment;

  /// 缩放按钮Padding
  final EdgeInsetsGeometry exitZoomButtonPadding;

  @override
  State<FlexiKlineWidget> createState() => _FlexiKlineWidgetState();
}

class _FlexiKlineWidgetState extends State<FlexiKlineWidget> with WidgetsBindingObserver, KlineLog {
  @override
  String get logTag => 'FlexiKlineWidget';

  /// 绘制工具条globalKey: 用于获取其大小
  GlobalKey? _drawToolbarKey;
  GlobalKey get drawToolbarKey => _drawToolbarKey ??= GlobalKey();

  /// 绘制工具条位置
  late final ValueNotifier<Offset> _drawToolbarPosition;
  Offset get drawToolbarPosition => _drawToolbarPosition.value;

  FlexiKlineController get controller => widget.controller;

  IConfiguration get configuration => controller.configuration;

  IFlexiKlineTheme get theme => configuration.theme;

  @override
  void initState() {
    super.initState();

    loggerDelegate = controller.loggerDelegate;

    controller.initState();
    if (widget.mainSize != null) {
      controller.setMainSize(widget.mainSize!);
    }

    _drawToolbarPosition = ValueNotifier(
      configuration.getDrawToolbarPosition(),
    );
  }

  @override
  void didUpdateWidget(covariant FlexiKlineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    logd('didUpdateWidget');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    logd('didChangeDependencies');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logd('didChangeAppLifecycleState($state)');
    // if (state == AppLifecycleState.resumed) {
    // } else {
    // }
  }

  @override
  void didHaveMemoryPressure() {
    controller.cleanUnlessKlineData();
  }

  @override
  void dispose() {
    configuration.saveDrawToolbarPosition(drawToolbarPosition);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.autoAdaptLayout) {
      return LayoutBuilder(
        builder: (context, constraints) {
          switch (controller.layoutMode) {
            case FixedLayoutMode(fixedSize: final size):
              controller.setFixedLayoutMode(Size(
                constraints.biggest.width,
                size.height,
              ));
            case NormalLayoutMode(mainSize: final size):
            case AdaptLayoutMode(mainSize: final size):
              controller.setAdaptLayoutMode(
                Size(
                  constraints.biggest.width,
                  size.height,
                ),
                syncMainSize: true,
              );
          }
          return _buildKlineContainer(context);
        },
      );
    } else {
      return _buildKlineContainer(context);
    }
  }

  Widget _buildKlineContainer(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.canvasSizeChangeListener,
      builder: (context, canvasRect, child) {
        if (controller.drawState.isEditing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateDrawToolbarPosition(drawToolbarPosition, canvasRect);
          });
        }
        return _buildKlineContent(context, canvasRect);
      },
    );
  }

  Widget _buildKlineContent(BuildContext context, Rect canvasRect) {
    // final canvasRect = controller.canvasRect;
    final canvasSize = canvasRect.size;
    final mainRect = controller.mainRect;
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
              key: const ValueKey('MainBackground'),
              rect: mainRect,
              child: widget.mainBackgroundView!,
            ),
          RepaintBoundary(
            key: const ValueKey('GridAndChartLayer'),
            child: CustomPaint(
              size: canvasSize,
              painter: GridPainter(
                controller: controller,
              ),
              foregroundPainter: ChartPainter(
                controller: controller,
              ),
              isComplex: true,
            ),
          ),
          RepaintBoundary(
            key: const ValueKey('DrawAndCrossLayer'),
            child: CustomPaint(
              size: canvasSize,
              painter: DrawPainter(
                controller: controller,
              ),
              foregroundPainter: CrossPainter(
                controller: controller,
              ),
              isComplex: true,
            ),
          ),
          widget.isTouchDevice
              ? TouchGestureDetector(
                  key: const ValueKey('TouchGestureDetector'),
                  controller: controller,
                  onDoubleTap: widget.onDoubleTap,
                )
              : NonTouchGestureDetector(
                  key: const ValueKey('NonTouchGestureDetector'),
                  controller: controller,
                  onDoubleTap: widget.onDoubleTap,
                ),
          _buildMagnifier(context, canvasRect),
          Positioned.fromRect(
            rect: mainRect,
            child: _buildExitZoomButton(context, mainRect),
          ),
          _buildDrawToolbar(context, canvasRect),
          Positioned.fromRect(
            rect: mainRect,
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
      valueListenable: controller.candleRequestListener,
      builder: (context, request, child) {
        return Offstage(
          offstage: !request.state.showLoading,
          child: Center(
            key: const ValueKey('loadingView'),
            child: SizedBox.square(
              dimension: controller.settingConfig.loading.size,
              child: CircularProgressIndicator(
                strokeWidth: controller.settingConfig.loading.strokeWidth,
                backgroundColor: controller.settingConfig.loading.background,
                valueColor: AlwaysStoppedAnimation<Color>(
                  controller.settingConfig.loading.valueColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateDrawToolbarPosition(Offset newPosition, [Rect? canvasRect]) {
    canvasRect ??= controller.canvasRect;
    final size = drawToolbarKey.currentContext?.size;
    if (widget.keepDrawToolbarFullyVisible && size != null && size.isFinite) {
      newPosition = Offset(
        newPosition.dx.clamp(
          canvasRect.left,
          math.max(canvasRect.left, canvasRect.right - size.width),
        ),
        newPosition.dy.clamp(
          canvasRect.top,
          math.max(canvasRect.top, canvasRect.bottom - size.height),
        ),
      );
    } else {
      newPosition = newPosition.clamp(canvasRect);
    }
    _drawToolbarPosition.value = newPosition;
    configuration.saveDrawToolbarPosition(newPosition);
  }

  /// 绘制DrawToolBar
  Widget _buildDrawToolbar(BuildContext flexiKlineContext, Rect canvasRect) {
    if (widget.drawToolbar == null) return const SizedBox.shrink();
    final drawToolbarWrapper = SizedBox(
      key: drawToolbarKey,
      child: widget.drawToolbar!,
    );
    return ValueListenableBuilder(
      valueListenable: controller.drawStateListener,
      builder: (context, state, child) => Visibility(
        visible: state.isEditing,
        child: ValueListenableBuilder(
          valueListenable: _drawToolbarPosition,
          builder: (context, position, child) {
            if (position == Offset.infinite || !canvasRect.contains(position)) {
              // 如果position无效, 则重置其为当前canvas区域左下角.
              position = Offset(0, canvasRect.height - widget.drawToolbarInitHeight);
            }
            return Positioned(
              left: position.dx,
              top: position.dy,
              child: MouseRegion(
                cursor: SystemMouseCursors.move,
                child: Draggable(
                  key: const ValueKey('DrawToolbarDraggable'),
                  feedback: drawToolbarWrapper,
                  childWhenDragging: const SizedBox.shrink(),
                  child: drawToolbarWrapper,
                  onDragEnd: (details) {
                    final box = flexiKlineContext.findRenderObject() as RenderBox;
                    final newPosition = box.globalToLocal(details.offset);
                    _updateDrawToolbarPosition(newPosition, canvasRect);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
    // return ValueListenableBuilder(
    //   valueListenable: controller.drawStateListener,
    //   builder: (context, state, child) => Visibility(
    //     visible: state.isEditing,
    //     child: ValueListenableBuilder(
    //       valueListenable: _drawToolbarPosition,
    //       builder: (context, position, child) {
    //         if (position == Offset.infinite || !canvasRect.contains(position)) {
    //           // 如果position无效, 则重置其为当前canvas区域左下角.
    //           position = Offset(0, canvasRect.height - widget.drawToolbarInitHeight);
    //         }
    //         return Positioned(
    //           left: position.dx,
    //           top: position.dy,
    //           child: MouseRegion(
    //             cursor: SystemMouseCursors.move,
    //             child: GestureDetector(
    //               onPanUpdate: (DragUpdateDetails details) {
    //                 _updateDrawToolbarPosition(position + details.delta, canvasRect);
    //               },
    //               onPanEnd: (event) {
    //                 configuration.saveDrawToolbarPosition(position);
    //               },
    //               child: SizedBox(
    //                 key: drawToolbarKey,
    //                 child: widget.drawToolbar,
    //               ),
    //             ),
    //           ),
    //         );
    //       },
    //     ),
    //   ),
    // );
  }

  /// 放大镜
  Widget _buildMagnifier(BuildContext context, Rect drawRect) {
    final config = controller.drawConfig.magnifier;
    if (!config.enable || config.size.isEmpty) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder(
      valueListenable: controller.drawPointerListener,
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
            final valueTxtWidth = controller.drawState.object?.valueTicksSize?.width ?? 0;
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
                shape: widget.magnifierDecorationShapeBuilder?.call(
                      context,
                      config.shapeSide.copyWith(color: theme.gridLine),
                    ) ??
                    CircleBorder(
                      side: config.shapeSide.copyWith(color: theme.gridLine),
                    ),
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

  /// 退出Zoom缩放按钮
  Widget _buildExitZoomButton(BuildContext context, Rect mainRect) {
    return ValueListenableBuilder(
      valueListenable: controller.isStartZoomChartListener,
      builder: (context, isStartZomming, child) => Visibility(
        visible: isStartZomming,
        child: Container(
          alignment: widget.exitZoomButtonAlignment,
          padding: widget.exitZoomButtonPadding,
          child: widget.exitZoomButtonBuilder?.call(context) ??
              IconButton(
                onPressed: controller.exitChartZoom.debounce(),
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  fixedSize: Size(20, 20),
                  foregroundColor: theme.tooltipTextColor,
                  backgroundColor: theme.tooltipBg.withAlpha(0.8.alpha),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: theme.gridLine, width: 1),
                ),
                icon: Text('A', style: TextStyle(fontSize: 12)),
              ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  GridPainter({
    required this.controller,
  }) : super(repaint: controller.repaintGridBg);

  final FlexiKlineController controller;

  @override
  void paint(Canvas canvas, Size size) {
    controller.paintGrid(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

class ChartPainter extends CustomPainter {
  ChartPainter({
    required this.controller,
  }) : super(repaint: controller.repaintChart);

  final FlexiKlineController controller;

  @override
  void paint(Canvas canvas, Size size) {
    Timeline.startSync("Flexi-PaintChart");

    // try {
    //   /// 保存画布状态
    //   canvas.save();
    //   canvas.clipRect(controller.canvasRect);
    controller.paintChart(canvas, size);
    // } finally {
    //   /// 恢复画布状态
    //   canvas.restore();
    // }

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

    try {
      canvas.save();
      canvas.clipRect(controller.mainRect);

      controller.paintDraw(canvas, size);
    } finally {
      canvas.restore();
    }

    controller.drawStateAxisTicksText(canvas, size);
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
    try {
      canvas.save();
      canvas.clipRect(controller.canvasRect);

      controller.paintCross(canvas, size);
    } finally {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
