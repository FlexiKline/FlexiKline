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

library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _day = Duration(days: 1);
final _latest = DateTime.utc(2026, 7, 10);
const _spec = KlineSpec(
  symbol: 'DATE-JUMP',
  interval: FlexiTimeInterval(1, TimeUnit.day),
);

CandleModel _candle(DateTime dateTime) {
  return CandleModel(
    timestamp: dateTime.millisecondsSinceEpoch,
    open: 100,
    high: 110,
    low: 90,
    close: 105,
    volume: 1000,
  );
}

List<CandleModel> _candles() {
  return [
    for (var i = 0; i <= 80; i++)
      if (i != 20) _candle(_latest.subtract(_day * i)),
  ];
}

Future<FlexiKlineController> _pumpChart(
  WidgetTester tester, {
  bool withData = true,
  bool? isTouchDevice,
}) async {
  final controller = createChartController();
  if (withData) {
    controller.switchKlineData(_spec);
    controller.replaceKlineData(_spec, _candles());
  }

  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: 400,
          height: 480,
          child: FlexiKlineWidget(
            controller: controller,
            candle: TestCandleIndicator(),
            time: TestTimeIndicator(),
            isTouchDevice: isTouchDevice,
          ),
        ),
      ),
    ),
  );
  await pumpUntilChart(
    tester,
    () => controller.isMounted && controller.mainChartWidth > 0 && (!withData || controller.klineData.isNotEmpty),
    withData ? 'chart data and layout' : 'empty chart layout',
  );
  return controller;
}

Future<T> _pumpUntilFutureComplete<T>(
  WidgetTester tester,
  Future<T> future,
  String description,
) async {
  var completed = false;
  future.then((_) {
    completed = true;
  });
  await pumpUntilChart(tester, () => completed, description);
  return future;
}

void _expectCandleCentered(
  FlexiKlineController controller,
  int index,
) {
  final candleCenter = controller.indexToDx(index)! - controller.candleWidthHalf;
  expect(
    candleCenter,
    closeTo(controller.mainChartRect.center.dx, 0.01),
  );
}

double _targetOffset(
  FlexiKlineController controller,
  int index,
) {
  return controller.clampPaintDxOffset(
    index * controller.candleActualWidth + controller.candleWidthHalf - controller.mainChartWidthHalf,
  );
}

