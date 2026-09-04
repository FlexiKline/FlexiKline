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

/// 落点归属的驱动来源与坐标模型。
///
/// 六种落点归属统一由 `onScaleUpdate` 驱动，坐标恒为「锚点 + 第一指总位移」。
/// 这两条不变量各自对应一类静默失效：
/// - 改回逐帧累加增量 → `onScaleUpdate` 的节流丢帧会同时丢掉位移，表现为「拖不到位」；
/// - 锚点取识别时刻位置 → 按下到抢占之间的一个 claimSlop 被吞掉，表现为「永久滞后」。
///
/// 两者都不会抛异常、不会改变回调序列，只有校验累计位移才能钉住。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'GESTURE-DRIVE',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

/// 可拖动手柄区。
const _handleRect = Rect.fromLTWH(100, 100, 30, 20);

/// 图表内避开 [_handleRect] 的落点。
const _blankPosition = Offset(300, 240);

/// 单步位移: 小于默认 claimSlop(touchSlop 18 * 0.5 = 9), 于是抢占发生在第二步,
/// 第一步的位移落在「按下到抢占」区间内 —— 正是锚点取错时会被吞掉的那一段。
const _stepDy = -5.0;
const _stepCount = 8;

/// 手指总位移。
const _totalDy = _stepDy * _stepCount;

const _frame = Duration(milliseconds: 16);
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

Future<FlexiKlineController> _pumpChart(
  WidgetTester tester,
  TestInteractiveIndicator indicator,
) async {
  final chart = createChartController();
  chart.switchKlineData(_spec);
  chart.replaceKlineData(_spec, _candles());

  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
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
    ),
  );
  await pumpUntilChart(
    tester,
    () => chart.isMounted && chart.mainChartWidth > 0 && chart.klineData.isNotEmpty,
    'chart data and layout',
  );
  return chart;
}

Offset _toGlobal(WidgetTester tester, Offset local) {
  final box = tester.renderObject<RenderBox>(find.byKey(const ValueKey('TouchListener')));
  return box.localToGlobal(local);
}

void main() {
  group('落点归属的坐标模型', () {
    testWidgets('累计位移等于手指总位移: 按下到抢占之间的一段不丢', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('drive_total_delta'),
        hitRect: _handleRect,
      );
      final chart = await _pumpChart(tester, indicator);
      addTearDown(() => disposeChart(tester, chart));
      final object = indicator.object!;

      final gesture = await tester.startGesture(
        _toGlobal(tester, _handleRect.center),
        kind: PointerDeviceKind.touch,
      );
      for (var i = 0; i < _stepCount; i++) {
        await gesture.moveBy(const Offset(0, _stepDy));
        await tester.pump(_frame);
      }
      await gesture.up();
      await tester.pump(_settle);

      // 锚点必须是按下位置: 取识别时刻位置会少掉第一步的 5px。
      expect(
        object.totalDragDelta,
        within(distance: 0.01, from: const Offset(0, _totalDy)),
        reason: '锚点取识别时刻位置会吞掉按下到抢占之间的一个 claimSlop',
      );
      expect(
        object.lastDragPosition,
        within(distance: 0.01, from: _handleRect.center + const Offset(0, _totalDy)),
      );
    });

    testWidgets('节流丢帧后累计位移仍等于手指总位移', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('drive_dropped_frames'),
        hitRect: _handleRect,
      );
      final chart = await _pumpChart(tester, indicator);
      addTearDown(() => disposeChart(tester, chart));
      final object = indicator.object!;

      final gesture = await tester.startGesture(
        _toGlobal(tester, _handleRect.center),
        kind: PointerDeviceKind.touch,
      );
      // 前两步各自推进一帧, 让抢占在第二步发生并产生第一次驱动。
      for (var i = 0; i < 2; i++) {
        await gesture.moveBy(const Offset(0, _stepDy));
        await tester.pump(_frame);
      }
      final drivesBeforeDrop = object.calls.where((call) => call == 'dragUpdate').length;
      // 余下六步不推进时钟: 全部落在同一个节流窗口内, `unaryThrottle` 只留最后一个。
      for (var i = 2; i < _stepCount; i++) {
        await gesture.moveBy(const Offset(0, _stepDy));
      }
      await tester.pump(_frame);
      await gesture.up();
      await tester.pump(_settle);

      final drives = object.calls.where((call) => call == 'dragUpdate').length;
      // 前置条件: 确实发生了丢帧, 否则本用例退化成上一条。
      expect(
        drives - drivesBeforeDrop,
        lessThan(_stepCount - 2),
        reason: '六步挤在同一节流窗口内, 驱动次数必须少于移动次数',
      );
      expect(
        object.totalDragDelta,
        within(distance: 0.01, from: const Offset(0, _totalDy)),
        reason: '逐帧累加增量的写法会随被丢弃的驱动一起丢掉位移',
      );
    });
  });

  group('cross 的拖动锚点', () {
    testWidgets('从当前十字线位置继续移动, 不跳回上一次点击的位置', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('drive_cross_anchor'),
        // 命中区移出下面用到的落点, 避免 PaintObject 与 cross 争抢归属。
        hitRect: const Rect.fromLTWH(0, 0, 10, 10),
      );
      final chart = await _pumpChart(tester, indicator);
      addTearDown(() => disposeChart(tester, chart));

      final tapPosition = _toGlobal(tester, _blankPosition);
      await tester.tapAt(tapPosition);
      await tester.pump(_settle);
      expect(chart.isCrossing, isTrue);

      // 由外部把焦点移到别处（`force` 重新锚定而不退出 crossing）：此后
      // 「上一次点击留下的手势数据」与「cross 的权威状态」不再相等,
      // 两种锚点来源才可区分。dy 从不按蜡烛量化, 是唯一可靠的观测量。
      final relocated = Offset(_blankPosition.dx, _blankPosition.dy - 120);
      chart.onCrossFollow(relocated);
      await tester.pump(_frame);
      final anchorDy = chart.crossOffset!.dy;
      expect(anchorDy, within(distance: 0.01, from: relocated.dy));

      final gesture = await tester.startGesture(tapPosition, kind: PointerDeviceKind.touch);
      for (var i = 0; i < _stepCount; i++) {
        await gesture.moveBy(const Offset(0, _stepDy));
        await tester.pump(_frame);
      }
      await gesture.up();
      await tester.pump(_settle);

      expect(
        chart.crossOffset!.dy,
        within(distance: 0.01, from: anchorDy + _totalDy),
        reason: '锚点取 onTapUp 留下的手势数据时, 十字线会跳回 ${_blankPosition.dy + _totalDy}',
      );
    });
  });

  group('长按与落点归属的竞技场之争', _longPressCollisionTests);
}

