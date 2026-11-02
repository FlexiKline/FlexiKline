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
import 'package:flutter/material.dart';
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
      find.descendant(of: find.byType(FlexiExitZoomButton), matching: find.byType(IconButton)),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(chart.isChartZooming, isFalse);
    expect(foregroundTaps, 0);
  });
}
