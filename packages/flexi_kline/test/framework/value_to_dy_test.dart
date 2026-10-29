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

/// PaintObject 的值与 dy 换算：区间 `[min, max]` 线性映射到 `[chartRect.bottom, chartRect.top]`。
///
/// chartRect 高度可以为零或负（主区很矮而 padding 很大），此时 `dyFactor` 为 0，
/// 所有值落在底边，`dyToValue` 返回 null 而不是除零。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

final _key = directKey(0);

MinMax _mm(num max, num min) => MinMax(max: FlexiNum.fromNum(max), min: FlexiNum.fromNum(min));

FlexiNum _v(num value) => FlexiNum.fromNum(value);

MainPaintObject _mountMain({Rect mainRect = const Rect.fromLTWH(0, 0, 300, 200), double padding = 12}) {
  final context = FakePaintContext()..mainRect = mainRect;
  final manager = IndicatorPaintObjectManager(
    configuration: FakeFlexiKlineConfiguration(
      mainChildren: {_key},
      mainIndicatorDefaultSize: mainRect.size,
      mainIndicatorDefaultPadding: EdgeInsets.symmetric(vertical: padding),
    ),
  );
  manager.mountIndicators(
    context: context,
    candle: TestCandleIndicator(),
    time: TestTimeIndicator(),
    mainIndicators: [TestRangeIndicator(key: _key)],
    subIndicators: const [],
  );
  final main = manager.mainPaintObject;
  main.doUpdateVisibleMinMax(mainPaneIndex, start: 0, end: 5);
  return main;
}

void main() {
  group('valueToDy / dyToValue', () {
    test('端点映射到上下边, 中点映射到中线', () {
      final main = _mountMain()..setMinMax(_mm(200, 100));
      final rect = main.chartRect;
      expect(rect.height, greaterThan(0));

      expect(main.valueToDy(_v(200)), closeTo(rect.top, 1e-9));
      expect(main.valueToDy(_v(100)), closeTo(rect.bottom, 1e-9));
      expect(main.valueToDy(_v(150)), closeTo(rect.center.dy, 1e-9));
    });

    test('dyToValue 是 valueToDy 的逆', () {
      final main = _mountMain()..setZoomMinMax(_mm(180.5, 120.25));

      for (final v in [120.25, 123.456789, 150, 180.5]) {
        expect(main.dyToValue(main.valueToDy(_v(v)))!.toDouble(), closeTo(v, 1e-9), reason: 'value=$v');
      }
    });

    test('默认不夹取; correct: true 夹到 chartRect 内', () {
      final main = _mountMain()..setMinMax(_mm(200, 100));
      final rect = main.chartRect;

      expect(main.valueToDy(_v(250)), lessThan(rect.top));
      expect(main.valueToDy(_v(50)), greaterThan(rect.bottom));
      expect(main.valueToDy(_v(250), correct: true), closeTo(rect.top, 1e-9));
      expect(main.valueToDy(_v(50), correct: true), closeTo(rect.bottom, 1e-9));
      expect(main.valueToDy(_v(150), correct: true), closeTo(rect.center.dy, 1e-9), reason: '区间内不受夹取影响');
    });

    test('max == min 时所有值都落在底边', () {
      // setZoomMinMax 不做 expandByRatios, 能构造出 max == min 的区间。
      final main = _mountMain()..setZoomMinMax(_mm(100, 100));
      expect(main.minMax.isSame, isTrue);

      for (final v in [50, 100, 100.5, 1e9]) {
        expect(main.valueToDy(_v(v), correct: true), main.chartRect.bottom, reason: 'value=$v');
      }
    });
  });

  group('chartRect 高度非正', () {
    const tiny = Rect.fromLTWH(0, 0, 300, 40);

    test('高度为零或负时 dyFactor 为 0, 不产生镜像', () {
      final zero = _mountMain(mainRect: tiny, padding: 20);
      final negative = _mountMain(mainRect: tiny, padding: 25);
      expect(zero.chartRect.height, 0);
      expect(negative.chartRect.height, lessThan(0));

      expect(zero.dyFactor, 0);
      expect(negative.dyFactor, 0);
    });

    test('valueToDy 恒为底边, dyToValue 返回 null', () {
      final main = _mountMain(mainRect: tiny, padding: 25)..setMinMax(_mm(100, 0));

      for (final v in [0, 50, 100]) {
        expect(main.valueToDy(_v(v)), main.chartRect.bottom, reason: 'value=$v');
      }
      expect(main.dyToValue(20), isNull);
    });
  });
}
