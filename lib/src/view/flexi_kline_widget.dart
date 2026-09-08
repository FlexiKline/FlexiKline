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

/// 通用定制 builder 签名.
typedef FlexiKlineWidgetBuilder = Widget Function(
  BuildContext context,
  FlexiKlineController controller,
);

/// 放大镜 decoration shape 定制签名.
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
    this.isTouchDevice,
    this.onDoubleTap,
    this.mainBackgroundBuilder,
    this.mainForegroundBuilder,
    this.loadingBuilder,
    this.exitZoomButtonBuilder,
    this.drawToolbarBuilder,
    this.drawToolbar,
    this.magnifierBuilder,
    this.magnifierDecorationShapeBuilder,
  });

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

  /// 是否是触摸设备.
  final bool? isTouchDevice;

  /// 整个图表双击事件
  final GestureTapCallback? onDoubleTap;

  /// 主区背景(logo/watermark等静态View, IgnorePointer).
  final FlexiKlineWidgetBuilder? mainBackgroundBuilder;

  /// 主区前景扩展(按钮组/标注层等业务UI).
  /// 与 loading 解耦, 两者独立叠加.
  final FlexiKlineWidgetBuilder? mainForegroundBuilder;

  /// Loading指示器. 为null时使用内置默认实现.
  /// 业务可监听 controller.loadingStateListenable 自行控制.
  final FlexiKlineWidgetBuilder? loadingBuilder;

  /// 退出缩放按钮. 为null时使用内置默认(仅isChartZooming时展示).
  /// 业务完全控制展示逻辑: 始终展示/自动展示/隐藏.
  final FlexiKlineWidgetBuilder? exitZoomButtonBuilder;

  /// 完全替换绘制工具条区域(含拖拽/展示逻辑).
  /// 提供此参数则忽略 [drawToolbar].
  final FlexiKlineWidgetBuilder? drawToolbarBuilder;

  /// 绘制工具条UI内容(轻量定制).
  /// 框架负责展示时机(isEditing)和拖拽定位.
  /// 仅在 [drawToolbarBuilder] 为null时生效.
  final Widget? drawToolbar;

  /// 完全替换放大镜. 提供此参数则忽略 [magnifierDecorationShapeBuilder].
  final FlexiKlineWidgetBuilder? magnifierBuilder;

  /// 放大镜decoration shape定制. 仅在 [magnifierBuilder] 为null时生效.
  final MagnifierDecorationShapeBuilder? magnifierDecorationShapeBuilder;

  @override
  State<FlexiKlineWidget> createState() => _FlexiKlineWidgetState();
}

class _FlexiKlineWidgetState extends State<FlexiKlineWidget> with WidgetsBindingObserver, FlexiLog {
  @override
  String get logTag => 'FlexiKlineWidget';

  bool get isTouchDevice => widget.isTouchDevice ?? PlatformUtil.isTouch;

