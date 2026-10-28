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

/// `doUpdateVisibleMinMax` 的两个失效信号: `range` 只重算可见区间, `geometry` 让绘制矩形失效并重算区间。
///
/// 覆盖层级: 主区 PaintObject 的区间更新入口。
library;

import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

final _key = directKey(0);

void main() {
  late FakePaintContext context;
  late MainPaintObject main;
  late TestRangePaintObject child;

  setUp(() {
    context = FakePaintContext()..mainRect = const Rect.fromLTWH(0, 0, 300, 200);
    final indicator = TestRangeIndicator(key: _key);
    final manager = IndicatorPaintObjectManager(
      configuration: FakeFlexiKlineConfiguration(mainChildren: {_key}, mainIndicatorDefaultSize: const Size(300, 200)),
    );
    addTearDown(manager.dispose);
    manager.mountIndicators(
      context: context,
      candle: TestCandleIndicator(),
      time: TestTimeIndicator(),
      mainIndicators: [indicator],
      subIndicators: const [],
    );
    main = manager.mainPaintObject;
    child = indicator.object!;
    main.doUpdateVisibleMinMax(mainPaneIndex, start: 0, end: 5);
  });

  test('不带信号且 start/end 未变时早退, 不重算区间', () {
    final count = child.computeCount;
    main.doUpdateVisibleMinMax(mainPaneIndex, start: 0, end: 5);
    expect(child.computeCount, count);
  });

  test('range: start/end 未变也重算区间, 但不让绘制矩形失效', () {
    final count = child.computeCount;
    final rect = child.drawableRect;
    context.mainRect = const Rect.fromLTWH(0, 0, 300, 400);

    main.doUpdateVisibleMinMax(mainPaneIndex, start: 0, end: 5, range: true);

    expect(child.computeCount, count + 1);
    expect(child.drawableRect, rect, reason: '几何缓存未失效, 仍是旧矩形');
  });

  test('geometry: 绘制矩形按新布局重算, 并重算区间', () {
    final count = child.computeCount;
    final rect = child.drawableRect;
    context.mainRect = const Rect.fromLTWH(0, 0, 300, 400);

    main.doUpdateVisibleMinMax(mainPaneIndex, start: 0, end: 5, geometry: true);

    expect(child.computeCount, count + 1);
    expect(child.drawableRect, isNot(rect));
    expect(child.drawableRect.height, greaterThan(rect.height));
  });
}
