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

/// 图表整体操作的兜底归属：条件抢占与族内切换。
///
/// 落点没有业务归属时，手势不再无条件归图表，也不再按指数二分 pan/scale：
/// - 方向判定：横向占优才抢占，纵向与斜拖让给外层滚动，位移不足则保留点击语义；
/// - 意图分派：双指同向横向是平移而非缩放，双指张开才是缩放，且只允许 pan → scale。
///
/// 三条静默失效各自对应一组用例：抢占阈值降到落点归属那个更小的 claimSlop 会吃掉点击；
/// 按指数分派会让双指同向横向「赢了竞技场却原地不动」；缺少族内切换会让双指先平移再张开
/// 时缩放永久失效。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind, kPanSlop, kScaleSlop, kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'CHART-FALLBACK',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

/// 图表内的空白落点：无任何落点归属，手势只能由兜底判定裁决。
///
/// 主图默认 400×300，取值留足右侧余量，避免拖动把质心顶到 canvasRect 边界被钳制。
const _blankPosition = Offset(200, 240);

/// 双指初始间距的一半。
const _spreadHalf = 40.0;

/// 单步位移：小于 [kTouchSlop]，让抢占发生在累计位移越过阈值的那一步。
const _step = 5.0;

const _frame = Duration(milliseconds: 16);

/// 手势收尾时长：`throttleOnFps` 的尾调用会再起一轮 timer，需留两个周期。
const _settle = Duration(milliseconds: 60);

Future<({FlexiKlineController chart, ScrollController scroll})> _arrange(WidgetTester tester) {
  return pumpChartInListView(tester, spec: _spec, candles: genFlatCandleList());
}

/// 从 [_blankPosition] 起按 [_step] 逐帧拖动 [steps] 步，方向由 [unit] 给出。
Future<TestGesture> _drag(
  WidgetTester tester, {
  required Offset unit,
  required int steps,
}) async {
  final gesture = await tester.startGesture(
    toChartGlobal(tester, _blankPosition),
    kind: PointerDeviceKind.touch,
  );
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(unit * _step);
    await tester.pump(_frame);
  }
  return gesture;
}

void main() {
  group('兜底归属的方向判定', () {
    testWidgets('横向占优: 越过 hitSlop 即平移图表, 不等原生 panSlop', (tester) async {
      final scene = await _arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));
      final before = scene.chart.paintDxOffset;

      // 累计 25px: 已越过 hitSlop(18) 但远未到 ScaleGestureRecognizer 自我 accept 的
      // panSlop(36) —— 这段区间只有条件抢占能拿到手势。
      const total = _step * 5;
      assert(total > kTouchSlop && total < kPanSlop);
      final gesture = await _drag(tester, unit: const Offset(1, 0), steps: 5);

      expect(
        scene.chart.paintDxOffset,
        isNot(before),
        reason: '不抢占时要等质心位移超过 panSlop($kPanSlop) 才起步, 此刻只有 $total',
      );
      expect(scene.scroll.offset, 0, reason: '纯横向拖动对外层的纵向累加没有贡献');

      await gesture.up();
      await tester.pump(_settle);
    });

    testWidgets('纵向拖动: 让给外层滚动, 图表不平移', (tester) async {
      final scene = await _arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));
      final before = scene.chart.paintDxOffset;

      final gesture = await _drag(tester, unit: const Offset(0, -1), steps: 8);
      await gesture.up();
      await tester.pump(_settle);

      // 普通平移只消费 dx, 纵向位移对它毫无意义, 让给外层是语义正确而非妥协。
      expect(scene.scroll.offset, greaterThan(0), reason: '纵向拖动应归外层滚动');
      expect(scene.chart.paintDxOffset, before);
    });

    testWidgets('45° 斜拖: 落在横向占优锥外, 仍归外层滚动', (tester) async {
      final scene = await _arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));
      final before = scene.chart.paintDxOffset;

      // dx:dy = 1:1, 默认 panClaimRatio=2 要求 dx > 2×dy, 因此放弃。
      final gesture = await _drag(tester, unit: const Offset(1, -1), steps: 8);
      await gesture.up();
      await tester.pump(_settle);

      expect(scene.scroll.offset, greaterThan(0), reason: '斜拖不满足横向占优, 不该抢占');
      expect(scene.chart.paintDxOffset, before);
    });

    testWidgets('位移不足 hitSlop: 点击语义保留, 十字线照常启动', (tester) async {
      final scene = await _arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));
      final before = scene.chart.paintDxOffset;

      // 10px 已超过落点归属的 claimSlop(touchSlop×0.5=9), 但未到 hitSlop(18)。
      // 兜底阈值若取 claimSlop, 这一手势就会变成平移, Tap 被 reject, 十字线再也起不来。
      final gesture = await tester.startGesture(
        toChartGlobal(tester, _blankPosition),
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump(_frame);
      await gesture.up();
      await tester.pump(_settle);

      expect(scene.chart.isCrossing, isTrue, reason: 'Tap 必须仍能赢下竞技场');
      expect(scene.chart.paintDxOffset, before);
      expect(scene.scroll.offset, 0);
    });
  });

  group('兜底归属的意图分派与族内切换', _fallbackDispatchTests);

  group('纵向捏合的抢占', _verticalPinchTests);
}

