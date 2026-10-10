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

/// [CandlePaintObject] 的日期气泡: 状态、计时、生命周期与绘制位置。
///
/// 经 controller 的绘制入口驱动, 直接调 [CandlePaintObject.didMoveToDate] 与 [ChartBinding.onChartMove];
/// 不覆盖手势识别与 Widget 坐标转换。moveToDateTime 的接线见 `move_to_date_time_widget_test`。
// ignore_for_file: invalid_use_of_protected_member
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'DATE-MARK', interval: FlexiTimeInterval(1, TimeUnit.minute));
const _otherSpec = KlineSpec(symbol: 'DATE-MARK-OTHER', interval: FlexiTimeInterval(1, TimeUnit.minute));

/// 唯一的最高点下标: 其余蜡烛 high 都是 100, 上方有足够空间; 它贴近主区顶部, 上方放不下。
const _peak = 5;

/// 唯一的最低点下标: 其余蜡烛 low 都是 90, 下方有足够空间。
const _trough = 7;

const _timed = DateMarkConfig();

List<CandleModel> _candles({int count = 200}) => List.generate(
  count,
  (i) => CandleModel(
    timestamp: 12000000 - i * 60000,
    open: 95,
    high: i == _peak ? 110 : 100,
    low: i == _trough ? 80 : 90,
    close: 98,
    volume: 1000,
  ),
);

/// 默认 holdDuration 为 0: 不留 Timer, 只断言位置的用例不必等它到期; 计时类用例显式传入时长。
class _Candle extends CandleIndicator {
  _Candle({super.chartType, super.dateMark = const DateMarkConfig(holdDuration: 0)}) : super(showCountdown: false);

  late CandlePaintObject object;

  @override
  CandlePaintObject createPaintObject() => object = CandlePaintObject();
}

/// 覆写气泡内容, 记下每次构建收到的蜡烛 ts 与颜色。
class _CustomSpanCandle extends _Candle {
  final calls = <(int, Color)>[];

  @override
  CandlePaintObject createPaintObject() => object = _CustomSpanObject(calls);
}

class _CustomSpanObject extends CandlePaintObject {
  _CustomSpanObject(this.calls);

  final List<(int, Color)> calls;

  @override
  InlineSpan buildDateMarkSpan(FlexiCandleModel model, Color color) {
    calls.add((model.ts, color));
    return const TextSpan(text: 'custom');
  }
}

