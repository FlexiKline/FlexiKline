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

/// Cross 焦点横轴吸附单测。
///
/// 覆盖层级：controller 的 `onCrossFollow` → 焦点校正。
/// 不覆盖：hover 手势识别与 Widget 坐标转换。
@TestOn('vm')
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'CROSS-SNAP', interval: FlexiTimeInterval(1, TimeUnit.minute));

void main() {
  group('cross blank snap', () {
    late FlexiKlineController chart;

    /// 蜡烛远少于可视根数, 最旧根左侧与最新根右侧都留有空白区。
    Future<void> arrange(WidgetTester tester) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      await scene.initWithData(_spec, genFlatCandleList(count: 5), canvasWidth: 400);
      chart = scene.controller;
      chart.flushPendingKlineData();
      await paintChartFrame(tester, chart);
    }

    Offset focus(double dx) => Offset(dx, chart.mainRect.center.dy);

    testWidgets('蜡烛区内吸附到所在蜡烛中心', (tester) async {
      await arrange(tester);

      chart.onCrossFollow(focus(chart.indexToDx(2) + 1));

      expect(chart.crossOffset!.dx, closeTo(chart.indexToDx(2), 1e-9));
    });

    testWidgets('最旧根左侧空白区不吸附', (tester) async {
      await arrange(tester);
      // 平移到最旧端, 最旧根左侧留出 minPaintBlankWidth 的空白。
      chart.onChartMove(const Offset(100000, 0));
      chart.onChartPanEnd();
      await paintChartFrame(tester, chart);
      final dx = chart.indexToDx(-1) + 1;
      expect(dx, greaterThan(chart.mainRect.left), reason: '前置：最旧根左侧须有空白区');

      chart.onCrossFollow(focus(dx));

      expect(chart.crossOffset!.dx, dx);
    });

    testWidgets('最新根右侧空白区不吸附', (tester) async {
      await arrange(tester);
      final dx = chart.indexToDx(chart.klineData.length + 1) + 1;
      expect(dx, lessThan(chart.mainRect.right), reason: '前置：最新根右侧须有空白区');

      chart.onCrossFollow(focus(dx));

      expect(chart.crossOffset!.dx, dx);
    });
  });
}
