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

/// `paintCandleLineChart` 的点列与填充区。
///
/// 折线在可见区两侧各多画一根，让线从视区外接入；填充区的底边取 chart 底边与最低点中更低的那个，
/// 视区外那根比可见区间更低时填充不会在底边处断开。
///
/// 覆盖层级：controller 挂载的 PaintObject 直接绘制到 [RecordingCanvas]。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'LINE-FILL', interval: FlexiTimeInterval(1, TimeUnit.minute));

final _key = directKey(0);

class _LineIndicator extends DirectIndicator {
  _LineIndicator() : super(key: _key, height: 100, padding: EdgeInsets.zero);

  _LinePaintObject? object;

  @override
  _LinePaintObject createPaintObject() => object = _LinePaintObject();
}

/// 区间取可见蜡烛的 high/low，视区外那根因此可能落在 chart 底边之下。
class _LinePaintObject extends DirectPaintObject<_LineIndicator> with PaintCandleChartMixin<_LineIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => klineData.calculateMinmax(start, end);

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

void main() {
  /// 价格随时间上行，平移到最新侧之外，使可见区两侧都还有蜡烛。
  Future<({FlexiKlineController chart, _LinePaintObject object})> arrange(WidgetTester tester) async {
    final indicator = _LineIndicator();
    final scene = ControllerScenario();
    addTearDown(scene.dispose);
    // 每根升幅大于蜡烛高低差, 视区外最旧那根的收盘价低于可见区间的最低价。
    final candles = genRampCandleList(count: 200, high: 3000, slope: 10);
    await scene.initWithData(_spec, candles, subIndicators: [indicator], canvasWidth: 400);
    final chart = scene.controller;
    chart.flushPendingKlineData();
    chart.showSubIndicator(_key);
    chart.onChartMove(Offset(chart.candleActualWidth * 40.5, 0));
    await paintChartFrame(tester, chart);
    final data = chart.klineData;
    expect(data.start, greaterThan(0), reason: '前置条件: 最旧侧有视区外的蜡烛');
    expect(data.end, lessThan(data.length), reason: '前置条件: 最新侧有视区外的蜡烛');
    return (chart: chart, object: indicator.object!);
  }

  const gradient = LinearGradient(colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)]);

  testWidgets('折线自左向右覆盖可见区及两侧各一根', (tester) async {
    final (:chart, :object) = await arrange(tester);
    final data = chart.klineData;
    final canvas = RecordingCanvas();

    object.paintCandleLineChart(canvas, linePaint: Paint());

    expect(canvas.countOf(#drawPath), 1, reason: '不传渐变时只画折线');
    final line = canvas.pathBounds.single;
    expect(line.left, closeTo(chart.indexToDx(data.start - 1), 1e-3));
    expect(line.right, closeTo(chart.indexToDx(data.end), 1e-3));
  });

  testWidgets('填充区底边下移到视区外更低的那根', (tester) async {
    final (:chart, :object) = await arrange(tester);
    final data = chart.klineData;
    final canvas = RecordingCanvas();
    final oldestDy = object.valueToDy(data[data.start - 1].close);
    expect(oldestDy, greaterThan(object.chartRect.bottom), reason: '前置条件: 视区外那根低于可见区间');

    object.paintCandleLineChart(canvas, linePaint: Paint(), gradient: gradient);

    expect(canvas.countOf(#drawPath), 2, reason: '折线 + 填充');
    final fill = canvas.pathBounds.last;
    expect(fill.bottom, closeTo(oldestDy, 1e-3));
    expect(fill.left, closeTo(chart.indexToDx(data.start - 1), 1e-3));
    expect(fill.right, closeTo(chart.indexToDx(data.end), 1e-3));
    // 底边是一条水平线: 最新侧 chart 底边之下的点也在填充区内。
    final fillPath = canvas.invocations.lastWhere((i) => i.memberName == #drawPath).positionalArguments[0] as Path;
    final belowBottom = (object.chartRect.bottom + oldestDy) / 2;
    expect(fillPath.contains(Offset(chart.indexToDx(data.end - 1), belowBottom)), isTrue);
  });
}
