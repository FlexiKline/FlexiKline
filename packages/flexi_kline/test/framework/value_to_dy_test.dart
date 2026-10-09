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

/// `valueToDy(correct: true)` 改为像素空间 clamp 后与旧实现逐点等价; `isSame` 区间是唯一需要特判的分支。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

final _key = directKey(0);

MinMax _mm(num max, num min) => MinMax(max: FlexiNum.fromNum(max), min: FlexiNum.fromNum(min));

/// 旧实现原文：先夹值，再换算。
double _legacyValueToDy(PaintObject object, FlexiNum value) {
  final minMax = object.minMax;
  value = value.clamp(minMax.min, minMax.max);
  return object.chartRect.bottom - (value - minMax.min).toDouble() * object.dyFactor;
}

void _expectMatchesLegacy(PaintObject object, Iterable<num> values) {
  for (final v in values) {
    final value = FlexiNum.fromNum(v);
    expect(object.valueToDy(value), closeTo(_legacyValueToDy(object, value), 1e-9), reason: 'value=$v');
  }
}

MainPaintObject _mountMain() {
  const mainRect = Rect.fromLTWH(0, 0, 300, 200);
  final context = FakePaintContext()..mainRect = mainRect;
  final manager = IndicatorPaintObjectManager(
    configuration: FakeFlexiKlineConfiguration(
      mainChildren: {_key},
      mainIndicatorDefaultSize: mainRect.size,
      mainIndicatorDefaultPadding: const EdgeInsets.symmetric(vertical: 12),
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

/// 区间内、端点、区间外两侧，以及一些非整数值。
const _values = <num>[-1e6, -50, 0, 99.999, 100, 100.25, 123.456789, 150, 199.5, 200, 200.0001, 250, 1e9];

void main() {
  test('前提：chartRect 有正高度', () {
    final main = _mountMain();
    expect(main.chartRect.height, greaterThan(0));
  });

  test('普通区间：区间内外各取值时与旧实现逐点相等', () {
    final main = _mountMain()..setMinMax(_mm(200, 100));
    expect(main.minMax.isSame, isFalse);

    _expectMatchesLegacy(main, _values);
  });

  test('缩放区间（不经 setMinMax 扩展）同样逐点相等', () {
    final main = _mountMain()..setZoomMinMax(_mm(180.5, 120.25));

    _expectMatchesLegacy(main, _values);
  });

  test('区间端点映射到 chartRect 上下边', () {
    final main = _mountMain()..setMinMax(_mm(200, 100));

    expect(main.valueToDy(FlexiNum.fromNum(200)), closeTo(main.chartRect.top, 1e-9));
    expect(main.valueToDy(FlexiNum.fromNum(100)), closeTo(main.chartRect.bottom, 1e-9));
  });

  test('isSame 区间：结果恒为 bottom，与旧实现一致', () {
    // setZoomMinMax 不做 expandByRatios, 能构造出 max == min 的区间。
    final main = _mountMain()..setZoomMinMax(_mm(100, 100));
    expect(main.minMax.isSame, isTrue);

    final values = [..._values, 100.5, 100.999];
    for (final v in values) {
      expect(main.valueToDy(FlexiNum.fromNum(v)), main.chartRect.bottom, reason: 'value=$v');
    }
    _expectMatchesLegacy(main, values);
  });

  test('correct: false 不夹取', () {
    final main = _mountMain()..setMinMax(_mm(200, 100));

    expect(main.valueToDy(FlexiNum.fromNum(250), correct: false), lessThan(main.chartRect.top));
    expect(main.valueToDy(FlexiNum.fromNum(50), correct: false), greaterThan(main.chartRect.bottom));
  });
}