void main() {
  group('FlexiKlineController.moveToDateTime', () {
    testWidgets('indexToCandleDx returns the candle center without changing indexToDx', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      const index = 40;
      final originalDx = controller.indexToDx(index)!;

      expect(
        controller.indexToCandleDx(index),
        closeTo(originalDx - controller.candleWidthHalf, 0.001),
      );
      expect(controller.indexToDx(index), originalDx);
      expect(controller.indexToCandleDx(80, check: true), isNull);
      expect(controller.indexToCandleDx(80, check: false), isNotNull);
    });

    testWidgets('exact timestamp animates the candle to chart center', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      final target = _latest.subtract(_day * 40);
      final index = controller.klineData.tsToIndex(
        target.millisecondsSinceEpoch,
      )!;
      final begin = controller.paintDxOffset;

      var completed = false;
      final future = controller.moveToDateTime(target).then((value) {
        completed = true;
        return value;
      });
      expect(controller.paintDxOffset, begin);

      await tester.pump(const Duration(milliseconds: 16));
      expect(completed, isFalse);

      await pumpUntilChart(
        tester,
        () => controller.paintDxOffset != begin,
        'exact date animation start',
      );
      expect(controller.paintDxOffset, isNot(begin));

      final expectedOffset = _targetOffset(controller, index);
      await pumpUntilChart(
        tester,
        () => (controller.paintDxOffset - expectedOffset).abs() < 0.01,
        'exact date animation',
      );
      _expectCandleCentered(controller, index);
      expect(await _pumpUntilFutureComplete(tester, future, 'exact date result'), index);
    });

    testWidgets('UTC calendar date keeps the selected day for daily candles', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      final selectedDay = DateTime.utc(2026, 6, 4);
      final expectedTimestamp = DateTime.utc(2026, 6, 4).millisecondsSinceEpoch;
      final expectedIndex = controller.klineData.tsToIndex(expectedTimestamp)!;

      final actualIndex = await _pumpUntilFutureComplete(
        tester,
        controller.moveToDateTime(selectedDay),
        'calendar date result',
      );

      expect(actualIndex, expectedIndex);
    });

    testWidgets('animation moves in both directions and initial reset reuses it', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      final historicalTarget = _latest.subtract(_day * 50);
      final initialOffset = controller.paintDxOffset;
      final historicalIndex = controller.klineData.tsToIndex(
        historicalTarget.millisecondsSinceEpoch,
      )!;

      final historicalFuture = controller.moveToDateTime(historicalTarget);
      await pumpUntilChart(
        tester,
        () => controller.paintDxOffset != initialOffset,
        'historical date animation start',
      );
      expect(controller.paintDxOffset, greaterThan(initialOffset));
      final expectedHistoricalOffset = _targetOffset(
        controller,
        historicalIndex,
      );
      await pumpUntilChart(
        tester,
        () => (controller.paintDxOffset - expectedHistoricalOffset).abs() < 0.01,
        'historical date animation',
      );
      expect(
        await _pumpUntilFutureComplete(tester, historicalFuture, 'historical date result'),
        historicalIndex,
      );

      final historicalOffset = controller.paintDxOffset;
      final expectedInitialOffset = controller.clampPaintDxOffset(
        controller.getInitPaintDxOffset(),
      );
      controller.requestMoveToInitialPosition();
      expect(controller.paintDxOffset, historicalOffset);

      await pumpUntilChart(
        tester,
        () => controller.paintDxOffset != historicalOffset,
        'initial position animation start',
      );
      expect(controller.paintDxOffset, lessThan(historicalOffset));
      await pumpUntilChart(
        tester,
        () => (controller.paintDxOffset - expectedInitialOffset).abs() < 0.01,
        'initial position animation',
      );
      expect(
        controller.paintDxOffset,
        closeTo(expectedInitialOffset, 0.01),
      );
    });

    testWidgets('same-position request cancels a pending animation', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      final historicalTarget = _latest.subtract(_day * 50);
      final initialOffset = controller.clampPaintDxOffset(
        controller.getInitPaintDxOffset(),
      );
      controller.requestMoveToInitialPosition();
      await pumpUntilChart(
        tester,
        () => (controller.paintDxOffset - initialOffset).abs() < 0.01,
        'initial position setup',
      );

      final dateMove = controller.moveToDateTime(historicalTarget);
      controller.requestMoveToInitialPosition();

      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        controller.paintDxOffset,
        closeTo(initialOffset, 0.01),
      );
      expect(await _pumpUntilFutureComplete(tester, dateMove, 'interrupted date result'), isNull);
    });

    testWidgets('same-position date move succeeds without changing the viewport', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      final target = _latest.subtract(_day * 40);
      final index = controller.klineData.tsToIndex(target.millisecondsSinceEpoch)!;

      final first = controller.moveToDateTime(target);
      await pumpUntilChart(
        tester,
        () => (controller.paintDxOffset - _targetOffset(controller, index)).abs() < 0.01,
        'initial date animation',
      );
      expect(await _pumpUntilFutureComplete(tester, first, 'initial date result'), index);

      final before = controller.paintDxOffset;
      final samePosition = controller.moveToDateTime(target);
      await tester.pump();

      expect(await _pumpUntilFutureComplete(tester, samePosition, 'same-position date result'), index);
      expect(controller.paintDxOffset, closeTo(before, 0.01));
    });

    testWidgets('later date move interrupts the earlier request', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      final firstTarget = _latest.subtract(_day * 60);
      final secondTarget = _latest.subtract(_day * 40);
      final secondIndex = controller.klineData.tsToIndex(secondTarget.millisecondsSinceEpoch)!;

      final first = controller.moveToDateTime(firstTarget);
      await tester.pump(const Duration(milliseconds: 16));
      final second = controller.moveToDateTime(secondTarget);

      expect(await _pumpUntilFutureComplete(tester, first, 'first interrupted date result'), isNull);
      await pumpUntilChart(
        tester,
        () => (controller.paintDxOffset - _targetOffset(controller, secondIndex)).abs() < 0.01,
        'second date animation',
      );
      expect(await _pumpUntilFutureComplete(tester, second, 'second date result'), secondIndex);
    });

    testWidgets('widget disposal interrupts a pending date move', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(controller.dispose);
      final target = _latest.subtract(_day * 60);
      final future = controller.moveToDateTime(target);

      await tester.pump(const Duration(milliseconds: 16));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(await _pumpUntilFutureComplete(tester, future, 'disposed date result'), isNull);
    });

    testWidgets('data switch during animation invalidates the target index', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      final target = _latest.subtract(_day * 60);
      final future = controller.moveToDateTime(target);

      await tester.pump(const Duration(milliseconds: 16));
      controller.switchKlineData(
        const KlineSpec(
          symbol: 'DATE-JUMP-OTHER',
          interval: FlexiTimeInterval(1, TimeUnit.day),
        ),
      );

      expect(await _pumpUntilFutureComplete(tester, future, 'switched data result'), isNull);
    });

    testWidgets('timestamp change at target index invalidates the result', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      final target = _latest.subtract(_day * 40);
      final index = controller.klineData.tsToIndex(target.millisecondsSinceEpoch)!;
      final future = controller.moveToDateTime(target);

      await tester.pump(const Duration(milliseconds: 16));
      final updated = _candles();
      updated[index] = _candle(target.add(const Duration(minutes: 1)));
      controller.replaceKlineData(_spec, updated);
      await tester.pump();

      expect(await _pumpUntilFutureComplete(tester, future, 'changed timestamp result'), isNull);
    });

    testWidgets('retained move callback is inert after widget disposal', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(controller.dispose);
      final callback = controller.moveToPositionCallback!;
      final before = controller.paintDxOffset;

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(await callback(before, before + 100), isFalse);
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.paintDxOffset, before);
    });

    testWidgets('widget disposal cancels a pending position animation', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(controller.dispose);
      final before = controller.paintDxOffset;
      final future = controller.moveToPositionCallback!(before, before + 100);

      await tester.pump(const Duration(milliseconds: 16));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(await future, isFalse);
    });

    testWidgets('position animation resolves true after it completes', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      final callback = controller.moveToPositionCallback!;
      final begin = controller.paintDxOffset;
      final end = controller.clampPaintDxOffset(begin + 100);
      var completed = false;

      final future = callback(begin, end).then((value) {
        completed = true;
        return value;
      });

      await tester.pump(const Duration(milliseconds: 16));
      expect(completed, isFalse);
      await pumpUntilChart(tester, () => completed, 'position animation completion');
      expect(await future, isTrue);
    });

    testWidgets('replacement position animation cancels the earlier request', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      final callback = controller.moveToPositionCallback!;
      final begin = controller.paintDxOffset;
      final firstEnd = controller.clampPaintDxOffset(begin + 100);
      final secondEnd = controller.clampPaintDxOffset(begin + 200);

      final first = callback(begin, firstEnd);
      await tester.pump(const Duration(milliseconds: 16));
      final second = callback(controller.paintDxOffset, secondEnd);

      expect(await first, isFalse);
      await pumpUntilChart(
        tester,
        () => (controller.paintDxOffset - secondEnd).abs() < 0.01,
        'replacement animation',
      );
      expect(await second, isTrue);
    });

    testWidgets('direct chart pan cancels a pending position animation', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      final begin = controller.paintDxOffset;
      final end = controller.clampPaintDxOffset(begin + 100);
      final future = controller.moveToPositionCallback!(begin, end);

      await tester.pump(const Duration(milliseconds: 16));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FlexiKlineWidget)),
      );
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();

      expect(await future, isFalse);
      await gesture.up();
    });

    testWidgets('touch zoom slider cancels a pending position animation when dragging starts', (tester) async {
      final controller = await _pumpChart(tester, isTouchDevice: true);
      addTearDown(() => disposeChart(tester, controller));
      controller.updateGestureConfig(
        (config) => config.copyWith(
          enableZoom: true,
          isManualSetZoomRect: true,
        ),
      );
      controller.setChartZoomSlideBarRect(
        Rect.fromLTWH(
          controller.mainRect.right - 24,
          controller.mainRect.top + 20,
          16,
          80,
        ),
      );
      await pumpUntilChart(
        tester,
        () => !controller.chartZoomSlideBarRect.isEmpty,
        'chart zoom slide bar layout',
      );
      final begin = controller.paintDxOffset;
      final end = controller.clampPaintDxOffset(begin + 100);
      final future = controller.moveToPositionCallback!(begin, end);

      await tester.pump(const Duration(milliseconds: 16));
      final listenerBox = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('TouchListener')),
      );
      final gesture = await tester.startGesture(
        listenerBox.localToGlobal(controller.chartZoomSlideBarRect.center),
      );
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump();

      expect(await _pumpUntilFutureComplete(tester, future, 'zoom slider interruption'), isFalse);
      await gesture.up();
    });

    testWidgets('touch zooming move cancels a pending position animation', (tester) async {
      final controller = await _pumpChart(tester, isTouchDevice: true);
      addTearDown(() => disposeChart(tester, controller));
      controller.updateGestureConfig(
        (config) => config.copyWith(
          enableZoom: true,
          isManualSetZoomRect: true,
        ),
      );
      controller.setChartZoomSlideBarRect(
        Rect.fromLTWH(
          controller.mainRect.right - 24,
          controller.mainRect.top + 20,
          16,
          80,
        ),
      );
      await pumpUntilChart(
        tester,
        () => !controller.chartZoomSlideBarRect.isEmpty,
        'chart zoom slide bar layout',
      );
      expect(
        controller.onChartZoomStart(controller.chartZoomSlideBarRect.center, false),
        isTrue,
      );
      await tester.pump();
      final begin = controller.paintDxOffset;
      final end = controller.clampPaintDxOffset(begin + 100);
      final future = controller.moveToPositionCallback!(begin, end);

      await tester.pump(const Duration(milliseconds: 16));
      final listenerBox = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('TouchListener')),
      );
      final gesture = await tester.startGesture(
        listenerBox.localToGlobal(controller.mainRect.center),
      );
      await gesture.moveBy(const Offset(30, 10));
      await tester.pump();

      expect(await _pumpUntilFutureComplete(tester, future, 'zooming move interruption'), isFalse);
      await gesture.up();
    });

    testWidgets('gap selects the nearest real candle at or before target', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      final missingDay = _latest.subtract(_day * 20);
      final target = missingDay.add(const Duration(hours: 12));
      final expected = _latest.subtract(_day * 21);
      final expectedIndex = controller.klineData.tsToIndex(
        expected.millisecondsSinceEpoch,
      )!;

      final future = controller.moveToDateTime(target);
      final expectedOffset = _targetOffset(controller, expectedIndex);
      await pumpUntilChart(
        tester,
        () => (controller.paintDxOffset - expectedOffset).abs() < 0.01,
        'gap date animation',
      );

      _expectCandleCentered(controller, expectedIndex);
      expect(await _pumpUntilFutureComplete(tester, future, 'gap date result'), expectedIndex);
    });

    testWidgets('latest and oldest candles use existing paint boundaries', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));

      final latestIndex = controller.klineData.tsToIndex(
        _latest.millisecondsSinceEpoch,
      )!;
      final expectedLatestOffset = _targetOffset(
        controller,
        latestIndex,
      );
      final latestFuture = controller.moveToDateTime(_latest);
      await pumpUntilChart(
        tester,
        () => (controller.paintDxOffset - expectedLatestOffset).abs() < 0.01,
        'latest candle animation',
      );
      expect(
        controller.paintDxOffset,
        closeTo(expectedLatestOffset, 0.01),
      );
      expect(await _pumpUntilFutureComplete(tester, latestFuture, 'latest date result'), latestIndex);

      final oldest = _latest.subtract(_day * 80);
      final oldestIndex = controller.klineData.tsToIndex(
        oldest.millisecondsSinceEpoch,
      )!;
      final expectedOldestOffset = _targetOffset(
        controller,
        oldestIndex,
      );
      final oldestFuture = controller.moveToDateTime(oldest);
      await pumpUntilChart(
        tester,
        () => (controller.paintDxOffset - expectedOldestOffset).abs() < 0.01,
        'oldest candle animation',
      );
      expect(
        controller.paintDxOffset,
        closeTo(expectedOldestOffset, 0.01),
      );
      expect(await _pumpUntilFutureComplete(tester, oldestFuture, 'oldest date result'), oldestIndex);
    });

    testWidgets('out-of-range dates fail without moving viewport', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => disposeChart(tester, controller));
      final before = controller.paintDxOffset;

      expect(await controller.moveToDateTime(_latest.add(_day)), isNull);
      expect(await controller.moveToDateTime(_latest.subtract(_day * 81)), isNull);
      expect(controller.paintDxOffset, before);
    });

    testWidgets('mounted empty chart rejects date movement', (tester) async {
      final controller = await _pumpChart(tester, withData: false);
      addTearDown(() => disposeChart(tester, controller));

      expect(await controller.moveToDateTime(_latest), isNull);
      expect(controller.paintDxOffset, 0);
    });
  });
}
