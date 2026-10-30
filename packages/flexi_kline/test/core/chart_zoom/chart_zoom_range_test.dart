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

/// Y 轴缩放作用于可见价格区间：像素几何全程不动（`padding` 恒等于声明值，`mainChartRect` 不变），
/// 缩放只改价格到像素映射的分母；换周期保持缩放、换标的交还自动区间。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/support.dart';
import 'zoom_scene.dart';

void main() {
  group('作用于可见价格区间', () {
    testWidgets('自动模式下区间取可见蜡烛的最高最低价', (tester) async {
      final scene = await arrange(tester);
      await paintFrame(tester, scene.controller);

      expect(rangeMax(scene.controller), closeTo(autoMax, 1e-9));
      expect(rangeMin(scene.controller), closeTo(autoMin, 1e-9));
    });

    testWidgets('缩放全程 padding 恒等于声明值，mainChartRect 不动', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final declaredPadding = chart.mainPadding;
      final rectBefore = chart.mainChartRect;

      dragSlider(chart, dragDy);
      await paintFrame(tester, chart);

      expect(chart.mainPadding, declaredPadding, reason: 'zoom 不得写 padding');
      expect(chart.mainChartRect, rectBefore, reason: '像素几何全程不参与 Y 轴缩放');
    });

    testWidgets('向下拖动：区间跨度变大、中点不变，内容视觉被压缩', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, dragDy);
      await paintFrame(tester, chart);

      expect(rangeSpan(chart), greaterThan(autoSpan));
      expect(rangeCenter(chart), closeTo(autoCenter, 1e-6), reason: '缩放围绕区间中点');
    });

    testWidgets('向上拖动：区间跨度变小、中点不变', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, -dragDy);
      await paintFrame(tester, chart);

      expect(rangeSpan(chart), lessThan(autoSpan));
      expect(rangeCenter(chart), closeTo(autoCenter, 1e-6));
    });

    testWidgets('基于按下快照重算：拖回起点即还原，不逐帧累乘', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final from = Offset(sliderRect(chart).center.dx, chart.mainRect.center.dy);
      expect(chart.onChartZoomStart(from), isTrue);

      // 中途来回若干帧, 最后停回起点。
      for (final dy in [20.0, 45.0, -30.0, 10.0, 0.0]) {
        chart.onChartZoomUpdate(from.dy + dy);
      }
      await paintFrame(tester, chart);

      expect(
        rangeSpan(chart),
        closeTo(autoSpan, 1e-6),
        reason: '快照口径下停回起点即系数为 1',
      );
    });

    testWidgets('缩放期间横向平移：Y 轴区间不变', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, dragDy);
      await paintFrame(tester, chart);
      final zoomedMax = rangeMax(chart);
      final zoomedMin = rangeMin(chart);

      // 横向平移改变可见蜡烛范围, 自动模式下会重算区间。
      chart.onChartMove(const Offset(-120, 0));
      await paintFrame(tester, chart);

      expect(rangeMax(chart), closeTo(zoomedMax, 1e-9));
      expect(rangeMin(chart), closeTo(zoomedMin, 1e-9));
    });

    testWidgets('缩放态下纵向拖动：跨度不变、中点按 dyDelta / dyFactor 位移', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, dragDy);
      await paintFrame(tester, chart);
      final spanBefore = rangeSpan(chart);
      final centerBefore = rangeCenter(chart);
      final factor = chart.mainChartRect.height / spanBefore;

      const dy = 24.0;
      chart.onChartMove(const Offset(0, dy));
      await paintFrame(tester, chart);

      expect(rangeSpan(chart), closeTo(spanBefore, 1e-6), reason: '平移不改变跨度');
      expect(
        rangeCenter(chart),
        closeTo(centerBefore + dy / factor, 1e-6),
        reason: '向下拖动使区间上移, 内容随手指下移',
      );
    });

    testWidgets('自动模式下纵向拖动不改变 Y 轴区间', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      chart.onChartMove(const Offset(0, 24));
      await paintFrame(tester, chart);

      expect(rangeMax(chart), closeTo(autoMax, 1e-9));
      expect(rangeMin(chart), closeTo(autoMin, 1e-9));
    });

    testWidgets('exitChartZoom 后回到自动区间', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, dragDy);
      await paintFrame(tester, chart);
      expect(rangeSpan(chart), isNot(closeTo(autoSpan, 1e-6)));

      chart.exitChartZoom();
      await paintFrame(tester, chart);

      expect(chart.isChartZooming, isFalse);
      expect(rangeMax(chart), closeTo(autoMax, 1e-9));
      expect(rangeMin(chart), closeTo(autoMin, 1e-9));
    });

    testWidgets('点一下滑竿未产生缩放：onChartZoomEnd 直接退出，不留待复位状态', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final from = Offset(sliderRect(chart).center.dx, chart.mainRect.center.dy);
      expect(chart.onChartZoomStart(from), isTrue);
      expect(chart.isChartZooming, isTrue);

      chart.onChartZoomEnd();
      await paintFrame(tester, chart);

      expect(chart.isChartZooming, isFalse, reason: '没缩放过就不该留下一个要按 A 才能清的状态');
      expect(rangeSpan(chart), closeTo(autoSpan, 1e-9));
    });

    testWidgets('缩放后 onChartZoomEnd 保持缩放态，只有显式复位才交还自动', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, dragDy);
      await paintFrame(tester, chart);

      chart.onChartZoomEnd();
      await paintFrame(tester, chart);

      expect(chart.isChartZooming, isTrue);
      expect(rangeSpan(chart), isNot(closeTo(autoSpan, 1e-6)));
    });

    testWidgets('未命中滑竿：不进入缩放、不取快照', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      expect(chart.onChartZoomStart(chart.mainRect.centerLeft), isFalse);
      expect(chart.isChartZooming, isFalse);

      // 没有快照, update 必须是 no-op。
      chart.onChartZoomUpdate(dragDy);
      await paintFrame(tester, chart);

      expect(rangeSpan(chart), closeTo(autoSpan, 1e-9));
    });

    /// 触摸端传给 `onChartZoomStart` 的是**当前**手指位置而非按下位置（归属在 PointerDown
    /// 判定、缩放要等纵向位移够 `zoomStartMinDistance`），所以斜向甩动可能在此之前已横向移出
    /// 滑竿。若那时把 `isChartZooming` 置 false 而不清缩放区间，就会留下「退出按钮消失、Y 轴
    /// 仍锁在缩放区间」的失同步状态 —— 用户看不到复位入口。
    testWidgets('缩放态下未命中滑竿：保持缩放态，不与缩放区间失同步', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, dragDy);
      await paintFrame(tester, chart);
      final zoomedSpan = rangeSpan(chart);

      expect(chart.onChartZoomStart(chart.mainRect.centerLeft), isFalse);
      await paintFrame(tester, chart);

      expect(chart.isChartZooming, isTrue, reason: '交还 Y 轴只有 exitChartZoom 一条路径');
      expect(rangeSpan(chart), closeTo(zoomedSpan, 1e-9));
    });
  });

  group('生命周期', () {
    testWidgets('换周期保持缩放区间', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, dragDy);
      await paintFrame(tester, chart);
      final zoomedSpan = rangeSpan(chart);

      chart.switchKlineData(
        const KlineSpec(symbol: 'CHART-ZOOM', interval: FlexiTimeInterval(1, TimeUnit.hour)),
      );
      chart.replaceKlineData(
        const KlineSpec(symbol: 'CHART-ZOOM', interval: FlexiTimeInterval(1, TimeUnit.hour)),
        genFlatCandleList(),
      );
      chart.flushPendingKlineData();
      await paintFrame(tester, chart);

      expect(chart.isChartZooming, isTrue, reason: '同一标的的视野应当保留');
      expect(rangeSpan(chart), closeTo(zoomedSpan, 1e-6));
    });

    testWidgets('换标的交还 Y 轴：退出缩放态', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, dragDy);
      await paintFrame(tester, chart);
      expect(chart.isChartZooming, isTrue);

      const other = KlineSpec(symbol: 'OTHER-SYMBOL', interval: FlexiTimeInterval(1, TimeUnit.day));
      chart.switchKlineData(other);
      chart.replaceKlineData(other, genFlatCandleList());
      chart.flushPendingKlineData();
      await paintFrame(tester, chart);

      expect(chart.isChartZooming, isFalse, reason: '另一个标的的价格区间没有意义');
      expect(rangeMax(chart), closeTo(autoMax, 1e-9));
      expect(rangeMin(chart), closeTo(autoMin, 1e-9));
    });

    testWidgets('主区尺寸变化不改变缩放区间，也不产生 padding 补偿', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final paddingBefore = chart.mainPadding;
      dragSlider(chart, dragDy);
      await paintFrame(tester, chart);
      final zoomedMax = rangeMax(chart);
      final zoomedMin = rangeMin(chart);

      chart.setMainSize(Size(chart.mainSize.width, chart.mainSize.height + 80));
      await paintFrame(tester, chart);

      expect(rangeMax(chart), closeTo(zoomedMax, 1e-9));
      expect(rangeMin(chart), closeTo(zoomedMin, 1e-9));
      expect(chart.mainPadding, paddingBefore, reason: '不产生按高度比例的 padding 补偿');
    });
  });
}
