// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// 图表嵌在可滚动容器内时, PaintObject 拖动与外层滚动的手势竞技场归属。
///
/// 单指 pan 的接受阈值恒为外层 Scrollable hitSlop 的两倍
/// ([DeviceGestureSettings.panSlop] 是 `touchSlop * 2` 的派生 getter),
/// 所以未经条件抢占的图表在可滚动容器内永远拿不到垂直拖动。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart' show DeviceGestureSettings, PointerDeviceKind, kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'SCROLLABLE-ARENA',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

/// 可拖动手柄区: 刻意做小, 与真实 TP/SL 手柄量级一致。
const _handleRect = Rect.fromLTWH(100, 100, 30, 20);

/// 图表内的空白落点: 在主区内但不命中 [_handleRect]。
const _blankPosition = Offset(300, 240);

/// 单步位移。
///
/// 必须小于外层 Scrollable 的 hitSlop, 否则一步就跨过双方阈值, 测到的是
/// "同一事件内谁先处理"而不是"谁的阈值先到", 慢速拖动的回归就漏了。
const _stepDy = -5.0;

/// 总步数: 累计 40px, 远超双方阈值。
const _stepCount = 8;

/// 每步之间推进一帧。
///
/// 不能用零时长的 `pump()`: `onScaleUpdate` 走 throttleOnFps, 时钟不走会让每一步的
/// throttle timer 全部积压到手势结束之后, 测试以"仍有未完成的 Timer"失败。
const _frame = Duration(milliseconds: 16);

/// 手势结束后的收尾时长。
///
/// throttle 的尾调用会再起一轮 timer(见 [unaryThrottle]), 需要留够两个周期。
const _settle = Duration(milliseconds: 60);

List<CandleModel> _candles() => List.generate(
      20,
      (index) => CandleModel(
        timestamp: 20000 - index * 60000,
        open: 100,
        high: 110,
        low: 90,
        close: 105,
        volume: 1000,
      ),
    );

Future<({FlexiKlineController chart, ScrollController scroll})> _pumpChartInListView(
  WidgetTester tester, {
  required TestInteractiveIndicator indicator,
  double? touchSlop,
  bool enableDraw = false,
  bool visibleMinMaxFromData = false,
}) {
  return pumpChartInListView(
    tester,
    spec: _spec,
    candles: _candles(),
    mainIndicators: [indicator],
    touchSlop: touchSlop,
    enableDraw: enableDraw,
    candle: visibleMinMaxFromData ? TestCandleIndicator(visibleMinMaxFromData: true) : null,
  );
}

/// 当前生效价格区间的上端：主图区顶边对应的价格。
double _rangeMax(FlexiKlineController chart) {
  return chart.dyToCandleValue(chart.mainChartRect.top, check: false)!.toDouble();
}

Offset _toGlobal(WidgetTester tester, Offset local) => toChartGlobal(tester, local);

