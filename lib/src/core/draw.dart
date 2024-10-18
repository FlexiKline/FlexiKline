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
import '../framework/draw/overlay.dart';
import '../framework/export.dart';
import '../model/bag_num.dart';
import '../model/gesture_data.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

/// 图形绘制
mixin DrawBinding
    on KlineBindingBase, SettingBinding
    implements IDraw, IState, IDrawContext {
  @override
  void init() {
    super.init();
    logd("init draw");
    _overlayManager = OverlayManager(
      configuration: configuration,
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
      _drawLineStyleListener.value = state.overlay?.lineConfig;
    });
    candleRequestListener.addListener(() {
      _overlayManager.onChangeCandleRequest(candleRequestListener.value);
    });
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose draw');
    _drawLineStyleListener.dispose();
    _drawTypeListener.dispose();
    _drawEditingListener.dispose();
    _drawStateListener.dispose();
    _repaintDraw.dispose();
    _overlayManager.disposeSyncAllOverlay();
  }

  @override
  DrawConfig get config => drawConfig;

  final ValueNotifier<int> _repaintDraw = ValueNotifier(0);

  @override
  Listenable get repaintDraw => _repaintDraw;

  void _markRepaint() => _repaintDraw.value++;

  @override
  void markRepaintDraw() {
    if (drawState.isOngoing || _overlayManager.hasOverlay) {
      _markRepaint();
    }
  }

  Iterable<IDrawType> get supportDrawTypes => _overlayManager.supportDrawTypes;

  /// 自定义overlay绘制对象构建器
  void registerOverlayDrawObjectBuilder(
    IDrawType type,
    DrawObjectBuilder builder,
  ) {
    _overlayManager.registerOverlayDrawObjectBuilder(type, builder);
  }

  final _drawStateListener = KlineStateNotifier(DrawState.exited());
  final _drawTypeListener = ValueNotifier<IDrawType?>(null);
  final _drawEditingListener = ValueNotifier(false);
  final _drawLineStyleListener = KlineStateNotifier<LineConfig?>(null);

  /// 主动通知绘制状态变化
  void _notifyDrawStateChange() => _drawStateListener.notifyListeners();

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

  ValueListenable<LineConfig?> get drawLineStyleListener =>
      _drawLineStyleListener;

  late final OverlayManager _overlayManager;

  @override
  void onDrawPrepare() {
    // 如果是非退出状态, 则无需变更状态.
    if (!drawState.isExited) return;
    _drawState = const Prepared();
    cancelCross();
  }

  /// 开始绘制新的[type]类型
  /// 1. 重置状态为Drawing
  /// 2. 初始化第一个Point的位置为[mainRect]中心
  @override
  void onDrawStart(IDrawType type) {
    cancelCross();
    if (drawState.overlay?.type == type) {
      _drawState = const Prepared();
    } else {
      final overlay = _overlayManager.createOverlay(type, config.crosshair);
      // 初始指针为[mainRect]中心
      overlay.setPointer(Point.pointer(0, mainRect.center));
      _drawState = DrawState.draw(overlay);
    }
    _markRepaint();
  }

  /// 更新当前指针坐标
  @override
  void onDrawUpdate(GestureData data) {
    if (!drawState.isDrawing) return;
    final overlay = drawState.overlay!;
    final pointer = overlay.pointer;
    if (pointer == null) {
      assert(() {
        logw('onDrawUpdate drawing ${overlay.type}, pointer is null!');
        return true;
      }());
      return;
    }
    final object = _overlayManager.getDrawObject(overlay);
    object?.onUpdatePoint(
      pointer,
      pointer.offset + data.delta,
    ); // TODO: 考虑对指针的更新封装到overlay中.
    _markRepaint();
  }

  /// 确认动作.
  /// 1. 将pointer指针offset转换为蜡烛坐标
  /// 2. 当前是drawing时:
  ///   2.1. 添加pointer到points中, 并重置pointer为下一个位置的指针.
  ///   2.2. 最后检查当前overlay是否绘制完成, 如果绘制完成切换状态为Editing.
  ///   2.3. 将overlay加入到_overlayManager中进行管理.
  /// 3. 当状态为Editing时:
  ///   3.1. 更新pointer到points中, 并清空pointer(等待下一次的选择)
  @override
  bool onDrawConfirm(GestureData data) {
    final overlay = drawState.overlay;
    if (overlay == null) return false;

    bool result = false;
    if (overlay.isDrawing) {
      Point? pointer = overlay.pointer;
      if (pointer == null) {
        // 可能永远不会触发
        final index = overlay.nextIndex;
        pointer = Point.pointer(index, data.offset);
      }

      final isOk = updatePointByOffset(pointer);
      if (!isOk) {
        logw('onDrawConfirm updatePointer failed! pointer:$pointer');
        return false;
      }
      overlay.addPointer(pointer);

      if (overlay.isEditing) {
        logi('onDrawConfirm ${overlay.type} draw completed!');
        // 绘制完成, 使用drawLine配置绘制实线.
        _drawState = Editing(overlay);
        _overlayManager.addOverlay(overlay);
        final object = _overlayManager.getDrawObject(overlay);
        object?.setDrawLineConfig(config.drawLine);
        result = false;
      } else {
        result = true;
      }
    } else if (overlay.isEditing) {
      final pointer = overlay.pointer;
      if (pointer == null) {
        // 当前处于编辑状态, 但是pointer又没有被赋值, 此时点击事件, 为确认完成.
        _overlayManager.addOverlay(overlay);
        // TODO: 增加object接口, 校正所有绘制点
        _drawState = const Prepared();
        result = false;
      } else {
        final isOk = updatePointByOffset(pointer);
        if (!isOk) {
          logw('onDrawConfirm updatePointer failed! pointer:$pointer');
          return false;
        }
        overlay.confirmPointer();
        result = false;
      }
    }

    _markRepaint();
    return result;
  }

  bool onDrawMoveStart(GestureData data) {
    if (!drawState.isEditing) return false; // 未完成的暂不允许移动
    final overlay = drawState.overlay!;
    final object = _overlayManager.getDrawObject(overlay);
    if (object == null) {
      assert(() {
        loge('onDrawMoveStart Failed to create Object for ${overlay.type}');
        return true;
      }());
      return false;
    }

    final position = data.offset;
    // 检查是否在某个绘制点上
    final point = object.hitTestPoint(this, position);
    if (point != null) {
      logd('onDrawMoveStart index:${point.index} point:$point');
      overlay.setPointer(point);
      overlay.setMoveing(true);
      _notifyDrawStateChange();
      _markRepaint();
      return true;
    } else if (object.hitTest(this, position, isMove: true) == true) {
      // 检查当前焦点是否命中Overlay
      overlay.setPointer(null);
      overlay.setMoveing(true);
      _notifyDrawStateChange();
      _markRepaint();
      return true;
    }

    return false;
  }

  /// 移动Overlay
  void onDrawMoveUpdate(GestureData data) {
    if (!drawState.isEditing) return; // 未完成的暂不允许移动
    final overlay = drawState.overlay!;

    final delta = data.delta;
    final object = _overlayManager.getDrawObject(overlay);
    if (overlay.pointer != null) {
      // 当前移动一个编辑状态的Overlay的某个绘制点指针时,
      // 需要通过[DrawObject]的`onUpdatePoint`接口来校正offset.
      object?.onUpdatePoint(
        overlay.pointer!,
        overlay.pointer!.offset + delta,
        isMove: true,
      );
    } else {
      object?.onMoveOverlay(delta);
    }
    _notifyDrawStateChange();
    _markRepaint();
  }

  void onDrawMoveEnd() {
    if (!drawState.isEditing) return; // 未完成的暂不允许移动
    final overlay = drawState.overlay!;

    final pointer = overlay.pointer;
    if (pointer != null) {
      logd('onDrawMoveEnd index:${pointer.index} point:$pointer');
      overlay.confirmPointer();
    }
    for (var point in overlay.points) {
      if (point != null) {
        updatePointByOffset(point);
      }
    }
    overlay.setMoveing(false);
    _notifyDrawStateChange();
    _markRepaint();
  }

  @override
  void onDrawSelect(Overlay overlay) {
    // if (!drawState.isPrepared) return;
    _drawState = DrawState.edit(overlay);
    cancelCross();
    _markRepaint();
  }

  @override
  void onDrawExit() {
    _drawState = const Exited();
    _markRepaint();
  }

  ////// 操作 //////
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

  void cleanAllDrawOverlay() {
    _overlayManager.cleanAllOverlay();
    final overlay = drawState.overlay;
    if (overlay != null) {
      _overlayManager.removeOverlay(overlay);
      _drawState = const Prepared();
    }
    _markRepaint();
  }

  bool changeDrawLineStyle({
    Color? color,
    double? strokeWidth,
    LineType? lineType,
  }) {
    final object = drawState.overlay?.object;
    if (object == null) return false;
    if (object.changeDrawLineStyle(
      color: color,
      strokeWidth: strokeWidth,
      lineType: lineType,
    )) {
      _drawLineStyleListener.notifyListeners();
      _markRepaint();
      return true;
    }
    return false;
  }

  ////// 绘制 //////

  /// 以当前蜡烛图绘制参数为基础, 将绘制参数[point]转换Offset坐标.
  @override
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
  @override
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

  /// 测试[position]位置上是否有命中的Overly.
  @override
  Overlay? hitTestOverlay(Offset position) {
    assert(position.isFinite, 'hitTestOverlay($position) position is invalid!');
    for (var overlay in _overlayManager.overlayList) {
      if (overlay.object?.hitTest(this, position) == true) {
        return overlay;
      }
    }
    return null;
  }

  /// 绘制Draw图层
  @override
  void paintDraw(Canvas canvas, Size size) {
    if (!drawConfig.enable) return;

    /// 首先绘制已完成的overlayList
    drawOverlayList(canvas, size);

    /// 最后绘制当前处于Drawing或Editing状态的Overlay.
    drawStateOverlay(canvas, size);
  }

  /// 绘制已完成的OverlayList
  void drawOverlayList(Canvas canvas, Size size) {
    final stateOverlay = drawState.overlay;
    for (var overlay in _overlayManager.overlayList) {
      /// 如果是当前编辑的overlay不用绘制
      if (stateOverlay == overlay) continue;

      DrawObject? object = _overlayManager.getDrawObject(overlay);
      if (object == null) continue;

      // TODO: 待优化, 仅在图表移动/缩放/数据源发生变化时, 才需要initPoint
      final succeed = object.initPoints(this);
      if (!succeed) continue;

      object.draw(this, canvas, size);
    }
  }

  void drawStateOverlay(Canvas canvas, Size size) {
    final overlay = drawState.overlay;
    if (overlay == null) return;
    final object = _overlayManager.getDrawObject(overlay);
    if (object == null) {
      assert(() {
        loge('drawStateOverlay Failed to create Object for ${overlay.type}');
        return true;
      }());
      return;
    }

    if (drawState is Editing && overlay.isEditing) {
      object.draw(this, canvas, size);
      // 绘制编辑状态的overlay的points为圆圈.
      object.drawPoints(
        this,
        canvas,
        isMoving: overlay.moving,
      );
    } else if (drawState is Drawing && overlay.isDrawing) {
      object.drawing(this, canvas, size);
    }
  }

  /// 绘制当前编辑/绘制中的Overlay的刻度
  void drawStateTick(Canvas canvas, Size size) {
    final overlay = drawState.overlay;
    if (overlay == null) return;
    final object = _overlayManager.getDrawObject(overlay);
    if (object == null) {
      assert(() {
        loge('drawStateTick Failed to create Object for ${overlay.type}');
        return true;
      }());
      return;
    }

    /// 计算刻度坐标
    Rect? bounds = object.getTickMarksBounds();
    if (bounds == null) {
      logd('drawStateTick not draw point!');
      return;
    }

    // logd('drawStateTick bounds:$bounds');
    object.drawTicks(this, canvas, bounds);
  }
}
