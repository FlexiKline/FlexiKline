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

/// 下标与 dx 的换算, 以及 cross tooltip 取到的前一根。
///
/// 覆盖层级：controller 的几何换算与 `onCrossFollow` → `paintCross`。
/// 不覆盖：手势识别与 Widget 坐标转换。
@TestOn('vm')
library;

import 'dart:ui' show Canvas, PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'GEOMETRY', interval: FlexiTimeInterval(1, TimeUnit.minute));

void main() {
  late FlexiKlineController chart;

  Future<void> arrange(WidgetTester tester) async {
    final scene = ControllerScenario();
    addTearDown(scene.dispose);
    await scene.initWithData(_spec, genFlatCandleList(count: 200), canvasWidth: 400);
    chart = scene.controller;
    chart.flushPendingKlineData();
    await paintChartFrame(tester, chart);
  }

  group('indexToDx / dxToIndex', () {
    testWidgets('整数下标即蜡烛中心, 蜡烛区间为 [中心 - w/2, 中心 + w/2)', (tester) async {
      await arrange(tester);
      final i = chart.klineData.length - 5;
      final center = chart.indexToDx(i), half = chart.candleWidthHalf;

      expect(chart.dxToIndex(center), i);
      expect(chart.dxToIndex(center - half), i, reason: '左边界属于本根');
      expect(chart.dxToIndex(center + half - 1e-6), i);
      expect(chart.dxToIndex(center + half), i + 1, reason: '右边界属于下一根');
    });

    testWidgets('最新根右侧空白区按蜡烛宽度外推出越界下标', (tester) async {
      await arrange(tester);
      final len = chart.klineData.length, w = chart.candleActualWidth;
      final latest = chart.indexToDx(len - 1);
      expect(latest + 2 * w, lessThan(chart.mainRect.right), reason: '前置: 最新根右侧有两根以上的空白');

      expect(chart.dxToIndex(latest + w), len);
      expect(chart.dxToIndex(latest + 2 * w), len + 1);
      expect(chart.indexToDx(len + 1), closeTo(latest + 2 * w, 1e-9));
      expect(chart.klineData.get(chart.dxToIndex(latest + w)), isNull, reason: '越界由 get 判定');
    });
  });

  group('cross tooltip', () {
    testWidgets('onCrossCustomTooltip 的 prev 是更旧的前一根', (tester) async {
      await arrange(tester);
      FlexiCandleModel? got, gotPrev;
      chart.onCrossCustomTooltip = (model, {prev}) {
        got = model;
        gotPrev = prev;
        return null;
      };
      final i = chart.klineData.length - 5;

      chart.onCrossFollow(Offset(chart.indexToDx(i), chart.mainRect.center.dy));
      chart.paintCross(Canvas(PictureRecorder()), chart.canvasRect.size);

      expect(got?.ts, chart.klineData[i].ts);
      expect(gotPrev?.ts, chart.klineData[i - 1].ts);
      expect(gotPrev!.ts, lessThan(got!.ts));
    });
  });
}
