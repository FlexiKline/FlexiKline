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

/// 非触摸端触控板（通道 P）捏合定责测试。
///
/// 覆盖：
/// - 双指纯滑动（scale 恒为 1）→ 图表平移，不发生 X 缩放
/// - 双指捏合（scale 变化）→ X 缩放，且图表不平移
/// - 捏合结束后重新发起手势可以正常平移
///
/// 覆盖边界：经 PointerPanZoom* → Listener → controller API。
/// **不覆盖**：真机触控板惯性衔接、光标外观。
/// **未经真机验证**。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

// ---------------------------------------------------------------------------
// 常量与搭建
// ---------------------------------------------------------------------------

const _spec = KlineSpec(
  symbol: 'NON-TOUCH-TRACKPAD',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

const _frame = Duration(milliseconds: 16);

Future<FlexiKlineController> _pumpNonTouchChart(WidgetTester tester) async {
  final controller = createChartController();
  controller.switchKlineData(_spec);
  controller.replaceKlineData(_spec, genFlatCandleList());

  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 400,
        height: 480,
        child: FlexiKlineWidget(
          controller: controller,
          candle: TestCandleIndicator(),
          time: TestTimeIndicator(),
          isTouchDevice: false,
        ),
      ),
    ),
  );
  await pumpUntilChart(
    tester,
    () => controller.isMounted && controller.mainChartWidth > 0 && controller.klineData.isNotEmpty,
    'non-touch chart data and layout',
  );
  return controller;
}

Offset _toGlobal(WidgetTester tester, Offset local) {
  final box = tester.renderObject<RenderBox>(
    find.byKey(const ValueKey('NonTouchListener')),
  );
  return box.localToGlobal(local);
}

Future<void> _disposeChart(
  WidgetTester tester,
  FlexiKlineController controller,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 200));
  controller.dispose();
}

// ---------------------------------------------------------------------------
// 用例
// ---------------------------------------------------------------------------

void main() {
  group('trackpad pinch vs pan', () {
    testWidgets('双指纯滑动（scale 恒为 1）→ 图表平移，不发生 X 缩放', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final center = controller.mainRect.center;
      final global = _toGlobal(tester, center);
      final initWidth = controller.candleWidth;
      final initDx = controller.paintDxOffset;

      // 触控板手势 kind 必须是 trackpad。
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      await gesture.panZoomStart(global);
      await tester.pump(_frame);

      // 纯滑动：scale 始终为 1，只有 pan 在变。
      var at = Duration.zero;
      for (var i = 0; i < 5; i++) {
        at += _frame;
        await gesture.panZoomUpdate(
          global,
          pan: Offset(10.0 * (i + 1), 0),
          scale: 1.0,
          timeStamp: at,
        );
        await tester.pump(_frame);
      }

      await gesture.panZoomEnd();
      await tester.pump(_frame);
      // DragGestureRecognizer 会把 panDelta 当拖动增量消费，触发 onPanEnd。
      // 等待 throttle 收尾。
      await tester.pump(const Duration(milliseconds: 60));

      // 蜡烛宽度不变（没有缩放）。
      expect(
        controller.candleWidth,
        equals(initWidth),
        reason: '纯滑动不应触发 X 缩放',
      );

      // paintDxOffset 应该有变化（平移发生了）。
      // DragGestureRecognizer 消费了 panDelta，走 onPanUpdate → onChartMove。
      expect(
        controller.paintDxOffset,
        isNot(equals(initDx)),
        reason: '纯滑动应触发图表平移',
      );
    });

    testWidgets('双指捏合（scale 变化）→ X 缩放，且图表不平移', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      // 用 right 锚点消除缩放本身对 paintDxOffset 的影响,
      // 使断言只反映 pan 位移。
      controller.updateGestureConfig(
        (c) => c.copyWith(scalePosition: ScalePosition.right),
      );

      final center = controller.mainRect.center;
      final global = _toGlobal(tester, center);
      final initWidth = controller.candleWidth;

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      await gesture.panZoomStart(global);
      await tester.pump(_frame);

      // 记录 pinching 置位前(PanZoomStart 已触发 onPanStart)的位置作为基线。
      final baselineDx = controller.paintDxOffset;

      // 捏合：scale 足够大使 pinching 在第一个 update 就置位。
      // pan 分量非零——真实捏合时手指也会移动, 这正是要被 pinching 抑制的部分。
      var at = Duration.zero;
      for (var i = 1; i <= 5; i++) {
        at += _frame;
        await gesture.panZoomUpdate(
          global,
          pan: Offset(8.0 * i, 0), // 非零 pan: 若 pinching 不生效会产生平移
          scale: 1.0 + 0.05 * i,
          timeStamp: at,
        );
        await tester.pump(_frame);
      }

      await gesture.panZoomEnd();
      await tester.pump(_frame);
      await tester.pump(const Duration(milliseconds: 60));

      // X 缩放发生了。
      expect(
        controller.candleWidth,
        isNot(equals(initWidth)),
        reason: '捏合应触发 X 缩放',
      );

      // right 锚点下 paintDxOffset <= 0 时不变(见 onChartScale 的 right 分支),
      // 所以 pinching 后 pan 位移的贡献为零。
      expect(
        (controller.paintDxOffset - baselineDx).abs(),
        lessThan(2.0),
        reason: '捏合期间 pinching 应抑制 pan',
      );
    });

    testWidgets('捏合结束后重新发起手势可以正常平移', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final center = controller.mainRect.center;
      final global = _toGlobal(tester, center);

      // 先做一轮捏合。
      final gesture1 = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      await gesture1.panZoomStart(global);
      await tester.pump(_frame);
      await gesture1.panZoomUpdate(global, scale: 1.3, timeStamp: _frame);
      await tester.pump(_frame);
      await gesture1.panZoomEnd();
      await tester.pump(_frame);
      await tester.pump(const Duration(milliseconds: 60));

      // 记录捏合后的 paintDxOffset。
      final afterPinchDx = controller.paintDxOffset;

      // 新一轮纯滑动。
      final gesture2 = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      await gesture2.panZoomStart(global);
      await tester.pump(_frame);

      var at = Duration.zero;
      for (var i = 0; i < 5; i++) {
        at += _frame;
        await gesture2.panZoomUpdate(
          global,
          pan: Offset(10.0 * (i + 1), 0),
          scale: 1.0,
          timeStamp: at,
        );
        await tester.pump(_frame);
      }

      await gesture2.panZoomEnd();
      await tester.pump(_frame);
      await tester.pump(const Duration(milliseconds: 60));

      // 捏合结束后, pinching 随 session 清零, 新一轮滑动能正常平移。
      expect(
        controller.paintDxOffset,
        isNot(equals(afterPinchDx)),
        reason: '捏合结束后重新发起的滑动应能正常平移',
      );
    });
  });
}