/// 纵向捏合在可滚动容器内的抢占时机。
///
/// 缩放判据与轴无关（span 是各指到质心的欧氏平均距离），所以纵向捏合本就能缩放；真机上
/// 「必须横着捏」是抢占失败后的适应性行为——横向捏合靠 `chartPan` 顺路抢到，纵向没有这条
/// 通道，只能等指间距判据，而它一度按 `kScaleSlop` 算、实际要求 36px 指间距变化，外层只
/// 要 18px。
///
/// 断言主体是 `candleWidth`：外层赢下竞技场即意味着图表的 Scale 被 reject，`onScaleUpdate`
/// 再也不来，缩放一动不动。`scroll.offset` 在张开方向上会被 `ClampingScrollPhysics` 钳在
/// 0，断言它反而测不出胜负。
///
/// 用例都取「一指不动或少动」的姿势：裁决前外层累加的是各指 dy 的**带符号和**
/// （`_shouldTrackMoveEvent` 在未 accept 时对所有指针放行，多指策略只影响 accept 之后的
/// 滚动增量），所以严格对称的捏合两指相消、外层永远不 accept，图表本就赢得轻松，测不出
/// 量纲错配。真机上输掉的正是一指主导的姿势。
void _verticalPinchTests() {
  /// 两指上下排列落在 [_blankPosition]，返回 (上指, 下指)。
  Future<(TestGesture, TestGesture)> verticalFingers(WidgetTester tester) {
    return startTwoFingers(
      tester,
      center: _blankPosition,
      axis: Axis.vertical,
      spreadHalf: _spreadHalf,
    );
  }

  testWidgets('纵向捏合: 图表赢下竞技场并缩放', (tester) async {
    final scene = await _arrange(tester);
    addTearDown(() => disposeChart(tester, scene.chart));
    final beforeWidth = scene.chart.candleWidth;

    final (top, bottom) = await verticalFingers(tester);
    // 下指主导、上指几乎不动: 每步指间距 +7 而外层只累加 +5, 图表在第 3 步抢到, 外层要到
    // 第 4 步才够 —— 判据按 kScaleSlop 时图表要等到第 6 步, 手势早被外层拿走。
    for (var i = 0; i < 6; i++) {
      await top.moveBy(const Offset(0, -1));
      await bottom.moveBy(const Offset(0, 6));
      await tester.pump(_frame);
    }

    expect(
      scene.chart.candleWidth,
      greaterThan(beforeWidth),
      reason: '判据按 kScaleSlop 时要等 36px 指间距变化, 外层 18px 就先接管并 reject 掉 Scale',
    );

    await top.up();
    await bottom.up();
    await tester.pump(_settle);
  });

  testWidgets('纵向捏合一指锚定: 移动的不是第一指也能抢到', (tester) async {
    final scene = await _arrange(tester);
    addTearDown(() => disposeChart(tester, scene.chart));
    final beforeWidth = scene.chart.candleWidth;

    final (top, bottom) = await verticalFingers(tester);
    // 拇指按住不动、食指移动是最常见的捏合姿势。抢占只看第一指位移时这条快速通道一次都不
    // 触发; 换成「任一指位移」才成立 —— claimSlop 防的是点击, 而点击只可能是单指。
    //
    // 这一姿势下图表的判据与外层严格同点(指间距变化 = 该指位移 = 外层的带符号累加), 胜负
    // 全靠事件内先后: Listener 在命中路径中深于 Scrollable, 同一 move 事件里先判定归属;
    // 图表的 recognizer 也先于外层注册进 pointerRouter, 显式 accept 立即兑现。
    for (var i = 0; i < 8; i++) {
      await bottom.moveBy(const Offset(0, 5));
      await tester.pump(_frame);
    }

    expect(
      scene.chart.candleWidth,
      greaterThan(beforeWidth),
      reason: '第一指位移恒为 0, 只看它就永远抢不到, 手势整段归外层滚动',
    );

    await top.up();
    await bottom.up();
    await tester.pump(_settle);
  });

  testWidgets('双指同向纵向: 仍归外层滚动, 不误判成缩放', (tester) async {
    final scene = await _arrange(tester);
    addTearDown(() => disposeChart(tester, scene.chart));
    final beforeWidth = scene.chart.candleWidth;
    final beforeOffset = scene.chart.paintDxOffset;

    final (top, bottom) = await verticalFingers(tester);
    // 同向移动不改变指间距, spanDelta 恒为 0: 抢占阈值降低不得把它拽进缩放, 否则
    //「双指同向纵向应由外层滚动」这条设计整条失效。
    for (var i = 0; i < 8; i++) {
      await top.moveBy(const Offset(0, -_step));
      await bottom.moveBy(const Offset(0, -_step));
      await tester.pump(_frame);
    }
    await top.up();
    await bottom.up();
    await tester.pump(_settle);

    expect(scene.scroll.offset, greaterThan(0), reason: '双指同向纵向应归外层滚动');
    expect(scene.chart.candleWidth, beforeWidth);
    expect(scene.chart.paintDxOffset, beforeOffset);
  });
}

