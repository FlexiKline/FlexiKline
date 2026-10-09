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

/// [CandlePaintObject] 接到 painting 之后的价格标签与批量蜡烛。
///
/// 经 controller 的绘制入口驱动, 断言录制下来的绘制指令与坐标; 命中只调 [CandlePaintObject.handleTap],
/// 不覆盖手势识别与 Widget 坐标转换。
// ignore_for_file: invalid_use_of_protected_member
library;

import 'dart:typed_data';
import 'dart:ui' show Paragraph, PointMode;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'CANDLE-LABEL', interval: FlexiTimeInterval(1, TimeUnit.minute));

List<Paragraph> _paragraphs(RecordingCanvas canvas) => [
  for (final i in canvas.invocations)
    if (i.memberName == #drawParagraph) i.positionalArguments[0] as Paragraph,
];

/// 涨跌交替: 偶数根(自最新起)上涨, 奇数根下跌。
List<CandleModel> _alternating({int count = 200, int latestTimestamp = 12000000}) => List.generate(
  count,
  (i) => CandleModel(
    timestamp: latestTimestamp - i * 60000,
    open: i.isEven ? 100 : 105,
    high: 110,
    low: 90,
    close: i.isEven ? 105 : 100,
    volume: 1000,
  ),
);

/// 记下创建的 [CandlePaintObject], 供用例读它的几何与标签状态。
class _Candle extends CandleIndicator {
  _Candle({super.chartType, super.inViewPriceMark, super.showCountdown = false});

  late CandlePaintObject object;

  @override
  CandlePaintObject createPaintObject() => object = CandlePaintObject();
}

void main() {
  late FlexiKlineController chart;

  Future<CandlePaintObject> mount(WidgetTester tester, _Candle candle, {List<CandleModel>? candles}) async {
    chart = FlexiKlineController(configuration: FakeFlexiKlineConfiguration());
    addTearDown(chart.dispose);
    chart.switchKlineData(_spec);
    chart.replaceKlineData(_spec, candles ?? _alternating());
    chart.mountIndicators(candle: candle, time: TimeIndicator(), mainIndicators: const [], subIndicators: const []);
    chart.initState();
    chart.setAdaptLayoutMode(width: 400);
    chart.flushPendingKlineData();
    return candle.object;
  }

  Future<RecordingCanvas> paint(WidgetTester tester) async {
    final canvas = RecordingCanvas();
    chart.paintChart(canvas, chart.canvasRect.size);
    await tester.pump();
    return canvas;
  }

  group('最后价(最新蜡烛在视区外)', () {
    testWidgets('offViewPriceLabelRect 即绘出的标签矩形, 命中区与标签重合', (tester) async {
      final candle = await mount(tester, _Candle());
      // 首帧以初值判定为视区内, 量出最新价宽度后切到最后价(见 paint_label_cache_test)。
      await paint(tester);
      final canvas = await paint(tester);

      final size = candle.offViewPriceLabelSize;
      expect(size, isNotNull, reason: '前置条件: 右侧留白不足以放下最新价, 画的是最后价');
      // 最后价有背景色, 装饰的填充走 drawRRect, 其外接矩形即标签 body。
      final body = canvas.rrectBounds.singleWhere((r) => r.size == size);
      final mark = candle.indicator.offViewPriceMark;
      expect(body.right, candle.chartRect.right + candle.latestPriceLabelOffsetX - mark.spacing);
      // 旧实现命中区顶边在最新价 dy, 比标签低半个标签高度。
      expect(candle.offViewPriceLabelRect, body);
    });

    testWidgets('handleTap: 命中标签回到初始位置, 标签外不消费', (tester) async {
      final candle = await mount(tester, _Candle());
      await paint(tester);
      await paint(tester);
      final hit = candle.offViewPriceLabelRect!;
      final margin = candle.indicator.offViewPriceMark.hitTestMargin;

      expect(candle.handleTap(hit.center), isTrue);
      expect(candle.handleTap(hit.topLeft.translate(-margin + 1, -margin + 1)), isTrue, reason: 'hitTestMargin 内');
      expect(candle.handleTap(hit.topLeft.translate(-margin - 1, 0)), isFalse);
      expect(candle.handleTap(Offset(hit.left, hit.bottom + margin + 1)), isFalse);
    });

    testWidgets('第二帧价格不变时复用 Paragraph', (tester) async {
      await mount(tester, _Candle());
      await paint(tester);
      final first = _paragraphs(await paint(tester));
      final second = _paragraphs(await paint(tester));
      expect(second, orderedEquals(first));
    });
  });

  group('最新价与倒计时(最新蜡烛在视区内)', () {
    /// 缩小最新价字号, 让 80px 的右侧留白放得下它, 停在视区内分支。
    _Candle smallLatest() {
      final mark = CandleIndicator().inViewPriceMark;
      return _Candle(
        showCountdown: true,
        inViewPriceMark: mark.copyWith(text: mark.text.copyWith(style: const TextStyle(fontSize: 6, height: 1))),
      );
    }

    /// 最新蜡烛的下次更新落在一分钟之后, 倒计时可见。
    List<CandleModel> live() {
      final now = DateTime.now().millisecondsSinceEpoch;
      return _alternating(latestTimestamp: now - now % 60000);
    }

    testWidgets('倒计时贴在最新价正下方, 与最新价同宽', (tester) async {
      final candle = await mount(tester, smallLatest(), candles: live());
      await paint(tester);
      final canvas = await paint(tester);
      expect(candle.offViewPriceLabelSize, isNull, reason: '前置条件: 停在视区内分支');

      final latestWidth = -candle.latestPriceLabelOffsetX - candle.indicator.inViewPriceMark.spacing;
      final right = candle.chartRect.right - candle.indicator.inViewPriceMark.spacing;
      final labels = canvas.rrectBounds.where((r) => (r.right - right).abs() < 0.01 && r.width == latestWidth);
      expect(labels, hasLength(2), reason: '最新价与倒计时两块填充');
      final [latest, countdown] = labels.toList();
      expect(countdown.top, latest.bottom);
      expect(countdown.left, latest.left);
    });

    testWidgets('同一秒内的第二帧, 最新价与倒计时都复用 Paragraph', (tester) async {
      await mount(tester, smallLatest(), candles: live());
      await paint(tester);
      // 倒计时以剩余整秒为 key: 两帧跨过秒边界时它理应重建, 重试到两帧落在同一秒。
      for (var attempt = 0; ; attempt++) {
        final before = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final first = _paragraphs(await paint(tester));
        final second = _paragraphs(await paint(tester));
        if (DateTime.now().millisecondsSinceEpoch ~/ 1000 != before && attempt < 3) continue;
        expect(second, orderedEquals(first));
        break;
      }
    });
  });

  group('批量蜡烛', () {
    List<Invocation> rawPoints(RecordingCanvas canvas) =>
        canvas.invocations.where((i) => i.memberName == #drawRawPoints).toList();

    testWidgets('实心: 涨跌影线与实体共 4 次 drawRawPoints, 实体线宽为 candleWidth、端帽 butt', (tester) async {
      final candle = await mount(tester, _Candle(chartType: FlexiChartType.barSolid));
      final canvas = await paint(tester);

      final calls = rawPoints(canvas);
      expect(calls, hasLength(4));
      final bodyLines = canvas.invocations.where(
        (i) => i.memberName == #drawLine && (i.positionalArguments[2] as Paint).strokeWidth == chart.candleWidth,
      );
      expect(bodyLines, isEmpty, reason: '实体不再逐根 drawLine');
      for (final call in calls) {
        expect(call.positionalArguments[0], PointMode.lines);
      }
      final visible = chart.klineData.end - chart.klineData.start;
      final bodies = calls.sublist(2);
      final bodySegments = bodies.fold<int>(0, (n, c) => n + (c.positionalArguments[1] as Float32List).length ~/ 4);
      expect(bodySegments, visible, reason: '每根可见蜡烛一段实体');
      for (final body in bodies) {
        final paint = body.positionalArguments[2] as Paint;
        expect(paint.strokeCap, StrokeCap.butt);
        expect(paint.strokeWidth, chart.candleWidth);
      }

      // 最新一根(上涨)的实体: 从 open 到 close, x 在蜡烛中心。
      final latest = chart.klineData.latest!;
      final long = bodies.first.positionalArguments[1] as Float32List;
      final dx = chart.startCandleDx - chart.candleWidthHalf;
      expect(long[0], closeTo(dx, 1e-3));
      expect(long[1], closeTo(candle.valueToDy(latest.open, correct: false), 1e-3));
      expect(long[3], closeTo(candle.valueToDy(latest.close, correct: false), 1e-3));
    });

    testWidgets('空心: 影线批量, 实体按涨跌各一条 Path 用空心画笔描边', (tester) async {
      await mount(tester, _Candle(chartType: FlexiChartType.barHollow));
      final canvas = await paint(tester);

      expect(rawPoints(canvas), hasLength(2), reason: '只有涨跌两批影线');
      // 只认画笔: Path 跨帧复用, 画完即 reset, 录制下来的实例此时已经清空。
      final hollow = canvas.invocations
          .where((i) => i.memberName == #drawPath)
          .where(
            (i) => (i.positionalArguments[1] as Paint).strokeWidth == chart.settingConfig.candleHollowBarBorderWidth,
          )
          .toList();
      expect(hollow, hasLength(2));
      final colors = {for (final i in hollow) (i.positionalArguments[1] as Paint).color.toARGB32()};
      expect(colors, {chart.theme.longColor.toARGB32(), chart.theme.shortColor.toARGB32()});
    });

    testWidgets('OHLC: 每根三段(影线 + 开盘左短线 + 收盘右短线), 按涨跌两批', (tester) async {
      await mount(tester, _Candle(chartType: FlexiChartType.barOhlc));
      final canvas = await paint(tester);

      final calls = rawPoints(canvas);
      expect(calls, hasLength(2));
      final visible = chart.klineData.end - chart.klineData.start;
      final segments = calls.fold<int>(0, (n, c) => n + (c.positionalArguments[1] as Float32List).length ~/ 4);
      expect(segments, visible * 3);
    });
  });
}
