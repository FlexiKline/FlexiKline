// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// 触摸端双击：滑竿区与图表其他位置一样由 DoubleTap 识别器派发，回调带上落点。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/support.dart';

const _spec = KlineSpec(
  symbol: 'ZOOM-SLIDER-DOUBLE-TAP',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

/// 两次点击之间的间隔，落在 `kDoubleTapMinTime` 与 `kDoubleTapTimeout` 之间。
const _gap = Duration(milliseconds: 100);

/// 用例结束前泵过 `kDoubleTapTimeout`，让识别器的计时器走完。
const _settle = Duration(milliseconds: 400);

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

Future<FlexiKlineController> _arrange(WidgetTester tester, {FlexiDoubleTapCallback? onDoubleTap}) async {
  final result = await pumpChartInListView(
    tester,
    spec: _spec,
    candles: _candles(),
    candle: TestCandleIndicator(visibleMinMaxFromData: true),
    onDoubleTap: onDoubleTap,
  );
  final chart = result.chart;
  addTearDown(() => disposeChart(tester, chart));
  chart.updateGestureConfig((config) => config.copyWith(enableZoom: true, useCustomZoomRect: true));
  chart.setChartZoomSlideBarRect(
    Rect.fromLTWH(chart.mainRect.right - 24, chart.mainRect.top, 24, chart.mainRect.height),
  );
  await tester.pump();
  await tester.pump();
  expect(chart.chartZoomSlideBarRect.isEmpty, isFalse, reason: '滑竿区必须已生效');
  return chart;
}

Offset _slider(FlexiKlineController chart) => Offset(chart.chartZoomSlideBarRect.center.dx, chart.mainRect.center.dy);

Future<void> _doubleTap(WidgetTester tester, Offset local) async {
  await tester.tapAt(toChartGlobal(tester, local));
  await tester.pump(_gap);
  await tester.tapAt(toChartGlobal(tester, local));
  await tester.pump(_settle);
}

void _enterZoom(FlexiKlineController chart) {
  final from = _slider(chart);
  expect(chart.onChartZoomStart(from), isTrue);
  chart.onChartZoomUpdate(from.dy - 60);
  chart.onChartZoomEnd();
  expect(chart.isChartZooming, isTrue, reason: '前置条件: 已进入缩放态');
}

void main() {
  testWidgets('双击滑竿 => 回调收到滑竿内落点, 框架不改缩放态', (tester) async {
    final positions = <Offset>[];
    final chart = await _arrange(tester, onDoubleTap: positions.add);
    _enterZoom(chart);

    await _doubleTap(tester, _slider(chart));

    expect(positions, [_slider(chart)]);
    expect(chart.isChartZooming, isTrue);
  });

  testWidgets('宿主在回调里按落点退出缩放 => Y 轴复位', (tester) async {
    late final FlexiKlineController chart;
    chart = await _arrange(
      tester,
      onDoubleTap: (position) {
        if (chart.chartZoomSlideBarRect.include(position)) chart.exitChartZoom();
      },
    );
    _enterZoom(chart);

    await _doubleTap(tester, _slider(chart));

    expect(chart.isChartZooming, isFalse);
  });

  testWidgets('双击主区 => 回调收到主区落点', (tester) async {
    final positions = <Offset>[];
    final chart = await _arrange(tester, onDoubleTap: positions.add);
    final target = chart.mainRect.center;

    await _doubleTap(tester, target);

    expect(positions, [target]);
  });

  testWidgets('未设回调 => 单击滑竿不等双击超时, 立即启动 cross', (tester) async {
    final chart = await _arrange(tester);

    await tester.tapAt(toChartGlobal(tester, _slider(chart)));
    await tester.pump();

    expect(chart.isCrossing, isTrue);
  });
}