  /// 绘制工具条位置
  late final ValueNotifier<Offset> _drawToolbarPosition;

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
    controller.evictInactiveKlineDataCache();
  }

  @override
  void dispose() {
    configuration.saveDrawToolbarPosition(drawToolbarPosition);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final biggest = constraints.biggest;
        return ValueListenableBuilder<FlexiLayoutMode>(
          valueListenable: controller.layoutModeListenable,
          child: _buildKlineContainer(context),
          builder: (context, layoutMode, child) {
            if (layoutMode == FlexiLayoutMode.adapt) {
              // adapt 只消费父约束宽度。
              if (biggest.width.isFinite) {
                controller.setAdaptLayoutMode(width: biggest.width);
              }
            } else if (layoutMode == FlexiLayoutMode.fixed) {
              // fixed 每个维度独立决策：biggest 优先，fixedSize 补位。
              final userSize = controller.fixedSize;
              final w = biggest.width.isFinite ? biggest.width : userSize?.width;
              final h = biggest.height.isFinite ? biggest.height : userSize?.height;

              if (w != null && w.isFinite && h != null && h.isFinite) {
                controller.setFixedLayoutMode(Size(w, h));
              } else {
                logw(
                  'FlexiLayoutMode.fixed: cannot resolve finite canvas size. '
                  'biggest=$biggest, fixedSize=$userSize',
                );
                assert(
                  false,
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
      valueListenable: controller.canvasRectListenable,
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
          // 第0层: 主区背景
          _buildMainBackground(context, mainRect),
          // 第1层: 网格+图表
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
          // 第2层: 绘制覆盖+十字线
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
          // 第3层: 手势
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
          // 第4层: 放大镜
          _buildMagnifier(context, canvasRect),
          // 第5层: 退出缩放按钮
          Positioned.fromRect(
            rect: mainRect,
            child: _buildExitZoomButton(context),
          ),
          // 第6层: 绘制工具条
          _buildDrawToolbar(context, canvasRect),
          // 第7层: Loading
          Positioned.fromRect(
            rect: mainRect,
            child: _buildLoading(context),
          ),
          // 第8层: 主区前景
          _buildMainForeground(context, mainRect),
        ],
      ),
    );
  }

  /// 主区背景
  Widget _buildMainBackground(BuildContext context, Rect mainRect) {
    if (widget.mainBackgroundBuilder == null) return const SizedBox.shrink();
    return Positioned.fromRect(
      key: const ValueKey('MainBackground'),
      rect: mainRect,
      child: IgnorePointer(
        child: widget.mainBackgroundBuilder!(context, controller),
      ),
    );
  }

  /// 主区前景
  Widget _buildMainForeground(BuildContext context, Rect mainRect) {
    if (widget.mainForegroundBuilder == null) return const SizedBox.shrink();
    return Positioned.fromRect(
      rect: mainRect,
      child: widget.mainForegroundBuilder!(context, controller),
    );
  }

  /// Loading指示器
  Widget _buildLoading(BuildContext context) {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context, controller);
    }
    // 内置默认
    return ValueListenableBuilder(
      valueListenable: controller.loadingStateListenable,
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

  /// 退出缩放按钮
  Widget _buildExitZoomButton(BuildContext context) {
    if (widget.exitZoomButtonBuilder != null) {
      return widget.exitZoomButtonBuilder!(context, controller);
    }
    // 内置默认: 仅在 isChartZooming 时展示
    return ValueListenableBuilder(
      valueListenable: controller.isChartZoomingListenable,
      builder: (context, isStartZooming, child) => Visibility(
        visible: isStartZooming,
        child: Container(
          alignment: AlignmentDirectional.bottomEnd,
          padding: const EdgeInsetsDirectional.all(12),
          child: IconButton(
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

  Offset _updateDrawToolbarPosition(Offset newPosition, [Rect? canvasRect]) {
    canvasRect ??= controller.canvasRect;
    final size = _drawToolbarKey.currentContext?.size;
    if (size != null && size.isFinite) {
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

  /// 绘制工具条. drawToolbarBuilder优先, drawToolbar其次.
  Widget _buildDrawToolbar(BuildContext flexiKlineContext, Rect canvasRect) {
    if (widget.drawToolbarBuilder != null) {
      return widget.drawToolbarBuilder!(flexiKlineContext, controller);
    }
    if (widget.drawToolbar == null) return const SizedBox.shrink();

    final drawToolbarWrapper = SizedBox(
      key: _drawToolbarKey,
      child: widget.drawToolbar!,
    );

    // 内置拖拽: Draggable(跟手) + onDragEnd clamp回画布内.
    // return ValueListenableBuilder(
    //   valueListenable: controller.drawStateListenable,
    //   builder: (context, state, child) => Visibility(
    //     visible: state.isEditing,
    //     child: ValueListenableBuilder(
    //       valueListenable: _drawToolbarPosition,
    //       builder: (context, position, child) {
    //         if (position == Offset.infinite || !canvasRect.contains(position)) {
    //           position = Offset(0, canvasRect.height - 50);
    //         }
    //         return Positioned(
    //           left: position.dx,
    //           top: position.dy,
    //           child: MouseRegion(
    //             cursor: SystemMouseCursors.move,
    //             child: Draggable(
    //               key: const ValueKey('DrawToolbarDraggable'),
    //               feedback: drawToolbarWrapper,
    //               childWhenDragging: const SizedBox.shrink(),
    //               child: drawToolbarWrapper,
    //               onDragEnd: (details) {
    //                 final box = flexiKlineContext.findRenderObject() as RenderBox;
    //                 final newPosition = box.globalToLocal(details.offset);
    //                 configuration.saveDrawToolbarPosition(
    //                   _updateDrawToolbarPosition(newPosition, canvasRect),
    //                 );
    //               },
    //             ),
    //           ),
    //         );
    //       },
    //     ),
    //   ),
    // );

    // ── 备选方案: GestureDetector + onPan ──
    // 优点: onPanUpdate 中实时 clamp, 拖拽过程不会移出画布.
    // 缺点: ValueListenableBuilder rebuild 有一帧延迟, 跟手性不如 Draggable.
    return ValueListenableBuilder(
      valueListenable: controller.drawStateListenable,
      builder: (context, state, child) => Visibility(
        visible: state.isEditing,
        child: ValueListenableBuilder(
          valueListenable: _drawToolbarPosition,
          builder: (context, position, child) {
            if (position == Offset.infinite || !canvasRect.contains(position)) {
              position = Offset(0, canvasRect.height - 50);
            }
            return Positioned(
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  _updateDrawToolbarPosition(
                    position + details.delta * 2,
                    canvasRect,
                  );
                },
                onPanEnd: (_) {
                  configuration.saveDrawToolbarPosition(drawToolbarPosition);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.move,
                  child: drawToolbarWrapper,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 放大镜. magnifierBuilder优先, magnifierDecorationShapeBuilder其次.
  Widget _buildMagnifier(BuildContext context, Rect drawRect) {
    if (widget.magnifierBuilder != null) {
      return widget.magnifierBuilder!(context, controller);
    }

    final config = controller.drawConfig.magnifier;
    if (!config.enable || config.size.isEmpty) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder(
      valueListenable: controller.drawPointerListenable,
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
                      side: config.shapeSide.copyWith(
                        color: config.shapeSide.color == transparent
                            ? controller.theme.gridLineColor
                            : config.shapeSide.color,
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
    if (!controller.isDrawVisible) return;

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
