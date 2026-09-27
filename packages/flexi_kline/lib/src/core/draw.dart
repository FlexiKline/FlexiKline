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
mixin DrawBinding on KlineBindingBase, SettingBinding {
  @override
  void init() {
    super.init();
    logd('init draw');
  }

  @override
  void initState() {
    super.initState();
    logd('initState draw');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose draw');
    _repaintDraw.dispose();
    _drawStateNotifier.dispose();
    _drawingPointerNotifier.dispose();
    _drawVisibilityNotifier.dispose();
    _drawMagnetModeNotifier.dispose();
    _drawContinuousNotifier.dispose();
  }

  final _repaintDraw = ValueNotifier(0);
  final _drawStateNotifier = FlexiStateNotifier(DrawState.exited());
  final _drawingPointerNotifier = FlexiStateNotifier<Point?>(null);
  final _drawVisibilityNotifier = ValueNotifier<bool>(true);
  final _drawMagnetModeNotifier = ValueNotifier<MagnetMode>(MagnetMode.normal);
  final _drawContinuousNotifier = ValueNotifier<bool>(false);

  Listenable get repaintDraw => _repaintDraw;

  void _markRepaintDraw() => _repaintDraw.value++;

  @override
  void markRepaintDraw() {
    if (hasDrawOverlay) {
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
  void _notifyDrawStateChange() => _drawStateNotifier.notifyListeners();

  DrawState get drawState => _drawStateNotifier.value;
  set _drawState(DrawState state) {
    _drawStateNotifier.value = state;
  }

  ValueListenable<DrawState> get drawStateListenable => _drawStateNotifier;

  /// 绘制中的指针; 无交互时为 null。
  ValueListenable<Point?> get drawingPointerListenable => _drawingPointerNotifier;

  ValueListenable<bool> get drawVisibilityListenable => _drawVisibilityNotifier;

  ValueListenable<MagnetMode> get drawMagnetModeListenable => _drawMagnetModeNotifier;

  ValueListenable<bool> get drawContinuousListenable => _drawContinuousNotifier;

  bool get isDrawVisible => drawVisibilityListenable.value;

  bool get hasDrawOverlay {
    return drawState.isOngoing || _drawObjectManager.hasObject;
  }

  /// Draw 图层这一帧是否需要绘制。
  bool get shouldPaintDraw => drawConfig.enable && isDrawVisible && hasDrawOverlay;

  @override
  MagnetMode get drawMagnet => drawMagnetModeListenable.value;

  @override
  bool isSelectedDrawObject(DrawObject object) => drawState.object == object;

  @override
  void onThemeChanged([covariant IFlexiKlineTheme? oldTheme]) {
    super.onThemeChanged(oldTheme);
    if (drawState is Drawing) {
      drawState.object?.doDidChangeTheme(theme);
    }
    for (final object in _drawObjectManager.overlayObjectList) {
      object.doDidChangeTheme(theme);
    }
  }

  @override
  void onKlineSpecChanged(KlineSpec oldSpec) {
    super.onKlineSpecChanged(oldSpec);
    final spec = klineData.spec;
    if (spec.symbol != oldSpec.symbol) {
      _drawObjectManager.onSymbolChanged(spec, drawConfig);
      exitDraw();
    }
  }

  /// 追平绘制 overlay: 按存储重建对象树。
  ///
  /// overlay 不在 [FlexiKlineConfig] 里，共享配置实例带不动它。重建顺带让每个
  /// [DrawObject] 换到新的 [DrawConfig]（它持有的是构造期快照），并 dispose 旧对象，
  /// 因此必须 [exitDraw] —— 否则 [drawState] 指向已弃对象。
  @override
  void syncFlexiKlineConfig([FlexiKlineConfig? config]) {
    super.syncFlexiKlineConfig(config);
    _drawObjectManager.updateDrawOverlaysConfig(drawConfig);
    exitDraw();
  }

  /// 把当前 overlay 列表落盘。
  ///
  /// 任何改动 [Overlay] 持久化字段的动作**结束时**都要调: points、line、lock、zIndex。
  /// 内存与存储一旦分叉，[syncFlexiKlineConfig] 按存储重建就会回退未落盘的改动。
  void _storeDrawOverlays() {
    _drawObjectManager.storeDrawOverlaysConfig();
  }

  /// 离开 [drawState] 当前持有的 object。
  void _leaveDrawStateObject() {
    final object = drawState.object;
    if (object == null) return;
    if (object.isCompleted) {
      object.resetInteraction();
    } else {
      object.dispose();
    }
  }

  void prepareDraw({bool force = false}) {
    // 如果是非退出状态, 则无需变更状态.
    if (!force && !drawState.isExited) return;
    _leaveDrawStateObject();
    _drawState = const Prepared();
    _markRepaintDraw();
  }

  void exitDraw() {
    _leaveDrawStateObject();
    _drawState = const Exited();
    _markRepaintDraw();
  }

  /// 开始绘制新的[type]类型
  /// 1. 重置状态为Drawing
  /// 2. 初始化第一个Point的位置为[mainRect]中心
  void startDraw(IDrawType type, {bool? isInitPointer}) {
    if (!isDrawVisible) return;

    if (drawState.object?.type == type) {
      // 再点同一个工具 = 收起。不收尾的话半成品会带着旧指针被丢弃。
      _leaveDrawStateObject();
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
        dispatchInteractionEvent(FlexiKlineEventType.drawStart, {'type': type.toString()});
      } else {
        _drawState = const Prepared();
      }
    }
    onPaintObjectDragCancel();
    requestCancelCross();
    _markRepaintDraw();
  }

  /// 更新当前指针坐标
  void onDrawUpdate(Offset position) {
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
    final newOffset = magneticSnap(position);
    if (newOffset != pointer.offset) {
      object.onUpdateDrawPoint(pointer, newOffset);
      _markRepaintDraw();
    }
  }

  /// 确认动作.
  void onDrawConfirm(Offset position) {
    final object = drawState.object;
    if (object == null) return;

    if (object.isDrawing) {
      Point? pointer = object.pointer;
      if (pointer == null) {
        // 指针未预置时(不预置初始指针的输入路径), 第一次确认才落下第一个指针
        final newOffset = magneticSnap(position);
        pointer = Point.pointer(object.nextIndex, newOffset);
      }

      object.addPointer(pointer);
      if (object.isCompleted) {
        logi('onDrawConfirm ${object.type} draw completed!');
        dispatchInteractionEvent(FlexiKlineEventType.drawComplete, {'type': object.type.toString()});
        updateDrawObjectPointsData(object);
        // 绘制完成, 使用line配置绘制实线.
        object.setDrawLineConfig(object.line);
        _drawObjectManager.addDrawObject(object, addToTop: true);
        _storeDrawOverlays();
        if (drawContinuousListenable.value) {
          final nextObj = _drawObjectManager.generateDrawObject(
            object.clone(),
            drawConfig,
          );
          if (nextObj != null) {
            final initOffset = object.lastPoint?.offset ?? position;
            nextObj.setPointer(Point.pointer(0, magneticSnap(initOffset)));
            _drawState = DrawState.draw(nextObj);
          } else {
            _drawState = Editing(object);
          }
        } else {
          _drawState = Editing(object);
        }
      }
    } else {
      assert(object.isCompleted, 'object must be completed here');
      final pointer = object.pointer;
      if (pointer == null) {
        // 当前处于编辑状态, 但是pointer又没有被赋值, 此时点击事件为确认完成绘制.
        updateDrawObjectPointsData(object);
        _drawObjectManager.addDrawObject(object, replaceIfPresent: false);
        _storeDrawOverlays();
        _drawState = const Prepared();
      } else {
        object.confirmPointer();
        // 与其他提交路径同源: onUpdateDrawPoint 只改 offset, ts/value 要在落盘前回填,
        // 否则存下去的是与视觉位置不符的旧蜡烛坐标。
        updateDrawObjectPointsData(object);
        _storeDrawOverlays();
      }
    }

    _markRepaintDraw();
  }

  /// 判据与 [onDrawMoveStart] 严格同源，只是不认领。
  ///
  /// 只覆盖 `Editing`：`Drawing` 的移动由 `onPointerMove` 直接驱动，不经竞技场。
  bool hitTestDrawObjectDrag(Offset position) {
    if (!isDrawVisible || !drawState.isEditing) return false;
    final object = drawState.object;
    if (object == null || object.lock) return false;
    return object.hitTestPoint(this, position) != null || object.hitTest(this, position, isMove: true);
  }

  bool onDrawMoveStart(Offset position) {
    if (!drawState.isEditing) return false; // 未完成的暂不允许移动
    final object = drawState.object!;
    if (object.lock) return false; // 锁定状态不允许移动

    // 检查是否在某个绘制点上
    final point = object.hitTestPoint(this, position);
    if (point != null) {
      logd('onDrawMoveStart index:${point.index} point:$point');
      object.setPointer(point);
      object.setMoving(true);
      _drawingPointerNotifier.updateValue(object.pointer);
      _notifyDrawStateChange();
      _markRepaintDraw();
      return true;
    } else if (object.hitTest(this, position, isMove: true) == true) {
      // 检查当前焦点是否命中Overlay
      object.setPointer(null);
      object.setMoving(true);
      _drawingPointerNotifier.updateValue(null);
      _notifyDrawStateChange();
      _markRepaintDraw();
      return true;
    }
    return false;
  }

  /// 移动Overlay
  ///
  /// [position] 移动单个绘制点时作为新落点(经磁吸校正), [delta] 整体平移时施加到每个点。
  void onDrawMoveUpdate(Offset position, Offset delta) {
    if (!drawState.isEditing) return; // 未完成的暂不允许移动
    final object = drawState.object!;

    final pointer = object.pointer;
    if (pointer != null) {
      // 当前移动一个编辑状态的Overlay的某个绘制点指针时,
      // 需要通过[DrawObject]的`onUpdatePoint`接口来校正offset.
      final newOffset = magneticSnap(position);
      if (newOffset != pointer.offset) {
        object.onUpdateDrawPoint(pointer, newOffset);
        _drawingPointerNotifier.updateValue(pointer);
        _markRepaintDraw();
      }
    } else {
      for (final point in object.points) {
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
        for (final point in object.points) {
          if (point == null) continue;
          final index = dxToIndex(point.offset.dx);
          if (index == null) continue;
          final dx = indexToDx(index)! - candleWidthHalf;
          object.onUpdateDrawPoint(point, Offset(dx, point.offset.dy));
        }
      }
    }
    updateDrawObjectPointsData(object);
    _storeDrawOverlays();
    object.setMoving(false);
    _drawingPointerNotifier.updateValue(null);
    _notifyDrawStateChange();
    _markRepaintDraw();
    dispatchInteractionEvent(FlexiKlineEventType.drawMove, {'type': object.type.toString()});
  }

  void onDrawSelect(DrawObject object) {
    if (drawState.isEditing) {
      updateDrawObjectPointsData(drawState.object!);
    }
    _drawState = DrawState.edit(object);
    onPaintObjectDragCancel();
    requestCancelCross();
    _markRepaintDraw();
    dispatchInteractionEvent(FlexiKlineEventType.drawSelect, {'type': object.type.toString()});
  }

  ////// 操作 //////
  /// 删除[object]; 如果不指定, 删除当前绘制[drawState]的object.
  void removeDrawObject({DrawObject? object}) {
    object ??= drawState.object;
    if (object == null) return;

    final isStateObject = drawState.object == object;
    _drawObjectManager.removeDrawObject(object);
    if (isStateObject) _drawState = const Prepared();
    _markRepaintDraw();
    dispatchInteractionEvent(FlexiKlineEventType.drawDelete, {
      'type': object.type.toString(),
      'all': false,
    });
  }

  void removeAllDrawObjects() {
    _drawObjectManager.removeAllDrawObjects();
    final object = drawState.object;
    if (object != null) {
      object.dispose();
      _drawState = const Prepared();
    }
    _markRepaintDraw();
    dispatchInteractionEvent(FlexiKlineEventType.drawDelete, {'all': true});
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
      _storeDrawOverlays();
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
    _storeDrawOverlays();
    _markRepaintDraw();
    _notifyDrawStateChange();
    return true;
  }

  void setDrawVisible(bool visible) {
    _drawVisibilityNotifier.value = visible;
    if (visible) {
      prepareDraw();
    } else {
      exitDraw();
    }
  }

  void setDrawMagnetMode(MagnetMode mode) {
    _drawMagnetModeNotifier.value = mode;
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
    _drawContinuousNotifier.value = isOn;
    if (!isOn) {
      _leaveDrawStateObject();
      _drawState = const Prepared();
      _markRepaintDraw();
    }
  }

  bool moveDrawStateObjectToTop() {
    if (!drawState.isEditing) return false;
    final object = drawState.object;
    if (object == null) return false;
    _drawObjectManager.moveToTop(object);
    _storeDrawOverlays();
    _markRepaintDraw();
    return true;
  }

  bool isDrawOnTop({DrawObject? object}) {
    object ??= drawState.object;
    if (object == null) return false;
    return _drawObjectManager.isOnTop(object);
  }

  bool moveDrawStateObjectToBottom() {
    if (!drawState.isEditing) return false;
    final object = drawState.object;
    if (object == null) return false;
    _drawObjectManager.moveToBottom(object);
    _storeDrawOverlays();
    _markRepaintDraw();
    return true;
  }

  bool isDrawOnBottom({DrawObject? object}) {
    object ??= drawState.object;
    if (object == null) return false;
    return _drawObjectManager.isOnBottom(object);
  }

  /// 测试[position]位置上是否有命中的Overly.
  DrawObject? hitTestDrawObject(Offset position) {
    assert(
      position.isFinite,
      'hitTestDrawObject($position) position is invalid!',
    );
    for (final object in _drawObjectManager.overlayObjectReversedList) {
      if (object.hitTest(this, position)) {
        return object;
      }
    }
    return null;
  }

  ////// 绘制 //////

  /// 绘制Draw图层
  void paintDraw(Canvas canvas, Size size) {
    if (!shouldPaintDraw) return;

    /// 首先绘制已完成的overlayObjectList
    _drawOverlayObjectList(canvas, size);

    /// 最后绘制当前处于Drawing或Editing状态的Overlay.
    _drawStateOverlayObject(canvas, size);
  }

  /// 绘制已完成的OverlayList
  void _drawOverlayObjectList(Canvas canvas, Size size) {
    final stateObject = drawState.object;
    for (final object in _drawObjectManager.overlayObjectList) {
      if (object.moving) continue;

      // 每帧重算: 蜡烛坐标(ts/value) → 屏幕坐标。
      final succeed = object.initPoints(this);
      if (!succeed) continue;
      object.draw(this, canvas, size);

      if (stateObject == object) {
        // 绘制编辑状态的overlay的points为圆圈.
        object.drawPoints(this, canvas);
      }
    }
  }

  void _drawStateOverlayObject(Canvas canvas, Size size) {
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
    final bounds = object.getTicksMarksBounds();
    if (bounds == null) {
      logd('drawStateAxisTicksText not draw point!');
      return;
    }

    // logd('drawStateAxisTicksText bounds:$bounds');
    object.drawAxisTicksText(this, canvas, bounds);
  }
}