void main() {
  group('可滚动容器内的拖动归属', () {
    testWidgets('从手柄垂直拖动 => PaintObject 收到拖动, 外层不滚动', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('arena_handle'),
        hitRect: _handleRect,
      );
      final scene = await _pumpChartInListView(tester, indicator: indicator);
      addTearDown(() => disposeChart(tester, scene.chart));
      final object = indicator.object!;

      final gesture = await tester.startGesture(
        _toGlobal(tester, _handleRect.center),
        kind: PointerDeviceKind.touch,
      );
      for (var i = 0; i < _stepCount; i++) {
        await gesture.moveBy(const Offset(0, _stepDy));
        await tester.pump(_frame);
      }

      expect(object.calls.first, 'dragStart');
      expect(object.calls, contains('dragUpdate'));
      expect(scene.scroll.offset, 0, reason: '拖动手柄不应带动外层滚动');

      await gesture.up();
      await tester.pump(_settle);
      expect(object.calls.last, 'dragEnd');
    });

    testWidgets('从空白区垂直拖动 => 外层滚动, PaintObject 无回调', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('arena_blank'),
        hitRect: _handleRect,
      );
      final scene = await _pumpChartInListView(tester, indicator: indicator);
      addTearDown(() => disposeChart(tester, scene.chart));
      final object = indicator.object!;

      final gesture = await tester.startGesture(
        _toGlobal(tester, _blankPosition),
        kind: PointerDeviceKind.touch,
      );
      for (var i = 0; i < _stepCount; i++) {
        await gesture.moveBy(const Offset(0, _stepDy));
        await tester.pump(_frame);
      }
      await gesture.up();
      await tester.pump(_settle);

      expect(scene.scroll.offset, greaterThan(0), reason: '空白区拖动仍归外层滚动');
      expect(object.calls, isEmpty);
    });

    testWidgets('手柄上点击（位移小于抢占阈值）=> 仍走 tap, 不认领拖动', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('arena_tap'),
        hitRect: _handleRect,
      );
      final scene = await _pumpChartInListView(tester, indicator: indicator);
      addTearDown(() => disposeChart(tester, scene.chart));
      final object = indicator.object!;

      await tester.tapAt(_toGlobal(tester, _handleRect.center));
      await tester.pump(_settle);

      expect(object.calls, ['tap']);
      expect(scene.chart.isPaintObjectDragging, isFalse);
      expect(scene.scroll.offset, 0);
    });

    testWidgets('zoom slider 落点即抢占 => 点击不穿透为 cross', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('arena_zoom_slider'),
        hitRect: _handleRect,
      );
      final scene = await _pumpChartInListView(tester, indicator: indicator);
      addTearDown(() => disposeChart(tester, scene.chart));
      scene.chart.updateGestureConfig((config) => config.copyWith(enableZoom: true));
      final sliderPosition = scene.chart.mainRect.center;
      scene.chart.setChartZoomSlideBarRect(
        Rect.fromCenter(center: sliderPosition, width: 80, height: 20),
      );
      await tester.pump();
      await tester.pump();

      await tester.tapAt(_toGlobal(tester, sliderPosition));
      await tester.pump(_settle);

      expect(scene.chart.isCrossing, isFalse);
      expect(scene.scroll.offset, 0);
    });

    testWidgets('cross 上的纯点击未被 Scale 抢占 => 仍按 Tap 语义关闭', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('arena_cross_tap'),
        hitRect: _handleRect,
      );
      final scene = await _pumpChartInListView(tester, indicator: indicator);
      addTearDown(() => disposeChart(tester, scene.chart));
      final position = _toGlobal(tester, _blankPosition);

      await tester.tapAt(position);
      await tester.pump(_settle);
      expect(scene.chart.isCrossing, isTrue);

      await tester.tapAt(position);
      await tester.pump(_settle);
      expect(scene.chart.isCrossing, isFalse);
    });

    testWidgets('抢占后第二指落下 => 保持原归属并继续拖动', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('arena_multi'),
        hitRect: _handleRect,
      );
      final scene = await _pumpChartInListView(tester, indicator: indicator);
      addTearDown(() => disposeChart(tester, scene.chart));
      final object = indicator.object!;

      final first = await tester.startGesture(
        _toGlobal(tester, _handleRect.center),
        pointer: 1,
        kind: PointerDeviceKind.touch,
      );
      for (var i = 0; i < _stepCount; i++) {
        await first.moveBy(const Offset(0, _stepDy));
        await tester.pump(_frame);
      }
      expect(object.calls.first, 'dragStart');

      final second = await tester.startGesture(
        _toGlobal(tester, _blankPosition),
        pointer: 2,
        kind: PointerDeviceKind.touch,
      );
      await tester.pump();

      expect(object.calls, isNot(contains('dragCancel')));
      expect(scene.chart.isPaintObjectDragging, isTrue);

      final updateCount = object.calls.where((call) => call == 'dragUpdate').length;
      await first.moveBy(const Offset(0, _stepDy));
      await tester.pump(_frame);
      expect(object.calls.where((call) => call == 'dragUpdate').length, greaterThan(updateCount));

      await first.up();
      await second.up();
      await tester.pump(_settle);
      expect(object.calls.last, 'dragEnd');
    });

    testWidgets('第二指落下后拖动位置仍跟第一指, 不跳到两指质心', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('arena_primary_finger'),
        hitRect: _handleRect,
      );
      final scene = await _pumpChartInListView(tester, indicator: indicator);
      addTearDown(() => disposeChart(tester, scene.chart));
      final object = indicator.object!;

      final first = await tester.startGesture(
        _toGlobal(tester, _handleRect.center),
        pointer: 1,
        kind: PointerDeviceKind.touch,
      );
      for (var i = 0; i < _stepCount; i++) {
        await first.moveBy(const Offset(0, _stepDy));
        await tester.pump(_frame);
      }
      expect(object.calls.first, 'dragStart');

      // 第二指落在远处: 质心会被拉到两指中点, 与第一指相差一百多像素, 断言不会误判。
      final second = await tester.startGesture(
        _toGlobal(tester, _blankPosition),
        pointer: 2,
        kind: PointerDeviceKind.touch,
      );
      await tester.pump(_frame);

      await first.moveBy(const Offset(0, _stepDy));
      await tester.pump(_frame);

      final firstFinger = _handleRect.center + const Offset(0, _stepDy * (_stepCount + 1));
      final centroid = Offset(
        (firstFinger.dx + _blankPosition.dx) / 2,
        (firstFinger.dy + _blankPosition.dy) / 2,
      );
      expect(
        object.lastDragPosition,
        within(distance: 1.0, from: firstFinger),
        reason: '位置来源必须是第一指, 用 ScaleUpdateDetails.localFocalPoint 会跳到 $centroid',
      );

      await first.up();
      await second.up();
      await tester.pump(_settle);
    });

    testWidgets('外层 touchSlop 小于 kTouchSlop 时仍能抢占', (tester) async {
      // Android 真机的平台 touchSlop 常小于框架常量, 写死像素阈值会在此失效:
      // 外层 hitSlop=8 时, 一个写死 10 的 claimSlop 永远晚一步。
      const outerTouchSlop = 8.0;
      assert(outerTouchSlop < kTouchSlop);
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('arena_small_slop'),
        hitRect: _handleRect,
      );
      final scene = await _pumpChartInListView(
        tester,
        indicator: indicator,
        touchSlop: outerTouchSlop,
      );
      addTearDown(() => disposeChart(tester, scene.chart));
      final object = indicator.object!;

      final gesture = await tester.startGesture(
        _toGlobal(tester, _handleRect.center),
        kind: PointerDeviceKind.touch,
      );
      // 单步必须细到 1px: 正确实现的 claimSlop 是 4(=8*0.5), 而两种典型错误
      // (写死 10、漏注入 gestureSettings 导致按 kTouchSlop 算出 9) 都落在外层的 8 之上。
      // 步长粗于 1px 时累计位移会跨过 8 与 9 之间的临界点, 这些错误就被单帧吞掉了。
      for (var i = 0; i < 30; i++) {
        await gesture.moveBy(const Offset(0, -1));
        await tester.pump(_frame);
      }

      expect(object.calls.first, 'dragStart');
      expect(scene.scroll.offset, 0, reason: 'claimSlop 必须随外层 hitSlop 一起变小');

      await gesture.up();
      await tester.pump(_settle);
    });
  });

  _drawArenaTests();
  _pointerMoveOwnerArenaTests();
  _scaleStartBaselineTests();
}

