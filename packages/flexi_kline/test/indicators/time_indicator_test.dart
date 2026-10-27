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

/// 时间轴标签的选根: 锚定 replace 时的第一根, 加载历史与新蜡烛都不让标签跳动。
///
/// 经 controller 的绘制入口驱动, 断言录制下来的标签位置; 不覆盖手势与 Widget 布局。
library;

import 'dart:math' as math;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'TIME-LABEL', interval: FlexiTimeInterval(1, TimeUnit.minute));

CandleModel _candle(int minute) =>
    CandleModel(timestamp: minute * 60000, open: 100, high: 110, low: 90, close: 105, volume: 1000);

void main() {
  late FlexiKlineController chart;

  Future<void> mount(WidgetTester tester) async {
    chart = FlexiKlineController(configuration: FakeFlexiKlineConfiguration());
    addTearDown(chart.dispose);
    chart.switchKlineData(_spec);
    chart.replaceKlineData(_spec, [for (var m = 1000; m < 1200; m++) _candle(m)]);
    chart.mountIndicators(
      candle: TestCandleIndicator(),
      time: TimeIndicator(),
      mainIndicators: const [],
      subIndicators: const [],
    );
    chart.initState();
    chart.setAdaptLayoutMode(width: 400);
    chart.flushPendingKlineData();
  }

  /// 本帧时间轴标签(画在主区下方)的左上角位置。
  Future<List<Offset>> labels(WidgetTester tester) async {
    final canvas = RecordingCanvas();
    chart.paintChart(canvas, chart.canvasRect.size);
    await tester.pump();
    return [
      for (final o in canvas.paragraphOffsets)
        if (o.dy >= chart.mainRect.bottom) o,
    ];
  }

  testWidgets('加载历史后时间轴标签仍落在原来的蜡烛上', (tester) async {
    await mount(tester);
    final before = await labels(tester);
    final latestDx = chart.indexToDx(chart.klineData.length - 1);
    expect(before.length, greaterThan(1));
    expect(chart.klineData.end - chart.klineData.start, greaterThan(before.length), reason: '前置: 标签隔根选取');

    // 净头插 1 根: 只按下标取模时所有标签都会错开一根。
    chart.prependHistoryKlineData(_spec, [_candle(999)]);
    chart.flushPendingKlineData();
    expect(chart.indexToDx(chart.klineData.length - 1), latestDx, reason: '前置: 视口不动');

    expect(await labels(tester), before);
  });

  testWidgets('新蜡烛追加在尾部时已有标签不跳', (tester) async {
    await mount(tester);
    final before = await labels(tester);
    final w = chart.candleActualWidth;

    chart.updateLatestKlineData(_spec, [_candle(1200)]);
    chart.flushPendingKlineData();
    final after = await labels(tester);

    // 视口锚定最新根, 新蜡烛让已有蜡烛整体左移一根; 标签跟着蜡烛走, 相位与左移一根后一致.
    final period = before[1].dx - before[0].dx;
    expect(period, greaterThan(w), reason: '前置: 标签隔根选取');
    for (final o in after) {
      final phase = (o.dx + w - before.first.dx) % period;
      expect(math.min(phase, period - phase), lessThan(1e-6), reason: '标签 $o 不在左移一根后的原相位上');
    }
  });
}
