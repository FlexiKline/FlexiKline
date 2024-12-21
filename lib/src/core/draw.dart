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

/// 图形绘制
mixin DrawBinding on KlineBindingBase, SettingBinding implements IDraw {
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
    _repaintDraw.dispose();
    _drawStateListener.dispose();
    _drawPointerListener.dispose();
    _drawVisibilityListener.dispose();
    _drawMagnetModeListener.dispose();
    _drawContinuousListener.dispose();
    _drawObjectManager.dispose();
  }

  late final OverlayDrawObjectManager _drawObjectManager;
  final _repaintDraw = ValueNotifier(0);
  final _drawStateListener = KlineStateNotifier(DrawState.exited());
  final _drawPointerListener = KlineStateNotifier<Point?>(null);
  final _drawVisibilityListener = ValueNotifier<bool>(true);
  final _drawMagnetModeListener = ValueNotifier<MagnetMode>(MagnetMode.normal);
  final _drawContinuousListener = ValueNotifier<bool>(false);

  Listenable get repaintDraw => _repaintDraw;

  void _markRepaintDraw() => _repaintDraw.value++;

  @override
  void markRepaintDraw() {
    if (drawState.isOngoing || _drawObjectManager.hasObject) {
      _markRepaintDraw();
    }
  }

  Iterable<IDrawType> get supportDrawTypes {
    return _drawObjectManager.supportDrawTypes;
  }

  Map<String, Iterable<IDrawType>> get supportDrawGroupTypes {
    return _drawObjectManager.supportDrawGroupTypes;
  }

  /// 注册绘制工具构造器
  void registerDrawObjectBuilder(
    IDrawType type,
    DrawObjectBuilder builder,
  ) {
    _drawObjectManager.registerDrawOverlayObjectBuilder(type, builder);
  }

  /// 主动通知绘制状态变化
  void _notifyDrawStateChange() => _drawStateListener.notifyListeners();

  DrawState get drawState => _drawStateListener.value;
  set _drawState(DrawState state) {
    _drawStateListener.value = state;
  }

  ValueListenable<DrawState> get drawStateListener => _drawStateListener;

  ValueListenable<Point?> get drawPointerListener => _drawPointerListener;

  ValueListenable<bool> get drawVisibilityListener => _drawVisibilityListener;

  ValueListenable<MagnetMode> get drawMagnetModeListener =>
      _drawMagnetModeListener;

  ValueListenable<bool> get drawContinuousListener => _drawContinuousListener;

  bool get isDrawVisibility => drawVisibilityListener.value;

  @override
  MagnetMode get drawMagnet => drawMagnetModeListener.value;

  void prepareDraw({bool force = false}) {
    // 如果是非退出状态, 则无需变更状态.
    if (!force && !drawState.isExited) return;
    drawState.object?.dispose();
    _drawState = const Prepared();
    _markRepaintDraw();
  }

  void exitDraw() {
    drawState.object?.dispose();
    _drawState = const Exited();
    _markRepaintDraw();
  }

  /// 开始绘制新的[type]类型
  /// 1. 重置状态为Drawing
  /// 2. 初始化第一个Point的位置为[mainRect]中心
  void startDraw(IDrawType type, {bool? isInitPointer}) {
    if (!isDrawVisibility) return;

    if (drawState.object?.type == type) {
      _drawState = const Prepared();
    } else {
      final object = _drawObjectManager.createDrawObject(
        type,
        drawConfig: drawConfig,
      );
      if (object != null) {
        if (isInitPointer ?? PlatformUtil.isTouch) {
          Offset? initOffset;
          if (drawState.pointerOffset?.isFinite == true) {
            initOffset = drawState.pointerOffset!;
          } else if (crossOffset != null && mainRect.contains(crossOffset!)) {
            initOffset = crossOffset!;
          }
          initOffset ??= mainRect.center;
          object.setPointer(Point.pointer(0, magneticSnap(initOffset)));
        }
        _drawState = DrawState.draw(object);
      } else {
        _drawState = const Prepared();
      }
    }
    cancelCross();
    _markRepaintDraw();
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
    final newOffset = magneticSnap(data.offset);
    if (newOffset != pointer.offset) {
      object.onUpdateDrawPoint(pointer, newOffset);
      _markRepaintDraw();
    }
  }

  /// 确认动作.
  void onDrawConfirm(GestureData data) {
    final object = drawState.object;
    if (object == null) return;

    if (object.isDrawing) {
      Point? pointer = object.pointer;
      if (pointer == null) {
        // 非触摸设备启动时, 不会设置初始指针, 只有在第一次Tap时, pointer才确认第一个指针
        final newOffset = magneticSnap(data.offset);
        pointer = Point.pointer(object.nextIndex, newOffset);
      }

      object.addPointer(pointer);
      if (object.isEditing) {
        logi('onDrawConfirm ${object.type} draw completed!');
        updateDrawObjectPointsData(object);
        // 绘制完成, 使用drawLine配置绘制实线.
        object.setDrawLineConfig(drawConfig.drawLine);
        _drawObjectManager.addDrawObject(object, addToTop: true);
        if (drawContinuousListener.value) {
          final nextObj = _drawObjectManager.generateDrawObject(
            object.clone(),
            drawConfig,
          );
          if (nextObj != null) {
            final initOffset = object.lastPoint?.offset ?? data.offset;
            nextObj.setPointer(Point.pointer(0, magneticSnap(initOffset)));
            _drawState = DrawState.draw(nextObj);
          } else {
            _drawState = Editing(object);
          }
        } else {
          _drawState = Editing(object);
        }
      }
    } else if (object.isEditing) {
      final pointer = object.pointer;
      if (pointer == null) {
        // 当前处于编辑状态, 但是pointer又没有被赋值, 此时点击事件为确认完成绘制.
        updateDrawObjectPointsData(object);
        _drawObjectManager.addDrawObject(object, replaceIfPresent: false);
        _drawState = const Prepared();
      } else {
        object.confirmPointer();
      }
    }

    _markRepaintDraw();
  }

  bool onDrawMoveStart(GestureData data) {
    if (!drawState.isEditing) return false; // 未完成的暂不允许移动
    final object = drawState.object!;
    if (object.lock) return false; // 锁定状态不允许移动

    final position = data.offset;
    // 检查是否在某个绘制点上
    final point = object.hitTestPoint(this, position);
    if (point != null) {
      logd('onDrawMoveStart index:${point.index} point:$point');
      object.setPointer(point);
      object.setMoveing(true);
      _drawPointerListener.updateValue(object.pointer);
      _notifyDrawStateChange();
      _markRepaintDraw();
      return true;
    } else if (object.hitTest(this, position, isMove: true) == true) {
      // 检查当前焦点是否命中Overlay
      object.setPointer(null);
      object.setMoveing(true);
      _drawPointerListener.updateValue(null);
      _notifyDrawStateChange();
      _markRepaintDraw();
      return true;
    }
    return false;
  }

  /// 移动Overlay
  void onDrawMoveUpdate(GestureData data) {
    if (!drawState.isEditing) return; // 未完成的暂不允许移动
    final object = drawState.object!;

    final delta = data.delta;
    final pointer = object.pointer;
    if (pointer != null) {
      // 当前移动一个编辑状态的Overlay的某个绘制点指针时,
      // 需要通过[DrawObject]的`onUpdatePoint`接口来校正offset.
      final newOffset = magneticSnap(data.offset);
      if (newOffset != pointer.offset) {
        object.onUpdateDrawPoint(pointer, newOffset);
        _drawPointerListener.updateValue(pointer);
        _markRepaintDraw();
      }
    } else {
      for (var point in object.points) {
        if (point != null && point.offset.isFinite) {
          object.onUpdateDrawPoint(point, point.offset + delta);
        }
      }
      _markRepaintDraw();
    }
  }

  void onDrawMoveEnd() {
    if (!drawState.isEditing) return; // 未完成的暂不允许移动
    final object = drawState.object!;

    if (object.pointer != null) {
      logd('onDrawMoveEnd pointer:${object.pointer}');
      object.confirmPointer();
    } else {
      if (!drawMagnet.isNormal && isMagneticDrawObject(object)) {
        for (var point in object.points) {
          if (point == null) continue;
          final index = dxToIndex(point.offset.dx);
          if (index == null) continue;
          final dx = indexToDx(index)! - candleWidthHalf;
          object.onUpdateDrawPoint(point, Offset(dx, point.offset.dy));
        }
      }
    }
    updateDrawObjectPointsData(object);
    object.setMoveing(false);
    _drawPointerListener.updateValue(null);
    _notifyDrawStateChange();
    _markRepaintDraw();
  }

  void onDrawSelect(DrawObject object) {
    if (drawState.isEditing) {
      updateDrawObjectPointsData(drawState.object!);
    }
    _drawState = DrawState.edit(object);
    cancelCross();
    _markRepaintDraw();
  }

  ////// 操作 //////
  /// 删除[object]; 如果不指定, 删除当前绘制[drawState]的object.
  void deleteDrawObject({DrawObject? object}) {
    if (object != null) {
      if (_drawObjectManager.removeDrawObject(object)) {
        _markRepaintDraw();
      }
    } else {
      object = drawState.object;
      if (object != null) {
        _drawObjectManager.removeDrawObject(object);
        _drawState = const Prepared();
        _markRepaintDraw();
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
    _markRepaintDraw();
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
      _markRepaintDraw();
      _notifyDrawStateChange();
      return true;
    }
    return false;
  }

  bool setDrawLockState(bool isLock) {
    final object = drawState.object;
    if (object == null) return false;
    object.setDrawLockState(isLock);
    _markRepaintDraw();
    _notifyDrawStateChange();
    return true;
  }

  void setDrawVisibility(bool isShow) {
    _drawVisibilityListener.value = isShow;
    if (isShow) {
      prepareDraw();
    } else {
      exitDraw();
    }
  }

  void setDrawMagnetMode(MagnetMode mode) {
    _drawMagnetModeListener.value = mode;
    if (mode != MagnetMode.normal && drawState.object?.pointer != null) {
      // 如果当前指针存在，主动根据[mode]校正指针.
      drawState.object!.onUpdateDrawPoint(
        drawState.object!.pointer!,
        magneticSnap(drawState.object!.pointer!.offset),
      );
    }
    _markRepaintDraw();
  }

  void setDrawContinuous(bool isOn) {
    _drawContinuousListener.value = isOn;
    if (!isOn) {
      drawState.object?.dispose();
      _drawState = const Prepared();
      _markRepaintDraw();
    }
  }

  bool moveDrawStateObjectToTop() {
    if (!drawState.isEditing) return false;
    final object = drawState.object;
    if (object == null) return false;
    _drawObjectManager.moveToTop(object);
    _markRepaintDraw();
    return true;
  }

  bool isDrawOnTop({DrawObject? object}) {
    object ??= drawState.object;
    if (object == null) false;
    return _drawObjectManager.isOnTop(object!);
  }

  bool moveDrawStateObjectToBottom() {
    if (!drawState.isEditing) return false;
    final object = drawState.object;
    if (object == null) return false;
    _drawObjectManager.moveToBottom(object);
    _markRepaintDraw();
    return true;
  }

  bool isDrawOnBottom({DrawObject? object}) {
    object ??= drawState.object;
    if (object == null) false;
    return _drawObjectManager.isOnBottom(object!);
  }

  /// 测试[position]位置上是否有命中的Overly.
  DrawObject? hitTestDrawObject(Offset position) {
    assert(
      position.isFinite,
      'hitTestDrawObject($position) position is invalid!',
    );
    for (var object in _drawObjectManager.overlayObjectReversedList) {
      if (object.hitTest(this, position)) {
        return object;
      }
    }
    return null;
  }

  ////// 绘制 //////

  /// 绘制Draw图层
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
      if (object.moving) continue;

      // TODO: 待优化,
      // 1. 检测points中每个value是否有效.
      // 2. 当发生图表移动/缩放/数据源发生变化时, 需要initPoint
      final succeed = object.initPoints(this);
      if (!succeed) continue;
      object.draw(this, canvas, size);

      if (stateObject == object) {
        // 绘制编辑状态的overlay的points为圆圈.
        object.drawPoints(this, canvas);
      }
    }
  }

  void drawStateOverlayObject(Canvas canvas, Size size) {
    final object = drawState.object;
    if (object == null) return;

    if (drawState is Editing && object.moving) {
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
