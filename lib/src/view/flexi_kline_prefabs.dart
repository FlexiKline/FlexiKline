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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../extension/geometry_ext.dart';
import '../framework/configuration.dart';
import '../kline_controller.dart';

// ── DrawToolbar ──

/// 基于 [Draggable] 的绘制工具条.
///
/// 跟手性好, 但拖拽过程中 widget 可临时移出画布(overlay 机制),
/// onDragEnd 时 clamp 回 canvasRect 内.
///
/// 仅在 drawState.isEditing 时展示.
class FlexiDraggableDrawToolbar extends StatefulWidget {
  const FlexiDraggableDrawToolbar({
    super.key,
    required this.controller,
    required this.child,
    required this.klineContext,
    this.cursor = SystemMouseCursors.move,
    this.toolbarSize = const Size(100, 50),
  });

  final FlexiKlineController controller;
  final Widget child;

  /// [FlexiKlineWidget] 的 [BuildContext], 用于 [Draggable.onDragEnd] 时
  /// 将全局坐标转换为相对于 Kline 画布的局部坐标.
  final BuildContext klineContext;

  /// 拖拽时的鼠标光标样式.
  final MouseCursor cursor;

  /// 工具条的预估尺寸.
  ///
  /// 用于首次定位(无缓存时贴左下角)和缓存位置超出画布时的粗略 clamp.
  /// 不要求精确, 交互结束后会用真实尺寸校准.
  final Size toolbarSize;

  @override
  State<FlexiDraggableDrawToolbar> createState() => _FlexiDraggableDrawToolbarState();
}

class _FlexiDraggableDrawToolbarState extends State<FlexiDraggableDrawToolbar> {
  late final GlobalKey _toolbarKey = GlobalKey();
  late final ValueNotifier<Offset> _position;
  late Rect _canvasRect;
  late Size _lastToolbarSize;

  @override
  void initState() {
    super.initState();
    _canvasRect = widget.controller.canvasRect;
    _lastToolbarSize = widget.toolbarSize;
    final cached = widget.controller.configuration.getDrawToolbarPosition();
    _position = ValueNotifier(
      _clampPosition(
        cached.isFinite ? cached : _canvasRect.bottomLeft,
        size: _lastToolbarSize,
      ),
    );
    widget.controller.canvasRectListenable.addListener(_onCanvasRectChanged);
  }

  void _onCanvasRectChanged() {
    _canvasRect = widget.controller.canvasRect;
    _position.value = _clampPosition(
      _position.value,
      size: _lastToolbarSize,
    );
    widget.controller.configuration.saveDrawToolbarPosition(_position.value);
  }

  Offset _clampPosition(
    Offset pos, {
    Size? size,
  }) {
    if (size != null && size.isFinite) {
      _lastToolbarSize = size;
      return Offset(
        pos.dx.clamp(
          _canvasRect.left,
          math.max(_canvasRect.left, _canvasRect.right - size.width),
        ),
        pos.dy.clamp(
          _canvasRect.top,
          math.max(_canvasRect.top, _canvasRect.bottom - size.height),
        ),
      );
    }
    return pos.clamp(_canvasRect);
  }

