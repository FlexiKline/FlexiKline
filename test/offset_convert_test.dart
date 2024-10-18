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

import 'dart:ui';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/framework/draw/overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base/mock.dart';
import 'base/test_flexi_kline_configuration.dart';

void main() {
  final configuration = TestFlexiKlineConfiguration();
  late FlexiKlineController controller;
  late CandleReq req;
  const mainSize = Size(400, 300);
  late MultiPaintObjectIndicator mainIndicator;

  setUpAll(() async {
    debugPrint('setUpAll');
    final list = getETHUSDT1DLimit50List();
    req = CandleReq(
      instId: 'ETH-USDT',
      bar: TimeBar.D1.bar,
      precision: 4,
    );
    controller = FlexiKlineController(configuration: configuration);
    controller.setMainSize(mainSize);
    controller.switchKlineData(req);
    await controller.updateKlineData(req, list);
    controller.calculateCandleDrawIndex();
    controller.ensurePaintObjectInstance();
    controller.mainIndicator.paintObject?.doInitState(
      mainIndicatorSlot,
      start: controller.curKlineData.start,
      end: controller.curKlineData.end,
      reset: true,
    );
  });

  group('group1 ', () {
    test('test in the range', () {
      Point point = Point(
        ts: 1727625600000, // 2024-09-30 00:00:00
        value: BagNum.fromNum(2500),
      );
      final isOk = controller.updateDrawPointByValue(point);
      debugPrint('isOk:$isOk, offset:$point');
      if (point.offset.isFinite) {
        final model = controller.dxToCandle(point.offset.dx);
        assert(model?.ts == point.ts);
      }
    });

    test('test out of start', () {
      Point point = Point(
        ts: 1727712000000, // 2024-10-01 00:00:00
        value: BagNum.fromNum(1500),
      );
      final isOk = controller.updateDrawPointByValue(point);
      debugPrint('isOk:$isOk, offset:$point');
      if (point.offset.isFinite) {
        final value = controller.dyToValue(point.offset.dy);
        assert(value == point.value);
      }
    });

    test('test out of end', () {
      Point point = Point(
        ts: 1723305600000, // 2024-08-11 00:00:00
        value: BagNum.fromNum(3000),
      );
      final isOk = controller.updateDrawPointByValue(point);
      debugPrint('isOk:$isOk, offset:$point');
      if (point.offset.isFinite) {
        final value = controller.dyToValue(point.offset.dy);
        assert(value == point.value);
      }
    });
  });
}
