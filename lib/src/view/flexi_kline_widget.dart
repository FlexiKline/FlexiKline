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
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constant.dart';
import '../extension/basic_type_ext.dart';
import '../extension/functions_ext.dart';
import '../extension/geometry_ext.dart';
import '../framework/chart/indicator.dart';
import '../framework/configuration.dart';
import '../framework/logger.dart';
import '../kline_controller.dart';
import '../model/layout_mode.dart';
import '../utils/platform_util.dart';
import 'non_touch_gesture_detector.dart';
import 'touch_gesture_detector.dart';

typedef MagnifierDecorationShapeBuilder = ShapeBorder Function(
  BuildContext context,
  BorderSide side,
);

class FlexiKlineWidget extends StatefulWidget {
  const FlexiKlineWidget({
    super.key,
    required this.controller,
    required this.candle,
    required this.time,
    this.mainIndicators = const [],
    this.subIndicators = const [],
    this.alignment,
    this.decoration,
    this.foregroundDecoration,
    this.mainForegroundViewBuilder,
    this.mainBackgroundView,
    this.isTouchDevice,
    this.onDoubleTap,
    this.drawToolbar,
    this.drawToolbarInitHeight = 50,
    this.keepDrawToolbarFullyVisible = true,
    this.magnifierDecorationShapeBuilder,
    this.exitZoomButtonBuilder,
    this.exitZoomButtonAlignment = AlignmentDirectional.bottomEnd,
    this.exitZoomButtonPadding = const EdgeInsetsDirectional.all(12),
  });

  FlexiKlineWidget.indicator({
    super.key,
    required this.controller,
    required IIndicatorConfig indicatorConfig,
    this.alignment,
    this.decoration,
    this.foregroundDecoration,
    this.mainForegroundViewBuilder,
    this.mainBackgroundView,
    this.isTouchDevice,
    this.onDoubleTap,
    this.drawToolbar,
    this.drawToolbarInitHeight = 50,
    this.keepDrawToolbarFullyVisible = true,
    this.magnifierDecorationShapeBuilder,
    this.exitZoomButtonBuilder,
    this.exitZoomButtonAlignment = AlignmentDirectional.bottomEnd,
    this.exitZoomButtonPadding = const EdgeInsetsDirectional.all(12),
  })  : candle = indicatorConfig.candle,
        time = indicatorConfig.time,
        mainIndicators = indicatorConfig.mainIndicators,
        subIndicators = indicatorConfig.subIndicators;

  final FlexiKlineController controller;

  /// 蜡烛图指标
  final CandleBaseIndicator candle;

  /// 时间轴指标
  final TimeBaseIndicator time;

  /// 主区可选指标列表
  final List<Indicator> mainIndicators;

  /// 副区可选指标列表
  final List<Indicator> subIndicators;

  /// Container属性配置
  final AlignmentGeometry? alignment;
  final BoxDecoration? decoration;
  final Decoration? foregroundDecoration;

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

  /// 是否是触摸设备.
  final bool? isTouchDevice;

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

class _FlexiKlineWidgetState extends State<FlexiKlineWidget> with WidgetsBindingObserver, FlexiLog {
  @override
  String get logTag => 'FlexiKlineWidget';

  bool get isTouchDevice => widget.isTouchDevice ?? PlatformUtil.isTouch;

  /// 绘制工具条 Key，用于获取尺寸。
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

    logger = controller.logger;

    // 挂载指标并恢复已激活的 PaintObject。
    controller.mountIndicators(
      candle: widget.candle,
      time: widget.time,
      mainIndicators: widget.mainIndicators,
      subIndicators: widget.subIndicators,
    );

    // 同步 controller 生命周期。
    controller.initState();

    // 处理挂载前暂存的数据。
    controller.flushPendingKlineData();

    _drawToolbarPosition = ValueNotifier(
      configuration.getDrawToolbarPosition(),
    );
  }

