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

/// `dyFactor` 在 chartRect 高度为零或负时的守卫。
///
/// chartRect.height 可为负：主区很矮 + padding.vertical + _tipsAreaHeight 超过总高度时
/// topRect.bottom > bottomRect.top。负高度不应产生负 dyFactor（导致 Y 轴镜像），也不应
/// 让 dyToValue 除零。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

/// 用一个很小的 mainRect + 很大的 padding 构造负 chartRect.height 场景。
const _tinyMainRect = Rect.fromLTWH(0, 0, 300, 40);
final _combineKey = directKey(0);

MinMax _mm(num max, num min) => MinMax(
      max: FlexiNum.fromNum(max),
      min: FlexiNum.fromNum(min),
    );

class _Scene {
  _Scene({required Rect mainRect, required EdgeInsets padding}) : context = (FakePaintContext()..mainRect = mainRect) {
    declarations = [TestRangeIndicator(key: _combineKey)];
    config = FakeFlexiKlineConfiguration(
      mainChildren: {_combineKey},
      mainIndicatorDefaultSize: mainRect.size,
      mainIndicatorDefaultPadding: padding,
    );
    manager = IndicatorPaintObjectManager(configuration: config);
    manager.mountIndicators(
      context: context,
      candle: TestCandleIndicator(),
      time: TestTimeIndicator(),
      mainIndicators: declarations,
      subIndicators: const [],
    );
  }

  final FakePaintContext context;
  late final List<Indicator> declarations;
  late final FakeFlexiKlineConfiguration config;
  late final IndicatorPaintObjectManager manager;

  MainPaintObject get main => manager.mainPaintObject;

  void updateRange(int start, int end) {
    main.doUpdateVisibleMinMax(
      mainPaneIndex,
      start: start,
      end: end,
    );
  }
}

void main() {
  group('dyFactor 负高度守卫', () {
    test('chartRect.height 为负时 dyFactor 返回 0 而非负值', () {
      // padding 上下各 25 → vertical = 50 > 40 (mainRect.height) → chartRect.height < 0
      final scene = _Scene(
        mainRect: _tinyMainRect,
        padding: const EdgeInsets.symmetric(vertical: 25),
      );
      scene.updateRange(0, 5);

      expect(scene.main.chartRect.height, lessThan(0), reason: '测试前提：chartRect.height 必须为负');
      expect(scene.main.dyFactor, equals(0), reason: '负高度时 dyFactor 应为 0，不应为负');
    });

    test('chartRect.height 为零时 dyFactor 返回 0', () {
      // padding vertical = 40 = mainRect.height → chartRect.height == 0
      final scene = _Scene(
        mainRect: _tinyMainRect,
        padding: const EdgeInsets.symmetric(vertical: 20),
      );
      scene.updateRange(0, 5);

      expect(scene.main.chartRect.height, equals(0), reason: '测试前提：chartRect.height 必须为 0');
      expect(scene.main.dyFactor, equals(0));
    });

    test('负高度时 valueToDy 返回 chartRect.bottom（所有点挤在一条线）', () {
      final scene = _Scene(
        mainRect: _tinyMainRect,
        padding: const EdgeInsets.symmetric(vertical: 25),
      );
      scene.updateRange(0, 5);
      scene.main.setMinMax(_mm(100, 0));

      final dy1 = scene.main.valueToDy(FlexiNum.fromNum(50));
      final dy2 = scene.main.valueToDy(FlexiNum.fromNum(0));
      final dy3 = scene.main.valueToDy(FlexiNum.fromNum(100));

      // dyFactor == 0 → valueToDy 返回 chartRect.bottom - 0 = chartRect.bottom
      expect(dy1, equals(scene.main.chartRect.bottom));
      expect(dy2, equals(scene.main.chartRect.bottom));
      expect(dy3, equals(scene.main.chartRect.bottom));
    });

    test('负高度时 dyToValue 返回 null 而非除零', () {
      final scene = _Scene(
        mainRect: _tinyMainRect,
        padding: const EdgeInsets.symmetric(vertical: 25),
      );
      scene.updateRange(0, 5);
      scene.main.setMinMax(_mm(100, 0));

      // dyFactor == 0 → 除零会产生 Infinity → 应返回 null
      final value = scene.main.dyToValue(20.0, check: false);
      expect(value, isNull, reason: 'dyFactor <= 0 时 dyToValue 应返回 null');
    });
  });
}
