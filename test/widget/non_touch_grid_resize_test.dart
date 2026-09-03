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

/// 非触摸端 gridResize（hover 变光标 + 直接拖动副区高度）的测试。
///
/// 覆盖：hover 到分隔线时光标变为 resizeRow、dx 约束（价格轴范围不命中）、
/// 拖动改变副区高度且不触发图表平移、fixed 布局下限制。
///
/// 覆盖边界：手势识别→controller API 调用→状态变更。
/// **不覆盖**：光标在各平台的真实渲染外观、真机触控板手感。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/view/non_touch_gesture_owner.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _spec = KlineSpec(
  symbol: 'GRID-RESIZE',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

const _chartWidth = 400.0;
const _chartHeight = 480.0;

/// Sub indicator height.
const _subHeight = 100.0;

// ---------------------------------------------------------------------------
// Setup helpers
// ---------------------------------------------------------------------------

/// Build a non-touch chart with sub indicator(s) and grid resize enabled.
Future<FlexiKlineController> _pumpGridResizeChart(
  WidgetTester tester, {
  FlexiLayoutMode layoutMode = FlexiLayoutMode.adapt,
  Size? fixedSize,
  int subCount = 1,
}) async {
  final controller = createChartController(
    initialLayoutMode: layoutMode,
    initialFixedSize: fixedSize,
  );
  controller.switchKlineData(_spec);
  controller.replaceKlineData(_spec, genFlatCandleList());

  // Enable grid resize.
  controller.updateGridConfig(
    (config) => config.copyWith(isAllowDragIndicatorHeight: true),
  );

  final subIndicators = <Indicator>[];
  for (var i = 0; i < subCount; i++) {
    final key = DirectIndicatorKey('grid_resize_sub_$i');
    subIndicators.add(TestDirectIndicator(
      key: key,
      height: _subHeight,
      autoActivate: true,
    ));
  }

  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: _chartWidth,
        height: _chartHeight,
        child: FlexiKlineWidget(
          controller: controller,
          candle: TestCandleIndicator(),
          time: TestTimeIndicator(),
          subIndicators: subIndicators,
          isTouchDevice: false,
        ),
      ),
    ),
  );
  await pumpUntilChart(
    tester,
    () =>
        controller.isMounted &&
        controller.mainChartWidth > 0 &&
        controller.klineData.isNotEmpty &&
        controller.getSubIndicatorHeights().isNotEmpty,
    'non-touch chart with sub indicator ready',
  );
  return controller;
}

/// Global coordinate conversion (non-touch Listener key).
Offset _toGlobal(WidgetTester tester, Offset local) {
  final box = tester.renderObject<RenderBox>(
    find.byKey(const ValueKey('NonTouchListener')),
  );
  return box.localToGlobal(local);
}

/// The divider between main and first sub sits at mainChartRect.bottom.
Offset _dividerInContent(FlexiKlineController controller) {
  final y = controller.mainChartRect.bottom;
  final x = controller.mainChartRect.width / 2;
  return Offset(x, y);
}

/// A position at divider height but in the price axis area (dx > mainChartRect.right).
Offset _dividerInPriceAxis(FlexiKlineController controller) {
  final y = controller.mainChartRect.bottom;
  final x = controller.mainChartRect.right + 10;
  return Offset(x, y);
}

