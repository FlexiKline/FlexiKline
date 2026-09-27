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

/// 绘制入口对可见区间的担保。
///
/// `paintChart` 承诺下发给 [IPaintObject.computeVisibleMinMax] 的区间满足
/// `0 <= start < end <= length`，指标因此不必自行校验区间或数据是否为空。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'PAINT-RANGE', interval: FlexiTimeInterval(1, TimeUnit.day));

final _rangeKey = directKey(0);

void main() {
  group('绘制入口的可见区间担保', () {
    testWidgets('canPaintChart 要求区间非空: start == end 时为假', (tester) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      await scene.initWithData(_spec, genFlatCandleList(count: 20), canvasWidth: 400);
      scene.controller.flushPendingKlineData();
      final data = scene.controller.klineData;

      data.ensureStartAndEndIndex(0, 10);
      expect(data.canPaintChart, isTrue, reason: '[0, 10) 是合法区间');

      // maxCandleCount 为 0 时 calculatePaintChartRange 就会算出这个退化区间。
      data.ensureStartAndEndIndex(0, 0);
      expect(data.start, data.end);
      expect(
        data.canPaintChart,
        isFalse,
        reason: 'start == end 表示零根可见蜡烛, end - 1 不是合法下标',
      );
    });

    testWidgets('画布宽度为 0 时不把退化区间下发给指标', (tester) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      final range = TestRangeIndicator(key: _rangeKey);
      // 不传 canvasWidth: mainChartWidth 为 0 → maxCandleCount 为 0
      // → calculatePaintChartRange 写出 start == end == 0。
      await scene.initWithData(
        _spec,
        genFlatCandleList(count: 20),
        subIndicators: [range],
      );
      scene.controller.flushPendingKlineData();
      scene.controller.showSubIndicator(_rangeKey);

      await paintChartFrame(tester, scene.controller);

      final data = scene.controller.klineData;
      expect(data.isNotEmpty, isTrue, reason: '数据本身是有的, 只是可见区间退化');
      expect(data.start, data.end, reason: '本帧算出的是退化区间');
      expect(
        range.object?.computeCount ?? 0,
        0,
        reason: '入口校验的必须是本帧重算后的区间, 而不是上一帧的旧值',
      );
    });

    testWidgets('下发的区间始终满足 0 <= start < end <= length', (tester) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      final range = TestRangeIndicator(key: _rangeKey);
      await scene.initWithData(
        _spec,
        genFlatCandleList(count: 200),
        subIndicators: [range],
        canvasWidth: 400,
      );
      final ctrl = scene.controller;
      ctrl.flushPendingKlineData();
      ctrl.showSubIndicator(_rangeKey);

      // 覆盖初始位置与双向平移到底: 三种 paintDxOffset 极值下区间都必须自洽。
      for (final delta in <double>[0, -100000, 200000]) {
        if (delta != 0) ctrl.onChartMove(Offset(delta, 0));
        await paintChartFrame(tester, ctrl);

        final object = range.object!;
        if (object.computeCount == 0) continue;
        final start = object.lastStart!;
        final end = object.lastEnd!;
        expect(start, greaterThanOrEqualTo(0));
        expect(start, lessThan(end), reason: 'end 是排他上界, 必须严格大于 start');
        expect(end, lessThanOrEqualTo(ctrl.klineData.length));
      }
    });

    testWidgets('蜡烛数远少于指标周期时入口依然自洽', (tester) async {
      // 老版 RSI 崩溃的形状: 可见区间合法, 但 `length - period` 派生出负下标后直接索引。
      // 入口只担保区间本身, 派生下标由指标自负; 这里锁住极少数据下入口不会给出脏区间。
      for (final count in <int>[1, 2, 6]) {
        final scene = ControllerScenario();
        addTearDown(scene.dispose);
        await scene.initWithData(_spec, genFlatCandleList(count: count), canvasWidth: 400);
        final ctrl = scene.controller;
        ctrl.flushPendingKlineData();

        await paintChartFrame(tester, ctrl);

        final data = ctrl.klineData;
        expect(data.length, count);
        if (data.canPaintChart) {
          expect(data.start, lessThan(data.end));
          expect(data.end, lessThanOrEqualTo(data.length));
        }
      }
    });
  });
}