  @override
  void didUpdateWidget(covariant FlexiKlineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    logd('didUpdateWidget');

    // 按 Widget 新旧声明增量同步指标。
    controller.updateIndicators(
      oldCandle: oldWidget.candle,
      newCandle: widget.candle,
      oldTime: oldWidget.time,
      newTime: widget.time,
      oldMainIndicators: oldWidget.mainIndicators,
      newMainIndicators: widget.mainIndicators,
      oldSubIndicators: oldWidget.subIndicators,
      newSubIndicators: widget.subIndicators,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    logd('didChangeDependencies');
  }

  @override
  void didHaveMemoryPressure() {
    controller.cleanUnlessKlineData();
  }

  @override
  void dispose() {
    configuration.saveDrawToolbarPosition(drawToolbarPosition);
    _drawToolbarKey = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final biggest = constraints.biggest;
        return ValueListenableBuilder<FlexiLayoutMode>(
          valueListenable: controller.layoutModeListener,
          child: _buildKlineContainer(context),
          builder: (context, layoutMode, child) {
            if (layoutMode == FlexiLayoutMode.adapt) {
              // adapt 只消费父约束宽度。
              if (biggest.width.isFinite) {
                controller.setAdaptLayoutMode(width: biggest.width);
              }
            } else if (layoutMode == FlexiLayoutMode.fixed) {
              // fixed 优先使用完整有限约束。
              if (biggest.width.isFinite && biggest.height.isFinite) {
                controller.setFixedLayoutMode(biggest);
              } else if (biggest.width.isFinite && controller.fixedSize != null) {
                // 滚动容器只给宽度时，沿用业务侧提供的 fixed 高度。
                final h = controller.fixedSize!.height;
                if (h.isFinite) {
                  controller.setFixedLayoutMode(Size(biggest.width, h));
                }
              } else {
                assert(
                  controller.fixedSize != null,
                  'FlexiLayoutMode.fixed requires a finite canvas size. '
                  'Use a bounded parent, pass initialFixedSize, or call '
                  'setFixedLayoutMode(size) before first fixed render in scrollable parents.',
                );
              }
            }
            return child!;
          },
        );
      },
    );
  }

  Widget _buildKlineContainer(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.canvasSizeChangeListener,
      builder: (context, canvasRect, child) {
        if (controller.drawState.isEditing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            configuration.saveDrawToolbarPosition(
              _updateDrawToolbarPosition(drawToolbarPosition, canvasRect),
            );
          });
        }
        return _buildKlineContent(context, canvasRect);
      },
    );
  }

  Widget _buildKlineContent(BuildContext context, Rect canvasRect) {
    final canvasSize = canvasRect.size;
    final mainRect = controller.mainRect;
    return Container(
      alignment: widget.alignment,
      width: canvasRect.width,
      height: canvasRect.height,
      decoration: widget.decoration ?? BoxDecoration(color: controller.theme.chartBg),
      foregroundDecoration: widget.foregroundDecoration,
      child: Stack(
        children: <Widget>[
          if (widget.mainBackgroundView != null)
            Positioned.fromRect(
              key: const ValueKey('MainBackground'),
              rect: mainRect,
              child: IgnorePointer(
                child: widget.mainBackgroundView!,
              ),
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
          isTouchDevice
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
      valueListenable: controller.loadingStateListener,
      builder: (context, loadingState, child) {
        final loadingConfig = controller.settingConfig.loading;
        return Offstage(
          offstage: !(loadingState.showLoading && controller.settingConfig.autoLoadMoreData),
          child: Center(
            key: const ValueKey('loadingView'),
            child: SizedBox.square(
              dimension: loadingConfig.size,
              child: CircularProgressIndicator(
                strokeWidth: loadingConfig.strokeWidth,
                backgroundColor: loadingConfig.backgroundColor ?? controller.theme.tooltipBg,
                valueColor: AlwaysStoppedAnimation<Color>(
                  loadingConfig.valueColor ?? controller.theme.textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _updateDrawToolbarPosition(Offset newPosition, [Rect? canvasRect]) {
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
    return _drawToolbarPosition.value = newPosition;
  }

  /// 绘制工具条。
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
              // 无效位置重置到画布左下角。
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
                    configuration.saveDrawToolbarPosition(
                      _updateDrawToolbarPosition(newPosition, canvasRect),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
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
                opacity: config.decorationOpacity,
                shadows: config.decorationShadows ??
                    [
                      BoxShadow(
                        offset: const Offset(0.1, 0.1),
                        blurRadius: 2,
                        spreadRadius: 3,
                        color: controller.theme.gridLineColor.withAlpha(0.1.alpha),
                      ),
                    ],
                shape: widget.magnifierDecorationShapeBuilder?.call(
                      context,
                      config.shapeSide,
                    ) ??
                    CircleBorder(
                      side: BorderSide(
                        color: config.shapeSide.color == transparent
                            ? controller.theme.gridLineColor
                            : config.shapeSide.color,
                        width: config.shapeSide.width <= 0 ? 1 : config.shapeSide.width,
                        style: config.shapeSide.style == BorderStyle.none ? BorderStyle.solid : config.shapeSide.style,
                      ),
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
                  fixedSize: const Size(20, 20),
                  foregroundColor: theme.tooltipTextColor,
                  backgroundColor: theme.tooltipBg.withAlpha(0.8.alpha),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: theme.gridLineColor, width: 1),
                ),
                icon: const Text('A', style: TextStyle(fontSize: 12)),
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
    Timeline.startSync('Flexi-PaintChart');

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
