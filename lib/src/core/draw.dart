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

import '../config/export.dart';
import '../extension/export.dart';
import '../framework/export.dart';
import '../framework/overlay_manager.dart';
import '../model/bag_num.dart';
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
      _overlayManager.onChangeCandleRequest(candleRequestListener.value);
    });
    candleDrawIndexListener.addListener(() {
      if (candleDrawIndexListener.value != null) {
        Future(_markRepaint);
      }
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
  DrawConfig get config => drawConfig;

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
  // DrawState get _drawState => _drawStateListener.value;
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
      final overlay = _overlayManager.createOverlay(type);
      _drawState = DrawState.draw(overlay);
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
  ///   2.3. 将overlay加入到_overlayManager中进行管理.
  /// 3. 当状态为Editing时:
  ///   3.1. 更新pointer到points中, 并清空pointer(等待下一次的选择)
  @override
  void onDrawConfirm(GestureData data) {
    if (!drawState.isOngoing) return;
    final overlay = drawState.overlay;
    if (overlay == null) return;

    if (overlay.isDrawing) {
      final pointer = overlay.pointer;
      if (pointer == null) return;

      final isOk = updatePointByOffset(pointer);
      if (!isOk) {
        logw('onDrawConfirm updatePointer failed! pointer:$pointer');
        return;
      }
      overlay.addPointer(pointer);

      if (overlay.isEditing) {
        logi('onDrawConfirm ${overlay.type} draw completed!');
        // 绘制完成, 使用drawLine配置绘制实线.
        overlay.line = config.drawLine;
        _drawState = Editing(overlay);
        _overlayManager.addOverlay(overlay);
      }
    } else if (overlay.isEditing) {
      final pointer = overlay.pointer;
      if (pointer == null) {
        // 当前处于编辑状态, 但是pointer又没有被赋值, 此时点击事件, 为确认完成.
        _overlayManager.addOverlay(overlay);
        _drawState = const Prepared();
      } else {
        final isOk = updatePointByOffset(pointer);
        if (!isOk) {
          logw('onDrawConfirm updatePointer failed! pointer:$pointer');
          return;
        }
        overlay.updatePointer(pointer);
      }
    }

    _markRepaint();
  }

  @override
  void onDrawSelect(Overlay overlay) {
    if (!drawState.isPrepared) return;
    _drawState = DrawState.edit(overlay);
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
        _overlayManager.removeOverlay(overlay);
        _drawState = const Prepared();
        _markRepaint();
      }
    }
  }

  /// 以当前蜡烛图绘制参数为基础, 将绘制参数[point]转换Offset坐标.
  bool updatePointByValue(Point point, {int? ts, BagNum? value}) {
    value ??= point.value;
    final dy = valueToDy(value);
    if (dy == null) return false;

    ts ??= point.ts;
    final index = curKlineData.timestampToIndex(ts);
    if (index == null) return false;
    final dx = indexToDx(index);
    if (dx == null) return false;

    point.ts = ts;
    point.value = value;
    point.offset = Offset(dx, dy);
    return true;
  }

  /// 以当前蜡烛图绘制参数为基础, 将绘制参数[offset]转换Point坐标.
  bool updatePointByOffset(Point point, {Offset? offset}) {
    offset ??= point.offset;
    final index = dxToIndex(offset.dx);
    if (index == null) return false;
    final ts = curKlineData.indexToTimestamp(index);
    if (ts == null) return false;

    final value = dyToValue(offset.dy);
    if (value == null) return false;

    point.offset = offset;
    point.ts = ts;
    point.value = value;
    return true;
  }

  @override
  Overlay? hitTestOverlay(Offset position) {
    // 测试[position]位置上是否有命中的Overly.
    Overlay? ret = _overlayManager.hitTestOverlay(position);
    return ret;
  }

  /// 绘制Draw图层
  @override
  void paintDraw(Canvas canvas, Size size) {
    logd('paintDraw ${canvas.hashCode}');
    if (!drawConfig.enable) return;

    /// 首先绘制已完成的overlayList
    drawOverlayList(canvas, size);

    /// 最后绘制当前处于Drawing或Editing状态的Overlay.
    drawStateOverlay(canvas, size);
  }

  /// 绘制已完成的OverlayList
  void drawOverlayList(Canvas canvas, Size size) {
    final stateOverlay = drawState.overlay;
    final drawRange = curKlineData.drawTimeRange;
    if (drawRange == null) {
      logw('drawOverlayList can not draw, because drawRange is null');
      return;
    }

    for (var overlay in _overlayManager.overlayList) {
      /// 如果是当前编辑的overlay不用绘制
      if (stateOverlay == overlay) continue;

      /// 检查overlay是否在当前蜡烛图绘制范围内, 如何存在才绘制overlay
      final timeRange = overlay.timeRange;
      if (timeRange != null && drawRange.contains(timeRange)) {
        // _calcuatePointsOffset(overlay);
        DrawObject? object = _overlayManager.getDrawObject(overlay);
        if (object != null) {
          object.drawOverlay(canvas, size);
        }
      }
    }
  }

  void drawStateOverlay(Canvas canvas, Size size) {
    final overlay = drawState.overlay;
    if (overlay == null) return;

    if (drawState is Editing && overlay.isEditing) {
      final object = _overlayManager.getDrawObject(overlay);
      object?.drawOverlay(canvas, size);
      // 绘制编辑状态的overlay的points为圆圈.
      object?.drawPointsAsCircles(canvas, config.drawPoint);
    } else if (drawState is Drawing && overlay.isDrawing) {
      // 步数即将完成, 构建object进行预绘制
      if (overlay.isComplete) {
        overlay.object ??= _overlayManager.createDrawObject(overlay);
        overlay.object?.drawOverlay(canvas, size);

        if (overlay.pointer != null) {
          _paintPointer(canvas, overlay.pointer!.offset, null);
        }
        // 绘制编辑状态的overlay的points为圆圈.
        overlay.object?.drawPointsAsCircles(canvas, config.drawPoint);
      } else {
        // 步数未完成时, 将overlay已确认的points与pointer联合绘制.
        Offset? last;
        Point? pointer = overlay.pointer;
        for (var point in overlay.points) {
          if (point != null) {
            final offset = point.offset;
            canvas.drawCirclePoint(offset, drawConfig.drawPoint);
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
            _paintPointer(canvas, pointer.offset, last);
            break;
          }
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
