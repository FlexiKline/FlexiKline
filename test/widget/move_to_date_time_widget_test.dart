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
}) async {
  final controller = FlexiKlineController(
    configuration: FakeFlexiKlineConfiguration(
      mainIndicatorDefaultSize: const Size(400, 300),
    ),
  );
  if (withData) {
    controller.switchKlineData(_spec);
    await controller.updateKlineData(_spec, _candles());
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
          ),
        ),
      ),
    ),
  );
  await _pumpUntil(
    tester,
    () => controller.isMounted && controller.mainChartWidth > 0 && (!withData || controller.klineData.isNotEmpty),
    withData ? 'chart data and layout' : 'empty chart layout',
  );
  return controller;
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition,
  String description,
) async {
  for (var i = 0; i < 200; i++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 16));
  }
  fail('Timed out waiting for $description');
}

Future<void> _disposeChart(
  WidgetTester tester,
  FlexiKlineController controller,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 200));
  controller.dispose();
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
    testWidgets('exact timestamp animates the candle to chart center', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => _disposeChart(tester, controller));
      final target = _latest.subtract(_day * 40);
      final index = controller.klineData.tsToIndex(
        target.millisecondsSinceEpoch,
      )!;
      final begin = controller.paintDxOffset;

      expect(controller.moveToDateTime(target), isTrue);
      expect(controller.paintDxOffset, begin);

      await _pumpUntil(
        tester,
        () => controller.paintDxOffset != begin,
        'exact date animation start',
      );
      expect(controller.paintDxOffset, isNot(begin));

      final expectedOffset = _targetOffset(controller, index);
      await _pumpUntil(
        tester,
        () => (controller.paintDxOffset - expectedOffset).abs() < 0.01,
        'exact date animation',
      );
      _expectCandleCentered(controller, index);
    });

    testWidgets('animation moves in both directions and initial reset reuses it', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => _disposeChart(tester, controller));
      final historicalTarget = _latest.subtract(_day * 50);
      final initialOffset = controller.paintDxOffset;
      final historicalIndex = controller.klineData.tsToIndex(
        historicalTarget.millisecondsSinceEpoch,
      )!;

      expect(controller.moveToDateTime(historicalTarget), isTrue);
      await _pumpUntil(
        tester,
        () => controller.paintDxOffset != initialOffset,
        'historical date animation start',
      );
      expect(controller.paintDxOffset, greaterThan(initialOffset));
      final expectedHistoricalOffset = _targetOffset(
        controller,
        historicalIndex,
      );
      await _pumpUntil(
        tester,
        () => (controller.paintDxOffset - expectedHistoricalOffset).abs() < 0.01,
        'historical date animation',
      );

      final historicalOffset = controller.paintDxOffset;
      final expectedInitialOffset = controller.clampPaintDxOffset(
        controller.getInitPaintDxOffset(),
      );
      controller.requestMoveToInitialPosition();
      expect(controller.paintDxOffset, historicalOffset);

      await _pumpUntil(
        tester,
        () => controller.paintDxOffset != historicalOffset,
        'initial position animation start',
      );
      expect(controller.paintDxOffset, lessThan(historicalOffset));
      await _pumpUntil(
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
      addTearDown(() => _disposeChart(tester, controller));
      final historicalTarget = _latest.subtract(_day * 50);
      final initialOffset = controller.clampPaintDxOffset(
        controller.getInitPaintDxOffset(),
      );
      controller.requestMoveToInitialPosition();
      await _pumpUntil(
        tester,
        () => (controller.paintDxOffset - initialOffset).abs() < 0.01,
        'initial position setup',
      );

      expect(controller.moveToDateTime(historicalTarget), isTrue);
      controller.requestMoveToInitialPosition();

      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        controller.paintDxOffset,
        closeTo(initialOffset, 0.01),
      );
    });

    testWidgets('retained move callback is inert after widget disposal', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(controller.dispose);
      final callback = controller.moveToPositionCallback!;
      final before = controller.paintDxOffset;

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(
        () => callback(before, before + 100),
        returnsNormally,
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.paintDxOffset, before);
    });

    testWidgets('gap selects the nearest real candle at or before target', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => _disposeChart(tester, controller));
      final missingDay = _latest.subtract(_day * 20);
      final target = missingDay.add(const Duration(hours: 12));
      final expected = _latest.subtract(_day * 21);
      final expectedIndex = controller.klineData.tsToIndex(
        expected.millisecondsSinceEpoch,
      )!;

      expect(controller.moveToDateTime(target), isTrue);
      final expectedOffset = _targetOffset(controller, expectedIndex);
      await _pumpUntil(
        tester,
        () => (controller.paintDxOffset - expectedOffset).abs() < 0.01,
        'gap date animation',
      );

      _expectCandleCentered(controller, expectedIndex);
    });

    testWidgets('latest and oldest candles use existing paint boundaries', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final latestIndex = controller.klineData.tsToIndex(
        _latest.millisecondsSinceEpoch,
      )!;
      final expectedLatestOffset = _targetOffset(
        controller,
        latestIndex,
      );
      expect(controller.moveToDateTime(_latest), isTrue);
      await _pumpUntil(
        tester,
        () => (controller.paintDxOffset - expectedLatestOffset).abs() < 0.01,
        'latest candle animation',
      );
      expect(
        controller.paintDxOffset,
        closeTo(expectedLatestOffset, 0.01),
      );

      final oldest = _latest.subtract(_day * 80);
      final oldestIndex = controller.klineData.tsToIndex(
        oldest.millisecondsSinceEpoch,
      )!;
      final expectedOldestOffset = _targetOffset(
        controller,
        oldestIndex,
      );
      expect(controller.moveToDateTime(oldest), isTrue);
      await _pumpUntil(
        tester,
        () => (controller.paintDxOffset - expectedOldestOffset).abs() < 0.01,
        'oldest candle animation',
      );
      expect(
        controller.paintDxOffset,
        closeTo(expectedOldestOffset, 0.01),
      );
    });

    testWidgets('out-of-range dates fail without moving viewport', (tester) async {
      final controller = await _pumpChart(tester);
      addTearDown(() => _disposeChart(tester, controller));
      final before = controller.paintDxOffset;

      expect(
        controller.moveToDateTime(_latest.add(_day)),
        isFalse,
      );
      expect(
        controller.moveToDateTime(_latest.subtract(_day * 81)),
        isFalse,
      );
      expect(controller.paintDxOffset, before);
    });

    testWidgets('mounted empty chart rejects date movement', (tester) async {
      final controller = await _pumpChart(tester, withData: false);
      addTearDown(() => _disposeChart(tester, controller));

      expect(controller.moveToDateTime(_latest), isFalse);
      expect(controller.paintDxOffset, 0);
    });
  });
}
