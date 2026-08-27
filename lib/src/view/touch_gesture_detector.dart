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

  /// 一次触摸序列（第一指按下 → 全部指针离开）的全部状态。
  ///
  /// 收进一个对象而不是平铺成十来个字段：这批状态的生命周期一致，收尾时整个丢弃即可，
  /// 不必逐个核对标志位是否都复位了。「有手势在进行」的判据见 [_TouchSession.isActive]。
  _TouchSession? _session;

  /// 长按监听数据。
  ///
  /// 不进 [_session] 有两个理由：长按赢下竞技场即意味着 Scale 被 reject，与归属驱动互斥；
  /// 它的收尾在 [onLongPressEnd]，晚于活跃指针归零。
  GestureData? _longData;

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
              shouldYieldToOwner: () => _session?.owner?.suppressesLongPress == true,
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
              // 问同一条优先级链, 不走旁路: 只查「落点在滑竿区内」表达不出「已进入 cross /
              // draw / 命中手柄时不抢」, 于是会为 zoom 抢下竞技场却由别人驱动, 而 Tap 已被
              // reject —— 点一下既退不出十字线也不做任何事。
              shouldClaimImmediately: (position) {
                return FlexiGestureOwner.resolveLanded(controller, position) == FlexiGestureOwner.zoomSlider;
              },
              shouldClaimOnSlop: () => _session?.owner != null,
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
    final current = _session;
    // 归属与位置基准只认第一指: 归属独占整个 pointer session, 后续指针既不重判归属,
    // 也不改写锚点。
    if (current != null && current.isActive) {
      current.pointers[event.pointer] = position;
      current.initialSpan = current.span;
      return;
    }

    // 判据是 isActive 而非 `!= null`: 图表兜底在指针归零后仍留着 session 等最终一次
    // [onScaleEnd], 而那次 onEnd 可能缺席。残留在这里被新 session 覆盖, 自愈, 不需要
    // 另一条清理路径。
    final session = _session = _TouchSession(event);
    // initialSpan 保持 0: 单指的 span 恒为 0。
    session.pointers[event.pointer] = position;
    final owner = session.owner = FlexiGestureOwner.resolveLanded(controller, position);
    if (owner != null) logd('onPointerDown owner:${owner.name} position:$position');
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
    final session = _session;
    if (session == null) return;
    session.pointers[event.pointer] = event.localPosition;
    if (event.pointer == session.pointer) session.latestPosition = event.localPosition;
    if (session.owner != null) return;

    final owner = FlexiGestureOwner.resolveChartFallback(
      controller,
      delta: session.delta,
      spanDelta: session.spanDelta,
      hitSlop: _hitSlop,
    );
    if (owner == null) return;
    session.owner = owner;
    logd('onPointerMove fallback owner:${owner.name}');
  }

  void onPointerUp(PointerUpEvent event) => _pointerEnd(event);

  void onPointerCancel(PointerCancelEvent event) => _pointerEnd(event);

  void _pointerEnd(PointerEvent event) {
    final session = _session;
    if (session == null) return;
    session.pointers.remove(event.pointer);
    session.initialSpan = session.span;
    session.canceled = session.canceled || event is PointerCancelEvent;
    if (session.isActive) return;

    final owner = session.owner;
    if (owner != null && owner.isChartFallback) {
      // 兜底族的收尾要用 recognizer 维护的抬手速度, 交给紧随其后的 [onScaleEnd]。drive 为空
      // 说明上一段已提交、剩余指针又没再移动, 不会再有 onScaleEnd。惯性不可能
      // 发生, 但 session 级的 loadMore 仍要在这里补上。
      if (session.drive != null) return;
      controller.checkAndLoadMoreCandlesWhenPanEnd();
    } else if (session.drive != null) {
      // 落点族就地收尾。drive 为空即归属已定却没抢赢竞技场(落点被双击吃掉、down 后立即
      // cancel), 无需收尾, session 随下面一行整体丢弃。
      _finish(session, velocity: Offset.zero);
    }
    _session = null;
  }

  /// 点击
  void onTapUp(TapUpDetails details) {
    if (controller.isDrawVisible) {
      switch (drawState) {
        case Drawing():
          final pointerOffset = drawState.pointerOffset;
          if (pointerOffset != null && pointerOffset.isFinite) {
            logd('onTapUp draw(drawing) confirm pointer:$pointerOffset');
            final data = GestureData.tap(pointerOffset);
            controller.onDrawConfirm(data);
            // 绘制点凑齐后状态转为 Editing, 本次点击的手势序列到此结束。
            if (drawState.isEditing) data.end();
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
            final data = GestureData.tap(offset);
            controller.onDrawConfirm(data);
            data.end();
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
    final data = GestureData.tap(details.localPosition);
    // 未能启动 crossing（点击被当作退出、或数据不可用）即就地结束这次手势数据。
    if (!controller.onCrossStart(data)) data.end();
  }

  /// 平移/缩放开始：为当前归属建立驱动状态。
  void onScaleStart(ScaleStartDetails details) {
    final session = _session;
    if (session == null) return;
    final focalPoint = details.localFocalPoint;

    final landed = session.owner;
    if (landed != null && !landed.isChartFallback) {
      // [ScaleGestureRecognizer] 在指针增减时会先派发一次 onEnd、再于下一次 move 重新
      // onStart, 一轮手势因此被拆成多段。归属独占整个序列, 锚点与业务认领只做第一次。
      if (session.drive != null) return;
      final drive = _startDrive(session, landed, focalPoint);
      if (drive != null) {
        session.drive = drive;
        return;
      }
      // 目标在 down 与 start 之间消失(数据刷新令 overlay 或 PaintObject 不复存在)。
      // 竞技场已抢到、外层已被 reject, 废掉手势等于白拿, 降级为图表兜底。
      logd('onScaleStart owner:${landed.name} claim failed, fallback to chart.');
    }

    // 落点无归属，或原目标在 down 与 start 之间消失时，沿用既有图表兜底。
    _stopPositionAnimation();
    // 按意图分派而非按指数(`pointerCount > 1`): 双指同向横向移动时 span 未变, 判成缩放会让
    // `details.scale` 恒等于 1.0, 图表赢了竞技场却原地不动。
    //
    // 每一段 start 都重判: [ScaleGestureRecognizer] 在指针增减时把手势拆成多段 start/end,
    // 上一段已由 [onScaleEnd] 提交, 沿用旧归属会让「双指缩放后抬起一指」卡在缩放态上
    // (单指 span 恒为 0, 缩放再不响应, 也不肯退回平移)。
    //
    // 判定不出来时仍归平移: 竞技场已由原生阈值赢下, 平移好过原地不动。
    final owner = FlexiGestureOwner.resolveChartFallback(
          controller,
          delta: session.delta,
          spanDelta: session.spanDelta,
          hitSlop: _hitSlop,
        ) ??
        FlexiGestureOwner.chartPan;
    session.owner = owner;
    session.drive = _startDrive(session, owner, focalPoint);
  }

  /// 打断进行中的位置动画（惯性平移或指定日期定位），并归位它写下的平移平滑因子。
  ///
  /// [animateToPosition] 的 `onCompleted` 只在动画自然跑完时执行，被打断时不会。而动画每帧
  /// 都经 [ChartBinding.onChartMove] 写入 `_panSmoothFactor`，不归位会让 Y 轴的 minMax 一直
  /// 走插值、且 `clipRect` 停在 `canvasRect` 而非 `mainRect`。
  void _stopPositionAnimation() {
    if (animationController == null) return;
    cancelPositionAnimation();
    controller.onPanEnd();
  }

  /// 解析缩放的锚定位置：[ScalePosition.auto] 按落点所在的三分之一区域就近锚定。
  ///
  /// 结果缓存在 session 上，一轮 pointer session 只解析一次。每段按新落点重解析会让「双指
  /// 缩放抬起一指再张开」时锚点从 middle 跳到 left。
  ScalePosition _resolveScalePosition(_TouchSession session, double focalDx) {
    final resolved = session.resolvedScalePosition;
    if (resolved != null) return resolved;

    final configured = gestureConfig.scalePosition;
    if (configured != ScalePosition.auto) return session.resolvedScalePosition = configured;
    final third = controller.canvasRect.width / 3;
    if (focalDx < third) return session.resolvedScalePosition = ScalePosition.left;
    if (focalDx > third + third) return session.resolvedScalePosition = ScalePosition.right;
    return session.resolvedScalePosition = ScalePosition.middle;
  }

  /// 为 [owner] 建立驱动状态：手势数据与位移锚点，并向业务侧认领目标。
  ///
  /// 返回 null 表示锚点或目标已失效（只发生在落点族），调用方应降级为图表兜底。
  ///
  /// [GestureData] 的类型不只是标签：`isPan` / `isMove` / `isScale` 会改变下游行为，最典型
  /// 的是 [ChartBinding.onChartMove] 只在 `isMove` 时消费 dy。
  ///
  /// case 顺序与 [FlexiGestureOwner] 的声明顺序一致，而声明顺序就是归属优先级；
  /// [onScaleUpdate] 与 [_finish] 的 switch 同序，任一归属的三段生命周期落在同一位置。
  ///
  /// [owner] 恒为 `session.owner` 的非空形式；[fallbackOrigin] 只有兜底族会用到。
  ({GestureData data, Offset origin})? _startDrive(
    _TouchSession session,
    FlexiGestureOwner owner,
    Offset fallbackOrigin,
  ) {
    final down = session.downPosition;
    // 兜底族的锚点是多指质心(缩放必须如此, 平移用质心也更抗抖); 落点族的锚点由归属自己给出,
    // 为 null 即目标已消失。
    final origin = owner.isChartFallback ? fallbackOrigin : owner.resolveAnchor(controller, down);
    if (origin == null) return null;

    switch (owner) {
      case FlexiGestureOwner.drawDrawing:
        return (data: GestureData.pan(origin), origin: origin);
      case FlexiGestureOwner.drawEditing:
        // 命中与位移基准都取按下位置, 两个理由缺一不可:
        // 1. 命中准: 识别时刻位置距按下点相差一个 slop, 远超
        //    [DrawConfig.hitTestMinDistance] 的 10px, 沿线方向之外必然脱靶。
        // 2. 跟手: [DrawBinding.onDrawMoveUpdate] 整体平移吃的是 `data.delta`, 以按下
        //    位置为基准时首帧 delta 恰好补上按下到识别之间的真实位移; 换成识别位置则
        //    首帧为 0, 线永久滞后一个 slop。
        logd('onScaleStart draw > down:$down');
        final data = GestureData.pan(origin);
        if (!controller.onDrawMoveStart(data)) return null;
        return (data: data, origin: origin);
      case FlexiGestureOwner.cross:
        return (data: GestureData.tap(origin), origin: origin);
      case FlexiGestureOwner.paintObject:
        if (!controller.onPaintObjectDragStart(down)) return null;
        logd('onScaleStart paintObject drag down:$down');
        _stopPositionAnimation();
        return (data: GestureData.pan(origin), origin: origin);
      case FlexiGestureOwner.zoomSlider:
        return (data: GestureData.zoom(origin), origin: origin);
      case FlexiGestureOwner.zoomingMove:
        return (data: GestureData.move(origin), origin: origin);
      case FlexiGestureOwner.chartScale:
        final position = _resolveScalePosition(session, origin.dx);
        logd('onScaleStart scale $position focal:$origin');
        return (data: GestureData.scale(origin, position: position), origin: origin);
      case FlexiGestureOwner.chartPan:
        logd('onScaleStart pan focal:$origin');
        return (data: GestureData.pan(origin), origin: origin);
    }
  }

  /// 平移/缩放中...
  ///
  /// 注册时挂了 `throttleOnFps`，所以这里每帧最多执行一次。
  void onScaleUpdate(ScaleUpdateDetails details) {
    final session = _session;
    final drive = session?.drive;
    final owner = session?.owner;
    if (session == null || drive == null || owner == null) {
      logd('onScaleUpdate no drive! details:$details');
      return;
    }

    if (!owner.isChartFallback) {
      // 落点族的坐标恒为「锚点 + 第一指总位移」。不逐帧累加增量: 本方法挂了节流, 累加会随
      // 被丢弃的中间调用一起丢位移。
      final data = drive.data;
      final newOffset = drive.origin + session.delta;
      switch (owner) {
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
        case FlexiGestureOwner.zoomSlider:
          data.update(newOffset);
          if (session.zoomStarted) {
            controller.onChartZoomUpdate(data);
          } else if (data.dyDelta.abs() >= gestureConfig.zoomStartMinDistance &&
              controller.onChartZoomStart(newOffset, false)) {
            // 抢占决定「手势归 zoom」, zoomStartMinDistance 决定「缩放何时真正开始」,
            // 两个阈值语义不同, 不合并。
            _stopPositionAnimation();
            session.zoomStarted = true;
          }
        case FlexiGestureOwner.zoomingMove:
          _stopPositionAnimation();
          data.update(newOffset);
          controller.onChartMove(data);
        // 到不了这里: 兜底归属的位置来源是多指质心, 由下面的分支驱动。
        case FlexiGestureOwner.chartScale || FlexiGestureOwner.chartPan:
          break;
      }
      return;
    }

    // 兜底族的位置来源是多指质心, 不是第一指。
    final data = drive.data;
    final position = details.localFocalPoint;

    // chartPan 单向切到 chartScale: 双指刚落下、还没张开就横向移了一点会被判为 chartPan,
    // 而指针数量没变就不会重新派发 start, 不在这里切换的话用户随后张开手指想缩放就永久
    // 失效。反向不切: 缩放一旦开始, 中途转平移会让 initialSpan 基准失去意义; 抬起一指
    // 是另一回事, 指针数量变化会重新派发 start 由 [onScaleStart] 重判。
    if (owner == FlexiGestureOwner.chartPan && gestureConfig.enableScale && session.spanDelta.abs() > kScaleSlop) {
      final scalePosition = _resolveScalePosition(session, position.dx);
      logd('onScaleUpdate pan > scale $scalePosition focal:$position');
      session.owner = FlexiGestureOwner.chartScale;
      data.end();
      // 平移阶段留下的平滑因子必须归位: 缩放的收尾不调 onPanEnd, 否则它会一直残留。
      controller.onPanEnd();
      session.drive = (
        data: GestureData.scale(
          position,
          // 以切换时刻的实际缩放为基准: 从 1.0 起算会把按下到切换之间的间距变化一次性吃掉。
          scale: scaledDecelerate(details.scale),
          position: scalePosition,
        ),
        origin: position,
      );
      // 本帧只切换: 新建的 data 其 scaleDelta 恒为 0, [ChartBinding.onChartScale] 拿它算不出
      // 任何宽度变化, 驱动要等下一帧。
      return;
    }

    // 按归属分派, 不看 [GestureData] 的类型: 类型由归属在 [onScaleStart] 决定, 再照类型分派
    // 一次只会多出一套要保持同步的判据。
    if (owner == FlexiGestureOwner.chartScale) {
      final newScale = scaledDecelerate(details.scale);
      final change = details.scale - data.scale;
      if (change.abs() > 0.01) {
        data.update(position, newScale: newScale);
        controller.onChartScale(data);
      }
    } else {
      data.update(position.clamp(controller.canvasRect), newScale: details.scale);
      controller.onChartMove(data, gestureConfig.tolerance.effectivePanSmoothFactor);
    }
  }

  /// 图表兜底手势（平移 / 缩放）的结束。
  ///
  /// 这里结束的是 [ScaleGestureRecognizer] 的一个 **segment**，不是一轮 pointer session：
  /// 任何指针增减都会让它先派发一次 onEnd、退回 accepted，下一次移动再重新 onStart。所以
  /// [ScaleEndDetails.pointerCount] 大于 0 时只提交本段写进业务的状态，惯性平移与 loadMore
  /// 属于整个 session，只在最后一段做。混用两者的后果是双指同向平移抬起一指就启动惯性，
  /// 而剩余手指还在屏幕上继续拖，两个源同时改 `paintDxOffset`。
  ///
  /// 落点归属不走这里，收尾在活跃指针归零处（原因见 [_finish]）。
  void onScaleEnd(ScaleEndDetails details) {
    final session = _session;
    if (session == null) return;
    final owner = session.owner;
    final drive = session.drive;
    if (owner == null || !owner.isChartFallback || drive == null) return;

    // candleWidth 按段落库: 双指缩放后抬起一指, 本段缩放的结果就该定下来。
    final isScale = owner == FlexiGestureOwner.chartScale;
    if (isScale) controller.onChartScaleEnd();

    if (details.pointerCount > 0) {
      logd('onScaleEnd segment end, ${details.pointerCount} pointer(s) left.');
      // 平移写进的平滑因子同样按段归位; 下一段由 [onScaleStart] 重判归属并重建 drive。
      if (!isScale) controller.onPanEnd();
      drive.data.end();
      // 置空即宣告「本段已提交」: 指针随后归零时 [_pointerEnd] 据此知道不会再有最终 onEnd。
      session.drive = null;
      return;
    }

    // <0: 从右向左滑动; >0: 从左向右滑动。
    _finish(session, velocity: details.velocity.pixelsPerSecond);
    _session = null;
  }

  /// 收尾整轮 pointer session：按归属提交或回滚业务状态。
  ///
  /// 两个调用点：落点归属在活跃指针归零时（[_pointerEnd]，[velocity] 恒为零），图表兜底在
  /// 最终一次 [onScaleEnd] 时（带系统维护的抬手速度）。
  ///
  /// 落点归属不挂 [onScaleEnd]：指针增减会把一轮 session 拆成多段，挂在那里会让第二指落下
  /// 就提前提交；而最终一次 onEnd 还可能缺席（上一段结束后剩余指针没再移动就抬起）。它的
  /// 收尾又不需要抬手速度，所以指针归零是更可靠的落点。
  ///
  /// case 顺序与 [_startDrive]、[onScaleUpdate] 一致，即 [FlexiGestureOwner] 的声明顺序。
  void _finish(_TouchSession session, {required Offset velocity}) {
    final drive = session.drive;
    final owner = session.owner;
    if (drive == null || owner == null) return;

    switch (owner) {
      case FlexiGestureOwner.drawDrawing:
        // 拖动只移动当前绘制点, 不确认它: 确认是独立的一次点击, 由 Tap 赢下竞技场后经
        // [onTapUp] 完成。抢占前也是这个语义 —— [TapGestureRecognizer] 的
        // `postAcceptSlopTolerance` 就是 `touchSlop`, 位移越过它之后 Tap 会自我 reject 并
        // 停止跟踪, `onTapUp` 根本不会来, 所以拖完从来不确认。
        break;
      case FlexiGestureOwner.drawEditing:
        controller.onDrawMoveEnd();
      case FlexiGestureOwner.cross:
        // 不关闭十字线: cross 是「点击进入、再次点击退出」的模式, 中间的平移只移动十字线。
        break;
      case FlexiGestureOwner.paintObject:
        // 本轮出现过 Cancel 即回滚: 系统接管了手势, 用户并未确认这次拖动。
        if (session.canceled) {
          controller.onPaintObjectDragCancel();
        } else {
          controller.onPaintObjectDragEnd();
        }
      case FlexiGestureOwner.zoomSlider:
        if (session.zoomStarted) controller.onChartZoomEnd();
      case FlexiGestureOwner.zoomingMove:
        // 无需收尾。
        break;
      case FlexiGestureOwner.chartScale:
        controller.checkAndLoadMoreCandlesWhenPanEnd();
      case FlexiGestureOwner.chartPan:
        // 惯性分支要等动画跑完才结束手势数据, 所以自行收尾。
        _finishChartPan(session, drive.data, velocity.dx);
        return;
    }
    drive.data.end();
  }

  /// chartPan 的 session 收尾：够条件就按抬手速度做惯性平移，否则就地结束。
  ///
  /// 两条路径都要检查 loadMore，惯性路径额外把预测的终点传进去，让预加载提前发生。
  void _finishChartPan(_TouchSession session, GestureData data, double velocity) {
    final tolerance = gestureConfig.tolerance;
    final panDistance = velocity * tolerance.distanceFactor;
    final panDuration = calcuInertialPanDuration(panDistance, maxDuration: tolerance.maxDuration);
    // 本轮出现过 PointerCancel 即不惯性: cancel 意味着系统接管了手势(来电、系统返回、父级
    // 抢占), 手指并非主动甩出去, 继续滚动是错的。
    final canInertialPan = !session.canceled &&
        gestureConfig.enableInertialPan &&
        controller.klineData.isNotEmpty &&
        !(velocity < 0 && !controller.canPanRTL) &&
        !(velocity > 0 && !controller.canPanLTR) &&
        // 平移距离为 0 或不足 1ms, 无需继续平移。
        panDistance.abs() >= precisionError &&
        panDuration > 1;

    if (!canInertialPan) {
      logd('_finishChartPan no inertial movement, velocity:$velocity canceled:${session.canceled}');
      data.end();
      controller.onPanEnd();
      controller.checkAndLoadMoreCandlesWhenPanEnd();
      return;
    }

    controller.checkAndLoadMoreCandlesWhenPanEnd(panDistance: panDistance, panDuration: panDuration);
    logi('_finishChartPan inertial movement, velocity:$velocity distance:$panDistance duration:$panDuration');
    final from = data.offset.dx;
    // 手势数据在动画启动前就结束: 动画自带一份 GestureData 驱动 onChartMove, 不消费这一份。
    // 放进 onCompleted 则动画被打断时(走 TickerCanceled)永远不执行。
    data.end();
    animateToPosition(
      from,
      from + panDistance,
      panDuration: Duration(milliseconds: panDuration),
      tolerance: tolerance,
      onCompleted: controller.onPanEnd,
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
    final data = _longData;
    if (!gestureConfig.enableLongPress || data == null) {
      return;
    }
    // 三条分支共用同一份长按数据, 位置更新与分派无关, 提到分支之前。
    data.update(details.localPosition);
    if (controller.isDrawVisible && drawState.isOngoing) {
      controller.onDrawMoveUpdate(data);
    } else if (controller.isStartDragGrid) {
      controller.onGridResizeUpdate(data);
    } else {
      controller.onCrossUpdate(data);
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

/// 一次触摸序列（第一指按下 → 全部指针离开）的状态，字段按「输入 → 归属 → 业务」三组排列。
class _TouchSession {
  _TouchSession(PointerDownEvent event)
      : pointer = event.pointer,
        downPosition = event.localPosition,
        latestPosition = event.localPosition;

  // ── 输入 ──

  /// 第一指。归属与位移基准只认它：多指质心会在第二指落下时突跳，而归属独占整个序列。
  final int pointer;
  final Offset downPosition;

  /// 第一指的最新位置。
  ///
  /// 必须独立存字段而不是读 [pointers]：第一指抬起而其他指针仍在屏幕上时，[pointers] 里
  /// 已经没有它，位移基准会突然归零。
  Offset latestPosition;

  /// 全部活跃指针的最新位置。`length` 即活跃指针数，`values` 用于算指间距。
  final Map<int, Offset> pointers = <int, Offset>{};

  /// 指针集合上次变化时的指间距，[spanDelta] 的基准。
  ///
  /// 与 [ScaleGestureRecognizer] 的 `_reconfigure` 同步：任何指针增减都重设，否则第二指
  /// 落下那一刻的既有间距会被算成用户张开的量。
  double initialSpan = 0;

  // ── 归属 ──

  /// 当前归属：落点归属在 `onPointerDown` 判定，兜底归属在 `onPointerMove` 判定。
  ///
  /// 本轮内不因业务状态或指针数变化而改变，两处例外都在图表兜底族内：`onScaleStart` 认领
  /// 失败时降级，`onScaleUpdate` 允许 chartPan 单向切到 chartScale。
  FlexiGestureOwner? owner;

  // ── 业务 ──

  /// 驱动状态：手势数据与位移锚点，在 Scale 赢下竞技场（`onScaleStart`）后建立。
  ///
  /// 非空即代表「已抢赢且已向业务侧认领」，所以不需要额外的 claimed 标志。
  ///
  /// 落点族的 drive 跨 segment 保持；兜底族的 drive 在 `onScaleEnd(pointerCount > 0)` 置空，
  /// 因此「兜底族 drive 非空」正是「当前 segment 仍活着、最终 onEnd 必来」的等价物。
  ({GestureData data, Offset origin})? drive;

  /// 本轮是否出现过 [PointerCancelEvent]。
  ///
  /// 必须跨整个 session 累积而不是只看最后离场的事件：Cancel 可能发生在非末指，此时末指
  /// 仍是正常的 [PointerUpEvent]，只看它会把被系统打断的手势误当成正常提交。
  bool canceled = false;

  /// zoom slider 拖拽是否已正式开始（通过了最小距离检查且 onChartZoomStart 返回 true）。
  bool zoomStarted = false;

  /// [ScalePosition.auto] 的解析结果，一轮 session 只解析一次。
  ScalePosition? resolvedScalePosition;

  /// 是否还有活跃指针。
  ///
  /// 「有手势在进行」的判据走这里而不是 `_session != null`：图表兜底在指针归零后仍要留着
  /// session 等最终一次 `onScaleEnd`——那是唯一能拿到系统抬手速度的地方——那段窗口里 session
  /// 非空却已无活跃指针。
  bool get isActive => pointers.isNotEmpty;

  /// 第一指从按下点到最新点的累计位移。
  Offset get delta => latestPosition - downPosition;

  /// 各指到质心的平均距离，口径与 [ScaleGestureRecognizer] 一致（两指时等于间距的一半）。
  ///
  /// 同口径才能让 [kScaleSlop] 在两处表达同一件事：判定说「张开够了」时，原生识别器也
  /// 正好认为够了。
  double get span {
    final count = pointers.length;
    if (count < 2) return 0;
    var focalPoint = Offset.zero;
    for (final position in pointers.values) {
      focalPoint += position;
    }
    focalPoint /= count.toDouble();
    var totalDeviation = 0.0;
    for (final position in pointers.values) {
      totalDeviation += (focalPoint - position).distance;
    }
    return totalDeviation / count;
  }

  /// 指间距相对 [initialSpan] 的变化量，正为张开、负为收拢。
  double get spanDelta => span - initialSpan;
}