/// cross 与 zoom 态纵向拖动在可滚动容器内的归属。
///
/// 这两条的移动由 `Listener.onPointerMove` 直接驱动，Scale 只负责抢占竞技场——
/// 归属漏判时它们不是「变卡」而是被外层滚动整体吃掉，所以成对用例必须同时钉住
/// 「条件满足时图表拿到手势」与「条件不满足时手势归外层」。
void _pointerMoveOwnerArenaTests() {
  group('可滚动容器内的 cross 与缩放态平移', () {
    testWidgets('crossing 是模式: 拖动只移动十字线, 抬手不退出, 再次点击才退出', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('arena_cross_drag'),
        hitRect: _handleRect,
      );
      final scene = await _pumpChartInListView(tester, indicator: indicator);
      addTearDown(() => disposeChart(tester, scene.chart));
      final tapPosition = _toGlobal(tester, _blankPosition);

      // crossing 必须先由一次 tap 建立: cross 的拖动锚点仍复用 onTapUp 留下的手势数据。
      await tester.tapAt(tapPosition);
      await tester.pump(_settle);
      expect(scene.chart.isCrossing, isTrue);

      // dy 从不按蜡烛量化, 永远自由跟随, 是这里唯一可靠的观测量。
      Future<double> dragUp() async {
        final beforeDy = scene.chart.crossOffset!.dy;
        final gesture = await tester.startGesture(tapPosition, kind: PointerDeviceKind.touch);
        for (var i = 0; i < _stepCount; i++) {
          await gesture.moveBy(const Offset(0, _stepDy));
          await tester.pump(_frame);
        }
        await gesture.up();
        await tester.pump(_settle);
        return beforeDy;
      }

      final beforeFirst = await dragUp();
      expect(scene.chart.crossOffset!.dy, lessThan(beforeFirst), reason: '十字线应随手指上移');
      expect(scene.scroll.offset, 0, reason: '拖动十字线不应带动外层滚动');
      expect(scene.chart.isCrossing, isTrue, reason: '抬手不退出十字线模式');

      // 第二次拖动必须照样生效: 锚点被清空时这里会静默零响应(竞技场已抢占, 外层也不滚)。
      final beforeSecond = await dragUp();
      expect(scene.chart.crossOffset!.dy, lessThan(beforeSecond), reason: '同一 crossing 内可连续拖动');
      expect(scene.scroll.offset, 0);

      await tester.tapAt(tapPosition);
      await tester.pump(_settle);
      expect(scene.chart.isCrossing, isFalse, reason: '退出只由再次点击负责');
    });

    testWidgets('非 crossing 时同一手势 => 外层滚动, 十字线不出现', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('arena_cross_absent'),
        hitRect: _handleRect,
      );
      final scene = await _pumpChartInListView(tester, indicator: indicator);
      addTearDown(() => disposeChart(tester, scene.chart));
      expect(scene.chart.isCrossing, isFalse);

      final gesture = await tester.startGesture(
        _toGlobal(tester, _blankPosition),
        kind: PointerDeviceKind.touch,
      );
      for (var i = 0; i < _stepCount; i++) {
        await gesture.moveBy(const Offset(0, _stepDy));
        await tester.pump(_frame);
      }
      await gesture.up();
      await tester.pump(_settle);

      expect(scene.chart.isCrossing, isFalse, reason: 'cross 归属只在 isCrossing 时成立');
      expect(scene.scroll.offset, greaterThan(0), reason: '不满足归属条件的拖动仍归外层滚动');
    });

    testWidgets('缩放态下垂直拖动 => 图表纵向移动, 外层不滚动', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('arena_zooming_move'),
        hitRect: _handleRect,
      );
      final scene = await _pumpChartInListView(
        tester,
        indicator: indicator,
        visibleMinMaxFromData: true,
      );
      addTearDown(() => disposeChart(tester, scene.chart));
      scene.chart.updateGestureConfig((config) => config.copyWith(enableZoom: true));
      final sliderPosition = scene.chart.mainRect.center;
      scene.chart.setChartZoomSlideBarRect(
        Rect.fromCenter(center: sliderPosition, width: 80, height: 20),
      );
      await tester.pump(_frame);
      expect(scene.chart.onChartZoomStart(sliderPosition), isTrue);
      expect(scene.chart.isChartZooming, isTrue);
      final beforeMax = _rangeMax(scene.chart);
      final beforePadding = scene.chart.mainPadding;

      // 落点在主区内且避开 slider 矩形, 否则归优先级更高的 zoomSlider。
      final dragFrom = Offset(_blankPosition.dx, scene.chart.mainRect.top + 30);
      final gesture = await tester.startGesture(
        _toGlobal(tester, dragFrom),
        kind: PointerDeviceKind.touch,
      );
      for (var i = 0; i < _stepCount; i++) {
        await gesture.moveBy(const Offset(0, _stepDy));
        await tester.pump(_frame);
      }

      // 观察点是可见价格区间: 缩放态下纵向拖动平移区间, padding 不参与。
      // 向上拖动(_stepDy < 0)让区间下移, 内容随手指上移。
      expect(_rangeMax(scene.chart), lessThan(beforeMax), reason: 'Y 轴区间应随手指纵向平移');
      expect(scene.chart.mainPadding, beforePadding, reason: 'padding 不参与 Y 轴缩放');
      expect(scene.scroll.offset, 0, reason: '缩放态下的平移不应带动外层滚动');

      await gesture.up();
      await tester.pump(_settle);
    });
  });
}