/// A position far from any divider (in the middle of main chart).
Offset _blankPosition(FlexiKlineController controller) {
  return Offset(
    controller.mainChartRect.width / 2,
    controller.mainChartRect.height / 3,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('gridResize hover cursor', () {
    testWidgets('hover on divider → resizeRow; move away → restores', (tester) async {
      final controller = await _pumpGridResizeChart(tester);
      addTearDown(() => disposeChart(tester, controller));

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      final divider = _dividerInContent(controller);
      final blank = _blankPosition(controller);

      // Enter chart at blank position.
      await tester.sendEventToBinding(pointer.hover(_toGlobal(tester, blank)));
      await tester.pump();

      // Ownership at blank should be chart, not gridResize.
      expect(
        NonTouchGestureOwner.resolveAt(controller, blank),
        isNot(NonTouchGestureOwner.gridResize),
        reason: 'blank position should not resolve to gridResize',
      );

      // Move to divider.
      await tester.sendEventToBinding(pointer.hover(_toGlobal(tester, divider)));
      await tester.pump();

      // Ownership at divider should be gridResize, and cursor should be resizeRow.
      expect(
        NonTouchGestureOwner.resolveAt(controller, divider),
        NonTouchGestureOwner.gridResize,
        reason: 'divider position within content area should resolve to gridResize',
      );
      expect(
        NonTouchGestureOwner.gridResize.hoverCursor,
        SystemMouseCursors.resizeRow,
        reason: 'gridResize hover cursor should be resizeRow',
      );

      // Move back to blank.
      await tester.sendEventToBinding(pointer.hover(_toGlobal(tester, blank)));
      await tester.pump();

      expect(
        NonTouchGestureOwner.resolveAt(controller, blank),
        isNot(NonTouchGestureOwner.gridResize),
        reason: 'ownership should restore when moving away from divider',
      );
    });

    testWidgets('hover at divider height in price axis → NOT gridResize (dx constraint)', (tester) async {
      final controller = await _pumpGridResizeChart(tester);
      addTearDown(() => disposeChart(tester, controller));

      final priceAxisPos = _dividerInPriceAxis(controller);

      // The raw hitTestGridResize (without dx constraint) should still hit.
      expect(
        controller.hitTestGridResize(priceAxisPos),
        isTrue,
        reason: 'raw hitTestGridResize (no dx constraint) hits the divider',
      );

      // But the ownership layer should reject it (dx > mainChartRect.right).
      expect(
        NonTouchGestureOwner.resolveAt(controller, priceAxisPos),
        isNot(NonTouchGestureOwner.gridResize),
        reason: 'dx in price axis range should be rejected by ownership layer dx constraint',
      );
    });
  });

  group('gridResize drag', () {
    testWidgets('drag on divider changes sub height; does not pan chart', (tester) async {
      final controller = await _pumpGridResizeChart(tester);
      addTearDown(() => disposeChart(tester, controller));

      final divider = _dividerInContent(controller);
      final beforeDxOffset = controller.paintDxOffset;

      // Get sub indicator heights before dragging.
      final heightsBefore = controller.getSubIndicatorHeights().toList();
      expect(heightsBefore, isNotEmpty, reason: 'sub indicator should exist');
      final firstSubHeightBefore = heightsBefore.first;

      // Start a mouse drag on the divider, move downward (expands main, shrinks sub).
      final gesture = await tester.startGesture(
        _toGlobal(tester, divider),
        kind: PointerDeviceKind.mouse,
      );
      var at = Duration.zero;
      for (var i = 0; i < 6; i++) {
        at += chartGestureFrame;
        await gesture.moveBy(const Offset(0, 5), timeStamp: at);
        await tester.pump(chartGestureFrame);
      }
      await gesture.up(timeStamp: at);
      await tester.pump(chartGestureSettle);

      final heightsAfter = controller.getSubIndicatorHeights().toList();
      final firstSubHeightAfter = heightsAfter.first;

      // Dragging down on the main/sub divider should shrink the sub indicator.
      expect(
        firstSubHeightAfter,
        lessThan(firstSubHeightBefore),
        reason: 'dragging divider down should shrink sub indicator height',
      );

      // Chart should not have panned.
      expect(
        controller.paintDxOffset,
        beforeDxOffset,
        reason: 'gridResize drag should not trigger chart pan',
      );
    });

    testWidgets('drag starts and ends grid resize state (isStartDragGrid)', (tester) async {
      final controller = await _pumpGridResizeChart(tester);
      addTearDown(() => disposeChart(tester, controller));

      final divider = _dividerInContent(controller);

      expect(controller.isStartDragGrid, isFalse, reason: 'no drag yet');

      final gesture = await tester.startGesture(
        _toGlobal(tester, divider),
        kind: PointerDeviceKind.mouse,
      );
      // Move enough to trigger pan recognition (mouse pan threshold ~2px).
      await gesture.moveBy(const Offset(0, 5));
      await tester.pump();

      expect(
        controller.isStartDragGrid,
        isTrue,
        reason: 'after drag on divider, isStartDragGrid should be true',
      );

      await gesture.up();
      await tester.pump(chartGestureSettle);

      expect(
        controller.isStartDragGrid,
        isFalse,
        reason: 'after drag end, isStartDragGrid should be false',
      );
    });

    testWidgets('gridResize drag cursor stays resizeRow during drag', (tester) async {
      final controller = await _pumpGridResizeChart(tester);
      addTearDown(() => disposeChart(tester, controller));

      // The drag cursor for gridResize should be resizeRow.
      expect(
        NonTouchGestureOwner.gridResize.dragCursor(controller),
        SystemMouseCursors.resizeRow,
        reason: 'gridResize drag cursor should be resizeRow',
      );
    });
  });

  group('gridResize fixed layout', () {
    testWidgets('fixed layout with single sub: last sub bottom is not resizable', (tester) async {
      final controller = await _pumpGridResizeChart(
        tester,
        layoutMode: FlexiLayoutMode.fixed,
        fixedSize: const Size(_chartWidth, _chartHeight),
      );
      addTearDown(() => disposeChart(tester, controller));

      final subHeights = controller.getSubIndicatorHeights().toList();
      expect(subHeights, hasLength(1), reason: 'single sub indicator setup');

      // The bottom of the sub panel. In adapt mode, the sub's bottom edge
      // can be dragged (canvas height changes), but in fixed mode there's no
      // "down" neighbor → hitTestGridResize returns false.
      final subRect = controller.subRect;
      final subBottom = Offset(controller.mainChartRect.width / 2, subRect.bottom);

      expect(
        controller.hitTestGridResize(subBottom),
        isFalse,
        reason: 'fixed layout: last sub bottom divider should not be resizable (no down neighbor)',
      );

      // But the main/sub divider IS resizable (has both up=main and down=sub).
      final mainSubDivider = _dividerInContent(controller);
      expect(
        controller.hitTestGridResize(mainSubDivider),
        isTrue,
        reason: 'fixed layout: main/sub divider should be resizable',
      );
    });

    testWidgets('fixed layout with two subs: inter-sub divider is resizable', (tester) async {
      final controller = await _pumpGridResizeChart(
        tester,
        layoutMode: FlexiLayoutMode.fixed,
        fixedSize: const Size(_chartWidth, _chartHeight),
        subCount: 2,
      );
      addTearDown(() => disposeChart(tester, controller));

      final subHeights = controller.getSubIndicatorHeights().toList();
      expect(subHeights.length, greaterThanOrEqualTo(2), reason: 'two sub indicators');

      // The divider between main and first sub.
      final mainSubDivider = _dividerInContent(controller);
      expect(
        controller.hitTestGridResize(mainSubDivider),
        isTrue,
        reason: 'main/sub divider should be resizable in fixed layout',
      );
    });
  });
}
