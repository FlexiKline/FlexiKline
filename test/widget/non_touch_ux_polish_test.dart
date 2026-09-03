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

/// 非触摸端交互策略收尾测试。
///
/// 覆盖：
/// - 触控板双指横滑（scale ≈ 1 微波动）→ 图表平移，不触发 X 缩放
/// - ESC 在 zoom 态 → 退出 zoom
/// - 右键在 zoom 态 → 退出 zoom
/// - drawEditing 拖动开始 → cross 被取消
///
/// 覆盖边界：手势识别→controller API 调用→状态变更。
/// **不覆盖**：光标在各平台的真实渲染外观、真机触控板手感。
/// **未经真机验证**。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _spec = KlineSpec(
  symbol: 'UX-POLISH',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

const _frame = Duration(milliseconds: 16);
const _settle = Duration(milliseconds: 60);

// ---------------------------------------------------------------------------
// Setup helpers
// ---------------------------------------------------------------------------

Future<FlexiKlineController> _pumpNonTouchChart(
  WidgetTester tester, {
  bool enableDraw = false,
  bool enableZoom = true,
}) async {
  final controller = createChartController();
  controller.switchKlineData(_spec);
  controller.replaceKlineData(_spec, genFlatCandleList());
  if (enableDraw) {
    registerTestDrawObject(controller);
    controller.setDrawVisible(true);
  }
  if (!enableZoom) {
    controller.updateGestureConfig(
      (config) => config.copyWith(enableZoom: false),
    );
  }

  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 400,
        height: 480,
        child: FlexiKlineWidget(
          controller: controller,
          candle: TestCandleIndicator(visibleMinMaxFromData: true),
          time: TestTimeIndicator(),
          isTouchDevice: false,
        ),
      ),
    ),
  );
  await pumpUntilChart(
    tester,
    () => controller.isMounted && controller.mainChartWidth > 0 && controller.klineData.isNotEmpty,
    'non-touch chart ready',
  );
  return controller;
}

Offset _toGlobal(WidgetTester tester, Offset local) {
  final box = tester.renderObject<RenderBox>(
    find.byKey(const ValueKey('NonTouchListener')),
  );
  return box.localToGlobal(local);
}

