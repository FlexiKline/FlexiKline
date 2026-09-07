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

part of 'core.dart';

/// 负责 Grid 图层绘制。
///
/// 包含网格线与指标高度拖拽线。
mixin GridBinding on KlineBindingBase, SettingBinding {
  @override
  void initState() {
    super.initState();
    logd('initState grid');
  }

  @override
  void dispose() {
    _upObject = _downObject = null;
    super.dispose();
    logd('dispose grid');
    _repaintGridBg.dispose();
  }

  final ValueNotifier<int> _repaintGridBg = ValueNotifier(0);
  Listenable get repaintGridBg => _repaintGridBg;

  @override
  void markRepaintGrid() => _repaintGridBg.value++;

  PaintObject? _upObject, _downObject;

  bool get isStartDragGrid {
    return gridConfig.isAllowDragIndicatorHeight && _upObject != null;
  }

  void paintGrid(Canvas canvas, Size size) {
    // 横向边框与 pane 分隔线
    _paintHorizontalBorder(canvas, size);

    // 左右边框
    _paintVerticalBorder(canvas, size);

    // 拖拽分隔线
    if (gridConfig.isAllowDragIndicatorHeight) {
      _paintDraggableLine(canvas, size);
    }
  }

  /// 绘制可拖拽线标识与正在拖拽的线
  void _paintDraggableLine(Canvas canvas, Size size) {
    final dragBg = theme.dragBg;

    final dragLine = gridConfig.dragLine;
    final dragLineHalf = (dragLine?.paint.strokeWidth ?? 0) / 2;
    final dragLineLen = dragLine?.length ?? 0;

    final minDistance = gridConfig.dragHitTestMinDistance;
    final minDistanceHalf = minDistance / 2;

    final list = subPaintObjects.where((obj) => obj.key != timeIndicatorKey);
    final lastObj = list.lastOrNull;
    for (final object in [mainPaintObject, ...list]) {
      if (isFixedLayoutMode && object == lastObj) {
        // fixed 下最后一个副区不能继续向下拖动。
        return;
      }
      final objRect = object.drawableRect;
      if (_upObject != null && _upObject == object) {
        if (dragLine != null) {
          canvas.drawLineByConfig(
            Path()
              ..moveTo(objRect.left, objRect.bottom - dragLineHalf)
              ..lineTo(objRect.right, objRect.bottom - dragLineHalf),
            dragLine,
            themeColor: theme.markLineColor,
          );
        } else if (gridConfig.draggingBgOpacity > 0) {
          // 正在拖拽的底部热区。
          canvas.drawRectBackground(
            offset: Offset(
              objRect.left,
              objRect.bottom - minDistanceHalf,
            ),
            size: Size(objRect.width, minDistance),
            backgroundColor: dragBg.withAlpha(gridConfig.draggingBgOpacity.alpha),
          );
        }
      } else {
        if (dragLine != null) {
          if (dragLineLen > 0) {
            final delta = (objRect.width - dragLineLen) / 2;
            canvas.drawLineType(
              LineType.solid,
              Path()
                ..moveTo(objRect.left + delta, objRect.bottom - dragLineHalf)
                ..lineTo(objRect.right - delta, objRect.bottom - dragLineHalf),
              dragLine.getLinePaint(dragBg.withAlpha(gridConfig.dragLineOpacity.alpha)),
              dashes: dragLine.dashes,
            );
          }
        } else if (gridConfig.dragBgOpacity > 0) {
          // 可拖拽的底部热区。
          canvas.drawRectBackground(
            offset: Offset(
              objRect.left,
              objRect.bottom - minDistanceHalf,
            ),
            size: Size(objRect.width, minDistance),
            backgroundColor: dragBg.withAlpha(gridConfig.dragBgOpacity.alpha),
          );
        }
      }
    }
  }

  /// 绘制主区顶边框与各 pane 底部分隔线。
  ///
  /// 网格横线不在此绘制: 它与 Y 轴刻度文本同源, 由 chart 层的
  /// [CandleBasePaintObject.paintGridLines] 产出, 才能保证线与文本用同一帧的
  /// minMax。grid 层因此只余布局线, 与价格无关。
  void _paintHorizontalBorder(Canvas canvas, Size size) {
    if (!gridConfig.horizontal.show) return;
    final border = gridConfig.horizontal.line;
    final main = mainRect;
    final sub = subRect;

    double dy = main.top;

    // 顶部边框线
    canvas.drawLineByConfig(
      Path()
        ..moveTo(main.left, dy)
        ..lineTo(main.right, dy),
      border,
      themeColor: theme.gridLineColor,
    );

    // 主区底部分隔线
    canvas.drawLineByConfig(
      Path()
        ..moveTo(main.left, main.bottom)
        ..lineTo(main.right, main.bottom),
      border,
      themeColor: theme.gridLineColor,
    );

    // 副区底部分隔线
    double height = 0.0;
    for (final object in subPaintObjects) {
      height += object.height;
      dy = sub.top + height;
      canvas.drawLineByConfig(
        Path()
          ..moveTo(main.left, dy)
          ..lineTo(main.right, dy),
        border,
        themeColor: theme.gridLineColor,
      );
    }
  }

  /// 绘制左右边框, 贯穿主区到副区底。
  ///
  /// 网格竖线不在此绘制: 它归主区蜡烛(`CandleBaseIndicator.verticalGrid`), 宿主自定义
  /// Candle 指标时才拿得到竖线的定制权。
  void _paintVerticalBorder(Canvas canvas, Size size) {
    if (!gridConfig.vertical.show) return;
    final border = gridConfig.vertical.line;
    final main = mainRect;
    final sub = subRect;

    // 左边框线
    canvas.drawLineByConfig(
      Path()
        ..moveTo(main.left, main.top)
        ..lineTo(main.left, sub.bottom),
      border,
      themeColor: theme.gridLineColor,
    );

    // 右边框线
    canvas.drawLineByConfig(
      Path()
        ..moveTo(main.right, main.top)
        ..lineTo(main.right, sub.bottom),
      border,
      themeColor: theme.gridLineColor,
    );
  }

  /// 询问 [position] 是否命中某条指标分隔线，不产生任何状态变更。
  ///
  /// 命中规则与 [onGridResizeStart] 严格同源（两者共用 [_findResizeCandidates]），
  /// 只是不认领。配合 [NonTouchGestureOwner] 的归属判定，在 hover 时安全调用。
  bool hitTestGridResize(Offset position) {
    final (up, down) = _findResizeCandidates(position.dy);
    if (up == null) return false;
    // fixed 下只能在两个区域之间分配高度，不能改变画布总高度。
    return !isFixedLayoutMode || down != null;
  }

  /// 测试 [position] 是否命中指标分隔线，命中则认领并触发重绘。
  bool onGridResizeStart(Offset position) {
    _upObject = _downObject = null;
    final (up, down) = _findResizeCandidates(position.dy);
    if (up == null) return false;

    // fixed 下只能在两个区域之间分配高度，不能改变画布总高度。
    if (!isFixedLayoutMode || down != null) {
      _upObject = up;
      _downObject = down;
      markRepaintGrid();
      return true;
    }
    return false;
  }

  /// 按 [dy] 在分隔线带中查找上下候选 PaintObject。
  ///
  /// 两个公开入口 [hitTestGridResize] 与 [onGridResizeStart] 共用此方法，
  /// 同源是结构保证而非纪律。
  (PaintObject? up, PaintObject? down) _findResizeCandidates(double dy) {
    if (!gridConfig.isAllowDragIndicatorHeight) return (null, null);

    final minDistance = gridConfig.dragHitTestMinDistance;
    final minDistanceHalf = minDistance / 2;
    final list = subPaintObjects.where((obj) => obj.key != timeIndicatorKey);
    final lastObj = list.lastOrNull;
    PaintObject? up;
    for (final object in [mainPaintObject, ...list]) {
      if (object.drawableRect.hitTestBottom(
        dy - (object == lastObj ? minDistanceHalf : 0),
        minDistance: minDistance,
      )) {
        up = object;
        continue;
      }
      if (up != null) {
        return (up, object);
      }
    }
    return (up, null);
  }

  /// 拖拽更新指标高度。
  ///
  /// [deltaDy] 为本帧纵向位移增量, 由手势层差分得出。>0 向下、<0 向上。
  void onGridResizeUpdate(double deltaDy) {
    if (!isStartDragGrid) return;

    if (deltaDy != 0) {
      // >0 向下，<0 向上。
      final bool isMainIndicator = _upObject is MainPaintObject;

      final subMinHeight = settingConfig.subMinHeight;
      final upHeight = _upObject!.height + deltaDy;
      if (isMainIndicator && upHeight < mainMinSize.height) {
        return;
      } else if (upHeight < subMinHeight) {
        return;
      }

      if (_downObject != null) {
        final height = _downObject!.height - deltaDy;
        if (height < subMinHeight) return;

        if (isMainIndicator) {
          _downObject?.doUpdateLayout(height: height);
          setMainSize(Size(canvasWidth, upHeight));
        } else {
          _upObject?.doUpdateLayout(height: upHeight);
          _downObject?.doUpdateLayout(height: height);
          markRepaintChart();
          markRepaintGrid();
        }
      } else {
        if (isMainIndicator) {
          setMainSize(Size(canvasWidth, upHeight));
        } else {
          _upObject?.doUpdateLayout(height: upHeight);
          // 最底部副区改变高度会改变 adapt 画布总高度，需要强制通知。
          _notifyCanvasSizeChanged(force: true);
        }
      }
    }
  }

  void onGridResizeEnd() {
    _upObject = _downObject = null;
    markRepaintGrid();
    markRepaintChart();
  }
}
