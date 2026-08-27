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

/// pointer session 与 recognizer segment 的分界。
///
/// [ScaleGestureRecognizer] 的 onEnd 结束的是一个 **segment**：任何指针增减都会让它先派发
/// onEnd、退回 accepted，下一次移动再重新 onStart。而惯性平移、loadMore、业务收尾属于整轮
/// **pointer session**，只该发生一次。混用两者会让双指同向平移抬起一指就启动惯性，而剩余
/// 手指还在屏幕上继续拖，两个源同时改 `paintDxOffset`。
///
/// 另一半是最终 onEnd 可能缺席：抬起一指结束上一段后，剩余指针没再移动就直接抬起，不会有
/// 新的 onStart，也就没有与之配对的 onEnd。所以落点归属的收尾挂在活跃指针归零，只有需要
/// 系统抬手速度的图表兜底才等 onEnd。
///
/// 本文件的用例覆盖三组静默失效：segment 被当成 session（中途惯性 / 中途 loadMore）、
/// Cancel 只看末指（被系统打断却按正常提交）、打断惯性后动画与手势双驱动。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind, kScaleSlop;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'GESTURE-SESSION',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

/// 图表内的空白落点：无任何落点归属，手势只能由兜底判定裁决。
const _blankPosition = Offset(200, 240);

/// 可拖 PaintObject 的命中区，与 [_blankPosition] 不重叠。
const _hitRect = Rect.fromLTWH(20, 20, 120, 80);
const _hitCenter = Offset(80, 60);

/// 单步位移：小于 touchSlop，让抢占发生在累计位移越过阈值的那一步。
const _step = Offset(5, 0);

/// 惯性动画的观测时长。
///
/// 默认 `distanceFactor` = 0.8，逐帧 5px/16ms 约 312px/s，惯性距离约 250px、时长数百毫秒，
/// 这段窗口足以观察到 `paintDxOffset` 是否还在推进。
const _inertiaWindow = Duration(milliseconds: 300);

Future<({FlexiKlineController chart, ScrollController scroll})> _arrange(
  WidgetTester tester, {
  List<Indicator> mainIndicators = const [],
}) {
  return pumpChartInListView(
    tester,
    spec: _spec,
    candles: genFlatCandleList(),
    mainIndicators: mainIndicators,
  );
}

/// 抬手后把惯性动画推进到 [_inertiaWindow]。
///
/// 必须先单独泵一帧：`AnimationController.forward()` 只是挂上 ticker，要等下一帧回调才开始
/// 推进。少这一帧的话「惯性发生了」与「惯性没发生」在断言里长得一模一样。
Future<void> _pumpInertia(WidgetTester tester) async {
  await tester.pump(chartGestureFrame);
  await tester.pump(_inertiaWindow);
}

Future<({TestGesture gesture, Duration at})> _dragAlone(
  WidgetTester tester, {
  Offset from = _blankPosition,
  required int steps,
  int pointer = 1,
}) async {
  final gesture = await tester.startGesture(
    toChartGlobal(tester, from),
    pointer: pointer,
    kind: PointerDeviceKind.touch,
  );
  final at = await movePointers(tester, [gesture], unit: _step, steps: steps);
  return (gesture: gesture, at: at);
}

