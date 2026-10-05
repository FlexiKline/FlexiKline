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

/// dispose 后 pending 帧回归测试。
///
/// `paintChart` 会注册两个 post-frame 回调（`calculatePaintChartRange` 的 chartRange、
/// `setChartZoomSlideBarRect` 的滑竿热区），它们不保证在 dispose 前被冲掉：helper 的
/// `tester.pump()` 不触发它们，只有 warm-up 帧（`runApp`/`pumpWidget`）会执行 pending
/// 回调。widget 卸载与下一帧之间的窗口在真机上同样存在。
///
/// 生命周期守卫必须短路对已销毁 notifier 的写入，否则 debug 断言崩溃。
@TestOn('vm')
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'DISPOSE-TEST', interval: FlexiTimeInterval(1, TimeUnit.day));

List<CandleModel> _candles({int count = 200}) {
  const latest = 12000000;
  return List.generate(count, (index) {
    final center = 100 + index * 10.0;
    return CandleModel(
      timestamp: latest - index * 60000,
      open: center,
      high: center + 5,
      low: center - 5,
      close: center,
      volume: 1000,
    );
  });
}

void main() {
  testWidgets('dispose 后 warm-up 帧触发 pending 回调不再写已销毁 notifier', (tester) async {
    final scene = ControllerScenario();
    await scene.initWithData(
      _spec,
      _candles(),
      canvasWidth: 400,
      candle: TestCandleIndicator(visibleMinMaxFromData: true),
      subIndicators: [TestDirectIndicator(key: directKey(1))],
    );
    final chart = scene.controller;
    chart.flushPendingKlineData();
    // paintChart 注册 chartRange / zoomSlideBarRect 两个 post-frame 回调；
    // paintChartFrame 的 pump 不会触发它们，刻意保留到 dispose 之后。
    await paintChartFrame(tester, chart);

    scene.dispose();
    // pumpWidget 触发一次 warm-up 帧，执行 pending 回调。
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
