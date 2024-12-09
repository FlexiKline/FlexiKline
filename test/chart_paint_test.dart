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

import 'package:flexi_kline/src/constant.dart';
import 'package:flexi_kline/src/framework/export.dart';
import 'package:flexi_kline/src/kline_controller.dart';
import 'package:flexi_kline/src/model/export.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base/test_flexi_kline_configuration.dart';
import 'base/mock.dart';

void main() {
  final stopwatch = Stopwatch();
  final configuration = TestFlexiKlineConfiguration();
  final controller = FlexiKlineController(configuration: configuration);
  late SinglePaintObjectIndicator maIndicator;
  final canvas = Canvas(PictureRecorder());
  const mainSize = Size(400, 300);
  int start = 50;
  int end = 100;

  setUpAll(() {
    debugPrint('setUpAll');
    final list = getCandleModelList();
    controller.updateKlineData(
      CandleReq(
        instId: 'BTC-USDT',
        bar: TimeBar.m15.bar,
        precision: 4,
      ),
      list,
    );

    controller.setMainSize(mainSize);

    // controller.addIndicatorInMain(IndicatorType.ma);
    // controller.addIndicatorInMain(IndicatorType.ema);
    // controller.addIndicatorInMain(IndicatorType.boll);
    // controller.addIndicatorInMain(IndicatorType.volume);

    controller.curKlineData.ensureStartAndEndIndex(start, end);

    // controller.mainIndicator.ensurePaintObject(controller);

    // maIndicator = controller.mainPaintObject.children.firstWhere(
    //   (child) => child.key == IndicatorType.ma,
    // );
  });

  setUp(() {
    debugPrint('setUp');
    stopwatch.reset();
    stopwatch.start();
  });

  tearDown(() {
    stopwatch.stop();
    debugPrint('tearDown spent:${stopwatch.elapsedMicroseconds}');
  });

  group('paint-Ma', () {
    // test('test-MA-preprocess', () {
    //   debugPrint('test-MA-preprocess');
    //   controller.curKlineData.precompute(
    //     maIndicator.key,
    //     calcParam: maIndicator.getCalcParams(),
    //     range: Range(start, end),
    //   );
    // });
    // test('test-MA-Paint', () async {
    //   debugPrint('test-MA-Paint');
    //   maIndicator.paintObject?.doInitState(
    //     mainIndicatorSlot,
    //     start: 0,
    //     end: 100,
    //   );
    //   maIndicator.paintObject?.doPaintChart(canvas, mainSize);
    // });
  });
}