void main() {
  group('session 结束才惯性', () {
    testWidgets('单指抬手 => 按系统 velocity 惯性平移', (tester) async {
      final scene = await _arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));

      final drag = await _dragAlone(tester, steps: 8);
      final atLift = scene.chart.paintDxOffset;
      await drag.gesture.up(timeStamp: drag.at);
      await _pumpInertia(tester);

      // 护栏: segment/session 分派若把最终一段也当成中间段, 惯性就整条丢失。
      expect(
        scene.chart.paintDxOffset,
        isNot(atLift),
        reason: '最终 segment 应使用 ScaleEndDetails.velocity 启动惯性',
      );
      await tester.pump(chartGestureSettle);
    });

    testWidgets('双指同向平移依次抬手 => 中间段不惯性, 末指抬手才惯性', (tester) async {
      final scene = await _arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));

      final (left, right) = await startTwoFingers(tester, center: _blankPosition);
      var at = await movePointers(tester, [left, right], unit: _step, steps: 8);

      final atFirstLift = scene.chart.paintDxOffset;
      await left.up(timeStamp: at);
      await _pumpInertia(tester);
      expect(
        scene.chart.paintDxOffset,
        atFirstLift,
        reason: '抬起一指只结束 segment, 剩余手指还在屏幕上, 不该启动惯性',
      );

      // 剩余一指继续平移: 新 segment 由 onScaleStart 重判为 chartPan。
      at = await movePointers(tester, [right], unit: _step, steps: 6, since: at + _inertiaWindow);
      final atLastLift = scene.chart.paintDxOffset;
      expect(atLastLift, isNot(atFirstLift), reason: '抬起一指后剩余手指仍应能平移图表');

      await right.up(timeStamp: at);
      await _pumpInertia(tester);
      expect(scene.chart.paintDxOffset, isNot(atLastLift), reason: 'session 结束才惯性');
      await tester.pump(chartGestureSettle);
    });

    testWidgets('抬起一指后不移动直接抬末指 => 无最终 onEnd, 不惯性也不残留', (tester) async {
      final scene = await _arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));
      scene.chart.updateGestureConfig(
        (config) => config.copyWith(loadMoreWhenNoEnoughDistance: 100000),
      );

      final (left, right) = await startTwoFingers(tester, center: _blankPosition);
      final at = await movePointers(tester, [left, right], unit: _step, steps: 8);
      await left.up(timeStamp: at);
      await tester.pump(chartGestureFrame);

      // 剩余指针不再移动就抬起: recognizer 上一段已在 accepted 态, 不会重新 onStart,
      // 也就没有与之配对的最终 onEnd。收尾只能由活跃指针归零兜底。
      final atLastLift = scene.chart.paintDxOffset;
      await right.up(timeStamp: at + chartGestureFrame);
      await _pumpInertia(tester);
      expect(
        scene.chart.paintDxOffset,
        atLastLift,
        reason: '上一 segment 已提交, 末指未移动不该产生惯性',
      );
      expect(
        scene.chart.klineData.loadingState,
        KlineLoadingState.loadMore,
        reason: '最终 onEnd 缺席时仍应在 pointer session 结束时检查 loadMore',
      );

      // 状态无残留: 下一轮手势的位移基准应重新建立。
      final beforeNext = scene.chart.paintDxOffset;
      final next = await _dragAlone(tester, steps: 6, pointer: 3);
      expect(scene.chart.paintDxOffset, isNot(beforeNext), reason: '残留会让新手势被吞或基准算错');
      await next.gesture.up(timeStamp: next.at);
      await _pumpInertia(tester);
      await tester.pump(chartGestureSettle);
    });
  });

  group('segment 提交与 session 收尾分离', () {
    testWidgets('双指缩放抬起一指 => candleWidth 按段落库, 随后单指退回平移', (tester) async {
      final scene = await _arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));
      final beforeWidth = scene.chart.candleWidth;

      final (left, right) = await startTwoFingers(tester, center: _blankPosition);
      // 对称张开: 每指外移 5px 使间距每步增加 10px, 累计 30 > kScaleSlop(18)。
      const spreadSteps = 6;
      assert(_step.dx * spreadSteps > kScaleSlop);
      var at = Duration.zero;
      for (var i = 0; i < spreadSteps; i++) {
        at += chartGestureFrame;
        await left.moveBy(-_step, timeStamp: at);
        await right.moveBy(_step, timeStamp: at);
        await tester.pump(chartGestureFrame);
      }
      expect(scene.chart.candleWidth, greaterThan(beforeWidth), reason: '张开手指应放大蜡烛');

      await left.up(timeStamp: at);
      await tester.pump(chartGestureFrame);
      // onChartScaleEnd 属于 segment 提交, 不分 pointerCount: 只挂在 session 结束会让这一段
      // 的缩放结果永远不落库。
      expect(
        scene.chart.settingConfig.candleWidth,
        scene.chart.candleWidth,
        reason: 'chartScale segment 结束就该把 candleWidth 同步进配置',
      );

      final afterScale = scene.chart.paintDxOffset;
      at = await movePointers(tester, [right], unit: _step, steps: 6, since: at + chartGestureFrame);
      expect(
        scene.chart.paintDxOffset,
        isNot(afterScale),
        reason: '沿用旧归属会卡在缩放态 —— 单指 spanDelta 恒为 0, 既不缩放也不肯退回平移',
      );

      await right.up(timeStamp: at);
      await _pumpInertia(tester);
      await tester.pump(chartGestureSettle);
    });

    testWidgets('auto 缩放锚点跨 segment 保持同一解析结果', (tester) async {
      final scene = await _arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));
      final canvas = scene.chart.canvasRect;
      final initialCenter = Offset(canvas.center.dx, _blankPosition.dy);

      final (first, second) = await startTwoFingers(tester, center: initialCenter);
      var firstX = initialCenter.dx - 40;
      var at = Duration.zero;
      for (var i = 0; i < 6; i++) {
        at += chartGestureFrame;
        firstX -= _step.dx;
        await first.moveBy(-_step, timeStamp: at);
        await second.moveBy(_step, timeStamp: at);
        await tester.pump(chartGestureFrame);
      }
      await second.up(timeStamp: at);
      await tester.pump(chartGestureFrame);

      // 第二段的质心故意移到左三分之一: 若 auto 在新 segment 重新解析, 会从 middle 跳成
      // left。断言点取 middle 真正固定的那一点 —— paintDxOffset 为正时 middle 锚定主图中心
      // (见 ChartBinding.onChartScale), 而 left 锚定左边界, 中心下的蜡烛随之滑走。
      final secondFocalX = canvas.left + canvas.width * 0.30;
      final thirdX = secondFocalX * 2 - firstX;
      final third = await tester.startGesture(
        toChartGlobal(tester, Offset(thirdX, _blankPosition.dy)),
        pointer: 3,
        kind: PointerDeviceKind.touch,
      );
      await tester.pump(chartGestureFrame);
      expect(scene.chart.paintDxOffset, greaterThan(0), reason: '前置条件: middle 走锚定中心的分支');
      final anchorDx = scene.chart.mainChartLeft + scene.chart.mainChartWidthHalf;
      final anchoredIndex = scene.chart.dxToIndex(anchorDx);
      expect(anchoredIndex, isNotNull, reason: '前置条件: 锚点必须对应可见蜡烛');
      final beforeSecondScale = scene.chart.candleWidth;

      // 张开得够多才拉得开两种锚定的差距: 缩放倍率越接近 1, middle 与 left 固定的两点
      // 越难分辨, 断言就会退化成「在容差内碰巧一致」。
      for (var i = 0; i < 12; i++) {
        at += chartGestureFrame;
        await first.moveBy(_step, timeStamp: at);
        await third.moveBy(-_step, timeStamp: at);
        await tester.pump(chartGestureFrame);
      }

      expect(scene.chart.candleWidth, greaterThan(beforeSecondScale), reason: '前置条件: 第二 segment 必须已缩放');
      expect(
        scene.chart.dxToIndex(anchorDx),
        closeTo(anchoredIndex!, 1),
        reason: '重新按新质心解析为 left 会改成锚定左边界, 主图中心下的蜡烛随之跳变',
      );

      await first.up(timeStamp: at);
      await third.up(timeStamp: at + chartGestureFrame);
      await tester.pump(chartGestureSettle);
    });

    testWidgets('惯性平移中拖动 => 立即接管, 原动画不再推进', (tester) async {
      final scene = await _arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));

      final first = await _dragAlone(tester, steps: 8);
      final atLift = scene.chart.paintDxOffset;
      await first.gesture.up(timeStamp: first.at);
      // 惯性推进两帧: 既确认它真的在跑, 又留足剩余行程供后面观察是否被打断。
      await tester.pump(chartGestureFrame);
      await tester.pump(chartGestureFrame);
      final duringInertia = scene.chart.paintDxOffset;
      expect(duringInertia, isNot(atLift), reason: '前置条件: 惯性动画必须正在推进');

      // 惯性还在跑时按下并越过抢占阈值: 新手势应打断动画并接管。
      final second = await _dragAlone(tester, steps: 6, pointer: 2);
      final afterTakeover = scene.chart.paintDxOffset;
      expect(afterTakeover, isNot(duringInertia), reason: '新手势应驱动平移');

      // 手指按住不动: 若旧动画没被打断, 它会继续推进 paintDxOffset。
      await _pumpInertia(tester);
      expect(
        scene.chart.paintDxOffset,
        afterTakeover,
        reason: '旧惯性动画与新手势不得同时驱动',
      );

      await second.gesture.up(timeStamp: second.at);
      await _pumpInertia(tester);
      await tester.pump(chartGestureSettle);
    });
  });

  group('Cancel 跨 session 累积', () {
    testWidgets('chartScale Cancel => 提交 candleWidth 并检查 loadMore', (tester) async {
      final scene = await _arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));
      scene.chart.updateGestureConfig(
        (config) => config.copyWith(loadMoreWhenNoEnoughDistance: 100000),
      );
      final beforeWidth = scene.chart.candleWidth;

      final (left, right) = await startTwoFingers(tester, center: _blankPosition);
      var at = Duration.zero;
      for (var i = 0; i < 6; i++) {
        at += chartGestureFrame;
        await left.moveBy(-_step, timeStamp: at);
        await right.moveBy(_step, timeStamp: at);
        await tester.pump(chartGestureFrame);
      }
      expect(scene.chart.candleWidth, greaterThan(beforeWidth), reason: '前置条件: 必须已进入缩放');

      await left.cancel(timeStamp: at);
      await tester.pump(chartGestureFrame);
      expect(
        scene.chart.settingConfig.candleWidth,
        scene.chart.candleWidth,
        reason: 'Cancel 仍要提交已生效的缩放结果',
      );

      await right.cancel(timeStamp: at + chartGestureFrame);
      await tester.pump(chartGestureSettle);
      expect(
        scene.chart.klineData.loadingState,
        KlineLoadingState.loadMore,
        reason: 'Cancel 结束整轮 pointer session 后仍要检查 loadMore',
      );
    });

    testWidgets('非末指 Cancel + 末指 Up => 视为被打断, 不做惯性', (tester) async {
      final scene = await _arrange(tester);
      addTearDown(() => disposeChart(tester, scene.chart));

      final (left, right) = await startTwoFingers(tester, center: _blankPosition);
      var at = await movePointers(tester, [left, right], unit: _step, steps: 8);

      // 第一指被系统取消, 末指正常抬起: 只看最后离场的事件会把整轮误当正常提交。
      await left.cancel(timeStamp: at);
      await tester.pump(chartGestureFrame);
      at = await movePointers(tester, [right], unit: _step, steps: 6, since: at + chartGestureFrame);

      final atLift = scene.chart.paintDxOffset;
      await right.up(timeStamp: at);
      await _pumpInertia(tester);
      expect(
        scene.chart.paintDxOffset,
        atLift,
        reason: '本轮出现过 PointerCancel 即视为系统接管, 不该惯性',
      );
      await tester.pump(chartGestureSettle);
    });

    testWidgets('PaintObject 拖动中非末指 Cancel => 回滚而非提交', (tester) async {
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('session_cancel'),
        hitRect: _hitRect,
      );
      final scene = await _arrange(tester, mainIndicators: [indicator]);
      addTearDown(() => disposeChart(tester, scene.chart));

      final first = await tester.startGesture(
        toChartGlobal(tester, _hitCenter),
        pointer: 1,
        kind: PointerDeviceKind.touch,
      );
      var at = await movePointers(tester, [first], unit: _step, steps: 4);
      expect(indicator.object!.calls, contains('dragStart'));

      // 第二指落下不改变归属（落点归属独占整个 session），随后第一指被取消、第二指正常抬起。
      final second = await tester.startGesture(
        toChartGlobal(tester, _blankPosition),
        pointer: 2,
        kind: PointerDeviceKind.touch,
      );
      await tester.pump(chartGestureFrame);
      at += chartGestureFrame;
      await first.cancel(timeStamp: at);
      await tester.pump(chartGestureFrame);
      await second.up(timeStamp: at + chartGestureFrame);
      await tester.pump(chartGestureSettle);

      expect(
        indicator.object!.calls.last,
        'dragCancel',
        reason: 'Cancel 只看末指会把被系统打断的拖动当成正常提交',
      );
    });
  });
}