/// 绘制工具（DrawObject）在可滚动容器内的拖动归属。
///
/// 与 PaintObject 共用同一个抢占机制，但走 `onScaleStart` 的 draw 分支——该分支
/// 优先级高于 PaintObject，且历史上用识别时刻位置命中（偏差 kPanSlop=36px，
/// 而 `drawConfig.hitTestMinDistance` 只有 10px，必然脱靶）。
void _drawArenaTests() {
  group('可滚动容器内的绘制工具拖动', () {
    /// 线画在图表右侧: 越靠右越确定落在已加载蜡烛的时间范围内,
    /// 否则 ts 算不出来、point.offset 变 infinite, hitTest 直接跳过。
    const lineFrom = Offset(280, 150);
    const lineTo = Offset(360, 150);
    const dragFrom = Offset(320, 150);

    Future<({FlexiKlineController chart, ScrollController scroll})> arrange(
      WidgetTester tester,
    ) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('draw_arena'),
        // 命中区移出线所在位置, 避免 PaintObject 抢走本该归 draw 的手势。
        hitRect: const Rect.fromLTWH(0, 260, 20, 20),
      );
      final scene = await _pumpChartInListView(
        tester,
        indicator: indicator,
        enableDraw: true,
      );
      drawTestLine(scene.chart, from: lineFrom, to: lineTo);
      await tester.pump(_frame);
      // 前置条件: 线已完成且处于 Editing, 两点 offset 有效。
      expect(scene.chart.drawState.isEditing, isTrue, reason: '两点直线应已绘制完成');
      final points = scene.chart.drawState.object!.points;
      expect(points.every((p) => p?.offset.isFinite == true), isTrue, reason: '绘制点 offset 必须有效');
      return scene;
    }

    testWidgets('从线上垂直拖动 => 绘制对象被拖动, 外层不滚动', (tester) async {
      final scene = await arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));
      final object = scene.chart.drawState.object!;
      final beforeDy = object.points.first!.offset.dy;

      final gesture = await tester.startGesture(
        _toGlobal(tester, dragFrom),
        kind: PointerDeviceKind.touch,
      );
      for (var i = 0; i < _stepCount; i++) {
        await gesture.moveBy(const Offset(0, _stepDy));
        await tester.pump(_frame);
      }

      expect(object.moving, isTrue, reason: 'onDrawMoveStart 应已认领本次拖动');
      expect(scene.scroll.offset, 0, reason: '拖动绘制对象不应带动外层滚动');

      await gesture.up();
      await tester.pump(_settle);
      expect(object.points.first!.offset.dy, lessThan(beforeDy), reason: '整条线应随手指上移');
    });

    testWidgets('从空白区垂直拖动 => 外层滚动, 绘制对象不动', (tester) async {
      final scene = await arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));
      final object = scene.chart.drawState.object!;

      // 与线有足够垂直距离, 超出 hitTestMinDistance(10)。
      final gesture = await tester.startGesture(
        _toGlobal(tester, const Offset(320, 60)),
        kind: PointerDeviceKind.touch,
      );
      for (var i = 0; i < _stepCount; i++) {
        await gesture.moveBy(const Offset(0, _stepDy));
        await tester.pump(_frame);
      }
      await gesture.up();
      await tester.pump(_settle);

      expect(scene.scroll.offset, greaterThan(0), reason: '空白区拖动仍归外层滚动');
      expect(object.moving, isFalse);
    });

    testWidgets('未完成绘制: 拖动只移动绘制点, 抬手不确认, 再点一次才确认', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('draw_drawing_owner'),
        hitRect: const Rect.fromLTWH(0, 260, 20, 20),
      );
      final scene = await _pumpChartInListView(
        tester,
        indicator: indicator,
        enableDraw: true,
      );
      addTearDown(() => disposeChart(tester, scene.chart));
      scene.chart.startDraw(testDrawLineType, isInitPointer: false);
      scene.chart.onDrawConfirm(lineFrom);
      expect(scene.chart.drawState.isDrawing, isTrue);
      final beforeDy = scene.chart.drawState.pointerOffset!.dy;

      final gesture = await tester.startGesture(
        _toGlobal(tester, lineFrom),
        kind: PointerDeviceKind.touch,
      );
      for (var i = 0; i < _stepCount; i++) {
        await gesture.moveBy(const Offset(0, _stepDy));
        await tester.pump(_frame);
      }
      await gesture.up();
      await tester.pump(_settle);

      // 拖动是调整位置, 不是落点: 抢占前 Tap 会在位移越过 postAcceptSlopTolerance
      // (= touchSlop) 时自我 reject 并停止跟踪, onTapUp 根本不会来, 所以从来不确认。
      expect(scene.chart.drawState.pointerOffset!.dy, lessThan(beforeDy), reason: '绘制点应随手指上移');
      expect(scene.chart.drawState.isDrawing, isTrue, reason: '拖动不得确认绘制点');
      expect(scene.scroll.offset, 0);

      // 确认是独立的一次点击。
      await tester.tapAt(_toGlobal(tester, lineTo));
      await tester.pump(_settle);
      expect(scene.chart.drawState.isEditing, isTrue, reason: '再点一次才确认第二个绘制点');
    });
  });
}

