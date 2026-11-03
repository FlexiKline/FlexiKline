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

/// 时间轴标签的选根: 锚定最新一根, 最新蜡烛下方恒有标签, 加载历史不让标签跳动。
///
/// 经 controller 的绘制入口驱动, 断言录制下来的标签位置; 不覆盖手势与 Widget 布局。
library;

import 'dart:ui' show Paragraph;

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

  /// 本帧时间轴标签(画在主区下方)的左上角位置与宽度。
  Future<List<({Offset offset, double width})>> labels(WidgetTester tester) async {
    final canvas = RecordingCanvas();
    chart.paintChart(canvas, chart.canvasRect.size);
    await tester.pump();
    final paragraphs = [
      for (final i in canvas.invocations)
        if (i.memberName == #drawParagraph) i.positionalArguments[0] as Paragraph,
    ];
    return [
      for (final (i, o) in canvas.paragraphOffsets.indexed)
        if (o.dy >= chart.mainRect.bottom) (offset: o, width: paragraphs[i].width),
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

  testWidgets('蜡烛宽过标签间距时每根都有标签, 不因 step 为 0 抛异常', (tester) async {
    await mount(tester);
    chart.settingConfig = chart.settingConfig.copyWith(candleMaxWidth: 300);
    chart.onChartScaleTo(150 / chart.candleWidth, position: ScalePosition.right, focalDx: 0);
    expect(chart.candleActualWidth, greaterThan(120), reason: '前置: 标签间距不足一根蜡烛');

    final shown = await labels(tester);

    expect(shown, isNotEmpty);
    expect(shown.length, chart.klineData.end - chart.klineData.start);
  });

  testWidgets('最新一根下方恒有标签, 新蜡烛追加后仍然如此', (tester) async {
    await mount(tester);
    final first = await labels(tester);
    expect(first.length, greaterThan(1), reason: '前置: 标签隔根选取');
    final step = ((first[1].offset.dx - first[0].offset.dx) / chart.candleActualWidth).round();

    // 追加 step + 1 根, 让最新一根走遍 step 的全部余数。
    for (var i = 0; i <= step; i++) {
      final latestDx = chart.indexToDx(chart.klineData.length - 1);
      final centers = [for (final l in await labels(tester)) l.offset.dx + l.width / 2];
      expect(centers.any((c) => (c - latestDx).abs() < 0.01), isTrue, reason: '追加 $i 根后最新一根下方没有标签');

      chart.updateLatestKlineData(_spec, [_candle(1200 + i)]);
      chart.flushPendingKlineData();
    }
    expect(chart.klineData.length, 200 + step + 1, reason: '前置: 蜡烛确实追加');
  });
}
