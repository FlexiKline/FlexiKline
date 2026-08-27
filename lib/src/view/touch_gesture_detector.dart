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

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../constant.dart';
import '../extension/functions_ext.dart';
import '../extension/geometry_ext.dart';
import '../framework/chart/indicator.dart';
import '../framework/draw/overlay.dart';
import '../model/gesture_data.dart';
import '../utils/algorithm_util.dart';
import 'flexi_gesture_owner.dart';
import 'flexi_long_press_gesture_recognizer.dart';
import 'flexi_scale_gesture_recognizer.dart';
import 'gesture_detector_widget.dart';

class TouchGestureDetector extends GestureDetectorWidget {
  const TouchGestureDetector({
    super.key,
    required super.controller,
    super.onDoubleTap,
  });

  @override
  GestureDetectorState<TouchGestureDetector> createState() => _TouchGestureDetectorState();
}

class _TouchGestureDetectorState extends GestureDetectorState<TouchGestureDetector> {
  @override
  String get logTag => 'TouchGesture';

  /// 图表兜底（pan / scale）的手势数据。与落点归属的 [_ownerData] 互斥。
  GestureData? _panScaleData;

  /// 落点归属的手势数据与位移锚点，同生共死：都在 [onScaleStart] 建立、[_pointerEnd] 清空。
  GestureData? _ownerData;
  Offset? _ownerAnchor;

  /// 点击监听数据，只服务 [onTapUp] 的 cross 启动与绘制点确认。
  GestureData? _tapData;

  /// 长按监听数据
  GestureData? _longData;

  /// 本轮 pointer session 内所有活跃指针的最新位置。
  ///
  /// 兜底归属要算指间距，只跟第一指不够；`length` 同时就是活跃指针数。
  final Map<int, Offset> _pointers = <int, Offset>{};

  /// 指针集合上次变化时的指间距，[_spanDelta] 的基准。
  ///
  /// 与 [ScaleGestureRecognizer] 的 `_reconfigure` 同步：任何指针增减都重设，否则第二指
  /// 落下那一刻的既有间距会被算成用户张开的量。
  double _initialSpan = 0;

  /// 本轮 pointer session 中第一指的按下位置与最新位置。
  ({int pointer, Offset down, Offset latest})? _primary;

  /// 当前归属：落点归属在 [onPointerDown] 判定，兜底归属在 [onPointerMove] 判定。
  ///
  /// 本轮 pointer session 内不因业务状态或指数变化而改变，两处例外都在图表兜底族内：
  /// [onScaleStart] 认领失败时降级，[onScaleUpdate] 允许 chartPan 单向切到 chartScale。
  FlexiGestureOwner? _owner;

  /// Scale 是否已为当前落点归属赢下竞技场；未赢时仍由 Tap 负责点击语义。
  bool _ownerClaimed = false;

  /// zoom slider 拖拽是否已正式开始（通过了最小距离检查且 onChartZoomStart 返回 true）
  bool _isZoomStarted = false;

  /// 当前 Scale 手势是否已由 PaintObject 路径认领。
  ///
  /// 即使 Controller 因失选等原因提前取消业务拖动，本次手势结束前仍保持认领，
  /// 避免中途转为蜡烛图平移、惯性平移或 loadMore。
  bool _isObjectDragGesture = false;

  /// 第一指从按下点到最新点的累计位移。
  Offset get _primaryDelta {
    final primary = _primary;
    return primary == null ? Offset.zero : primary.latest - primary.down;
  }

  /// 各指到质心的平均距离，口径与 [ScaleGestureRecognizer] 一致（两指时等于间距的一半）。
  ///
  /// 同口径才能让 [kScaleSlop] 在两处表达同一件事：判定说「张开够了」时，原生识别器也
  /// 正好认为够了。
  double get _span {
    final count = _pointers.length;
    if (count < 2) return 0;
    var focalPoint = Offset.zero;
    for (final position in _pointers.values) {
      focalPoint += position;
    }
    focalPoint /= count.toDouble();
    var totalDeviation = 0.0;
    for (final position in _pointers.values) {
      totalDeviation += (focalPoint - position).distance;
    }
    return totalDeviation / count;
  }

