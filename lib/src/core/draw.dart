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
import '../framework/overlay_manager.dart';
import '../model/gesture_data.dart';
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
  void init() {
    super.init();
    _overlayManager = OverlayManager(
      configuration: configuration,
      drawBinding: this,
      logger: loggerDelegate,
    );
  }

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
    candleRequestListener.addListener(() {
      _overlayManager.switchCandleRequest(candleRequestListener.value);
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
    _overlayManager.saveOverlayListConfig(isClean: true);
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

  void _markRepaint() => _repaintDraw.value++;

  @override
  void markRepaintDraw() {
    _markRepaint();
  }

  Iterable<IDrawType> get supportDrawTypes => _overlayManager.supportDrawTypes;

  /// 自定义overlay绘制对象构建器
  void customOverlayDrawObjectBuilder(
    IDrawType type,
    DrawObjectBuilder builder,
  ) {
    _overlayManager.customOverlayDrawObjectBuilder(type, builder);
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

  late final OverlayManager _overlayManager;

  @override
  void onDrawPrepare() {
    // 如果是非退出状态, 则无需变更状态.
    if (!drawState.isExited) return;
    _drawState = const Prepared();
  }

  /// 开始绘制新的[type]类型
  /// 1. 重置状态为Drawing
  /// 2. 初始化第一个Point的位置为[initialPosition]
  @override
  void onDrawStart(IDrawType type) {
    cancelCross();
    if (drawState.overlay?.type == type) {
      _drawState = const Prepared();
    } else {
      _drawState = DrawState.draw(type, this);
      _drawState.overlay?.pointer = Point.pointer(0, initialPosition);
    }
    _markRepaint();
  }

  /// 更新当前指针坐标
  @override
  void onDrawUpdate(GestureData data) {
    if (!drawState.isOngoing) return;
    drawState.overlay?.pointer?.offset = data.offset;
    _markRepaint();
  }

  /// 确认动作
  /// 1. 将pointer指针offset转换为蜡烛坐标
  /// 2. 当前是drawing时:
  ///   2.1. 添加pointer到points中, 并重置pointer为下一个位置的指针.
  ///   2.2. 最后检查当前overlay是否绘制完成, 如果绘制完成切换状态为Editing.
  /// 3. 当状态为Editing时:
  ///   3.1. 更新pointer到points中, 并清空pointer(等待下一次的选择)
  @override
  void onDrawConfirm(GestureData data) {
    if (!drawState.isOngoing) return;
    final overlay = drawState.overlay;
    if (overlay == null) return;

    final pointer = overlay.pointer;
    if (pointer == null) return;

    final isOk = _convertPointer(pointer);
    if (!isOk) {
      logw('onDrawConfirm updatePointer failed! pointer:$pointer');
      return;
    }

    if (overlay.isDrawing) {
      overlay.addPointer(pointer);
      if (overlay.isEditing) {
        logi('onDrawConfirm ${overlay.type} draw completed!');
        _drawState = Editing(overlay);
      }
    } else if (overlay.isEditing) {
      overlay.updatePointer(pointer);
    }

    _markRepaint();
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
      if (_overlayManager.removeOverlay(overlay)) {
        _markRepaint();
      }
    } else {
      overlay = drawState.overlay;
      if (overlay != null) {
        // final object = _overlayToObjects.remove(overlay);
        // object?.dispose();
        _drawState = const Prepared();
        _markRepaint();
      }
    }
  }

  bool _convertPointer(Point pointer) {
    final offset = pointer.offset;
    final model = dxToCandle(offset.dx);
    final value = dyToValue(offset.dy);
    if (model != null && value != null) {
      pointer.ts = model.ts;
      pointer.value = value;
      return true;
    }
    return false;
  }

  @override
  Overlay? hitTestOverlay(Offset position) {
    // 测试[position]位置上是否有命中的Overly.
    Overlay? ret;
    for (var overlay in _overlayManager.overlayList) {
      final object = _overlayManager.getDrawObject(overlay);
      if (object != null && object.hitTest(position)) {
        ret = overlay;
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
    for (var overlay in _overlayManager.overlayList) {
      // TODO: 首先检测overlay是否在当前绘制区域内, 如果在, 则调用object进行绘制; 否则忽略.
      final object = _overlayManager.getDrawObject(overlay);
      if (object != null) {
        object.drawOverlay(canvas, size);
      }
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
      Point? pointer = overlay.pointer;
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
        } else if (pointer != null) {
          // TODO: 考虑如何预先创建drawObject
          _paintPointer(canvas, pointer.offset, last);
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
