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
import '../utils/platform_util.dart';
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
    _drawObjectManager = OverlayDrawObjectManager(
      configuration: configuration,
      logger: loggerDelegate,
    );
  }

  @override
  void initState() {
    super.initState();
    logd('initState draw');
    _drawLineStyleListener = KlineStateNotifier(drawConfig.drawLine);
    candleRequestListener.addListener(() {
      _drawObjectManager.onChangeCandleRequest(
        candleRequestListener.value,
        drawConfig,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose draw');
    _drawLineStyleListener.dispose();
    _drawTypeListener.dispose();
    _drawStateListener.dispose();
    _repaintDraw.dispose();
    _drawObjectManager.dispose();
    _drawPointerListener.dispose();
  }

  late final OverlayDrawObjectManager _drawObjectManager;
  late final KlineStateNotifier<LineConfig> _drawLineStyleListener;
  final _repaintDraw = ValueNotifier(0);
  final _drawStateListener = KlineStateNotifier(DrawState.exited());
  final _drawTypeListener = ValueNotifier<IDrawType?>(null);
  final _drawPointerListener = KlineStateNotifier<Point?>(null);

  @override
  Listenable get repaintDraw => _repaintDraw;

  void _markRepaint() => _repaintDraw.value++;

  @override
  void markRepaintDraw() {
    if (drawState.isOngoing || _drawObjectManager.hasObject) {
      _markRepaint();
    }
  }

  Iterable<IDrawType> get supportDrawTypes {
    return _drawObjectManager.supportDrawTypes;
  }

  /// 自定义overlay绘制对象构建器
  void registerDrawOverlayObjectBuilder(
    IDrawType type,
    DrawObjectBuilder builder,
  ) {
    _drawObjectManager.registerDrawOverlayObjectBuilder(type, builder);
  }

  /// 主动通知绘制状态变化
  void _notifyDrawStateChange() => _drawStateListener.notifyListeners();

  @override
  DrawState get drawState => _drawStateListener.value;
  set _drawState(DrawState state) {
    _drawStateListener.value = state;
    // 子状态更新
    _drawTypeListener.value = state.object?.type;
    if (state.object != null) {
      _drawLineStyleListener.value = state.object!.line;
    }
  }

  @override
  ValueListenable<DrawState> get drawStateLinstener => _drawStateListener;

  @override
  ValueListenable<IDrawType?> get drawTypeListener => _drawTypeListener;
  ValueListenable<Point?> get drawPointerListener => _drawPointerListener;

  @override
  ValueListenable<LineConfig> get drawLineStyleListener =>
      _drawLineStyleListener;

  @override
  void prepareDraw() {
    // 如果是非退出状态, 则无需变更状态.
    if (!drawState.isExited) return;
    _drawState = const Prepared();
    cancelCross();
  }

  @override
  void exitDraw() {
    drawState.object?.dispose();
    _drawState = const Exited();
    _markRepaint();
  }

  /// 开始绘制新的[type]类型
  /// 1. 重置状态为Drawing
  /// 2. 初始化第一个Point的位置为[mainRect]中心
  @override
  void startDraw(IDrawType type, {bool? isInitPointer}) {
    cancelCross();
    if (drawState.object?.type == type) {
      _drawState = const Prepared();
    } else {
      final object = _drawObjectManager.createDrawObject(
        type: type,
        config: drawConfig,
      );
      if (object != null) {
        // 初始指针为[mainRect]中心
        if (isInitPointer ?? PlatformUtil.isTouch) {
          object.setPointer(Point.pointer(0, mainRect.center));
        }
        _drawState = DrawState.draw(object);
      } else {
        _drawState = const Prepared();
      }
    }
    _markRepaint();
  }

  /// 更新当前指针坐标
  void onDrawUpdate(GestureData data) {
    if (!drawState.isDrawing) return;
    final object = drawState.object!;
    final pointer = object.pointer;
    if (pointer == null) {
      assert(() {
        logw('onDrawUpdate drawing ${object.type}, pointer is null!');
        return true;
      }());
      return;
    }
    object.onUpdateDrawPoint(
      pointer,
      pointer.offset + data.delta,
    );
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
  bool onDrawConfirm(GestureData data) {
    final object = drawState.object;
    if (object == null) return false;

    bool result = false;
    if (object.isDrawing) {
      Point? pointer = object.pointer;
      if (pointer == null) {
        // 非触摸设备启动时, 不会设置初始指针, 只有在第一次Tap时, pointer才确认第一个指针
        final index = object.nextIndex;
        pointer = Point.pointer(index, data.offset);
      }

      // final isOk = updateDrawPointByOffset(pointer);
      // if (!isOk) {
      //   logw('onDrawConfirm updatePointer failed! pointer:$pointer');
      //   return false;
      // }
      object.addPointer(pointer);

      if (object.isEditing) {
        logi('onDrawConfirm ${object.type} draw completed!');
        // 绘制完成, 使用drawLine配置绘制实线.
        _drawObjectManager.addDrawObject(object);
        object.setDrawLineConfig(drawConfig.drawLine);
        _drawState = Editing(object);
        // TODO: 增加object接口, 校正所有绘制点
        result = false;
      } else {
        result = true;
      }
    } else if (object.isEditing) {
      final pointer = object.pointer;
      if (pointer == null) {
        // 当前处于编辑状态, 但是pointer又没有被赋值, 此时点击事件, 为确认完成.
        _drawObjectManager.addDrawObject(object);
        // TODO: 增加object接口, 校正所有绘制点
        for (var point in object.points) {
          if (point != null) {
            updateDrawPointByOffset(point);
          }
        }
        _drawState = const Prepared();
        result = false;
      } else {
        // final isOk = updateDrawPointByOffset(pointer);
        // if (!isOk) {
        //   logw('onDrawConfirm updatePointer failed! pointer:$pointer');
        //   return false;
        // }
        object.confirmPointer();
        result = false;
      }
    }

    _markRepaint();
    return result;
  }

  bool onDrawMoveStart(GestureData data) {
    if (!drawState.isEditing) return false; // 未完成的暂不允许移动
    final object = drawState.object!;

    final position = data.offset;
    // 检查是否在某个绘制点上
    final point = object.hitTestPoint(this, position);
    if (point != null) {
      logd('onDrawMoveStart index:${point.index} point:$point');
      object.setPointer(point);
      object.setMoveing(true);
      _drawPointerListener.updateValue(object.pointer);
      _notifyDrawStateChange();
      _markRepaint();
      return true;
    } else if (object.hitTest(this, position, isMove: true) == true) {
      // 检查当前焦点是否命中Overlay
      object.setPointer(null);
      object.setMoveing(true);
      _drawPointerListener.updateValue(null);
      _notifyDrawStateChange();
      _markRepaint();
      return true;
    }
    return false;
  }

  /// 移动Overlay
  void onDrawMoveUpdate(GestureData data) {
    if (!drawState.isEditing) return; // 未完成的暂不允许移动
    final object = drawState.object!;

    final delta = data.delta;
    if (object.pointer != null) {
      // 当前移动一个编辑状态的Overlay的某个绘制点指针时,
      // 需要通过[DrawObject]的`onUpdatePoint`接口来校正offset.
      object.onUpdateDrawPoint(
        object.pointer!,
        object.pointer!.offset + delta,
        isMove: true,
      );
      _drawPointerListener.updateValue(object.pointer);
    } else {
      object.onMoveDrawObject(delta);
    }
    // _notifyDrawStateChange();
    _markRepaint();
  }

  void onDrawMoveEnd() {
    if (!drawState.isEditing) return; // 未完成的暂不允许移动
    final object = drawState.object!;

    final pointer = object.pointer;
    if (pointer != null) {
      logd('onDrawMoveEnd index:${pointer.index} point:$pointer');
      object.confirmPointer();
    }
    for (var point in object.points) {
      if (point != null) {
        updateDrawPointByOffset(point);
      }
    }
    object.setMoveing(false);
    _drawPointerListener.updateValue(null);
    _notifyDrawStateChange();
    _markRepaint();
  }

  void onDrawSelect(DrawObject object) {
    _drawState = DrawState.edit(object);
    cancelCross();
    _markRepaint();
  }

  ////// 操作 //////
  /// 删除[object]; 如果不指定, 删除当前绘制[drawState]的object.
  void deleteDrawObject({DrawObject? object}) {
    if (object != null) {
      if (_drawObjectManager.removeDrawObject(object)) {
        _markRepaint();
      }
    } else {
      object = drawState.object;
      if (object != null) {
        _drawObjectManager.removeDrawObject(object);
        _drawState = const Prepared();
        _markRepaint();
      }
    }
  }

  void deleteAllDrawObject() {
    _drawObjectManager.cleanAllDrawObject();
    final object = drawState.object;
    if (object != null) {
      _drawObjectManager.removeDrawObject(object);
      _drawState = const Prepared();
    }
    _markRepaint();
  }

  bool changeDrawLineStyle({
    Color? color,
    double? strokeWidth,
    LineType? lineType,
  }) {
    final object = drawState.object;
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

  /// 以当前蜡烛图绘制参数为基础, 将绘制参数[point]转换Offset坐标.
  @override
  bool updateDrawPointByValue(Point point, {int? ts, BagNum? value}) {
    value ??= point.value;
    final dy = valueToDy(value);
    if (dy == null) return false;

    ts ??= point.ts;
    final dx = timestampToDx(ts);
    if (dx == null) return false;

    point.ts = ts;
    point.value = value;
    point.offset = Offset(dx, dy);
    return true;
  }

  /// 以当前蜡烛图绘制参数为基础, 将绘制参数[offset]转换Point坐标.
  @override
  bool updateDrawPointByOffset(Point point, {Offset? offset}) {
    offset ??= point.offset;
    final ts = dxToTimestamp(offset.dx);
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
  DrawObject? hitTestDrawObject(Offset position) {
    assert(
      position.isFinite,
      'hitTestDrawObject($position) position is invalid!',
    );
    for (var object in _drawObjectManager.overlayObjectList) {
      if (object.hitTest(this, position)) {
        return object;
      }
    }
    return null;
  }

  ////// 绘制 //////

  /// 绘制Draw图层
  @override
  void paintDraw(Canvas canvas, Size size) {
    if (!drawConfig.enable) return;

    /// 首先绘制已完成的overlayObjectList
    drawOverlayObjectList(canvas, size);

    /// 最后绘制当前处于Drawing或Editing状态的Overlay.
    drawStateOverlayObject(canvas, size);
  }

  /// 绘制已完成的OverlayList
  void drawOverlayObjectList(Canvas canvas, Size size) {
    final stateObject = drawState.object;
    for (var object in _drawObjectManager.overlayObjectList) {
      /// 如果是当前编辑的overlay不用绘制
      if (stateObject == object) continue;

      // TODO: 待优化,
      // 1. 检测points中每个value是否有效.
      // 2. 当发生图表移动/缩放/数据源发生变化时, 需要initPoint
      final succeed = object.initPoints(this);
      if (!succeed) continue;

      object.draw(this, canvas, size);
    }
  }

  void drawStateOverlayObject(Canvas canvas, Size size) {
    final object = drawState.object;
    if (object == null) return;

    if (drawState is Editing && object.isEditing) {
      object.draw(this, canvas, size);
      // 绘制编辑状态的overlay的points为圆圈.
      object.drawPoints(this, canvas);
    } else if (drawState is Drawing && object.isDrawing) {
      object.drawing(this, canvas, size);
    }
  }

  /// 绘制当前编辑/绘制中的Overlay的刻度文本
  void drawStateAxisTicksText(Canvas canvas, Size size) {
    final object = drawState.object;
    if (object == null) return;

    /// 计算刻度坐标
    Rect? bounds = object.getTicksMarksBounds();
    if (bounds == null) {
      logd('drawStateAxisTicksText not draw point!');
      return;
    }

    // logd('drawStateAxisTicksText bounds:$bounds');
    object.drawAxisTicksText(this, canvas, bounds);
  }
}
