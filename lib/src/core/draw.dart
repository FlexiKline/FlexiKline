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

import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../config/line_config/line_config.dart';
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/gesture_data.dart';
import '../overlay/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

/// 图形绘制层
/// 每一种图形绘制主要分为以下几步:
/// 1. 启动绘制绘制功能, 此时会阻隔事件传递到chart/cross层
/// 2. 选择绘制图类型, 此时会主动进行第一绘制点待确认状态, 即会以主图区域中心点坐标绘制十字线.
/// 3. 移动绘制点, 并确认第一绘制点, 并转换成蜡烛数据坐标记录到[Overlay]的points的first位置.
/// 4. 重复步骤3, 确认绘制图类型所需要的所有绘制点.
/// 5. 绘制完成后, 当前绘制图形默认为选中状态.
mixin DrawBinding on KlineBindingBase, SettingBinding implements IDraw, IState {
  @override
  void initState() {
    super.initState();
    logd('initState draw');
    _drawStateListener.addListener(() {
      // 子状态更新
      final state = _drawStateListener.value;
      _drawTypeListener.value = state.overlay?.type;
      _drawEditingListener.value = state.isEditing;
    });
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose draw');
    _drawTypeListener.dispose();
    _drawEditingListener.dispose();
    _drawStateListener.dispose();
    _repaintDraw.dispose();
  }

  @override
  String get chartKey => curDataKey;

  @override
  LineConfig get drawLineConfig => drawConfig.drawLine;

  @override
  Offset get initialPosition => mainRect.center;

  final ValueNotifier<int> _repaintDraw = ValueNotifier(0);

  @override
  Listenable get repaintDraw => _repaintDraw;
  void _markRepaint() {
    _repaintDraw.value++;
  }

  @override
  void markRepaintDraw() {
    _markRepaint();
  }

  /// DrawType的Overlay对应DrawObject的构建生成器集合
  final Map<IDrawType, DrawObjectBuilder> _overlayBuilders = {
    DrawType.trendLine: TrendLineDrawObject.new,
    DrawType.horizontalLine: HorizontalLineDrawObject.new,
  };

  Iterable<IDrawType>? _supportDrawType;
  Iterable<IDrawType> get supportDrawType {
    return _supportDrawType ??= _overlayBuilders.keys;
  }

  /// 自定义overlay绘制对象构建器
  void customOverlayDrawObjectBuilder(
    IDrawType type,
    DrawObjectBuilder builder,
  ) {
    _overlayBuilders[type] = builder;
    _supportDrawType = null;
  }

  DrawObject? createDrawObject(Overlay overlay) {
    final object = _overlayBuilders[overlay.type]?.call(overlay);
    return object;
  }

  final _drawStateListener = ValueNotifier(DrawState.exited());
  final _drawTypeListener = ValueNotifier<IDrawType?>(null);
  final _drawEditingListener = ValueNotifier(false);

  @override
  DrawState get drawState => _drawStateListener.value;
  DrawState get _drawState => _drawStateListener.value;
  set _drawState(DrawState state) {
    _drawStateListener.value = state;
  }

  @override
  ValueListenable<DrawState> get drawStateLinstener => _drawStateListener;

  @override
  ValueListenable<IDrawType?> get drawTypeListener => _drawTypeListener;

  @override
  ValueListenable<bool> get drawEditingListener => _drawEditingListener;

  /// overlay对应的DrawObject集合.
  final _overlayToObjects = <Overlay, DrawObject>{};

  @override
  void onDrawPrepare() {
    // 如果已不是退出状态, 则无需变更状态.
    if (!drawState.isExited) return;
    _drawState = const Prepared();
  }

  @override
  void onDrawStart(IDrawType type) {
    cancelCross();
    if (drawState.overlay?.type == type) {
      _drawState = const Prepared();
    } else {
      _drawState = DrawState.draw(type, this);
      _drawState.overlay?.pointer = initialPosition;
    }
    _markRepaint();
  }

  @override
  void onDrawUpdate(GestureData data) {
    if (!drawState.isOngoing) return;
    drawState.overlay?.pointer = data.offset;
    _markRepaint();
  }

  @override
  void onDrawConfirm(GestureData data) {
    if (!drawState.isDrawing) return;
    final offset = data.offset;
    final point = offsetToPoint(offset);
    final overlay = drawState.overlay;
    if (point != null && overlay != null) {
      overlay.updatePoint(point);
      if (overlay.isEditing == true) {
        // 说明绘制完成, 更新至_overlayToObjects
        _drawState = Editing(overlay);
        final object = createDrawObject(overlay);
        if (object != null) {
          _overlayToObjects[overlay] = object;
        } else {
          // 没有配置overlay的drawType对应的DrawObjectBuilder时的异常分支.
          _drawState = const Prepared();
        }
      }
      _markRepaint();
    }
  }

  @override
  void onDrawSelect(Overlay overlay) {
    if (!drawState.isPrepared) return;
    _drawState = DrawState.from(overlay);
    _markRepaint();
  }

  @override
  void onDrawExit() {
    _drawState = const Exited();
    _markRepaint();
  }

  void onDrawDelete({Overlay? overlay}) {
    if (overlay != null) {
      final object = _overlayToObjects.remove(overlay);
      object?.dispose();
      _markRepaint();
    } else {
      overlay = drawState.overlay;
      if (overlay != null) {
        final object = _overlayToObjects.remove(overlay);
        object?.dispose();
        _drawState = const Prepared();
        _markRepaint();
      }
    }
  }

  Point? offsetToPoint(Offset offset) {
    final model = dxToCandle(offset.dx);
    final value = dyToValue(offset.dy);
    if (model != null && value != null) {
      return Point(
        ts: model.ts,
        value: value.toDecimal(),
        offset: offset,
      );
    }
    return null;
  }

  @override
  Overlay? hitTestOverlay(Offset position) {
    // 测试[position]位置上是否有命中的Overly.
    Overlay? ret;
    for (var entry in _overlayToObjects.entries) {
      if (entry.value.hitTest(position)) {
        ret = entry.key;
        break;
      }
    }
    return ret;
  }

  /// 绘制Draw图层
  @override
  void paintDraw(Canvas canvas, Size size) {
    if (!drawConfig.enable) return;

    /// TODO: 遍历已完成绘制的Overlay对应的DrawObject去[paintDrawObject]
    for (var item in _overlayToObjects.entries) {
      // TODO: 首先检测overlay是否在当前绘制区域内, 如果在, 则调用object进行绘制; 否则忽略.
      // if ()
      item.value.drawOverlay(canvas, size);
    }

    paintDrawStateOverlay(canvas, size);
  }

  void paintDrawStateOverlay(Canvas canvas, Size size) {
    final overlay = drawState.overlay;
    if (overlay == null) return;
    if (overlay.isEditing) {
      for (var point in overlay.points) {
        canvas.drawCirclePoint(point!.offset, drawConfig.drawDot);
      }
    } else {
      Offset? last;
      Offset pointer = overlay.pointer;
      for (var point in overlay.points) {
        if (point != null) {
          final offset = point.offset;
          canvas.drawCirclePoint(offset, drawConfig.drawDot);
          if (last != null) {
            final linePath = Path()
              ..moveTo(offset.dx, offset.dy)
              ..lineTo(last.dx, last.dy);
            canvas.drawLineType(
              drawConfig.crosshair.type,
              linePath,
              drawConfig.crosshair.linePaint,
              dashes: drawConfig.crosshair.dashes,
            );
          }
          last = offset;
        } else {
          // TODO: 考虑如何预先创建drawObject
          _paintPointer(canvas, pointer, last);
          break;
        }
      }
    }
  }

  void _paintPointer(Canvas canvas, Offset pointer, Offset? last) {
    final path = Path()
      ..moveTo(mainChartLeft, pointer.dy)
      ..lineTo(mainChartRight, pointer.dy)
      ..moveTo(pointer.dx, 0)
      ..lineTo(pointer.dx, mainChartHeight);

    canvas.drawLineType(
      drawConfig.crosshair.type,
      path,
      drawConfig.crosshair.linePaint,
      dashes: drawConfig.crosshair.dashes,
    );
    if (last != null && last.isFinite) {
      final linePath = Path()
        ..moveTo(pointer.dx, pointer.dy)
        ..lineTo(last.dx, last.dy);
      canvas.drawLineType(
        drawConfig.crosshair.type,
        linePath,
        drawConfig.crosshair.linePaint,
        dashes: drawConfig.crosshair.dashes,
      );
    }
    canvas.drawCirclePoint(pointer, drawConfig.crosspoint);
  }
}