/// 驱动收敛后 Scale 是落点归属的唯一驱动源，而 `LongPressGestureRecognizer` 在 500ms
/// 无位移时会 `resolve(accepted)` 并把 Scale 踢出竞技场 —— 此时归属还在，却再没有回调
/// 能驱动它。cross 与未完成绘制在 `onLongPressStart` 里本就是空操作，所以必须让长按
/// 让开；而 draw editing 有自己的长按路径，让开不能扩到它身上。
void _longPressCollisionTests() {
  testWidgets('crossing 中先长按停顿再拖动 => 十字线仍随手指移动', (tester) async {
    final indicator = TestInteractiveIndicator(
      key: const ExternalIndicatorKey('drive_longpress_cross'),
      hitRect: const Rect.fromLTWH(0, 0, 10, 10),
    );
    final chart = await _pumpChart(tester, indicator);
    addTearDown(() => disposeChart(tester, chart));

    final position = _toGlobal(tester, _blankPosition);
    await tester.tapAt(position);
    await tester.pump(_settle);
    expect(chart.isCrossing, isTrue);

    final beforeDy = chart.crossOffset!.dy;
    final gesture = await tester.startGesture(position, kind: PointerDeviceKind.touch);
    // 停顿超过 kLongPressTimeout(500ms) 再动手指。
    await tester.pump(const Duration(milliseconds: 600));
    for (var i = 0; i < _stepCount; i++) {
      await gesture.moveBy(const Offset(0, _stepDy));
      await tester.pump(_frame);
    }
    await gesture.up();
    await tester.pump(_settle);

    expect(
      chart.crossOffset!.dy,
      lessThan(beforeDy),
      reason: '长按赢下竞技场后 Scale 被 reject, 十字线会完全不响应',
    );
  });

  testWidgets('未完成绘制中先长按停顿再拖动 => 绘制点仍随手指移动', (tester) async {
    final indicator = TestInteractiveIndicator(
      key: const ExternalIndicatorKey('drive_longpress_drawing'),
      hitRect: const Rect.fromLTWH(0, 0, 10, 10),
    );
    final chart = await _pumpChart(tester, indicator);
    addTearDown(() => disposeChart(tester, chart));
    registerTestDrawObject(chart);
    chart.setDrawVisible(true);
    // 画在右侧: 越靠右越确定落在已加载蜡烛的时间范围内, 否则 point.offset 会变 infinite。
    const drawFrom = Offset(320, 150);
    chart.startDraw(testDrawLineType, isInitPointer: false);
    chart.onDrawConfirm(drawFrom);
    await tester.pump(_frame);
    expect(chart.drawState.isDrawing, isTrue);
    final beforeDy = chart.drawState.pointerOffset!.dy;

    final gesture = await tester.startGesture(
      _toGlobal(tester, drawFrom),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(const Duration(milliseconds: 600));
    for (var i = 0; i < _stepCount; i++) {
      await gesture.moveBy(const Offset(0, _stepDy));
      await tester.pump(_frame);
    }

    expect(
      chart.drawState.pointerOffset!.dy,
      lessThan(beforeDy),
      reason: '长按赢下竞技场后 Scale 被 reject, 绘制点会完全不响应',
    );

    await gesture.up();
    await tester.pump(_settle);
  });

  testWidgets('编辑中的绘制对象长按仍立即进入移动态: 让开只覆盖没有长按路径的归属', (tester) async {
    final indicator = TestInteractiveIndicator(
      key: const ExternalIndicatorKey('drive_longpress_editing'),
      hitRect: const Rect.fromLTWH(0, 260, 20, 20),
    );
    final chart = await _pumpChart(tester, indicator);
    addTearDown(() => disposeChart(tester, chart));
    registerTestDrawObject(chart);
    chart.setDrawVisible(true);
    drawTestLine(chart, from: const Offset(280, 150), to: const Offset(360, 150));
    await tester.pump(_frame);
    expect(chart.drawState.isEditing, isTrue);
    final object = chart.drawState.object!;

    final gesture = await tester.startGesture(
      _toGlobal(tester, const Offset(320, 150)),
      kind: PointerDeviceKind.touch,
    );
    // 只停顿, 一步都不移动: 唯一能进入移动态的路径就是长按。
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      object.moving,
      isTrue,
      reason: 'draw editing 有自己的长按路径, 把让开扩到全部归属会连带废掉它',
    );

    await gesture.up();
    await tester.pump(_settle);
  });
}
