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

/// ListView 里图表下方的填充高度, 保证外层确实可滚动。
const _filler = 800.0;

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

/// 把图表嵌进可垂直滚动的 [ListView], 返回观测外层滚动的 controller。
///
/// [touchSlop] 非空时在图表子树外覆盖 `gestureSettings`, 用于模拟 Android 真机上
/// 小于 [kTouchSlop] 的平台值 —— 外层 Scrollable 与图表读同一份设置。
Future<({FlexiKlineController chart, ScrollController scroll})> _pumpChartInListView(
  WidgetTester tester, {
  required TestInteractiveIndicator indicator,
  double? touchSlop,
  bool enableDraw = false,
}) async {
  final chart = createChartController();
  chart.switchKlineData(_spec);
  chart.replaceKlineData(_spec, _candles());
  if (enableDraw) {
    registerTestDrawObject(chart);
    chart.setDrawVisible(true);
  }
  final scroll = ScrollController();
  addTearDown(scroll.dispose);

  Widget wrapGestureSettings(BuildContext context, Widget child) {
    if (touchSlop == null) return child;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        gestureSettings: DeviceGestureSettings(touchSlop: touchSlop),
      ),
      child: child,
    );
  }

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => wrapGestureSettings(
          context,
          ListView(
            controller: scroll,
            children: [
              SizedBox(
                width: 400,
                height: 480,
                child: FlexiKlineWidget(
                  controller: chart,
                  candle: TestCandleIndicator(),
                  time: TestTimeIndicator(),
                  mainIndicators: [indicator],
                  isTouchDevice: true,
                ),
              ),
              const SizedBox(height: _filler),
            ],
          ),
        ),
      ),
    ),
  );
  await pumpUntilChart(
    tester,
    () => chart.isMounted && chart.mainChartWidth > 0 && chart.klineData.isNotEmpty,
    'chart data and layout',
  );
  return (chart: chart, scroll: scroll);
}

/// 把图表局部坐标换算为全局坐标。
Offset _toGlobal(WidgetTester tester, Offset local) {
  final box = tester.renderObject<RenderBox>(find.byKey(const ValueKey('TouchListener')));
  return box.localToGlobal(local);
}

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

    testWidgets('抢占后第二指落下 => 转缩放语义并回滚拖动', (tester) async {
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

      expect(object.calls.last, 'dragCancel');
      expect(scene.chart.isPaintObjectDragging, isFalse);

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
  _scaleStartBaselineTests();
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

    // 每指外移 2px, 走到刚越过 kScaleSlop(18) 的那一步就停下: 初始双指相距 80(span 40),
    // 每步 span +2, 第 10 步 spanDelta=20 首次越过阈值, accept 与首帧 update 同时发生。
    for (var i = 0; i < 10; i++) {
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
