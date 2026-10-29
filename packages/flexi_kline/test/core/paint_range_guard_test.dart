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

      data.ensurePaintRange(barsBack: 10, count: 10);
      expect(data.canPaintChart, isTrue, reason: '[0, 10) 是合法区间');

      // maxCandleCount 为 0 时 calculatePaintChartRange 就会算出这个退化区间。
      data.ensurePaintRange(barsBack: data.length, count: 0);
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

  /// 可见窗口 `[start, end)` 就是屏幕上的蜡烛：最新侧截到最后一根仍有部分在屏内的蜡烛，
  /// 最旧侧取覆盖左边界的那一根（四舍五入，误差不超过半根）。平移量取非整数倍蜡烛宽。
  group('可见窗口与屏幕蜡烛一致', () {
    Future<FlexiKlineController> arrange(WidgetTester tester, {bool alwaysOneScreen = false}) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      await scene.initWithData(_spec, genFlatCandleList(count: 200), canvasWidth: 400);
      final ctrl = scene.controller;
      ctrl.flushPendingKlineData();
      if (alwaysOneScreen) {
        ctrl.updateSettingConfig((c) => c.copyWith(alwaysCalculateScreenOfCandlesIfEnough: true));
      }
      await paintChartFrame(tester, ctrl);
      return ctrl;
    }

    double leftEdge(FlexiKlineController ctrl, int index) => ctrl.indexToDx(index) - ctrl.candleActualWidth / 2;

    testWidgets('最新侧移出屏幕时：end 是最后一根仍有部分在屏内的蜡烛之后', (tester) async {
      final ctrl = await arrange(tester);
      final rect = ctrl.mainChartRect;
      final w = ctrl.candleActualWidth;
      ctrl.onChartMove(Offset(-ctrl.paintDxOffset, 0));
      var checked = 0;
      for (var step = 0; step < 40; step++) {
        ctrl.onChartMove(Offset(w * 0.37, 0));
        if (ctrl.paintDxOffset <= 0) continue;
        ctrl.calculatePaintChartRange();
        final data = ctrl.klineData;
        final context = 'step=$step offset=${ctrl.paintDxOffset} range=[${data.start}, ${data.end})';
        checked++;

        expect(leftEdge(ctrl, data.end), greaterThanOrEqualTo(rect.right - 1e-9), reason: 'end 及之后整根在屏外. $context');
        expect(leftEdge(ctrl, data.end - 1), lessThan(rect.right), reason: 'end - 1 仍有一部分在屏内. $context');
        expect((leftEdge(ctrl, data.start) - rect.left).abs(), lessThanOrEqualTo(w / 2 + 1e-9), reason: context);
      }
      expect(checked, greaterThan(20), reason: '平移量不足, 用例空转');
    });

    testWidgets('最新根右侧留白时：end 恒为 length，start 覆盖左边界', (tester) async {
      final ctrl = await arrange(tester);
      final rect = ctrl.mainChartRect;
      final w = ctrl.candleActualWidth;
      var checked = 0;
      for (var step = 0; step < 40; step++) {
        ctrl.onChartMove(Offset(-w * 0.37, 0));
        if (ctrl.paintDxOffset > 0) continue;
        ctrl.calculatePaintChartRange();
        final data = ctrl.klineData;
        final context = 'step=$step offset=${ctrl.paintDxOffset} range=[${data.start}, ${data.end})';
        checked++;

        expect(data.end, data.length, reason: context);
        // maxCandleCount 向上取整、留白根数四舍五入: 起点最多再往左多出一根。
        final edge = leftEdge(ctrl, data.start);
        expect(edge, lessThanOrEqualTo(rect.left + w / 2 + 1e-9), reason: context);
        expect(edge, greaterThanOrEqualTo(rect.left - w * 1.5 - 1e-9), reason: context);
      }
      expect(checked, greaterThan(5), reason: '平移量不足, 用例空转');
    });

    testWidgets('alwaysCalculateScreenOfCandlesIfEnough 时留白也按一屏根数取窗口', (tester) async {
      final ctrl = await arrange(tester, alwaysOneScreen: true);
      ctrl.onChartMove(Offset(-ctrl.mainChartWidth / 3, 0));
      expect(ctrl.paintDxOffset, lessThan(0), reason: '前置条件: 最新根右侧有留白');
      ctrl.calculatePaintChartRange();

      final data = ctrl.klineData;
      expect(data.end, data.length);
      expect(data.end - data.start, ctrl.maxCandleCount);
    });
  });
}
