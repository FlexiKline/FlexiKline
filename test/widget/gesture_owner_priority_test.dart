// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// zoom 族不得截走已进入模式的手势（design.md 决策 8）。
///
/// `touch_gesture_owner_test.dart` 已按落点逐条钉住判定顺序，本文件补的是端到端那一段：
/// 判定顺序对了，驱动是否也真的落在预期的业务上。真机反馈的困惑正是在这一层观察到的
/// ——十字线已显示，拖动却把整个图表拖走，十字线反而不动。
///
/// 放大器是 `chartZoomSlideBarRect`：价格轴那一整条全高隐形热区，与其余落点大面积重叠。
///
/// 曾有第二条放大器——`isChartZooming` 是粘性状态、而 `zoomingMove` 的领地是整个 `mainRect`，
/// 调过一次留白之后主区内任何单指拖动都归它。该归属已随「Y 轴缩放作用于可见价格区间」一并
/// 删除：模式状态不再在归属层表达，zoom 态下的拖动与普通平移同归 `chartPan`。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'GESTURE-PRIORITY',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

/// 宿主自定义的滑竿区：贴主图右侧，与 [_modePosition] 不重叠。
///
/// 用自定义区而不是让蜡烛指标自动上报，是为了不与自动上报争同一个字段——自动上报每帧都会
/// 按最宽刻度文本重算。
const _sliderRect = Rect.fromLTWH(340, 20, 40, 200);

/// 进入模式后发起拖动的落点：在主区内、滑竿区外、无任何可拖对象。
const _modePosition = Offset(150, 150);

/// 单步位移：小于 touchSlop，让抢占发生在累计位移越过阈值的那一步。
const _step = Offset(5, 0);

/// 建图表、启用 zoom、自定义滑竿区，并把图表推进到「已在 zoom 模式」。
///
/// zoom 模式一旦进入就是粘性的：`onChartZoomEnd` 只在本轮未产生任何缩放时才退出，否则要靠
/// 那个浮动按钮。所以这就是用户调过一次 Y 轴缩放之后的常驻状态。
Future<FlexiKlineController> _arrangeZooming(WidgetTester tester) async {
  final scene = await pumpChartInListView(
    tester,
    spec: _spec,
    candles: genFlatCandleList(),
    // onChartZoomStart 要求已有可见价格区间: 没有区间可缩放时不进入缩放态。
    candle: TestCandleIndicator(visibleMinMaxFromData: true),
  );
  addTearDown(() => disposeChart(tester, scene.chart));
  final chart = scene.chart;

  chart.updateGestureConfig(
    (config) => config.copyWith(enableZoom: true, useCustomZoomRect: true),
  );
  chart.setChartZoomSlideBarRect(_sliderRect);
  await tester.pump();
  expect(chart.chartZoomSlideBarRect, isNot(Rect.zero), reason: '前置条件: 滑竿区必须已生效');

  expect(chart.onChartZoomStart(_sliderRect.center), isTrue);
  expect(chart.isChartZooming, isTrue, reason: '前置条件: 必须已进入 zoom 模式');
  return chart;
}

void main() {
  testWidgets('zoom 模式下 crossing 拖动 => 移动十字线, 不移动图表', (tester) async {
    final chart = await _arrangeZooming(tester);
    expect(chart.onCrossStart(GestureData.tap(_modePosition)), isTrue);
    final crossBefore = chart.crossOffset;
    final panBefore = chart.paintDxOffset;
    expect(crossBefore, isNotNull, reason: '前置条件: 必须已显示十字线');

    final gesture = await tester.startGesture(
      toChartGlobal(tester, _modePosition),
      pointer: 1,
      kind: PointerDeviceKind.touch,
    );
    final at = await movePointers(tester, [gesture], unit: _step, steps: 6);

    expect(chart.crossOffset, isNot(crossBefore), reason: 'crossing 中的拖动应移动十字线');
    expect(
      chart.paintDxOffset,
      panBefore,
      reason: 'zoom 族抢在 cross 之前会把图表拖走, 十字线反而一动不动',
    );

    await gesture.up(timeStamp: at);
    await tester.pump(chartGestureSettle);
  });

  testWidgets('退出模式后 zoom 态的图表移动仍正常', (tester) async {
    final chart = await _arrangeZooming(tester);
    final panBefore = chart.paintDxOffset;

    // 正向护栏: 降级不能让 zoom 态的主区拖动变成永不可达。
    final gesture = await tester.startGesture(
      toChartGlobal(tester, _modePosition),
      pointer: 1,
      kind: PointerDeviceKind.touch,
    );
    final at = await movePointers(tester, [gesture], unit: _step, steps: 6);

    expect(chart.paintDxOffset, isNot(panBefore), reason: '无人认领时应归兜底 chartPan');

    await gesture.up(timeStamp: at);
    await tester.pump(chartGestureSettle);
  });
}
