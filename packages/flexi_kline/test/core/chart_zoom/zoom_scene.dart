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

/// Y 轴缩放用例的公共场景：恒定价量的蜡烛、贴主区右缘的滑竿、按区间端点读回价格。
///
/// 观察点取 `dyToCandleValue`（经蜡烛的映射反算区间端点）而非主区内部字段：它同时验证了
/// 缩放区间向 combine 子对象的下发链路，且是公开面。
///
/// 用 `testWidgets` 而非 `test`：`setChartZoomSlideBarRect` 走 `addPostFrameCallback`，
/// 不泵帧则滑竿区恒为 `Rect.zero`，`onChartZoomStart` 永远返回 false。
library;

import 'dart:math' as math;
import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/support.dart';

const zoomSpec = KlineSpec(symbol: 'CHART-ZOOM', interval: FlexiTimeInterval(1, TimeUnit.day));

/// 蜡烛价量恒定：high 110 / low 90，自动区间跨度 20、中点 100，断言可写精确值。
const autoMax = 110.0;
const autoMin = 90.0;
const autoSpan = autoMax - autoMin;
const autoCenter = (autoMax + autoMin) / 2;

/// 拖动距离：主区高 300，60px 足以产生可断言的系数又不贴边界。
const dragDy = 60.0;

/// 一格滚轮的缩放系数，按生产映射 `exp(-dy / signalScaleFactor)` 算出（默认因子 200）。
///
/// `dy = ±100` 是桌面端一格滚轮的常见量级。用真实量级而非人造大系数：本组要证明的是
/// 「用户实际能敲出的输入」能否脱困，凑一个够大的系数会把缺陷掩盖掉。
final wheelShrink = math.exp(-100 / 200);
final wheelExpand = math.exp(100 / 200);

/// 滑竿区宽 24、贴主区右缘、高度取整个主区，与生产实现（价格轴全高热区）同形。
Rect sliderRect(FlexiKlineController chart) => Rect.fromLTWH(
  chart.mainRect.right - 24,
  chart.mainRect.top,
  24,
  chart.mainRect.height,
);

/// 当前生效区间的上端：主图区顶边对应的价格。
double rangeMax(FlexiKlineController chart) {
  return chart.dyToCandleValue(chart.mainChartRect.top)!.toDouble();
}

/// 当前生效区间的下端：主图区底边对应的价格。
double rangeMin(FlexiKlineController chart) {
  return chart.dyToCandleValue(chart.mainChartRect.bottom)!.toDouble();
}

double rangeSpan(FlexiKlineController chart) => rangeMax(chart) - rangeMin(chart);

double rangeCenter(FlexiKlineController chart) => (rangeMax(chart) + rangeMin(chart)) / 2;

/// 建 controller、灌数据、启用 zoom 并把滑竿区泵到生效。
Future<ControllerScenario> arrange(WidgetTester tester) async {
  final scene = ControllerScenario();
  addTearDown(scene.dispose);
  await scene.initWithData(
    zoomSpec,
    genFlatCandleList(),
    canvasWidth: 400,
    candle: TestCandleIndicator(visibleMinMaxFromData: true),
  );
  scene.controller.flushPendingKlineData();
  scene.controller.updateGestureConfig(
    (config) => config.copyWith(enableZoom: true, useCustomZoomRect: true),
  );
  scene.controller.setChartZoomSlideBarRect(sliderRect(scene.controller));
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  expect(scene.controller.chartZoomSlideBarRect.isEmpty, isFalse, reason: '滑竿区必须已生效');
  return scene;
}

/// 驱动一帧绘制，让 `doUpdateVisibleMinMax` 走完一轮，并泵掉这一帧。
///
/// 必须泵帧：`calculatePaintChartRange` 会排一个 post-frame 回调去写 notifier，
/// 不泵掉它会活到本用例 dispose 之后，在下一个用例的首帧里炸「used after disposed」。
Future<void> paintFrame(WidgetTester tester, FlexiKlineController chart) async {
  final canvas = Canvas(PictureRecorder());
  chart.paintChart(canvas, chart.canvasRect.size);
  await tester.pump();
}

/// 在滑竿上按下并拖到 `起点 + [dy]`。
void dragSlider(FlexiKlineController chart, double dy) {
  final from = Offset(sliderRect(chart).center.dx, chart.mainRect.center.dy);
  expect(chart.onChartZoomStart(from), isTrue);
  chart.onChartZoomUpdate(from.dy + dy);
}

/// 一轮完整的触摸缩小手势：抓主图区底边拖到顶边，取到本轮最大压缩（系数 `1 / M`）。
///
/// 结尾调 [FlexiKlineController.onChartZoomEnd] 关闭会话，下一轮才会重新取快照——
/// 「多轮叠加」正是靠这一点，每轮的快照都是上一轮的缩放结果。
void fullShrinkGesture(FlexiKlineController chart) {
  final dx = sliderRect(chart).center.dx;
  final rect = chart.mainChartRect;
  final from = Offset(dx, rect.bottom);
  expect(chart.onChartZoomStart(from), isTrue);
  chart.onChartZoomUpdate(rect.top);
  chart.onChartZoomEnd();
}

/// [fullShrinkGesture] 的反向：抓顶边拖到底边，取到本轮最大放大（系数 `M`）。
void fullExpandGesture(FlexiKlineController chart) {
  final dx = sliderRect(chart).center.dx;
  final rect = chart.mainChartRect;
  final from = Offset(dx, rect.top);
  expect(chart.onChartZoomStart(from), isTrue);
  chart.onChartZoomUpdate(rect.bottom);
  chart.onChartZoomEnd();
}

/// 反复驱动 [step] 直到跨度不再变化，返回稳定后的跨度。
///
/// 判稳用**相对**差而非绝对差：无界实现下跨度会一路趋零，绝对差会在还在成倍变化时就
/// 误判为已稳定，让用例假绿。
Future<double> shrinkUntilStable(
  WidgetTester tester,
  FlexiKlineController chart,
  void Function() step,
) async {
  var span = rangeSpan(chart);
  for (var i = 0; i < 20; i++) {
    step();
    await paintFrame(tester, chart);
    final next = rangeSpan(chart);
    if ((next - span).abs() <= span.abs() * 1e-9) return next;
    span = next;
  }
  return span;
}
