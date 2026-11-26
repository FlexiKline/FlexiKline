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

/// 主区 tips 区高度在绘制期变化后, Chart 图层在帧后补绘一次。
///
/// 覆盖层级：controller 的 `paintChart` / `paintCross` 与帧后回调。
/// 不覆盖：真实 Widget 树中补绘后的画面。
@TestOn('vm')
library;

import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'TIPS-AREA', interval: FlexiTimeInterval(1, TimeUnit.minute));

void main() {
  late ControllerScenario scene;
  late FlexiKlineController chart;
  var repaints = 0;

  Future<void> arrange({bool disposeOnTearDown = true}) async {
    scene = ControllerScenario(
      config: FakeFlexiKlineConfiguration(mainChildren: {directKey(0)}, drawBelowTipsArea: true),
    );
    if (disposeOnTearDown) addTearDown(scene.dispose);
    // 前半段 close 为 50(tips 一行), 后半段为 150(两行); 最新一根是两行。
    final candles = genCandleList(
      count: 50,
      ohlc: (i) {
        final close = i < 25 ? 50 : 150;
        return (open: close, high: close, low: close, close: close);
      },
    );
    await scene.initWithData(_spec, candles, mainIndicators: [_RowIndicator(key: directKey(0))], canvasWidth: 400);
    chart = scene.controller;
    chart.flushPendingKlineData();
    repaints = 0;
    chart.repaintChart.addListener(() => repaints++);
  }

  void paintChart() => chart.paintChart(Canvas(PictureRecorder()), chart.canvasRect.size);
  void paintCross() => chart.paintCross(Canvas(PictureRecorder()), chart.canvasRect.size);

  /// 显式排一帧再泵: 没有 Widget 树时单纯 pump 不会执行帧后回调。
  Future<void> flushFrame(WidgetTester tester) async {
    tester.binding.scheduleFrame();
    await tester.pump();
  }

  testWidgets('chart 图层 tips 区变化后帧后补绘一次, 稳定后不再补绘', (tester) async {
    await arrange();

    paintChart();
    await flushFrame(tester);
    expect(repaints, 1, reason: '首帧让出 tips 区, 本帧网格线按旧几何画出');

    paintChart();
    await flushFrame(tester);
    paintChart();
    await flushFrame(tester);
    expect(repaints, 1, reason: 'tips 区不变时不补绘, 不形成重绘循环');
  });

  testWidgets('cross 改写 tips 区时补绘 chart 图层', (tester) async {
    await arrange();
    paintChart();
    await flushFrame(tester);
    // combine 子对象与主区共享 chartRect。
    final candle = scene.candle.object!;
    final chartTop = candle.chartRect.top;

    chart.onCrossFollow(Offset(chart.indexToDx(5), chart.mainRect.center.dy));
    final opened = repaints;

    paintCross();
    await flushFrame(tester);
    expect(candle.chartRect.top, lessThan(chartTop), reason: '十字线所在蜡烛的 tips 只有一行');
    expect(repaints, opened + 1, reason: 'chart 图层按两行 tips 的几何画出, 不补绘时价格标签与画面错位');

    paintCross();
    await flushFrame(tester);
    expect(repaints, opened + 1, reason: '同一蜡烛上重绘 cross 不改变 tips 区');
  });

  testWidgets('dispose 后帧后回调不写已销毁的 notifier', (tester) async {
    await arrange(disposeOnTearDown: false);
    paintChart();
    scene.dispose();

    await flushFrame(tester);
    expect(tester.takeException(), isNull);
    expect(repaints, 0);
  });
}

/// close >= 100 时 tips 折成两行, 否则一行, 模拟数值位数不同导致换行数变化。
class _RowIndicator extends DirectIndicator {
  _RowIndicator({required super.key}) : super(height: 100, autoActivate: false, padding: EdgeInsets.zero);

  @override
  DirectPaintObject<DirectIndicator> createPaintObject() => _RowObject();
}

class _RowObject extends DirectPaintObject<_RowIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size, {required int start, required int end}) {}
  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) {
    if (model == null) return null;
    return Size(tipsRect?.width ?? 0, model.close >= 100 ? 24 : 12);
  }
}