  @override
  void dispose() {
    widget.controller.canvasRectListenable.removeListener(_onCanvasRectChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.controller.drawStateListenable,
      builder: (context, state, child) => Visibility(
        visible: state.isEditing,
        child: child!,
      ),
      child: ValueListenableBuilder(
        valueListenable: _position,
        builder: (context, position, child) {
          return Positioned(
            left: position.dx,
            top: position.dy,
            child: MouseRegion(
              cursor: widget.cursor,
              child: Draggable(
                feedback: child!,
                childWhenDragging: const SizedBox.shrink(),
                child: child,
                onDragEnd: (details) {
                  final box = widget.klineContext.findRenderObject() as RenderBox;
                  final pos = box.globalToLocal(details.offset);
                  _position.value = _clampPosition(
                    pos,
                    size: _toolbarKey.currentContext?.size,
                  );
                  widget.controller.configuration.saveDrawToolbarPosition(_position.value);
                },
              ),
            ),
          );
        },
        child: SizedBox(
          key: _toolbarKey,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 基于 [GestureDetector]+onPan 的绘制工具条.
///
/// 拖拽过程实时 clamp, widget 不会移出画布.
/// 通过 [panSpeedMultiplier] 补偿 ValueListenableBuilder 的一帧重建延迟.
///
/// 仅在 drawState.isEditing 时展示.
class FlexiPannableDrawToolbar extends StatefulWidget {
  const FlexiPannableDrawToolbar({
    super.key,
    required this.controller,
    required this.child,
    this.cursor = SystemMouseCursors.move,
    this.toolbarSize = const Size(100, 50),
    this.panSpeedMultiplier = 2.0,
  });

  final FlexiKlineController controller;
  final Widget child;

  /// 拖拽时的鼠标光标样式.
  final MouseCursor cursor;

  /// 工具条的预估尺寸.
  ///
  /// 用于首次定位(无缓存时贴左下角)和缓存位置超出画布时的粗略 clamp.
  /// 不要求精确, 交互结束后会用真实尺寸校准.
  final Size toolbarSize;

  /// onPanUpdate delta 乘数, 补偿重建延迟. 1.0=原速, 2.0=两倍速.
  final double panSpeedMultiplier;

  @override
  State<FlexiPannableDrawToolbar> createState() => _FlexiPannableDrawToolbarState();
}

class _FlexiPannableDrawToolbarState extends State<FlexiPannableDrawToolbar> {
  late final GlobalKey _toolbarKey = GlobalKey();
  late final ValueNotifier<Offset> _position;
  late Rect _canvasRect;
  late Size _lastToolbarSize;

  @override
  void initState() {
    super.initState();
    _canvasRect = widget.controller.canvasRect;
    _lastToolbarSize = widget.toolbarSize;
    final cached = widget.controller.configuration.getDrawToolbarPosition();
    _position = ValueNotifier(
      _clampPosition(
        cached.isFinite ? cached : _canvasRect.bottomLeft,
        size: _lastToolbarSize,
      ),
    );
    widget.controller.canvasRectListenable.addListener(_onCanvasRectChanged);
  }

  void _onCanvasRectChanged() {
    _canvasRect = widget.controller.canvasRect;
    _position.value = _clampPosition(
      _position.value,
      size: _lastToolbarSize,
    );
    widget.controller.configuration.saveDrawToolbarPosition(_position.value);
  }

  Offset _clampPosition(
    Offset pos, {
    Size? size,
  }) {
    if (size != null && size.isFinite) {
      _lastToolbarSize = size;
      return Offset(
        pos.dx.clamp(
          _canvasRect.left,
          math.max(_canvasRect.left, _canvasRect.right - size.width),
        ),
        pos.dy.clamp(
          _canvasRect.top,
          math.max(_canvasRect.top, _canvasRect.bottom - size.height),
        ),
      );
    }
    return pos.clamp(_canvasRect);
  }

  @override
  void dispose() {
    widget.controller.canvasRectListenable.removeListener(_onCanvasRectChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.controller.drawStateListenable,
      builder: (context, state, child) => Visibility(
        visible: state.isEditing,
        child: child!,
      ),
      child: ValueListenableBuilder(
        valueListenable: _position,
        builder: (context, position, child) {
          return Positioned(
            left: position.dx,
            top: position.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                _position.value = _clampPosition(
                  position + details.delta * widget.panSpeedMultiplier,
                  size: _toolbarKey.currentContext?.size,
                );
              },
              onPanEnd: (_) {
                _position.value = _clampPosition(
                  _position.value,
                  size: _toolbarKey.currentContext?.size,
                );
                widget.controller.configuration.saveDrawToolbarPosition(_position.value);
              },
              child: child!,
            ),
          );
        },
        child: MouseRegion(
          cursor: widget.cursor,
          child: SizedBox(
            key: _toolbarKey,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ── Loading ──

/// Loading指示器预制件.
///
/// 监听 [controller.loadingStateListenable], 在 showLoading 时展示.
/// 样式参数优先使用传入值, 未传时从 [controller.settingConfig.loading] 读取.
class FlexiLoading extends StatelessWidget {
  const FlexiLoading({
    super.key,
    required this.controller,
    this.alignment = Alignment.center,
    this.size,
    this.strokeWidth,
    this.backgroundColor,
    this.valueColor,
  });

  final FlexiKlineController controller;

  /// 指示器在主区内的对齐方式.
  final AlignmentGeometry alignment;

  /// 指示器尺寸. 为null时使用 LoadingConfig.size.
  final double? size;

  /// 线宽. 为null时使用 LoadingConfig.strokeWidth.
  final double? strokeWidth;

  /// 背景色. 为null时使用 LoadingConfig.backgroundColor ?? theme.tooltipBg.
  final Color? backgroundColor;

  /// 值颜色. 为null时使用 LoadingConfig.valueColor ?? theme.textColor.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final config = controller.settingConfig.loading;
    final theme = controller.theme;
    return ValueListenableBuilder(
      valueListenable: controller.loadingStateListenable,
      builder: (context, loadingState, child) {
        return Offstage(
          offstage: !(loadingState.showLoading && controller.settingConfig.autoLoadMoreData),
          child: child,
        );
      },
      child: Align(
        alignment: alignment,
        child: SizedBox.square(
          dimension: size ?? config.size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth ?? config.strokeWidth,
            backgroundColor: backgroundColor ?? config.backgroundColor ?? theme.tooltipBg,
            valueColor: AlwaysStoppedAnimation<Color>(
              valueColor ?? config.valueColor ?? theme.textColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ── ExitZoomButton ──

/// 退出缩放按钮预制件.
///
/// 监听 [controller.isChartZoomingListenable], 在缩放时展示.
/// 可通过 [visibleListenable] 外部控制始终展示.
/// 样式参数优先使用传入值, 未传时使用主题色.
class FlexiExitZoomButton extends StatelessWidget {
  const FlexiExitZoomButton({
    super.key,
    required this.controller,
    this.visibleListenable,
    this.alignment = AlignmentDirectional.bottomEnd,
    this.padding = const EdgeInsetsDirectional.all(12),
    this.buttonSize = const Size(20, 20),
    this.icon,
    this.borderRadius = 4,
    this.foregroundColor,
    this.backgroundColor,
    this.borderSide,
  });

  final FlexiKlineController controller;

  /// 外部可见性开关. 与 isChartZooming 做 OR 运算.
  /// 为null时仅由 isChartZooming 控制展示.
  final ValueListenable<bool>? visibleListenable;

  /// 按钮在主区内的对齐方式.
  final AlignmentGeometry alignment;

  /// 按钮外边距.
  final EdgeInsetsGeometry padding;

  /// 按钮尺寸.
  final Size buttonSize;

  /// 按钮图标. 为null时使用 Text('A').
  final Widget? icon;

  /// 圆角半径.
  final double borderRadius;

  /// 前景色. 为null时使用 theme.tooltipTextColor.
  final Color? foregroundColor;

  /// 背景色. 为null时使用 theme.tooltipBg * 0.8.
  final Color? backgroundColor;

  /// 边框. 为null时使用 BorderSide(color: theme.gridLineColor, width: 1).
  final BorderSide? borderSide;

  @override
  Widget build(BuildContext context) {
    final theme = controller.configuration.theme;
    return ListenableBuilder(
      listenable: Listenable.merge([
        visibleListenable,
        controller.isChartZoomingListenable,
      ]),
      child: Container(
        alignment: alignment,
        padding: padding,
        child: IconButton(
          onPressed: controller.exitChartZoom,
          constraints: const BoxConstraints(),
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            fixedSize: buttonSize,
            foregroundColor: foregroundColor ?? theme.tooltipTextColor,
            backgroundColor: backgroundColor ?? theme.tooltipBg.withAlpha(0xCC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            side: borderSide ?? BorderSide(color: theme.gridLineColor, width: 1),
          ),
          icon: icon ?? const Text('A', style: TextStyle(fontSize: 12)),
        ),
      ),
      builder: (context, child) {
        final forceVisible = visibleListenable?.value ?? false;
        return Visibility(
          visible: forceVisible || controller.isChartZooming,
          child: child!,
        );
      },
    );
  }
}

// ── Magnifier ──

/// 放大镜 decoration shape 定制签名.
typedef MagnifierDecorationShapeBuilder = ShapeBorder Function(
  BuildContext context,
  BorderSide side,
);

/// 绘制放大镜预制件.
///
/// 监听 [controller.drawPointerListenable], 在绘制指针可见时展示.
/// 样式参数优先使用传入值, 未传时从 [controller.drawConfig.magnifier] 读取.
class FlexiMagnifier extends StatelessWidget {
  const FlexiMagnifier({
    super.key,
    required this.controller,
    this.shapeBuilder,
    this.size,
    this.magnificationScale,
    this.decorationOpacity,
    this.margin,
  });

  final FlexiKlineController controller;

  /// 定制 decoration shape. 为null时使用 CircleBorder.
  final MagnifierDecorationShapeBuilder? shapeBuilder;

  /// 放大镜尺寸. 为null时使用 MagnifierConfig.size.
  final Size? size;

  /// 放大倍数. 为null时使用 MagnifierConfig.magnificationScale.
  final double? magnificationScale;

  /// decoration 透明度. 为null时使用 MagnifierConfig.decorationOpacity.
  final double? decorationOpacity;

  /// 放大镜外边距. 为null时使用 MagnifierConfig.margin.
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final config = controller.drawConfig.magnifier;
    if (!config.enable || config.size.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveSize = size ?? config.size;
    final effectiveScale = magnificationScale ?? config.magnificationScale;
    final effectiveOpacity = decorationOpacity ?? config.decorationOpacity;

    return ValueListenableBuilder(
      valueListenable: controller.drawPointerListenable,
      builder: (context, pointer, child) {
        bool visible = false;
        final pointerOffset = pointer?.offset;
        Offset focalPosition = Offset.zero;
        AlignmentGeometry alignment = AlignmentDirectional.topStart;
        EdgeInsets effectiveMargin = margin ?? config.margin;
        if (pointerOffset != null && pointerOffset.isFinite) {
          visible = true;
          final drawRect = controller.canvasRect;
          Offset position;
          if (pointerOffset.dx > drawRect.width * 0.5) {
            alignment = AlignmentDirectional.topStart;
            position = effectiveSize.center(effectiveMargin.topLeft);
            position = Offset(
              drawRect.left + position.dx,
              drawRect.top + position.dy,
            );
          } else {
            alignment = AlignmentDirectional.topEnd;
            final valueTxtWidth = controller.drawState.object?.valueTicksSize?.width ?? 0;
            effectiveMargin = effectiveMargin.copyWith(
              right: effectiveMargin.right + valueTxtWidth,
            );
            position = Offset(
              drawRect.right - effectiveMargin.right - effectiveSize.width / 2,
              drawRect.top + effectiveMargin.top + effectiveSize.height / 2,
            );
          }
          focalPosition = pointerOffset - position;
        }
        final theme = controller.theme;
        return Visibility(
          visible: visible,
          child: Container(
            alignment: alignment,
            margin: effectiveMargin,
            child: RawMagnifier(
              decoration: MagnifierDecoration(
                opacity: effectiveOpacity,
                shadows: config.decorationShadows ??
                    [
                      BoxShadow(
                        offset: const Offset(0.1, 0.1),
                        blurRadius: 2,
                        spreadRadius: 3,
                        color: theme.gridLineColor.withAlpha(0x1A),
                      ),
                    ],
                shape: shapeBuilder?.call(context, config.shapeSide) ??
                    CircleBorder(
                      side: config.shapeSide.copyWith(
                        color: config.shapeSide.color == const Color(0x00000000)
                            ? theme.gridLineColor
                            : config.shapeSide.color,
                      ),
                    ),
              ),
              size: effectiveSize,
              focalPointOffset: focalPosition,
              magnificationScale: effectiveScale,
            ),
          ),
        );
      },
    );
  }
}
