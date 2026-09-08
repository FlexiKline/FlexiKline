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
    this.cursor = SystemMouseCursors.move,
    this.defaultBottomOffset = 50,
  });

  final FlexiKlineController controller;
  final Widget child;

  /// 拖拽时的鼠标光标样式.
  final MouseCursor cursor;

  /// 无有效缓存位置时, 工具条距画布底部的默认偏移.
  final double defaultBottomOffset;

  @override
  State<FlexiDraggableDrawToolbar> createState() => _FlexiDraggableDrawToolbarState();
}

class _FlexiDraggableDrawToolbarState extends State<FlexiDraggableDrawToolbar> {
  late final GlobalKey _toolbarKey = GlobalKey();
  late final ValueNotifier<Offset> _position = ValueNotifier(
    widget.controller.configuration.getDrawToolbarPosition(),
  );

  Offset _clampPosition(Offset pos) {
    final canvasRect = widget.controller.canvasRect;
    final size = _toolbarKey.currentContext?.size;
    if (size != null && size.isFinite) {
      return Offset(
        pos.dx.clamp(
          canvasRect.left,
          math.max(canvasRect.left, canvasRect.right - size.width),
        ),
        pos.dy.clamp(
          canvasRect.top,
          math.max(canvasRect.top, canvasRect.bottom - size.height),
        ),
      );
    }
    return pos.clamp(canvasRect);
  }

  void _savePosition(Offset pos) {
    _position.value = _clampPosition(pos);
    widget.controller.configuration.saveDrawToolbarPosition(_position.value);
  }

  @override
  void dispose() {
    widget.controller.configuration.saveDrawToolbarPosition(_position.value);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wrappedChild = SizedBox(
      key: _toolbarKey,
      child: widget.child,
    );
    return ValueListenableBuilder(
      valueListenable: widget.controller.drawStateListenable,
      builder: (context, state, child) => Visibility(
        visible: state.isEditing,
        child: child!,
      ),
      child: ValueListenableBuilder(
        valueListenable: _position,
        builder: (context, position, child) {
          final canvasRect = widget.controller.canvasRect;
          if (position == Offset.infinite || !canvasRect.contains(position)) {
            position = Offset(
              0,
              canvasRect.height - widget.defaultBottomOffset,
            );
          }
          return Positioned(
            left: position.dx,
            top: position.dy,
            child: MouseRegion(
              cursor: widget.cursor,
              child: Draggable(
                feedback: wrappedChild,
                childWhenDragging: const SizedBox.shrink(),
                child: wrappedChild,
                onDragEnd: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  _savePosition(box.globalToLocal(details.offset));
                },
              ),
            ),
          );
        },
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
    this.defaultBottomOffset = 50,
    this.panSpeedMultiplier = 2.0,
  });

  final FlexiKlineController controller;
  final Widget child;

  /// 拖拽时的鼠标光标样式.
  final MouseCursor cursor;

  /// 无有效缓存位置时, 工具条距画布底部的默认偏移.
  final double defaultBottomOffset;

  /// onPanUpdate delta 乘数, 补偿重建延迟. 1.0=原速, 2.0=两倍速.
  final double panSpeedMultiplier;

  @override
  State<FlexiPannableDrawToolbar> createState() => _FlexiPannableDrawToolbarState();
}

class _FlexiPannableDrawToolbarState extends State<FlexiPannableDrawToolbar> {
  late final GlobalKey _toolbarKey = GlobalKey();
  late final ValueNotifier<Offset> _position = ValueNotifier(
    widget.controller.configuration.getDrawToolbarPosition(),
  );

  Offset _clampPosition(Offset pos) {
    final canvasRect = widget.controller.canvasRect;
    final size = _toolbarKey.currentContext?.size;
    if (size != null && size.isFinite) {
      return Offset(
        pos.dx.clamp(
          canvasRect.left,
          math.max(canvasRect.left, canvasRect.right - size.width),
        ),
        pos.dy.clamp(
          canvasRect.top,
          math.max(canvasRect.top, canvasRect.bottom - size.height),
        ),
      );
    }
    return pos.clamp(canvasRect);
  }

  void _savePosition(Offset pos) {
    _position.value = _clampPosition(pos);
    widget.controller.configuration.saveDrawToolbarPosition(_position.value);
  }

  @override
  void dispose() {
    widget.controller.configuration.saveDrawToolbarPosition(_position.value);
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
          final canvasRect = widget.controller.canvasRect;
          if (position == Offset.infinite || !canvasRect.contains(position)) {
            position = Offset(
              0,
              canvasRect.height - widget.defaultBottomOffset,
            );
          }
          // onPanUpdate 闭包捕获 position, 每次值不同, 内层无法用 child.
          return Positioned(
            left: position.dx,
            top: position.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                _position.value = _clampPosition(
                  position + details.delta * widget.panSpeedMultiplier,
                );
              },
              onPanEnd: (_) => _savePosition(_position.value),
              child: MouseRegion(
                cursor: widget.cursor,
                child: SizedBox(
                  key: _toolbarKey,
                  child: widget.child,
                ),
              ),
            ),
          );
        },
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
