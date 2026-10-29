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

  /// 主区蜡烛的绘制对象, 用来读 PaintObject 层的几何 API。
  late TestCandlePaintObject candle;

  Future<void> arrange(WidgetTester tester) async {
    final scene = ControllerScenario();
    addTearDown(scene.dispose);
    await scene.initWithData(_spec, genFlatCandleList(count: 200), canvasWidth: 400);
    chart = scene.controller;
    chart.flushPendingKlineData();
    await paintChartFrame(tester, chart);
    candle = scene.candle.object!;
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

  /// 换算的代数性质：互逆、等距、视口锚定。对三种 `paintDxOffset`（右侧留白、贴边、最新侧移出屏幕）各验一遍。
  group('几何换算的性质', () {
    Future<void> forEachOffset(WidgetTester tester, void Function(String context) check) async {
      await arrange(tester);
      final w = chart.candleActualWidth;
      for (final delta in [0.0, -chart.paintDxOffset, w * 7.3]) {
        chart.onChartMove(Offset(delta, 0));
        check('paintDxOffset=${chart.paintDxOffset}');
      }
    }

    testWidgets('paintDxOffset 是最新根实体右缘到绘制区右缘的距离', (tester) async {
      await forEachOffset(tester, (context) {
        final latest = chart.klineData.length - 1;
        final bodyRight = chart.indexToDx(latest) + chart.candleWidthHalf;
        expect(bodyRight - chart.mainChartRect.right, closeTo(chart.paintDxOffset, 1e-9), reason: context);
        expect(candle.latestCandleDx, closeTo(chart.indexToDx(latest), 1e-9), reason: context);
      });
    });

    testWidgets('相邻下标等距一个蜡烛宽度, dxToIndex 与 indexToDx 互逆（含越界下标）', (tester) async {
      await forEachOffset(tester, (context) {
        final len = chart.klineData.length, w = chart.candleActualWidth;
        for (var i = -3; i <= len + 3; i++) {
          final center = chart.indexToDx(i);
          expect(chart.dxToIndex(center), i, reason: 'i=$i $context');
          expect(chart.dxToIndex(center - w / 2), i, reason: '左边界属于本根. i=$i $context');
          expect(chart.dxToIndex(center + w / 2 - 1e-6), i, reason: '右边界之前属于本根. i=$i $context');
          expect(chart.indexToDx(i + 1) - chart.indexToDx(i), closeTo(w, 1e-9), reason: 'i=$i $context');
        }
      });
    });

    testWidgets('dxToFloatIndex 是 indexToDx 的逆, 小数下标同样成立', (tester) async {
      await forEachOffset(tester, (context) {
        for (final x in [-2.25, 0.0, 17.5, 101.75, chart.klineData.length + 1.4]) {
          expect(candle.dxToFloatIndex(chart.indexToDx(x)), closeTo(x, 1e-9), reason: 'x=$x $context');
        }
      });
    });

    testWidgets('dxToTimestamp 与 timestampToDx 互逆: 蜡烛 ts、相邻蜡烛之间与两端之外', (tester) async {
      await forEachOffset(tester, (context) {
        final list = chart.klineData.list;
        final span = _spec.interval.milliseconds;
        final samples = [
          list.first.ts - 3 * span,
          list.first.ts,
          list[50].ts + span ~/ 4,
          list.last.ts,
          list.last.ts + 2 * span,
        ];
        for (final ts in samples) {
          final dx = chart.timestampToDx(ts)!;
          expect(chart.dxToTimestamp(dx), ts, reason: 'ts=$ts $context');
        }
        expect(chart.timestampToDx(list[50].ts), closeTo(chart.indexToDx(50), 1e-9), reason: '蜡烛 ts 对应其中心. $context');
      });
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
