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

/// 绘制开销的确定性计数: 不计时, 进普通测试门禁, 守住 painting 层的三条结构性收益。
///
/// 只覆盖 controller 绘制入口(RecordingCanvas 记录 Dart 侧的 Canvas 调用), 不覆盖 raster 线程、
/// 手势与 Widget 层。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'PAINT-COUNT', interval: FlexiTimeInterval(1, TimeUnit.minute));

class _SpyResource implements PaintResource {
  int disposed = 0;

  @override
  void reset() {}

  @override
  void dispose() => disposed++;
}

class _OwningIndicator extends DirectIndicator {
  _OwningIndicator()
    : super(
        key: const DirectIndicatorKey('owning'),
        height: 60,
        padding: EdgeInsets.zero,
        autoActivate: true,
      );

  final resource = _SpyResource();

  @override
  DirectPaintObject<DirectIndicator> createPaintObject() => _OwningPaintObject();
}

class _OwningPaintObject extends DirectPaintObject<_OwningIndicator> {
  late final _resource = own(indicator.resource);

  @override
  MinMax? computeVisibleMinMax(int start, int end) => klineData.calculateMinmax(start, end);

  /// 首次绘制时登记; 替身的 reset 是空操作, 只为触发 late 初始化。
  @override
  void paint(Canvas canvas, Size size) => _resource.reset();

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

int _drawCalls(RecordingCanvas canvas) =>
    canvas.invocations.where((i) => i.memberName.toString().startsWith('Symbol("draw')).length;

void main() {
  late FlexiKlineController chart;

  void mount({List<Indicator> subIndicators = const [], List<CandleModel>? candles}) {
    chart = FlexiKlineController(configuration: FakeFlexiKlineConfiguration());
    chart.switchKlineData(_spec);
    chart.replaceKlineData(_spec, candles ?? genRampCandleList(count: 1000, high: 1000, spread: 14, slope: 0.5));
    chart.mountIndicators(
      candle: CandleIndicator(showCountdown: false),
      time: TimeIndicator(),
      mainIndicators: const [],
      subIndicators: subIndicators,
    );
    chart.initState();
    chart.setAdaptLayoutMode(width: 400);
    chart.flushPendingKlineData();
  }

  Future<RecordingCanvas> paintChart(WidgetTester tester) async {
    final canvas = RecordingCanvas();
    chart.paintChart(canvas, chart.canvasRect.size);
    await tester.pump();
    return canvas;
  }

  int visibleCandles() => chart.klineData.end - chart.klineData.start;

  testWidgets('可见根数增加 10 倍, Canvas 绘制调用数不变', (tester) async {
    mount();
    await paintChart(tester);
    final few = visibleCandles();
    final fewCanvas = await paintChart(tester);

    chart.onChartScaleTo(0.1, position: ScalePosition.right, focalDx: 0);
    await paintChart(tester);
    final many = visibleCandles();
    final manyCanvas = await paintChart(tester);

    expect(many, greaterThanOrEqualTo(few * 5), reason: '前置条件: 缩小后可见根数显著增加($few -> $many)');
    expect(manyCanvas.countOf(#drawRawPoints), fewCanvas.countOf(#drawRawPoints));
    expect(_drawCalls(manyCanvas), _drawCalls(fewCanvas), reason: '几何应按画笔批量绘制, 不随根数增长');
    chart.dispose();
  });

  testWidgets('不跨刻度的 1px 平移: 本帧没有任何标签重新排版', (tester) async {
    // 价格恒定: 平移不改变 minMax, Y 刻度与最高最低价逐帧相同。
    mount(candles: genFlatCandleList());
    // 首帧用初值判断最新价是否在视区内, 第二帧起才用实测宽度; 跳过这次切换。
    await paintChart(tester);
    await paintChart(tester);

    TextLayoutCache.debugMissCount = 0;
    chart.onChartMove(const Offset(1, 0));
    final canvas = await paintChart(tester);

    expect(canvas.countOf(#drawParagraph), greaterThan(5), reason: '前置条件: 这一帧确实画了一批标签');
    expect(TextLayoutCache.debugMissCount, 0);
    chart.dispose();
  });

  testWidgets('controller dispose 后 own() 登记的资源被释放', (tester) async {
    final owning = _OwningIndicator();
    mount(subIndicators: [owning]);
    await paintChart(tester);
    expect(owning.resource.disposed, 0);

    chart.dispose();
    expect(owning.resource.disposed, 1);
  });
}
