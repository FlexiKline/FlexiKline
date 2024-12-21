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

  void paintGridBg(Canvas canvas, Size size) {
    if (gridConfig.show) {
      // 主图图Grid X轴起始值
      final mainLeft = mainRect.left;
      final mainRight = mainRect.right;
      // 主图图Grid Y轴起始值
      final mainTop = mainRect.top;
      final mainBottom = mainRect.bottom;
      // 副图Grid Y轴起始值
      final subTop = subRect.top;
      final subBottom = subRect.bottom;

      /// 绘制horizontal轴 Grid 线
      if (gridConfig.horizontal.show) {
        final horiLine = gridConfig.horizontal.line;

        final dragPosition = _upObject?.drawableRect.bottom ?? 0;
        final minDistance = gridConfig.dragHitTestMinDistance;
        final dragLineConfig = gridConfig.dragLine ?? horiLine;

        double dy = mainTop;

        // 绘制Top边框线
        canvas.drawLineByConfig(
          Path()
            ..moveTo(mainLeft, dy)
            ..lineTo(mainRight, dy),
          horiLine,
        );

        // 绘制主图网格横线
        final step = mainBottom / gridConfig.horizontal.count;
        for (int i = 1; i < gridConfig.horizontal.count; i++) {
          dy = i * step;
          canvas.drawLineByConfig(
            Path()
              ..moveTo(mainLeft, dy)
              ..lineTo(mainRight, dy),
            horiLine,
          );
        }

        // 绘制主图mainDrawBottom线
        canvas.drawLineByConfig(
          Path()
            ..moveTo(mainLeft, mainBottom)
            ..lineTo(mainRight, mainBottom),
          (dragPosition - mainBottom).abs() < minDistance
              ? dragLineConfig
              : horiLine,
        );

        /// 副图区域
        // 绘制每一个副图的底部线
        double height = 0.0;
        for (final object in subPaintObjects) {
          height += object.height;
          dy = subTop + height;
          canvas.drawLineByConfig(
            Path()
              ..moveTo(mainLeft, dy)
              ..lineTo(mainRight, dy),
            (dragPosition - dy).abs() < minDistance ? dragLineConfig : horiLine,
          );
        }
      }

      /// 绘制Vertical轴 Grid 线
      if (gridConfig.vertical.show) {
        final vertLine = gridConfig.vertical.line;

        double dx = mainLeft;
        final step = mainRight / gridConfig.vertical.count;

        // 绘制左边框线
        canvas.drawLineByConfig(
          Path()
            ..moveTo(dx, mainTop)
            ..lineTo(dx, subBottom),
          vertLine,
        );

        // 计算排除时间指标后的top和bottom
        double top = subTop;
        double bottom = subBottom;
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
              ..moveTo(dx, mainTop)
              ..lineTo(dx, mainBottom),
            vertLine,
          );

          /// 绘制副区Grid竖线
          canvas.drawLineByConfig(
            Path()
              ..moveTo(dx, top)
              ..lineTo(dx, bottom),
            vertLine,
          );
        }

        // 绘制右边框线
        canvas.drawLineByConfig(
          Path()
            ..moveTo(mainRight, mainTop)
            ..lineTo(mainRight, subBottom),
          vertLine,
        );
      }
    }
  }

  PaintObject? _upObject, _downObject;
  bool get isStartDragGrid {
    return gridConfig.isAllowDragIndicatorHeight && _upObject != null;
  }

  /// 测试[position]是否命中指标图边界
  bool onGridMoveStart(Offset position) {
    _upObject = _downObject = null;
    if (!gridConfig.isAllowDragIndicatorHeight) return false;

    final dy = position.dy;
    final minDistance = gridConfig.dragHitTestMinDistance;
    final list = subPaintObjects.where((obj) => obj.key != timeIndicatorKey);
    for (var object in [mainPaintObject, ...list]) {
      if (object.drawableRect.hitTestBottom(dy, minDistance: minDistance)) {
        _upObject = object;
        continue;
      }
      if (_upObject != null) {
        // if (object.drawableRect.hitTestTop(dy)) {
        _downObject = object;
        break;
      }
    }

    if (_upObject != null && !isFixedSizeMode) {
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
      if (isMainIndicator && upHeight < mainMinimumHeight) {
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
          // downObject为空说明[_upObject]已是最底部的指标, 此时向下移动需要通知整个绘制区域高度.
          _invokeSizeChanged();
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
