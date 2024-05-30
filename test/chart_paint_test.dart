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

import 'dart:math' as math;
import 'dart:ui';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock.dart';

class TestFlexiKlineTheme implements IFlexiKlineTheme {
  @override
  String key = 'flexi_kline_config_key_test';

  double? _scale;
  @override
  double get scale {
    if (_scale != null) return _scale!;
    final mediaQuery = MediaQueryData.fromWindow(window);
    _scale = math.min(mediaQuery.size.width, mediaQuery.size.height) / 393;
    return _scale!;
  }

  double? _pixel;
  @override
  double get pixel {
    if (_pixel != null) return _pixel!;
    final mediaQuery = MediaQueryData.fromWindow(window);
    _pixel = 1.0 / mediaQuery.devicePixelRatio;
    return _pixel!;
  }

  @override
  double setDp(num size) => size * scale;

  @override
  double setSp(num fontSize) => fontSize * scale;

  @override
  Color long = const Color(0xFF33BD65);

  @override
  Color short = const Color(0xFFE84E74);

  @override
  Color chartBg = const Color(0xFFFFFFFF);

  @override
  Color tooltipBg = const Color(0xFFF2F2F2);

  @override
  Color countDownTextBg = const Color(0xFFBDBDBD);

  @override
  Color crossTextBg = const Color(0xFF111111);

  @override
  Color transparent = Colors.transparent;

  @override
  Color lastPriceTextBg = Colors.black54;

  @override
  Color gridLine = const Color(0xffE9EDF0);

  @override
  Color crosshair = const Color(0xFF000000);

  @override
  Color priceMarkLine = const Color(0xFF000000);

  @override
  Color textColor = const Color(0xFF000000);

  @override
  Color tickTextColor = const Color(0xFF949494);

  @override
  Color lastPriceTextColor = const Color(0xFF5F5F5F);

  @override
  Color crossTextColor = const Color(0xFFFFFFFF);

  @override
  Color tooltipTextColor = const Color(0xFF949494);
}

class TestFlexiKlineConfiguration extends BaseFlexiKlineThemeConfiguration {
  @override
  Size get initialMainSize {
    final mediaQuery = MediaQueryData.fromWindow(window);
    return Size(mediaQuery.size.width, 300);
  }

  @override
  FlexiKlineConfig getFlexiKlineConfig([TestFlexiKlineTheme? theme]) {
    return genFlexiKlineConfig(TestFlexiKlineTheme());
  }

  @override
  void saveFlexiKlineConfig(FlexiKlineConfig config) {
    // TODO: implement saveFlexiKlineConfig
  }
}

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
    controller.setKlineData(
      CandleReq(
        instId: 'BTC-USDT',
        bar: TimeBar.m15.bar,
        precision: 4,
      ),
      list,
    );

    controller.setMainSize(mainSize);

    controller.addIndicatorInMain(maKey);
    controller.addIndicatorInMain(emaKey);
    controller.addIndicatorInMain(bollKey);
    controller.addIndicatorInMain(volumeKey);

    controller.curKlineData.ensureStartAndEndIndex(start, end);

    controller.mainIndicator.ensurePaintObject(controller);

    maIndicator = controller.mainIndicator.children.firstWhere(
      (child) => child.key == maKey,
    );
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
    test('test-MA-preprocess', () {
      debugPrint('test-MA-preprocess');
      controller.curKlineData.preprocess(maIndicator, start: start, end: end);
    });
    test('test-MA-Paint', () async {
      debugPrint('test-MA-Paint');
      maIndicator.paintObject?.doInitState(
        mainIndicatorSlot,
        start: 0,
        end: 100,
      );
      maIndicator.paintObject?.doPaintChart(canvas, mainSize);
    });
  });
}
