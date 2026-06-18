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

/// 双布局模式（adapt / fixed）单元测试。
library;

import 'dart:ui';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_indicators.dart';
import '../helpers/test_kline_config.dart';

FlexiKlineController _createController({
  FlexiLayoutMode initial = FlexiLayoutMode.adapt,
  Size? mainDefault,
  Size? initialFixedSize,
}) {
  return FlexiKlineController(
    configuration: TestFlexiKlineConfiguration(
      mainIndicatorDefaultSize: mainDefault ?? const Size(400, 300),
    ),
    initialLayoutMode: initial,
    initialFixedSize: initialFixedSize,
  );
}

void _mount(
  FlexiKlineController c, {
  List<Indicator> subIndicators = const [],
}) {
  c.mountIndicators(
    candle: TestCandleIndicator(),
    time: TestTimeIndicator(),
    mainIndicators: const [],
    subIndicators: subIndicators,
  );
  c.initState();
}

void main() {
  group('Layout mode defaults', () {
    test('initial adapt + fixedSize null', () {
      final c = _createController();
      addTearDown(c.dispose);
      expect(c.layoutMode, FlexiLayoutMode.adapt);
      expect(c.fixedSize, isNull);
      expect(c.canUpdateLayoutHeight, isTrue);
    });

    test('initial fixed implies fixedSize null until set', () {
      final c = _createController(initial: FlexiLayoutMode.fixed);
      addTearDown(c.dispose);
      expect(c.layoutMode, FlexiLayoutMode.fixed);
      expect(c.fixedSize, isNull);
      expect(c.canUpdateLayoutHeight, isFalse);
    });

    test('initial fixed can use initialFixedSize before layout constraints arrive', () {
      final c = _createController(
        initial: FlexiLayoutMode.fixed,
        initialFixedSize: const Size(480, 360),
      );
      _mount(c);
      addTearDown(c.dispose);
      expect(c.layoutMode, FlexiLayoutMode.fixed);
      expect(c.fixedSize, equals(const Size(480, 360)));
      expect(c.canvasRect.size, equals(const Size(480, 360)));
    });
  });

  group('setAdaptLayoutMode', () {
    test('width below mainMinSize returns false', () {
      final c = _createController();
      _mount(c);
      addTearDown(c.dispose);
      expect(c.setAdaptLayoutMode(width: 10), isFalse);
    });

    test('same adapt mode updates width via setMainSize path', () {
      final c = _createController();
      _mount(c);
      addTearDown(c.dispose);
      expect(c.setAdaptLayoutMode(width: 500), isTrue);
      expect(c.mainSize.width, closeTo(500, 0.01));
      expect(c.layoutMode, FlexiLayoutMode.adapt);
    });
  });

  group('Adapt ↔ Fixed', () {
    test('enter fixed then canvas matches fixedSize', () {
      final c = _createController();
      _mount(c);
      addTearDown(c.dispose);
      expect(c.setAdaptLayoutMode(width: 440), isTrue);
      expect(c.setMainSize(const Size(440, 280)), isTrue);

      expect(c.setFixedLayoutMode(const Size(800, 600)), isTrue);
      expect(c.layoutMode, FlexiLayoutMode.fixed);
      expect(c.fixedSize, equals(const Size(800, 600)));
      expect(c.canvasRect.size, equals(const Size(800, 600)));
      expect(c.mainRect.width, 800);
      expect(c.mainRect.height + c.subRect.height, closeTo(600, 0.01));
    });

    test('leave fixed restores adapt and width from config', () {
      final c = _createController();
      _mount(c);
      addTearDown(c.dispose);
      c.setAdaptLayoutMode(width: 420);
      c.setMainSize(const Size(420, 260));
      c.setFixedLayoutMode(const Size(900, 700));
      expect(c.setAdaptLayoutMode(), isTrue);
      expect(c.layoutMode, FlexiLayoutMode.adapt);
      expect(c.fixedSize, isNull);
      expect(c.mainSize.width, closeTo(420, 0.01));
    });

    test('setFixedLayoutMode rejects non-finite size', () {
      final c = _createController();
      _mount(c);
      addTearDown(c.dispose);
      expect(c.setFixedLayoutMode(const Size(double.infinity, 400)), isFalse);
    });
  });

  group('fixed canvas invariants (deterministic sweep)', () {
    test('main + sub height equals canvas for many sizes', () {
      for (var seed = 0; seed < 80; seed++) {
        final c = _createController();
        _mount(c);
        final w = 220.0 + (seed % 50) * 8;
        final h = 450.0 + (seed ~/ 50) * 7;
        if (!c.setFixedLayoutMode(Size(w, h))) {
          c.dispose();
          continue;
        }
        expect(c.canvasRect.height, closeTo(h, 0.02));
        expect(c.mainRect.height + c.subRect.height, closeTo(h, 0.02));
        expect(c.canvasRect.width, closeTo(w, 0.02));
        c.dispose();
      }
    });

    test('adding and removing sub indicators keeps fixed regions non-overlapping', () {
      const macdKey = ComputedIndicatorKey('macd');
      const kdjKey = ComputedIndicatorKey('kdj');
      final c = _createController();
      _mount(
        c,
        subIndicators: [
          TestComputedIndicator(key: macdKey, height: 120),
          TestComputedIndicator(key: kdjKey, height: 80),
        ],
      );
      addTearDown(c.dispose);

      expect(c.setFixedLayoutMode(const Size(600, 500)), isTrue);
      final initialMainHeight = c.mainRect.height;

      expect(c.showSubIndicator(macdKey), isTrue);
      expect(c.canvasRect.size, equals(const Size(600, 500)));
      expect(c.mainRect.bottom, closeTo(c.subRect.top, 0.01));
      expect(c.mainRect.height, lessThan(initialMainHeight));

      expect(c.hideSubIndicator(macdKey), isTrue);
      expect(c.canvasRect.size, equals(const Size(600, 500)));
      expect(c.mainRect.bottom, closeTo(c.subRect.top, 0.01));
      expect(c.mainRect.height, closeTo(initialMainHeight, 0.01));
    });

    test('fixed compression keeps every sub indicator at least subMinHeight', () {
      const bigKey = ComputedIndicatorKey('big');
      const smallKey = ComputedIndicatorKey('small');
      final c = _createController();
      _mount(
        c,
        subIndicators: [
          TestComputedIndicator(key: bigKey, height: 1000),
          TestComputedIndicator(key: smallKey, height: 10),
        ],
      );
      addTearDown(c.dispose);

      expect(c.setFixedLayoutMode(const Size(600, 160)), isTrue);
      expect(c.showSubIndicator(bigKey), isTrue);
      expect(c.showSubIndicator(smallKey), isTrue);

      expect(c.mainRect.height, closeTo(c.mainMinSize.height, 0.01));
      expect(c.getSubIndicatorHeights().toList(), everyElement(greaterThanOrEqualTo(c.settingConfig.subMinHeight)));
      expect(c.mainRect.height + c.subRect.height, closeTo(160, 0.01));
    });

    test('showSubIndicator returns false and rolls back when fixed height is insufficient', () {
      const macdKey = ComputedIndicatorKey('macd');
      final c = _createController();
      _mount(
        c,
        subIndicators: [
          TestComputedIndicator(key: macdKey, height: 120),
        ],
      );
      addTearDown(c.dispose);

      expect(c.setFixedLayoutMode(const Size(600, 110)), isTrue);
      expect(c.showSubIndicator(macdKey), isFalse);
      expect(c.hasAddedSubIndicator(macdKey), isFalse);
      expect(c.canvasRect.size, equals(const Size(600, 110)));
    });
  });
}
