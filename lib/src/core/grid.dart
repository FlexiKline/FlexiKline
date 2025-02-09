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

/// 负责Grid图层的绘制
///
/// 绘制底层的网络
mixin GridBinding on KlineBindingBase, SettingBinding implements IGrid, IChart {
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

  LineConfig? _horiLine;
  LineConfig? _vertLine;
  LineConfig? _dragLine;
  PaintObject? _upObject, _downObject;

  bool get isStartDragGrid {
    return gridConfig.isAllowDragIndicatorHeight && _upObject != null;
  }

  @override
  void onThemeChanged([covariant IFlexiKlineTheme? oldTheme]) {
    super.onThemeChanged(oldTheme);
    _horiLine = null;
    _vertLine = null;
    _dragLine = null;
  }

  void paintGridBg(Canvas canvas, Size size) {
    if (gridConfig.show) {
      /// 绘制horizontal轴 Grid 线
      _paintHorizontalGrid(canvas, size);

      /// 绘制Vertical轴 Grid 线
      _paintVerticalGrid(canvas, size);
    }

    /// 绘制拖拽分隔线
    _paintDragableLine(canvas, size);
  }

  /// 绘制可拖拽线标识与正在拖拽的线
  void _paintDragableLine(Canvas canvas, Size size) {
    final dragBg = theme.dragBg;

    _dragLine ??= gridConfig.dragLine?.of(paintColor: theme.dragBg);
    final dragLineHalf = (_dragLine?.paint.strokeWidth ?? 0) / 2;
    final dragLineLen = _dragLine?.length ?? 0;

    final minDistance = gridConfig.dragHitTestMinDistance;
    final minDistanceHalf = minDistance / 2;

    final list = subPaintObjects.where((obj) => obj.key != timeIndicatorKey);
    final lastObj = list.lastOrNull;
    for (var object in [mainPaintObject, ...list]) {
      if (isFixedLayoutMode && object == lastObj) {
        // 如果是固定布局模式, 最后一个指标图不能拖动
        return;
      }
      final objRect = object.drawableRect;
      if (_upObject != null && _upObject == object) {
        if (_dragLine != null) {
          canvas.drawLineByConfig(
            Path()
              ..moveTo(objRect.left, objRect.bottom - dragLineHalf)
              ..lineTo(objRect.right, objRect.bottom - dragLineHalf),
            _dragLine!,
          );
        } else if (gridConfig.draggingBgOpacity > 0) {
          // 绘制正在拖拽的object的底部线
          canvas.drawRectBackground(
            offset: Offset(
              objRect.left,
              objRect.bottom - minDistanceHalf,
            ),
            size: Size(objRect.width, minDistance),
            backgroundColor: dragBg.withOpacity(gridConfig.draggingBgOpacity),
          );
        }
      } else {
        if (_dragLine != null) {
          if (dragLineLen > 0) {
            final delta = (objRect.width - dragLineLen) / 2;
            canvas.drawLineType(
              LineType.solid,
              Path()
                ..moveTo(objRect.left + delta, objRect.bottom - dragLineHalf)
                ..lineTo(objRect.right - delta, objRect.bottom - dragLineHalf),
              _dragLine!.linePaint
                ..color = dragBg.withOpacity(gridConfig.dragLineOpacity),
              dashes: _dragLine!.dashes,
            );
          }
        } else if (gridConfig.dragBgOpacity > 0) {
          // 绘制当前object线底部拖拽标志
          canvas.drawRectBackground(
            offset: Offset(
              objRect.left,
              objRect.bottom - minDistanceHalf,
            ),
            size: Size(objRect.width, minDistance),
            backgroundColor: dragBg.withOpacity(gridConfig.dragBgOpacity),
          );
        }
      }
    }
  }

  /// 绘制horizontal轴 Grid 线
  void _paintHorizontalGrid(Canvas canvas, Size size) {
    if (!gridConfig.horizontal.show) return;
    final main = mainRect;
    final sub = subRect;

    _horiLine ??= gridConfig.horizontal.line.of(paintColor: theme.gridLine);
    double dy = main.top;

    // 绘制Top边框线
    canvas.drawLineByConfig(
      Path()
        ..moveTo(main.left, dy)
        ..lineTo(main.right, dy),
      _horiLine!,
    );

    // 绘制主图网格横线
    final step = main.bottom / gridConfig.horizontal.count;
    for (int i = 1; i < gridConfig.horizontal.count; i++) {
      dy = i * step;
      canvas.drawLineByConfig(
        Path()
          ..moveTo(main.left, dy)
          ..lineTo(main.right, dy),
        _horiLine!,
      );
    }

    // 绘制主图mainDrawBottom线
    canvas.drawLineByConfig(
      Path()
        ..moveTo(main.left, main.bottom)
        ..lineTo(main.right, main.bottom),
      _horiLine!,
    );

    /// 副图区域
    // 绘制每一个副图的底部线
    double height = 0.0;
    for (final object in subPaintObjects) {
      height += object.height;
      dy = sub.top + height;
      canvas.drawLineByConfig(
        Path()
          ..moveTo(main.left, dy)
          ..lineTo(main.right, dy),
        _horiLine!,
      );
    }
  }

  /// 绘制Vertical轴 Grid 线
  void _paintVerticalGrid(Canvas canvas, Size size) {
    if (!gridConfig.vertical.show) return;
    final main = mainRect;
    final sub = subRect;
    _vertLine ??= gridConfig.vertical.line.of(paintColor: theme.gridLine);

    double dx = main.left;
    final step = main.right / gridConfig.vertical.count;

    // 绘制左边框线
    canvas.drawLineByConfig(
      Path()
        ..moveTo(dx, main.top)
        ..lineTo(dx, sub.bottom),
      _vertLine!,
    );

    // 计算排除时间指标后的top和bottom
    double top = sub.top;
    double bottom = sub.bottom;
    switch (timePaintObject.position) {
      case DrawPosition.middle:
        top += timePaintObject.height;
      case DrawPosition.bottom:
        bottom -= timePaintObject.height;
    }

    // 绘制主区/副区的Vertical线
    for (int i = 1; i < gridConfig.vertical.count; i++) {
      dx = i * step;

      /// 绘制主区的Grid竖线
      canvas.drawLineByConfig(
        Path()
          ..moveTo(dx, main.top)
          ..lineTo(dx, main.bottom),
        _vertLine!,
      );

      /// 绘制副区Grid竖线
      canvas.drawLineByConfig(
        Path()
          ..moveTo(dx, top)
          ..lineTo(dx, bottom),
        _vertLine!,
      );
    }

    // 绘制右边框线
    canvas.drawLineByConfig(
      Path()
        ..moveTo(main.right, main.top)
        ..lineTo(main.right, sub.bottom),
      _vertLine!,
    );
  }

  /// 测试[position]是否命中指标图边界
  bool onGridMoveStart(Offset position) {
    _upObject = _downObject = null;
    if (!gridConfig.isAllowDragIndicatorHeight) return false;

    final dy = position.dy;
    final minDistance = gridConfig.dragHitTestMinDistance;
    final minDistanceHalf = minDistance / 2;
    final list = subPaintObjects.where((obj) => obj.key != timeIndicatorKey);
    final lastObj = list.lastOrNull;
    for (var object in [mainPaintObject, ...list]) {
      if (object.drawableRect.hitTestBottom(
        dy - (object == lastObj ? minDistanceHalf : 0),
        minDistance: minDistance,
      )) {
        _upObject = object;
        continue;
      }
      if (_upObject != null) {
        // if (object.drawableRect.hitTestTop(dy)) {
        _downObject = object;
        break;
      }
    }

    // 注: 固定模式下不允许调整画布的高度(即_downObject不能为空)
    if (_upObject != null && (!isFixedLayoutMode || _downObject != null)) {
      markRepaintGrid();
      return true;
    }
    _upObject = _downObject = null;
    return false;
  }

  /// 更新指标高度
  void onGridMoveUpdate(GestureData data) {
    if (!isStartDragGrid) return;

    final deltaDy = data.delta.dy;
    if (deltaDy != 0) {
      // >0 向下移动; <0 向上移动
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
        }
      } else {
        if (isMainIndicator) {
          setMainSize(Size(canvasWidth, upHeight));
        } else {
          _upObject?.doUpdateLayout(height: upHeight);
          // downObject为空说明[_upObject]已是最底部的指标, 此时向下向上移动将会导致整个canvas区域变化, 固force需要通知整个绘制区域高度.
          _invokeSizeChanged(force: true);
        }
      }

      markRepaintGrid();
    }
  }

  void onGridMoveEnd() {
    _upObject = _downObject = null;
    markRepaintGrid();
    markRepaintChart();
  }
}