/// Enter zoom state by enabling zoom and calling onChartZoomStep.
/// Must be called after `await tester.pump()` so paint has completed at least once.
Future<void> _enterZoom(
  WidgetTester tester,
  FlexiKlineController controller,
) async {
  controller.updateGestureConfig(
    (config) => config.copyWith(enableZoom: true),
  );
  // Pump multiple frames to ensure at least one full paint pass populates minMax.
  for (var i = 0; i < 5; i++) {
    await tester.pump(_frame);
  }
  final result = controller.onChartZoomStep(0.8); // zoom in
  expect(result, isTrue, reason: 'onChartZoomStep should succeed after paint');
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ---- A: Trackpad two-finger horizontal pan with micro scale noise ----
  group('trackpad horizontal pan (pinch threshold)', () {
    testWidgets('two-finger horizontal slide with scale noise < 0.05 → pan, no scale', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => disposeChart(tester, controller));

      final center = controller.mainRect.center;
      final global = _toGlobal(tester, center);
      final initWidth = controller.candleWidth;
      final initDx = controller.paintDxOffset;

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      await gesture.panZoomStart(global);
      await tester.pump(_frame);

      // Simulate horizontal slide with small scale noise (< 0.05 from 1.0).
      // Real trackpad data shows noise typically < 0.02.
      var at = Duration.zero;
      for (var i = 0; i < 8; i++) {
        at += _frame;
        await gesture.panZoomUpdate(
          global,
          pan: Offset(8.0 * (i + 1), 0),
          // Scale oscillates around 1.0 with amplitude < 0.02.
          scale: 1.0 + (i.isEven ? 0.015 : -0.01),
          timeStamp: at,
        );
        await tester.pump(_frame);
      }

      await gesture.panZoomEnd();
      await tester.pump(_frame);
      await tester.pump(_settle);

      // Candle width should NOT change (no X scale triggered).
      expect(
        controller.candleWidth,
        equals(initWidth),
        reason: 'scale noise < 0.05 should not trigger pinching/X-scale',
      );

      // Chart should have panned (pan not suppressed).
      expect(
        controller.paintDxOffset,
        isNot(equals(initDx)),
        reason: 'horizontal slide with small scale noise should still pan',
      );
    });

    testWidgets('two-finger pinch with scale > 0.05 from 1.0 → scale, pan suppressed', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => disposeChart(tester, controller));

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

      final baselineDx = controller.paintDxOffset;

      // Scale clearly exceeds threshold (> 0.05 from 1.0).
      var at = Duration.zero;
      for (var i = 1; i <= 5; i++) {
        at += _frame;
        await gesture.panZoomUpdate(
          global,
          pan: Offset(8.0 * i, 0),
          scale: 1.0 + 0.06 * i, // 1.06, 1.12, 1.18, 1.24, 1.30
          timeStamp: at,
        );
        await tester.pump(_frame);
      }

      await gesture.panZoomEnd();
      await tester.pump(_frame);
      await tester.pump(_settle);

      // X scale should have occurred.
      expect(
        controller.candleWidth,
        isNot(equals(initWidth)),
        reason: 'scale > 0.05 should trigger pinching and X-scale',
      );

      // Pan should be suppressed (right anchor: paintDxOffset stable).
      expect(
        (controller.paintDxOffset - baselineDx).abs(),
        lessThan(2.0),
        reason: 'pinching should suppress pan',
      );
    });
  });

  // ---- B: ESC and right-click exit zoom ----
  group('exit zoom shortcuts', () {
    testWidgets('ESC exits zoom state', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => disposeChart(tester, controller));

      await _enterZoom(tester, controller);
      await tester.pump();
      expect(controller.isChartZooming, isTrue, reason: 'precondition: zooming');

      // Send ESC key event. KeyboardListener needs focus.
      // Simulate ESC via sendKeyEvent.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(
        controller.isChartZooming,
        isFalse,
        reason: 'ESC should exit zoom state',
      );
    });

    testWidgets('ESC prefers exiting zoom over exiting draw', (tester) async {
      final controller = await _pumpNonTouchChart(tester, enableDraw: true);
      addTearDown(() => disposeChart(tester, controller));

      // Enter draw and zoom simultaneously.
      final mainRect = controller.mainRect;
      controller.startDraw(testDrawLineType, isInitPointer: false);
      controller.onDrawConfirm(GestureData.tap(
        Offset(mainRect.left + 20, mainRect.center.dy),
      ));
      await tester.pump();
      expect(controller.drawState.isDrawing, isTrue);

      await _enterZoom(tester, controller);
      await tester.pump();
      expect(controller.isChartZooming, isTrue);

      // ESC should exit zoom first, draw stays.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(controller.isChartZooming, isFalse, reason: 'ESC exits zoom first');
      expect(controller.drawState.isOngoing, isTrue, reason: 'draw should still be active');

      // Second ESC exits draw.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(controller.drawState.isOngoing, isFalse, reason: 'second ESC exits draw');
    });

    testWidgets('right-click exits zoom state', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => disposeChart(tester, controller));

      await _enterZoom(tester, controller);
      await tester.pump();
      expect(controller.isChartZooming, isTrue, reason: 'precondition: zooming');

      // Send a secondary (right) mouse button down event via Listener.
      final center = controller.mainRect.center;
      final global = _toGlobal(tester, center);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.down(global, buttons: kSecondaryMouseButton));
      await tester.pump();
      await tester.sendEventToBinding(pointer.up());
      await tester.pump();

      expect(
        controller.isChartZooming,
        isFalse,
        reason: 'right-click should exit zoom state',
      );
    });

    testWidgets('right-click when not zooming does nothing', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => disposeChart(tester, controller));

      expect(controller.isChartZooming, isFalse);

      final center = controller.mainRect.center;
      final global = _toGlobal(tester, center);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.down(global, buttons: kSecondaryMouseButton));
      await tester.pump();
      await tester.sendEventToBinding(pointer.up());
      await tester.pump();

      // Should not crash or change any state.
      expect(controller.isChartZooming, isFalse);
    });
  });

  // ---- C: drawEditing drag cancels cross ----
  group('drawEditing drag cancels cross', () {
    testWidgets('dragging a draw object cancels cross', (tester) async {
      final controller = await _pumpNonTouchChart(tester, enableDraw: true);
      addTearDown(() => disposeChart(tester, controller));

      // Draw a line to enter Editing state.
      final mainRect = controller.mainRect;
      final from = Offset(mainRect.left + 20, mainRect.center.dy);
      final to = Offset(mainRect.left + 100, mainRect.center.dy);
      drawTestLine(controller, from: from, to: to);
      await tester.pump();
      expect(controller.drawState.isEditing, isTrue);

      // Establish cross via hover.
      final hoverGesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        pointer: 1,
      );
      await hoverGesture.addPointer(location: _toGlobal(tester, from));
      await tester.pump();
      await hoverGesture.moveTo(_toGlobal(tester, from));
      await tester.pump();
      // Note: hover on drawEditing early-returns, so cross may not be active.
      // Explicitly start cross if needed.
      if (!controller.isCrossing) {
        // Move to chart area first to establish cross, then move to draw object.
        final chartPos = Offset(mainRect.center.dx, mainRect.top + 10);
        await hoverGesture.moveTo(_toGlobal(tester, chartPos));
        await tester.pump();
      }
      await hoverGesture.removePointer();
      await tester.pump();

      // Manually ensure crossing is active for the test.
      if (!controller.isCrossing) {
        controller.onCrossStart(GestureData.hover(from), force: true);
        await tester.pump();
      }
      expect(controller.isCrossing, isTrue, reason: 'precondition: cross active');

      // Start dragging the draw object (it's at `from`).
      final dragGesture = await tester.startGesture(
        _toGlobal(tester, from),
        kind: PointerDeviceKind.mouse,
        pointer: 2,
      );
      await dragGesture.moveBy(const Offset(0, -10));
      await tester.pump();

      // Cross should be cancelled at drag start.
      expect(
        controller.isCrossing,
        isFalse,
        reason: 'drawEditing drag start should cancel cross',
      );

      await dragGesture.up();
      await tester.pump(_settle);
    });
  });
}
