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

/// 非触摸端双击：回调带上落点，滑竿区与图表其他位置相同。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/support.dart';

const _spec = KlineSpec(
  symbol: 'NON-TOUCH-DOUBLE-TAP',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

const _gap = Duration(milliseconds: 100);
const _settle = Duration(milliseconds: 400);

/// 指标点击命中区, 用来观察 `onTapUp` 何时派发。
const _hitRect = Rect.fromLTWH(100, 100, 30, 20);

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

Future<({FlexiKlineController chart, TestInteractiveIndicator indicator})> _arrange(
  WidgetTester tester, {
  FlexiDoubleTapCallback? onDoubleTap,
}) async {
  final indicator = TestInteractiveIndicator(
    key: const ExternalIndicatorKey('non_touch_double_tap'),
    hitRect: _hitRect,
  );
  final result = await pumpChartInListView(
    tester,
    spec: _spec,
    candles: _candles(),
    mainIndicators: [indicator],
    isTouchDevice: false,
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
  return (chart: chart, indicator: indicator);
}

Future<void> _click(WidgetTester tester, Offset local) {
  return tester.tapAt(toNonTouchChartGlobal(tester, local), kind: PointerDeviceKind.mouse);
}

void main() {
  testWidgets('鼠标双击滑竿 => 回调收到滑竿内落点', (tester) async {
    final positions = <Offset>[];
    final scene = await _arrange(tester, onDoubleTap: positions.add);
    final slider = Offset(scene.chart.chartZoomSlideBarRect.center.dx, scene.chart.mainRect.center.dy);

    await _click(tester, slider);
    await tester.pump(_gap);
    await _click(tester, slider);
    await tester.pump(_settle);

    expect(positions, [slider]);
  });

  testWidgets('未设回调 => 鼠标单击不等双击超时', (tester) async {
    final scene = await _arrange(tester);

    await _click(tester, _hitRect.center);
    await tester.pump();

    expect(scene.indicator.object!.calls, ['tap']);
  });
}