/// 双指手势按意图而非指数分派。
///
/// 旧实现只看 `details.pointerCount > 1`：双指同向横向移动被判为缩放，而 span 未变
/// `details.scale` 恒为 1.0，`onScaleUpdate` 的 0.01 阈值把它整段吞掉 —— 图表赢了竞技场
/// 却原地不动。
void _fallbackDispatchTests() {
  /// 落下两指，返回 (左指, 右指)。
  Future<(TestGesture, TestGesture)> twoFingers(WidgetTester tester) async {
    final left = await tester.startGesture(
      toChartGlobal(tester, _blankPosition - const Offset(_spreadHalf, 0)),
      pointer: 1,
      kind: PointerDeviceKind.touch,
    );
    final right = await tester.startGesture(
      toChartGlobal(tester, _blankPosition + const Offset(_spreadHalf, 0)),
      pointer: 2,
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(_frame);
    return (left, right);
  }

  /// 双指同向平移 [steps] 步。
  Future<void> translate(
    WidgetTester tester,
    TestGesture left,
    TestGesture right, {
    required int steps,
  }) async {
    for (var i = 0; i < steps; i++) {
      await left.moveBy(const Offset(_step, 0));
      await right.moveBy(const Offset(_step, 0));
      await tester.pump(_frame);
    }
  }

  testWidgets('双指同向横向 => 平移图表, 不进缩放', (tester) async {
    final scene = await _arrange(tester);
    addTearDown(() => disposeChart(tester, scene.chart));
    final beforeOffset = scene.chart.paintDxOffset;
    final beforeWidth = scene.chart.candleWidth;

    final (left, right) = await twoFingers(tester);
    await translate(tester, left, right, steps: 6);

    expect(
      scene.chart.paintDxOffset,
      isNot(beforeOffset),
      reason: '按指数分派时会判成缩放, 而 span 未变 => details.scale 恒为 1.0, 图表原地不动',
    );
    expect(scene.chart.candleWidth, beforeWidth, reason: 'span 未变就不该缩放');

    await left.up();
    await right.up();
    await tester.pump(_settle);
  });

  testWidgets('先同向平移再张开手指 => 单向切换到缩放', (tester) async {
    final scene = await _arrange(tester);
    addTearDown(() => disposeChart(tester, scene.chart));

    final (left, right) = await twoFingers(tester);
    // 先把归属定在 chartPan 上。
    await translate(tester, left, right, steps: 6);
    final afterPanWidth = scene.chart.candleWidth;

    // 再对称张开: 每指外移 5px 使 span 增加 5px, 6 步后累计 30 > kScaleSlop(18)。
    const spread = _step * 6;
    assert(spread > kScaleSlop);
    for (var i = 0; i < 6; i++) {
      await left.moveBy(const Offset(-_step, 0));
      await right.moveBy(const Offset(_step, 0));
      await tester.pump(_frame);
    }

    expect(
      scene.chart.candleWidth,
      greaterThan(afterPanWidth),
      reason: '不允许 pan => scale 切换时, 指针数量没变就不会重新派发 start, 缩放永久失效',
    );

    await left.up();
    await right.up();
    await tester.pump(_settle);
  });

  testWidgets('缩放开始后收回间距再同向平移 => 不回切平移', (tester) async {
    final scene = await _arrange(tester);
    addTearDown(() => disposeChart(tester, scene.chart));
    final beforeWidth = scene.chart.candleWidth;

    final (left, right) = await twoFingers(tester);
    // 只动右指张开: 第一指不动 => 兜底判定拿不到位移, 由原生 kScaleSlop 直接判成缩放,
    // 绕开 pan => scale 的切换路径, 单独钉住"反向不切"。
    Future<void> spreadRight(double unit) async {
      for (var i = 0; i < 12; i++) {
        await right.moveBy(Offset(unit, 0));
        await tester.pump(_frame);
      }
    }

    await spreadRight(_step);
    expect(scene.chart.candleWidth, greaterThan(beforeWidth), reason: '张开手指应放大蜡烛');

    // 收回到初始间距: 此刻累计 spanDelta 归零, 若每帧重判归属就会翻回 chartPan ——
    // 这是"反向切换"唯一能发生的形态, 也是本用例要挡住的。
    await spreadRight(-_step);

    final scaledOffset = scene.chart.paintDxOffset;
    final scaledWidth = scene.chart.candleWidth;
    await translate(tester, left, right, steps: 6);

    expect(
      scene.chart.paintDxOffset,
      scaledOffset,
      reason: '回切平移会让缩放中途转成 onChartMove, paintDxOffset 随质心一起漂移',
    );
    expect(scene.chart.candleWidth, scaledWidth);

    await left.up();
    await right.up();
    await tester.pump(_settle);
  });
}
