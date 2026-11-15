// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// 退出缩放按钮的层级：宿主前景盖住整个主区时按钮仍可达。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'EXIT-ZOOM-LAYER',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

List<CandleModel> _candles() => List.generate(
  40,
  (index) => CandleModel(
    timestamp: 60000 * (index + 1),
    open: 100,
    high: 110 + index % 5,
    low: 90 - index % 3,
    close: 105,
    volume: 1000,
  ),
);

void main() {
  testWidgets('主区前景铺满不透明区域 => 退出缩放按钮仍可点, 前景收不到这次点击', (tester) async {
    var foregroundTaps = 0;
    final scene = await pumpChartInListView(
      tester,
      spec: _spec,
      candles: _candles(),
      candle: TestCandleIndicator(visibleMinMaxFromData: true),
      mainForegroundBuilder: (context, controller) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => foregroundTaps++,
        child: const SizedBox.expand(),
      ),
    );
    final chart = scene.chart;
    addTearDown(() => disposeChart(tester, chart));

    chart.updateGestureConfig((config) => config.copyWith(enableZoom: true));
    final from = Offset(chart.mainRect.right - 10, chart.mainRect.center.dy);
    expect(chart.onChartZoomStart(from), isTrue);
    chart.onChartZoomUpdate(from.dy - 60);
    chart.onChartZoomEnd();
    await tester.pump();
    expect(chart.isChartZooming, isTrue, reason: '前置条件: 已进入缩放态');

    await tester.tap(
      find.descendant(of: find.byType(FlexiExitZoomButton), matching: find.text('A')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(chart.isChartZooming, isFalse);
    expect(foregroundTaps, 0);
  });

  /// 从滑竿中心按下并拖动, 进入缩放态。
  Future<void> enterZoom(WidgetTester tester, FlexiKlineController chart) async {
    chart.updateGestureConfig((config) => config.copyWith(enableZoom: true));
    final from = chart.chartZoomSlideBarRect.center;
    expect(chart.chartZoomSlideBarRect.isEmpty, isFalse, reason: '前置条件: 滑竿已绘制');
    expect(chart.onChartZoomStart(from), isTrue);
    chart.onChartZoomUpdate(from.dy - 60);
    chart.onChartZoomEnd();
    await tester.pump();
  }

  Container buttonContainer(WidgetTester tester) {
    return tester.widget<Container>(
      find.descendant(of: find.byType(FlexiExitZoomButton), matching: find.byType(Container)).first,
    );
  }

  testWidgets('未指定 alignment 与 padding: 滑竿在左侧时贴左下, 水平居中于滑竿, 底部与水平间距相同', (tester) async {
    final scene = await pumpChartInListView(
      tester,
      spec: _spec,
      candles: _candles(),
      candle: TestCandleIndicator(visibleMinMaxFromData: true, yAxisSide: AxisDirection.left),
    );
    final chart = scene.chart;
    addTearDown(() => disposeChart(tester, chart));

    await enterZoom(tester, chart);

    // 按钮默认尺寸为 20x20, 居中留白由滑竿实测宽度换算。
    final container = buttonContainer(tester);
    final slideBar = chart.chartZoomSlideBarRect;
    expect(container.alignment, AlignmentDirectional.bottomStart);
    expect(container.padding, EdgeInsets.all((slideBar.width - 20) / 2));
  });

  testWidgets('指定 padding 未指定 alignment: 滑竿在左侧时贴左下, padding 原样使用', (tester) async {
    final scene = await pumpChartInListView(
      tester,
      spec: _spec,
      candles: _candles(),
      candle: TestCandleIndicator(visibleMinMaxFromData: true, yAxisSide: AxisDirection.left),
      // 前景层先于默认按钮挂入 Stack, 所以 first 取到的是这里传入 padding 的按钮。
      mainForegroundBuilder: (context, controller) => FlexiExitZoomButton(
        controller: controller,
        padding: const EdgeInsets.all(12),
      ),
    );
    final chart = scene.chart;
    addTearDown(() => disposeChart(tester, chart));

    await enterZoom(tester, chart);

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(FlexiExitZoomButton).first, matching: find.byType(Container)).first,
    );
    expect(container.alignment, AlignmentDirectional.bottomStart);
    expect(container.padding, const EdgeInsets.all(12));
  });

  testWidgets('指定 alignment 与 padding 时, 不论滑竿在哪一侧都按指定值', (tester) async {
    final scene = await pumpChartInListView(
      tester,
      spec: _spec,
      candles: _candles(),
      candle: TestCandleIndicator(visibleMinMaxFromData: true, yAxisSide: AxisDirection.left),
      // 前景层先于默认按钮挂入 Stack, 所以 first 取到的是这里显式指定的按钮。
      mainForegroundBuilder: (context, controller) => FlexiExitZoomButton(
        controller: controller,
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.all(3),
      ),
    );
    final chart = scene.chart;
    addTearDown(() => disposeChart(tester, chart));

    await enterZoom(tester, chart);

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(FlexiExitZoomButton).first, matching: find.byType(Container)).first,
    );
    expect(container.alignment, Alignment.topLeft);
    expect(container.padding, const EdgeInsets.all(3));
  });
}
