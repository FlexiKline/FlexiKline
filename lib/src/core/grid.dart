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
    if (gridConfig.show) {
      // 横向网格线
      _paintHorizontalGrid(canvas, size);

      // 纵向网格线
      _paintVerticalGrid(canvas, size);
    }

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

  /// 绘制横向网格线。
  void _paintHorizontalGrid(Canvas canvas, Size size) {
    if (!gridConfig.horizontal.show) return;
    final main = mainRect;
    final sub = subRect;

    double dy = main.top;

    // 顶部边框线
    canvas.drawLineByConfig(
      Path()
        ..moveTo(main.left, dy)
        ..lineTo(main.right, dy),
      gridConfig.horizontal.line,
      themeColor: theme.gridLineColor,
    );

    // 主区网格线
    final step = main.bottom / gridConfig.horizontal.count;
    for (int i = 1; i < gridConfig.horizontal.count; i++) {
      dy = i * step;
      canvas.drawLineByConfig(
        Path()
          ..moveTo(main.left, dy)
          ..lineTo(main.right, dy),
        gridConfig.horizontal.line,
        themeColor: theme.gridLineColor,
      );
    }

    // 主区底部分隔线
    canvas.drawLineByConfig(
      Path()
        ..moveTo(main.left, main.bottom)
        ..lineTo(main.right, main.bottom),
      gridConfig.horizontal.line,
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
        gridConfig.horizontal.line,
        themeColor: theme.gridLineColor,
      );
    }
  }

  /// 绘制纵向网格线。
  void _paintVerticalGrid(Canvas canvas, Size size) {
    if (!gridConfig.vertical.show) return;
    final main = mainRect;
    final sub = subRect;
    double dx = main.left;
    final step = main.right / gridConfig.vertical.count;

    // 左边框线
    canvas.drawLineByConfig(
      Path()
        ..moveTo(dx, main.top)
        ..lineTo(dx, sub.bottom),
      gridConfig.vertical.line,
      themeColor: theme.gridLineColor,
    );

    // 时间轴不绘制纵向副区网格线。
    double top = sub.top;
    double bottom = sub.bottom;
    switch (timePaintObject.position) {
      case DrawPosition.middle:
        top += timePaintObject.height;
      case DrawPosition.bottom:
        bottom -= timePaintObject.height;
    }

    // 主区与副区纵向网格线
    for (int i = 1; i < gridConfig.vertical.count; i++) {
      dx = i * step;

      // 主区竖线
      canvas.drawLineByConfig(
        Path()
          ..moveTo(dx, main.top)
          ..lineTo(dx, main.bottom),
        gridConfig.vertical.line,
        themeColor: theme.gridLineColor,
      );

      // 副区竖线
      canvas.drawLineByConfig(
        Path()
          ..moveTo(dx, top)
          ..lineTo(dx, bottom),
        gridConfig.vertical.line,
        themeColor: theme.gridLineColor,
      );
    }

    // 右边框线
    canvas.drawLineByConfig(
      Path()
        ..moveTo(main.right, main.top)
        ..lineTo(main.right, sub.bottom),
      gridConfig.vertical.line,
      themeColor: theme.gridLineColor,
    );
  }

  /// 测试 [position] 是否命中指标分隔线。
  bool onGridResizeStart(Offset position) {
    _upObject = _downObject = null;
    if (!gridConfig.isAllowDragIndicatorHeight) return false;

    final dy = position.dy;
    final minDistance = gridConfig.dragHitTestMinDistance;
    final minDistanceHalf = minDistance / 2;
    final list = subPaintObjects.where((obj) => obj.key != timeIndicatorKey);
    final lastObj = list.lastOrNull;
    for (final object in [mainPaintObject, ...list]) {
      if (object.drawableRect.hitTestBottom(
        dy - (object == lastObj ? minDistanceHalf : 0),
        minDistance: minDistance,
      )) {
        _upObject = object;
        continue;
      }
      if (_upObject != null) {
        _downObject = object;
        break;
      }
    }

    // fixed 下只能在两个区域之间分配高度，不能改变画布总高度。
    if (_upObject != null && (!isFixedLayoutMode || _downObject != null)) {
      markRepaintGrid();
      return true;
    }
    _upObject = _downObject = null;
    return false;
  }

  /// 拖拽更新指标高度。
  void onGridResizeUpdate(GestureData data) {
    if (!isStartDragGrid) return;

    final deltaDy = data.delta.dy;
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