  /// 指间距相对 [_initialSpan] 的变化量，正为张开、负为收拢。
  double get _spanDelta => _span - _initialSpan;

  /// 外层可滚动容器的裁决阈值，也是兜底归属的抢占阈值。
  ///
  /// 不能降到落点归属那个更小的 claimSlop：[TapGestureRecognizer] 的
  /// `preAcceptSlopTolerance` 就是同一个 `touchSlop`，提前抢占会在它自我 reject 之前把它
  /// 踢出竞技场，「点图表看十字线」就变成了平移。
  double get _hitSlop => MediaQuery.maybeGestureSettingsOf(context)?.touchSlop ?? kTouchSlop;

  @override
  Widget build(BuildContext context) {
    // [RawGestureDetector] 不像 [GestureDetector] 那样自动注入 gestureSettings, 必须
    // 逐个识别器手动注入: 漏了会让所有识别器退回框架常量, 丢掉平台适配, 并让
    // [FlexiScaleGestureRecognizer] 的抢占阈值按 kTouchSlop 而非设备值计算。
    final gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    return Listener(
      key: const ValueKey('TouchListener'),
      behavior: HitTestBehavior.translucent,
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      child: RawGestureDetector(
        behavior: HitTestBehavior.translucent,

        /// map 的插入顺序即竞技场加入顺序，保持与 [GestureDetector] 一致：Tap 在最前。
        gestures: <Type, GestureRecognizerFactory>{
          /// 点击
          TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(debugOwner: this),
            (instance) => instance
              ..onTapUp = onTapUp
              ..gestureSettings = gestureSettings,
          ),

          /// 双击
          DoubleTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
            () => DoubleTapGestureRecognizer(debugOwner: this),
            (instance) => instance
              ..onDoubleTap = widget.onDoubleTap
              ..gestureSettings = gestureSettings,
          ),

          /// 长按
          FlexiLongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<FlexiLongPressGestureRecognizer>(
            () => FlexiLongPressGestureRecognizer(
              debugOwner: this,
              // 无副作用: deadline 到点时只读已判定的归属。
              shouldYieldToOwner: () => _owner?.suppressesLongPress == true,
            ),
            (instance) => instance
              ..onLongPressStart = onLongPressStart
              ..onLongPressMoveUpdate = onLongPressMoveUpdate.throttleOnFps
              ..onLongPressEnd = onLongPressEnd
              ..gestureSettings = gestureSettings,
          ),

          /// 移动 缩放
          FlexiScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<FlexiScaleGestureRecognizer>(
            () => FlexiScaleGestureRecognizer(
              debugOwner: this,
              claimSlopFactor: gestureConfig.dragClaimSlopFactor,
              // 两个回调都必须无副作用: 归属只由 [onPointerDown] / [onPointerMove] 按第一指
              // 写入。若在此处顺手记归属, 外层已赢下本轮之后落下的第二指会被 recognizer
              // 当成新的第一指再问一次, 于是非第一指也能改写归属。
              shouldClaimImmediately: (position) => FlexiGestureOwner.resolveImmediate(controller, position) != null,
              shouldClaimOnSlop: () => _owner != null,
            ),
            (instance) => instance
              ..onStart = onScaleStart
              // 节流窗口即一帧: 一次移动会为每个指针各派发一个事件, 而屏幕本来只能按帧
              // 显示; 配合「锚点 + 总位移」的绝对坐标模型, 丢帧不丢位移。
              ..onUpdate = onScaleUpdate.throttleOnFps
              ..onEnd = onScaleEnd
              // [GestureDetector] 会显式设为 start, 而 [ScaleGestureRecognizer] 构造默认是
              // down: down 不在 accept 时重置 _initialSpan, 双指缩放首帧的 scale 已偏离 1.0,
              // 表现为缩放一上手跳一下。
              ..dragStartBehavior = DragStartBehavior.start
              ..gestureSettings = gestureSettings,
          ),
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  void onPointerDown(PointerDownEvent event) {
    final position = event.localPosition;
    _pointers[event.pointer] = position;
    _initialSpan = _span;
    // 归属与位置基准只认第一指: 归属独占整个 pointer session, 后续指针既不重判归属,
    // 也不改写锚点。
    if (_pointers.length != 1) return;

    _primary = (pointer: event.pointer, down: position, latest: position);
    _ownerClaimed = false;
    _owner = FlexiGestureOwner.resolveLanded(controller, position);
    if (_owner != null) logd('onPointerDown owner:${_owner!.name} position:$position');
  }

  /// 原始移动：记录第一指位置，落点无归属时判定兜底归属。不驱动任何业务。
  ///
  /// 位置不取 [ScaleUpdateDetails.localFocalPoint]：多指时它是质心，第二指落下会把位置拽
  /// 到两指中点，而归属独占整个 session、本就不该受第二指影响。
  ///
  /// 兜底判定放在这里而非 recognizer：外层 [Listener] 在命中路径中先于 `GestureBinding`
  /// 收到同一个 move 事件，「本事件判定、本事件抢占」因此成立；而外层 Scrollable 的识别器
  /// 在 `pointerRouter` 里排在图表之后，同一事件内图表先赢。判定出归属即满足
  /// [FlexiScaleGestureRecognizer] 的抢占条件（[_hitSlop] 恒大于它的 claimSlop）。竞技场
  /// 已被外层赢下时判定照样执行，此时抢占是空操作、`onScaleStart` 也不会来。
  void onPointerMove(PointerMoveEvent event) {
    _pointers[event.pointer] = event.localPosition;
    final primary = _primary;
    if (primary != null && primary.pointer == event.pointer) {
      _primary = (pointer: primary.pointer, down: primary.down, latest: event.localPosition);
    }
    if (_owner != null) return;

    _owner = FlexiGestureOwner.resolveChartFallback(
      controller,
      delta: _primaryDelta,
      spanDelta: _spanDelta,
      hitSlop: _hitSlop,
    );
    if (_owner != null) logd('onPointerMove fallback owner:${_owner!.name}');
  }

  void onPointerUp(PointerUpEvent event) => _pointerEnd(event);

  void onPointerCancel(PointerCancelEvent event) => _pointerEnd(event);

  void _pointerEnd(PointerEvent event) {
    _pointers.remove(event.pointer);
    _initialSpan = _span;
    if (_pointers.isNotEmpty) return;

    if (_ownerClaimed) {
      _endLandedGesture(canceled: event is PointerCancelEvent);
    }
    // pointer session 归零即无条件清空: 归属已定却没能抢赢竞技场时(落点被双击吃掉、
    // down 后立即 cancel)不会走 [_endLandedGesture], 残留的锚点会让下一轮把位移
    // 算在上一轮的基准上。
    _ownerData = null;
    _ownerAnchor = null;
    _isZoomStarted = false;
    _primary = null;
    _owner = null;
    _ownerClaimed = false;
  }

  /// 收尾当前落点归属的业务状态。
  ///
  /// 只在 Scale 已为该归属抢赢竞技场（[_ownerClaimed]）且活跃指针归零时调用一次。
  /// 不能挂到 [onScaleEnd]：[ScaleGestureRecognizer] 会在指针数量变化时把一轮手势拆成
  /// 多段 start/end，挂在那里会让第二指落下就提前提交，与「归属独占整个手势序列」冲突。
  ///
  /// [canceled] 为真表示指针被系统取消，业务侧应回滚而非提交。
  void _endLandedGesture({required bool canceled}) {
    switch (_owner) {
      case FlexiGestureOwner.zoomSlider:
        logd('zoom end');
        if (_isZoomStarted) controller.onChartZoomEnd();
      case FlexiGestureOwner.drawDrawing:
        // 拖动只移动当前绘制点, 不确认它: 确认是独立的一次点击, 由 Tap 赢下竞技场后经
        // [onTapUp] 完成。抢占前也是这个语义 —— [TapGestureRecognizer] 的
        // `postAcceptSlopTolerance` 就是 `touchSlop`, 位移越过它之后 Tap 会自我 reject 并
        // 停止跟踪, `onTapUp` 根本不会来, 所以拖完从来不确认。
        break;
      case FlexiGestureOwner.drawEditing:
        if (_ownerData != null) controller.onDrawMoveEnd();
      case FlexiGestureOwner.cross:
        // 不关闭十字线: cross 是「点击进入、再次点击退出」的模式, 中间的平移只移动十字线。
        break;
      case FlexiGestureOwner.paintObject:
        if (_isObjectDragGesture) {
          _isObjectDragGesture = false;
          if (canceled) {
            controller.onPaintObjectDragCancel();
          } else {
            controller.onPaintObjectDragEnd();
          }
        }
      // zoomingMove 无需收尾; 兜底归属不经过这里, 由 [onScaleEnd] 负责惯性平移与 loadMore。
      case FlexiGestureOwner.zoomingMove || FlexiGestureOwner.chartScale || FlexiGestureOwner.chartPan || null:
    }
    _ownerData?.end();
  }

  /// 点击
  void onTapUp(TapUpDetails details) {
    if (controller.isDrawVisible) {
      switch (drawState) {
        case Drawing():
          final pointerOffset = drawState.pointerOffset;
          if (pointerOffset != null && pointerOffset.isFinite) {
            logd('onTapUp draw(drawing) confirm pointer:$pointerOffset');
            _tapData = GestureData.tap(pointerOffset);
            controller.onDrawConfirm(_tapData!);
            if (drawState.isEditing) {
              _tapData?.end();
              _tapData = null;
            }
          }
          return;
        case Editing():
          final offset = details.localPosition;
          final object = controller.hitTestDrawObject(offset);
          if (object != null && object != drawState.object) {
            logd('onTapUp draw(editing) switch object:$object');
            controller.onDrawSelect(object);
          } else {
            logd('onTapUp draw(editing) confirm offset:$offset');
            _tapData = GestureData.tap(offset);
            controller.onDrawConfirm(_tapData!);
            _tapData?.end();
            _tapData = null;
          }
          return;
        case Exited():
          if (controller.drawConfig.allowSelectWhenExit) {
            final object = controller.hitTestDrawObject(details.localPosition);
            if (object != null) {
              logd('onTapUp draw(exited) select object:$object');
              controller.onDrawSelect(object);
              return;
            }
          }
          break;
        case Prepared():
          final object = controller.hitTestDrawObject(details.localPosition);
          if (object != null) {
            logd('onTapUp draw(prepared) select object:$object');
            controller.onDrawSelect(object);
            return;
          }
      }
    }

    // if (!controller.isCrossing) {
    // 这里检测是否命中指标图定制位置
    if (controller.onTap(details.localPosition)) {
      logd('onTapUp handled! :$details');
      return;
    }
    // }

    logd('onTapUp cross start details:$details');
    _tapData = GestureData.tap(details.localPosition);
    final ret = controller.onCrossStart(_tapData!);
    if (!ret) {
      _tapData?.end();
      _tapData = null;
    }
  }

  /// 平移/缩放开始.
  void onScaleStart(ScaleStartDetails details) {
    final owner = _owner;
    if (owner != null && !owner.isChartFallback) {
      _ownerClaimed = true;
      // [ScaleGestureRecognizer] 在指针增减时会先派发一次 onEnd、再于下一次 move 重新
      // onStart, 一轮手势因此被拆成多段。归属独占整个序列, 锚点与业务认领只做第一次。
      if (_ownerData != null) return;
      if (_startLandedGesture(owner)) return;
      // 目标在 down 与 start 之间消失(数据刷新令 overlay 或 PaintObject 不复存在)。
      // 竞技场已抢到、外层已被 reject, 废掉手势等于白拿, 降级为图表兜底。
      logd('onScaleStart owner:${owner.name} claim failed, fallback to chart.');
      _owner = null;
      _ownerClaimed = false;
    }

    if (_panScaleData != null && !_panScaleData!.isEnd) {
      // 如果上次平移或缩放, 还没有结束, 不允许开始.
      logd('onScaleStart Currently still ongoing, ignore!!!');
      return;
    }

    // 落点无归属，或原目标在 down 与 start 之间消失时，沿用既有图表兜底。
    cancelPositionAnimation();
    final focalPoint = details.localFocalPoint;
    // 按意图分派而非按指数(`pointerCount > 1`): 双指同向横向移动时 span 未变, 判成缩放会让
    // `details.scale` 恒等于 1.0, 图表赢了竞技场却原地不动。
    //
    // 每一段 start 都重判: [ScaleGestureRecognizer] 在指针增减时把手势拆成多段 start/end,
    // 上一段已由 [onScaleEnd] 提交, 沿用旧归属会让「双指缩放后抬起一指」卡在缩放态上
    // (单指 span 恒为 0, 缩放再不响应, 也不肯退回平移)。
    //
    // 判定不出来时仍归平移: 竞技场已由原生阈值赢下, 平移好过原地不动。
    _owner = FlexiGestureOwner.resolveChartFallback(
          controller,
          delta: _primaryDelta,
          spanDelta: _spanDelta,
          hitSlop: _hitSlop,
        ) ??
        FlexiGestureOwner.chartPan;
    if (_owner == FlexiGestureOwner.chartScale) {
      final position = _resolveScalePosition(focalPoint.dx);
      logd('onScaleStart scale $position focal:$focalPoint');
      _panScaleData = GestureData.scale(focalPoint, position: position);
    } else {
      logd('onScaleStart pan focal:$focalPoint');
      _panScaleData = GestureData.pan(focalPoint);
    }
  }

  /// 解析缩放的锚定位置：[ScalePosition.auto] 按落点所在的三分之一区域就近锚定。
  ScalePosition _resolveScalePosition(double focalDx) {
    final configured = _panScaleData?.initPosition ?? gestureConfig.scalePosition;
    if (configured != ScalePosition.auto) return configured;
    final third = controller.canvasRect.width / 3;
    if (focalDx < third) return ScalePosition.left;
    if (focalDx > third + third) return ScalePosition.right;
    return ScalePosition.middle;
  }

  /// 建立落点归属的锚点与手势数据，并向业务侧认领目标。
  ///
  /// 返回 false 表示锚点或目标已失效，调用方应降级为图表兜底。
  ///
  /// [GestureData] 的类型不只是标签：`isPan` / `isMove` / `isScale` 会改变下游行为，最典型
  /// 的是 [ChartBinding.onChartMove] 只在 `isMove` 时消费 dy。
  bool _startLandedGesture(FlexiGestureOwner owner) {
    final down = _primary?.down;
    if (down == null) return false;
    final anchor = owner.resolveAnchor(controller, down);
    if (anchor == null) return false;

    final GestureData data;
    switch (owner) {
      case FlexiGestureOwner.zoomSlider:
        data = GestureData.zoom(anchor);
      case FlexiGestureOwner.zoomingMove:
        data = GestureData.move(anchor);
      case FlexiGestureOwner.cross:
        data = GestureData.tap(anchor);
      case FlexiGestureOwner.drawDrawing:
        data = GestureData.pan(anchor);
      case FlexiGestureOwner.drawEditing:
        // 命中与位移基准都取按下位置, 两个理由缺一不可:
        // 1. 命中准: 识别时刻位置距按下点相差一个 slop, 远超
        //    [DrawConfig.hitTestMinDistance] 的 10px, 沿线方向之外必然脱靶。
        // 2. 跟手: [DrawBinding.onDrawMoveUpdate] 整体平移吃的是 `data.delta`, 以按下
        //    位置为基准时首帧 delta 恰好补上按下到识别之间的真实位移; 换成识别位置则
        //    首帧为 0, 线永久滞后一个 slop。
        logd('onScaleStart draw > down:$down');
        data = GestureData.pan(anchor);
        if (!controller.onDrawMoveStart(data)) return false;
      case FlexiGestureOwner.paintObject:
        if (!controller.onPaintObjectDragStart(down)) return false;
        logd('onScaleStart paintObject drag down:$down');
        cancelPositionAnimation();
        data = GestureData.pan(anchor);
        _isObjectDragGesture = true;
      case FlexiGestureOwner.chartScale:
      case FlexiGestureOwner.chartPan:
        // 到不了这里: 兜底归属的 resolveAnchor 已返回 null。
        return false;
    }

    _ownerData = data;
    _ownerAnchor = anchor;
    return true;
  }

  /// 平移/缩放中...
  ///
  /// 注册时挂了 `throttleOnFps`，所以这里每帧最多执行一次。
  void onScaleUpdate(ScaleUpdateDetails details) {
    final owner = _owner;
    if (owner != null && !owner.isChartFallback) {
      _driveLandedGesture(owner);
      return;
    }

    if (_panScaleData == null) {
      logd('onScaleUpdate panScaleData is empty! details:$details');
      return;
    }

    // 兜底族的位置来源是多指质心, 不是第一指。
    final position = details.localFocalPoint;

    // chartPan 单向切到 chartScale: 双指刚落下、还没张开就横向移了一点会被判为 chartPan,
    // 而指针数量没变就不会重新派发 start, 不在这里切换的话用户随后张开手指想缩放就永久
    // 失效。反向不切: 缩放一旦开始, 中途转平移会让 [_initialSpan] 基准失去意义; 抬起一指
    // 是另一回事, 指针数量变化会重新派发 start 由 [onScaleStart] 重判。
    if (_owner == FlexiGestureOwner.chartPan && gestureConfig.enableScale && _spanDelta.abs() > kScaleSlop) {
      // 必须在替换 _panScaleData 之前解析: auto 锚定要读它的 initPosition。
      final scalePosition = _resolveScalePosition(position.dx);
      logd('onScaleUpdate pan > scale $scalePosition focal:$position');
      _owner = FlexiGestureOwner.chartScale;
      _panScaleData?.end();
      // 平移阶段留下的平滑因子必须归位: 缩放的收尾不再调 onPanEnd, 否则它会一直残留。
      controller.onPanEnd();
      _panScaleData = GestureData.scale(
        position,
        // 以切换时刻的实际缩放为基准: 从 1.0 起算会把按下到切换之间的间距变化一次性吃掉。
        scale: scaledDecelerate(details.scale),
        position: scalePosition,
      );
    }

    if (controller.isDrawVisible && drawState.isOngoing) {
      if (_panScaleData!.isPan) {
        _panScaleData!.update(
          position,
          newScale: details.scale,
        );
        controller.onDrawMoveUpdate(_panScaleData!);
      }
    } else if (gestureConfig.enableScale && _panScaleData!.isScale) {
      final newScale = scaledDecelerate(details.scale);
      final change = details.scale - _panScaleData!.scale;
      // assert(() {
      //   logd("onScaleUpdate scale ${details.scale}>$newScale change:$change");
      //   return true;
      // }());
      if (change.abs() > 0.01) {
        _panScaleData!.update(
          position,
          newScale: newScale,
        );
        controller.onChartScale(_panScaleData!);
      }
    } else if (_panScaleData!.isPan) {
      _panScaleData!.update(
        position.clamp(controller.canvasRect),
        newScale: details.scale,
      );
      controller.onChartMove(
        _panScaleData!,
        gestureConfig.tolerance.effectivePanSmoothFactor,
      );
    }
  }

  /// 按落点归属驱动业务，坐标恒为「锚点 + 第一指总位移」。
  void _driveLandedGesture(FlexiGestureOwner owner) {
    final data = _ownerData;
    final anchor = _ownerAnchor;
    final primary = _primary;
    if (data == null || anchor == null || primary == null) return;

    final newOffset = anchor + (primary.latest - primary.down);
    switch (owner) {
      case FlexiGestureOwner.zoomSlider:
        data.update(newOffset);
        if (_isZoomStarted) {
          controller.onChartZoomUpdate(data);
        } else if (data.dyDelta.abs() >= gestureConfig.zoomStartMinDistance &&
            controller.onChartZoomStart(newOffset, false)) {
          // 抢占决定「手势归 zoom」, zoomStartMinDistance 决定「缩放何时真正开始」,
          // 两个阈值语义不同, 不合并。
          cancelPositionAnimation();
          _isZoomStarted = true;
        }
      case FlexiGestureOwner.zoomingMove:
        cancelPositionAnimation();
        data.update(newOffset);
        controller.onChartMove(data);
      case FlexiGestureOwner.drawDrawing:
        data.update(newOffset);
        controller.onDrawUpdate(data);
      case FlexiGestureOwner.drawEditing:
        data.update(newOffset);
        controller.onDrawMoveUpdate(data);
      case FlexiGestureOwner.cross:
        data.update(newOffset.clamp(controller.canvasRect));
        controller.onCrossUpdate(data);
      case FlexiGestureOwner.paintObject:
        // 不做区域钳制: 是否限制在图表内由绘制对象自行决定.
        data.update(newOffset);
        controller.onPaintObjectDragUpdate(data);
      // 到不了这里: 兜底归属的位置来源是多指质心, 由 [onScaleUpdate] 直接驱动。
      case FlexiGestureOwner.chartScale || FlexiGestureOwner.chartPan:
        break;
    }
  }

  /// 平移/缩放结束.
  void onScaleEnd(ScaleEndDetails details) {
    // 落点归属的收尾在 [_endLandedGesture]，这里必须让开。
    //
    // 真正会命中这一条的是指针数量变化：[ScaleGestureRecognizer] 每次增减指针都会
    // 先派发一次 onEnd 再重新 onStart，此时归属仍在，提交就早了一整段手势。
    // 正常抬手时外层 [Listener] 在命中路径中先于 recognizer 执行（`GestureBinding`
    // 的 `HitTestEntry` 排在 path 末尾），[_pointerEnd] 已收尾并清空归属，走到这里
    // 时归属为空、`_panScaleData` 也已为空，由下面的空值分支返回。
    //
    // 兜底归属不让开：它的收尾（提交缩放、惯性平移、loadMore）本来就在这里。
    final owner = _owner;
    if (owner != null && !owner.isChartFallback) return;

    if (_panScaleData == null) {
      logd('onScaleEnd panScaledata and ticker is empty! > details:$details');
      return;
    }

    if (_isObjectDragGesture) {
      logd('onScaleEnd paintObject drag end.');
      _isObjectDragGesture = false;
      controller.onPaintObjectDragEnd();
      _panScaleData?.end();
      _panScaleData = null;
      // 拖动的是绘制对象而非蜡烛图: 不做惯性平移, 也不检查 loadMore.
      return;
    }

    if (controller.isDrawVisible && drawState.isOngoing) {
      if (_panScaleData!.isPan) {
        controller.onDrawMoveEnd();
      }
      _panScaleData?.end();
      _panScaleData = null;
      return;
    }

    if (_panScaleData!.isScale) {
      logd('onScaleEnd scale. ${details.pointerCount}');
      _panScaleData?.end();
      _panScaleData = null;
      controller.onChartScaleEnd();

      /// 检查并加载更多蜡烛数据
      controller.checkAndLoadMoreCandlesWhenPanEnd();
      return;
    }

    // <0: 负数代表从右向左滑动.
    // >0: 正数代表从左向右滑动.
    final velocity = details.velocity.pixelsPerSecond.dx;

    if (!gestureConfig.enableInertialPan ||
        controller.klineData.isEmpty ||
        (velocity < 0 && !controller.canPanRTL) ||
        (velocity > 0 && !controller.canPanLTR)) {
      logd('onScaleEnd currently can not pan!');
      _panScaleData?.end();
      _panScaleData = null;
      controller.onPanEnd();

      /// 检查并加载更多蜡烛数据
      controller.checkAndLoadMoreCandlesWhenPanEnd();
      return;
    }

    final tolerance = gestureConfig.tolerance;

    /// 惯性平移的最大距离.
    final panDistance = velocity * tolerance.distanceFactor;

    final panDuration = calcuInertialPanDuration(
      panDistance,
      maxDuration: tolerance.maxDuration,
    );

    // 平移距离为0 或者 不足1ms, 无需继续平移
    if (panDistance.abs() < precisionError || panDuration <= 1) {
      logd('onScaleEnd currently not need for inertial movement!');
      _panScaleData?.end();
      _panScaleData = null;
      controller.onPanEnd();

      /// 检查并加载更多蜡烛数据
      controller.checkAndLoadMoreCandlesWhenPanEnd();
      return;
    }

    /// 检查并加载更多蜡烛数据
    controller.checkAndLoadMoreCandlesWhenPanEnd(
      panDistance: panDistance,
      panDuration: panDuration,
    );

    logi(
      'onScaleEnd inertial movement, velocity:$velocity, panDistance:$panDistance, panDuration:$panDuration',
    );

    animateToPosition(
      _panScaleData!.offset.dx,
      _panScaleData!.offset.dx + panDistance,
      panDuration: Duration(milliseconds: panDuration),
      tolerance: tolerance,
      onCompleted: () {
        _panScaleData?.end();
        _panScaleData = null;
        controller.onPanEnd();
      },
    );
  }

  /// 长按
  ///
  /// 如果当前正在crossing中时, 不触发后续的长按逻辑.
  void onLongPressStart(LongPressStartDetails details) {
    if (!gestureConfig.enableLongPress || controller.isCrossing) {
      logd('onLongPressStart ignore! > crossing:${controller.isCrossing}');
      return;
    }

    if (controller.isDrawVisible && drawState.isOngoing) {
      if (drawState.isDrawing) {
        // 未完成的暂不允许移动
        return;
      }
      if (drawState.object?.lock == true) return;
      logd('onLongPressStart draw > details:$details');
      _longData = GestureData.long(details.localPosition);
      final result = controller.onDrawMoveStart(_longData!);
      if (!result) {
        _longData?.end();
        _longData = null;
      }
    } else if (!controller.isCrossing && controller.onGridResizeStart(details.localPosition)) {
      logd('onLongPressStart move > details:$details');
      _longData = GestureData.long(details.localPosition);
    } else {
      logd('onLongPressStart cross > details:$details');
      _longData = GestureData.long(details.localPosition);
      final result = controller.onCrossStart(_longData!);
      if (!result) {
        _longData?.end();
        _longData = null;
      }
    }
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!gestureConfig.enableLongPress || _longData == null) {
      return;
    }
    // assert(() {
    //   logd(
    //     "onLongPressMoveUpdate ${DateTime.now().millisecond} > details:${details.localPosition}",
    //   );
    //   return true;
    // }());
    if (controller.isDrawVisible && drawState.isOngoing) {
      _longData!.update(details.localPosition);
      controller.onDrawMoveUpdate(_longData!);
    } else if (controller.isStartDragGrid) {
      _longData!.update(details.localPosition);
      controller.onGridResizeUpdate(_longData!);
    } else {
      _longData!.update(details.localPosition);
      controller.onCrossUpdate(_longData!);
    }
  }

  void onLongPressEnd(LongPressEndDetails details) {
    if (!gestureConfig.enableLongPress || _longData == null) {
      logd('onLongPressEnd ignore! > details:$details');
      return;
    }
    // assert(() {
    //   logd("onLongPressEnd details:$details");
    //   return true;
    // }());
    if (controller.isDrawVisible && drawState.isOngoing) {
      controller.onDrawMoveEnd();
    } else if (controller.isStartDragGrid) {
      controller.onGridResizeEnd();
    } else {
      // 长按结束, 尝试取消Cross事件.
      controller.requestCancelCross();
    }
    _longData?.end();
    _longData = null;
  }
}
