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

/// 非触摸端退出 zoom 的快捷方式：ESC 与右键。
///
/// 经 Listener / KeyboardListener → controller API。**未经真机验证**。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import '../../support/support.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _spec = KlineSpec(
  symbol: 'UX-POLISH',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

const _frame = Duration(milliseconds: 16);

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
      controller.onDrawConfirm(
        Offset(mainRect.left + 20, mainRect.center.dy),
      );
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
}
