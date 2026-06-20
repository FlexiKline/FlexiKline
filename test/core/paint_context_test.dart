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

    test('requestMoveToInitialPosition delegates through controller callback', () {
      final controller = FlexiKlineController(
        configuration: FakeFlexiKlineConfiguration(),
      );

      var moved = false;
      controller.moveToInitialPositionCallback = () {
        moved = true;
      };

      (controller as PaintContext).requestMoveToInitialPosition();

      expect(moved, isTrue);
      controller.moveToInitialPositionCallback = null;
    });

    test('reportChartZoomSlideBarRect respects manual zoom rect config', () {
      final controller = FlexiKlineController(
        configuration: FakeFlexiKlineConfiguration(),
      );

      controller.gestureConfig = controller.gestureConfig.copyWith(
        isManualSetZoomRect: true,
      );

      (controller as PaintContext).reportChartZoomSlideBarRect(
        const Rect.fromLTWH(1, 2, 3, 4),
      );

      expect(controller.chartZoomSlideBarRect, Rect.zero);
    });
  });
}