/// 双指缩放的起始基准。
///
/// `GestureDetector` 会给 Scale 识别器设 `dragStartBehavior`（默认 `start`），
/// `ScaleGestureRecognizer` 构造默认却是 `down`。取 `down` 时 `acceptGesture`
/// 不重置 `_initialSpan`，于是 accept 那一刻 `details.scale` 已经偏离 1.0，
/// `onScaleUpdate` 里首帧 `change` 就越过 0.01 阈值 → 缩放一上手跳一下。
void _scaleStartBaselineTests() {
  testWidgets('双指缩放首帧不跳变: 蜡烛宽度按 accept 时刻为基准', (tester) async {
    final indicator = TestInteractiveIndicator(
      key: const ExternalIndicatorKey('scale_baseline'),
      hitRect: const Rect.fromLTWH(0, 260, 20, 20),
    );
    final scene = await _pumpChartInListView(tester, indicator: indicator);
    addTearDown(() => disposeChart(tester, scene.chart));
    final beforeWidth = scene.chart.candleWidth;

    // 双指水平相背张开: 走 spanDelta 触发 accept, 而非 focalPointDelta。
    const center = Offset(200, 150);
    final left = await tester.startGesture(
      _toGlobal(tester, center - const Offset(40, 0)),
      pointer: 1,
      kind: PointerDeviceKind.touch,
    );
    final right = await tester.startGesture(
      _toGlobal(tester, center + const Offset(40, 0)),
      pointer: 2,
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(_frame);

    // 每指外移 2px, 走到刚越过抢占阈值的那一步就停下: 初始双指相距 80(span 40), 每步
    // span +2; 判据是「指间距变化 > hitSlop(18)」即 spanDelta > 9, 第 5 步 spanDelta=10
    // 首次越过, accept 与首帧 update 同时发生。多走一步这里就掺进真实缩放, 断言失去意义。
    for (var i = 0; i < 5; i++) {
      await left.moveBy(const Offset(-2, 0));
      await right.moveBy(const Offset(2, 0));
      await tester.pump(_frame);
    }

    // accept 时刻的 scale 必须以当时的 span 为基准(1.0), 否则首帧就吞掉一段缩放。
    // 允许 1 像素级的误差: 越过阈值那一步本身会带来极小的真实缩放。
    expect(
      scene.chart.candleWidth,
      closeTo(beforeWidth, 1.0),
      reason: 'dragStartBehavior 为 down 时 _initialSpan 不重置, 首帧 scale 已偏离 1.0',
    );

    // 继续张开: 缩放本身必须生效, 否则「首帧不跳变」会被「根本不缩放」假阳性满足。
    for (var i = 0; i < 20; i++) {
      await left.moveBy(const Offset(-4, 0));
      await right.moveBy(const Offset(4, 0));
      await tester.pump(_frame);
    }
    expect(scene.chart.candleWidth, greaterThan(beforeWidth), reason: '张开手指应放大蜡烛');

    await left.up();
    await right.up();
    await tester.pump(_settle);
  });
}
