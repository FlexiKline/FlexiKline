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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  group('PaintContext controller implementation', () {
    test('controller implements PaintContext', () {
      final controller = FlexiKlineController(
        configuration: FakeFlexiKlineConfiguration(),
      );

      expect(controller, isA<PaintContext>());
      expect((controller as PaintContext).klineData, same(controller.klineData));
    });

    test('requestMoveToInitialPosition delegates begin and end through controller callback', () {
      final controller = FlexiKlineController(
        configuration: FakeFlexiKlineConfiguration(
          mainIndicatorDefaultSize: const Size(400, 300),
        ),
      );
      addTearDown(controller.dispose);
      controller.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: const [],
      );
      controller.initState();

      double? actualBegin;
      double? actualEnd;
      controller.moveToPositionCallback = (begin, end) async {
        actualBegin = begin;
        actualEnd = end;
        return true;
      };
      final expectedBegin = controller.paintDxOffset;
      final expectedEnd = controller.clampPaintDxOffset(
        controller.getInitPaintDxOffset(),
      );

      (controller as PaintContext).requestMoveToInitialPosition();

      expect(actualBegin, expectedBegin);
      expect(actualEnd, expectedEnd);
      controller.moveToPositionCallback = null;
    });

    test('reportChartZoomSlideBarRect respects useCustomZoomRect', () {
      final controller = FlexiKlineController(
        configuration: FakeFlexiKlineConfiguration(),
      );

      controller.gestureConfig = controller.gestureConfig.copyWith(
        useCustomZoomRect: true,
      );

      (controller as PaintContext).reportChartZoomSlideBarRect(
        const Rect.fromLTWH(1, 2, 3, 4),
      );

      expect(controller.chartZoomSlideBarRect, Rect.zero);
    });
  });
}