void main() {
  late FlexiKlineController chart;
  late _Candle indicator;

  Future<CandlePaintObject> mount(WidgetTester tester, _Candle candle) async {
    indicator = candle;
    chart = FlexiKlineController(configuration: FakeFlexiKlineConfiguration());
    addTearDown(chart.dispose);
    chart.switchKlineData(_spec);
    chart.replaceKlineData(_spec, _candles());
    chart.mountIndicators(candle: candle, time: TimeIndicator(), mainIndicators: const [], subIndicators: const []);
    chart.initState();
    chart.setAdaptLayoutMode(width: 400);
    chart.flushPendingKlineData();
    // 首帧算出可视区间与 Y 轴区间, 之后的坐标换算才可信。
    chart.paintChart(RecordingCanvas(), chart.canvasRect.size);
    await tester.pump();
    return candle.object;
  }

  RecordingCanvas paint() {
    final canvas = RecordingCanvas();
    chart.paintChart(canvas, chart.canvasRect.size);
    return canvas;
  }

  /// 气泡的填充路径: 只有它用 crossTextBg 填充(含箭头, 包围盒即「主体 + 箭头」)。
  List<Path> bubbles(RecordingCanvas canvas) => [
    for (final i in canvas.invocations)
      if (i.memberName == #drawPath &&
          (i.positionalArguments[1] as Paint).color.toARGB32() == chart.theme.crossTextBg.toARGB32())
        i.positionalArguments[0] as Path,
  ];

  int tsOf(int index) => chart.klineData[index].ts;
  double dxOf(int index) => chart.indexToCandleDx(index)!;

  group('绘制位置', () {
    testWidgets('默认放在 high 上方: 箭头尖端在蜡烛中心、high 上方 spacing 处', (tester) async {
      final candle = await mount(tester, _Candle());
      const index = 20;
      candle.didMoveToDate(tsOf(index));

      final bounds = bubbles(paint()).single.getBounds();
      final config = candle.indicator.dateMark;
      expect(bounds.bottom, closeTo(candle.valueToDy(chart.klineData[index].high) - config.spacing, 0.01));
      expect(bounds.center.dx, closeTo(dxOf(index), 0.01));
    });

    testWidgets('平移后气泡随蜡烛移动', (tester) async {
      final candle = await mount(tester, _Candle());
      const index = 20;
      candle.didMoveToDate(tsOf(index));
      final before = bubbles(paint()).single.getBounds();

      chart.onChartMove(const Offset(30, 0));
      final after = bubbles(paint()).single.getBounds();

      expect(after.center.dx, closeTo(dxOf(index), 0.01));
      expect(after.center.dx - before.center.dx, closeTo(30, 0.01));
    });

    testWidgets('贴近左边缘: 主体夹回 drawableRect 内, 箭头仍对准蜡烛', (tester) async {
      final candle = await mount(tester, _Candle());
      // 箭头只能落在直边上(圆角 + 半个根宽之外), 取离左边缘 15~30px 的蜡烛: 主体放不下、箭头够得着。
      final index = [
        for (var i = chart.klineData.start; i < chart.klineData.end; i++) i,
      ].firstWhere((i) => dxOf(i) > candle.drawableRect.left + 15 && dxOf(i) < candle.drawableRect.left + 30);
      candle.didMoveToDate(tsOf(index));

      final path = bubbles(paint()).single;
      final bounds = path.getBounds();
      expect(bounds.left, greaterThanOrEqualTo(candle.drawableRect.left - 0.01));
      expect(bounds.center.dx, greaterThan(dxOf(index)), reason: '前置条件: 主体被向右夹取');
      expect(path.contains(Offset(dxOf(index), bounds.bottom - 0.5)), isTrue, reason: '箭头尖端在蜡烛中心');
    });

    testWidgets('auto: 上方放不下时放到 low 下方', (tester) async {
      final candle = await mount(tester, _Candle());
      candle.didMoveToDate(tsOf(_peak));

      final bounds = bubbles(paint()).single.getBounds();
      final config = candle.indicator.dateMark;
      expect(bounds.top, closeTo(candle.valueToDy(chart.klineData[_peak].low) + config.spacing, 0.01));
    });

    testWidgets('above: 上方放不下时整体夹回 drawableRect, 不翻到下方', (tester) async {
      final candle = await mount(
        tester,
        _Candle(dateMark: const DateMarkConfig(holdDuration: 0, position: DateMarkPosition.above)),
      );
      candle.didMoveToDate(tsOf(_peak));

      final bounds = bubbles(paint()).single.getBounds();
      expect(bounds.top, closeTo(candle.drawableRect.top, 0.01));
      expect(bounds.bottom, lessThan(candle.valueToDy(chart.klineData[_peak].low)), reason: '没有翻到下方');
    });

    testWidgets('below: 上方有空间也放在 low 下方', (tester) async {
      final candle = await mount(
        tester,
        _Candle(dateMark: const DateMarkConfig(holdDuration: 0, position: DateMarkPosition.below)),
      );
      const index = 20;
      candle.didMoveToDate(tsOf(index));

      final bounds = bubbles(paint()).single.getBounds();
      final config = candle.indicator.dateMark;
      expect(bounds.top, closeTo(candle.valueToDy(chart.klineData[index].low) + config.spacing, 0.01));
    });

    testWidgets('线图: 锚点取 close', (tester) async {
      final candle = await mount(tester, _Candle(chartType: FlexiChartType.lineNormal));
      const index = 20;
      candle.didMoveToDate(tsOf(index));

      final bounds = bubbles(paint()).single.getBounds();
      final config = candle.indicator.dateMark;
      expect(bounds.bottom, closeTo(candle.valueToDy(chart.klineData[index].close) - config.spacing, 0.01));
    });

    testWidgets('目标蜡烛不在可视区时不画', (tester) async {
      final candle = await mount(tester, _Candle());
      candle.didMoveToDate(tsOf(chart.klineData.end + 10));

      expect(bubbles(paint()), isEmpty);
      expect(candle.dateMarkTs, isNotNull, reason: '状态保留, 移回可视区仍在计时内则再次出现');
    });

    testWidgets('最新蜡烛插入后仍指向同一根蜡烛(按 ts 锚定)', (tester) async {
      final candle = await mount(tester, _Candle());
      const index = 20;
      final ts = tsOf(index);
      candle.didMoveToDate(ts);

      chart.updateLatestKlineData(_spec, [
        CandleModel(timestamp: tsOf(0) + 60000, open: 95, high: 100, low: 90, close: 98, volume: 1000),
      ]);
      chart.flushPendingKlineData();
      await tester.pump();

      expect(tsOf(index + 1), ts, reason: '前置条件: 下标整体后移一位');
      final bounds = bubbles(paint()).single.getBounds();
      expect(bounds.center.dx, closeTo(dxOf(index + 1), 0.01));
    });

    testWidgets('子类覆写 buildDateMarkSpan 替换内容, 缓存命中时不重建', (tester) async {
      final candle = _CustomSpanCandle();
      final object = await mount(tester, candle);
      const index = 20;
      object.didMoveToDate(tsOf(index));
      paint();
      paint();

      expect(candle.calls, [(tsOf(index), chart.theme.crossTextColor)]);
    });
  });

  group('状态与计时', () {
    testWidgets('show 关闭时忽略', (tester) async {
      final candle = await mount(tester, _Candle(dateMark: const DateMarkConfig(show: false)));
      candle.didMoveToDate(tsOf(20));

      expect(candle.dateMarkTs, isNull);
      expect(bubbles(paint()), isEmpty);
    });

    testWidgets('显示时请求重绘; holdDuration 到期清空并再请求一次', (tester) async {
      final candle = await mount(tester, _Candle(dateMark: _timed));
      var repaints = 0;
      chart.repaintChart.addListener(() => repaints++);

      candle.didMoveToDate(tsOf(20));
      expect(repaints, 1, reason: 'moveToDateTime 返回时那一帧已画完, 必须再请求一帧');

      await tester.pump(const Duration(milliseconds: 1999));
      expect(candle.dateMarkTs, isNotNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect(candle.dateMarkTs, isNull);
      expect(repaints, 2);
    });

    testWidgets('再次显示替换目标并重新计时', (tester) async {
      final candle = await mount(tester, _Candle(dateMark: _timed));
      candle.didMoveToDate(tsOf(20));
      await tester.pump(const Duration(milliseconds: 1500));

      candle.didMoveToDate(tsOf(30));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(candle.dateMarkTs, tsOf(30), reason: '第一次的计时已被取消');

      await tester.pump(const Duration(milliseconds: 500));
      expect(candle.dateMarkTs, isNull);
    });

    testWidgets('holdDuration 为 0 时一直显示', (tester) async {
      final candle = await mount(tester, _Candle(dateMark: const DateMarkConfig(holdDuration: 0)));
      candle.didMoveToDate(tsOf(20));

      await tester.pump(const Duration(seconds: 10));
      expect(candle.dateMarkTs, tsOf(20));
    });

    testWidgets('切换标的时清空', (tester) async {
      final candle = await mount(tester, _Candle(dateMark: _timed));
      candle.didMoveToDate(tsOf(20));

      chart.switchKlineData(_otherSpec);
      expect(candle.dateMarkTs, isNull);
      // 清空同时取消计时, 否则用例结束时报「Timer 仍未完成」。
    });

    testWidgets('运行时关闭 show 时清空', (tester) async {
      final candle = await mount(tester, _Candle(dateMark: _timed));
      candle.didMoveToDate(tsOf(20));

      final time = TimeIndicator();
      chart.updateIndicators(
        oldCandle: indicator,
        newCandle: _Candle(dateMark: const DateMarkConfig(show: false)),
        oldTime: time,
        newTime: time,
        oldMainIndicators: const [],
        newMainIndicators: const [],
        oldSubIndicators: const [],
        newSubIndicators: const [],
      );
      expect(candle.dateMarkTs, isNull);
    });

    testWidgets('dispose 取消计时', (tester) async {
      final candle = await mount(tester, _Candle(dateMark: _timed));
      candle.didMoveToDate(tsOf(20));

      candle.dispose();
      // 未取消时 Timer 仍挂着, 用例结束时 flutter_test 会报「Timer 仍未完成」(teardown 的 chart.dispose 在那之后)。
    });
  });
}
