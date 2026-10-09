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

/// 设计 v2 U1: 平移、缩放、cross 轨迹下核心标签缓存的命中率, 用来定 LabelPainter 容量。
///
/// - 整体命中: 本帧 drawParagraph 收到的 Paragraph 在此前帧出现过即算命中(换文本或重建都会生成新 Paragraph);
/// - 淘汰: Y 刻度与时间刻度经可覆写的格式器计数, 同一 key 在 [_window] 帧内再次格式化, 说明它被挤出过池子;
/// - 同屏数: 时间轴区域内、Y 轴右侧的段落数, 与容量 16 对照。
///
/// 只打印读数, 无业务断言。
@Tags(['exploration'])
library;

import 'dart:ui' show Paragraph;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'LABEL-HIT-RATE', interval: FlexiTimeInterval(1, TimeUnit.minute));
const _frames = 300;
const _window = 30;

/// 记录格式化的 key 与帧号, 统计窗口内的重复格式化。
class _Misses {
  int frame = 0;
  int count = 0;
  int evicted = 0;
  final Map<Object, int> _last = {};

  void hit(Object key) {
    count++;
    final last = _last[key];
    if (last != null && frame - last <= _window) evicted++;
    _last[key] = frame;
  }
}

final _yTicks = _Misses();
final _timeTicks = _Misses();

class _Candle extends CandleIndicator {
  _Candle();

  @override
  CandlePaintObject createPaintObject() => _CandleObject();
}

class _CandleObject extends CandlePaintObject<_Candle> {
  @override
  String formatTicksValue(FlexiNum value, {required int precision}) {
    _yTicks.hit((value, precision));
    return super.formatTicksValue(value, precision: precision);
  }
}

class _Time extends TimeIndicator {
  _Time();

  @override
  TimePaintObject createPaintObject() => _TimeObject();
}

class _TimeObject extends TimePaintObject<_Time> {
  @override
  String formatTimeLabel(FlexiCandleModel model, ITimeInterval interval) {
    _timeTicks.hit(model.ts);
    return super.formatTimeLabel(model, interval);
  }
}

void main() {
  late FlexiKlineController chart;

  setUp(() {
    _yTicks
      ..frame = 0
      ..count = 0
      ..evicted = 0
      .._last.clear();
    _timeTicks
      ..frame = 0
      ..count = 0
      ..evicted = 0
      .._last.clear();
    chart = FlexiKlineController(configuration: FakeFlexiKlineConfiguration());
    chart.switchKlineData(_spec);
    chart.replaceKlineData(_spec, genRampCandleList(count: 500, high: 1000, spread: 14, slope: 0.5));
    chart.mountIndicators(candle: _Candle(), time: _Time(), mainIndicators: const [], subIndicators: const []);
    chart.initState();
    chart.setAdaptLayoutMode(width: 400);
    chart.flushPendingKlineData();
  });

  tearDown(() => chart.dispose());

  Future<void> run(WidgetTester tester, String label, void Function(int i, RecordingCanvas canvas) frame) async {
    // 预热两帧: 首帧用初值判断最新价是否在视区内, 不计入。
    for (var i = 0; i < 2; i++) {
      frame(-1, RecordingCanvas());
      await tester.pump();
    }
    _yTicks
      ..count = 0
      ..evicted = 0;
    _timeTicks
      ..count = 0
      ..evicted = 0;

    final seen = Set<Paragraph>.identity();
    var drawn = 0, created = 0, maxTime = 0, maxYTicks = 0;
    for (var i = 0; i < _frames; i++) {
      _yTicks.frame = _timeTicks.frame = i;
      final canvas = RecordingCanvas();
      frame(i, canvas);
      await tester.pump();

      final timeRect = chart.timeRect;
      var time = 0, yTicks = 0;
      final paragraphs = [
        for (final call in canvas.invocations)
          if (call.memberName == #drawParagraph) call.positionalArguments[0] as Paragraph,
      ];
      for (final (j, offset) in canvas.paragraphOffsets.indexed) {
        if (timeRect.contains(offset)) {
          time++;
        } else if (offset.dx + paragraphs[j].width >= chart.mainRect.right - 1) {
          yTicks++;
        }
      }
      if (time > maxTime) maxTime = time;
      if (yTicks > maxYTicks) maxYTicks = yTicks;
      for (final p in paragraphs) {
        drawn++;
        if (seen.add(p)) created++;
      }
    }

    String rate(int misses, int total) => total == 0 ? '-' : '${(100 * (1 - misses / total)).toStringAsFixed(1)}%';
    debugPrint(
      'label_hit_rate[$label]: paragraphs $drawn, hit ${rate(created, drawn)}; '
      'yTicks miss ${_yTicks.count} (evicted ${_yTicks.evicted}, max on screen $maxYTicks); '
      'time miss ${_timeTicks.count} (evicted ${_timeTicks.evicted}, max on screen $maxTime)',
    );
  }

  void paintChart(RecordingCanvas canvas) {
    final size = chart.canvasRect.size;
    chart.paintChart(canvas, size);
    chart.paintDraw(canvas, size);
  }

  testWidgets('pan ±3px, 50 帧换向', (tester) async {
    await run(tester, 'pan', (i, canvas) {
      if (i >= 0) chart.onChartMove(Offset((i ~/ 50).isEven ? 3 : -3, 0));
      paintChart(canvas);
    });
  });

  testWidgets('zoom 2%/帧, 在 [2, 14] 来回', (tester) async {
    var zoomIn = false;
    await run(tester, 'zoom', (i, canvas) {
      if (i >= 0) {
        if (chart.candleWidth <= 2.2) zoomIn = true;
        if (chart.candleWidth >= 14) zoomIn = false;
        chart.onChartScaleTo(zoomIn ? 1.02 : 0.98, position: ScalePosition.right, focalDx: 0);
      }
      paintChart(canvas);
    });
  });

  for (final fast in const [false, true]) {
    testWidgets('cross ${fast ? 'fast' : 'slow'}', (tester) async {
      chart.paintChart(RecordingCanvas(), chart.canvasRect.size);
      chart.onCrossToggle(chart.mainRect.center);
      await run(tester, 'cross ${fast ? 'fast' : 'slow'}', (i, canvas) {
        final rect = chart.mainRect;
        final step = fast ? chart.candleActualWidth : 1.0;
        final n = i < 0 ? 0 : i;
        chart.onCrossUpdate(Offset(rect.left + 40 + (n % 40) * step, rect.top + 40 + (n % 60)));
        chart.paintCross(canvas, chart.canvasRect.size);
      });
    });
  }
}
