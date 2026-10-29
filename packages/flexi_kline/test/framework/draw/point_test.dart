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

/// 画线点的持久化与屏幕位置。
///
/// 画线落盘的是蜡烛坐标 `(ts, value)`，屏幕坐标每帧由当前视口换算：蜡烛 ts 落在蜡烛中心，
/// 相邻蜡烛之间（含交易时间缺口）按 ts 线性插值。
///
/// 覆盖层级：[Point] 的 JSON 与 controller 的 `calculateDrawPointOffset`。
/// 不覆盖：画线手势、磁吸与命中。
library;

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/support.dart';

const _spec = KlineSpec(symbol: 'DRAW-POINT', interval: FlexiTimeInterval(1, TimeUnit.minute));

void main() {
  group('Point JSON', () {
    test('落盘字段只有 index / ts / value, 读回后相等', () {
      final point = Point(index: 1, ts: 120000, value: FlexiNum.fromDecimal(Decimal.parse('101.25')));

      final json = point.toJson();
      expect(json.keys, unorderedEquals(['index', 'ts', 'value']), reason: '屏幕坐标是临时值, 不落盘');

      final restored = Point.fromJson(json);
      expect(restored, point);
      expect(restored.value.toDecimal(), Decimal.parse('101.25'));
      expect(restored.offset, Offset.infinite, reason: '读回后要等下一帧按视口换算');
    });

    test('缺键时取默认值', () {
      final restored = Point.fromJson(const {'value': 3});

      expect(restored.index, -1);
      expect(restored.ts, -1);
      expect(restored.value.toDouble(), 3);
    });
  });

  group('calculateDrawPointOffset', () {
    /// 200 根 1 分钟蜡烛, 去掉下标 100 那一根, 在 99 与 100 之间留出两分钟的缺口。
    Future<FlexiKlineController> arrange(WidgetTester tester) async {
      final candles = genFlatCandleList(count: 201)..removeAt(100);
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      await scene.initWithData(
        _spec,
        candles,
        canvasWidth: 400,
        candle: TestCandleIndicator(visibleMinMaxFromData: true),
      );
      final chart = scene.controller;
      chart.flushPendingKlineData();
      await paintChartFrame(tester, chart);
      return chart;
    }

    testWidgets('蜡烛 ts 落在该蜡烛中心', (tester) async {
      final chart = await arrange(tester);
      final list = chart.klineData.list;

      for (final i in [0, 99, 100, list.length - 1]) {
        final offset = chart.calculateDrawPointOffset(Point(ts: list[i].ts, value: FlexiNum.fromInt(100)))!;
        expect(offset.dx, closeTo(chart.indexToDx(i), 1e-9), reason: 'i=$i');
      }
    });

    testWidgets('缺口内的 ts 按相邻两根的 ts 线性插值', (tester) async {
      final chart = await arrange(tester);
      final list = chart.klineData.list;
      final lo = list[99].ts, hi = list[100].ts;
      expect(hi - lo, 2 * _spec.interval.milliseconds, reason: '前置条件: 99 与 100 之间有缺口');

      final quarter = lo + (hi - lo) ~/ 4;
      final offset = chart.calculateDrawPointOffset(Point(ts: quarter, value: FlexiNum.fromInt(100)))!;

      final expected = chart.indexToDx(99) + (chart.indexToDx(100) - chart.indexToDx(99)) / 4;
      expect(offset.dx, closeTo(expected, 1e-9));
    });
  });
}
