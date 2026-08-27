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

/// Widget 级图表测试的公共步骤。
///
/// 只收敛各用例逐字相同的原子操作(建 controller、泵到就绪、卸载收尾)。
/// widget 树本身各用例差异实质, 仍由用例自己搭建。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart' show DeviceGestureSettings, kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../doubles/fake_kline_config.dart';
import '../doubles/test_draw_object.dart';
import '../doubles/test_indicators.dart';

/// Widget 测试默认的主图尺寸。
const defaultChartMainSize = Size(400, 300);

/// 以固定主图尺寸创建 controller。
///
/// widget 测试依赖确定的画布几何做位置断言, 因此统一给出 [mainIndicatorDefaultSize]。
FlexiKlineController createChartController({
  Size mainIndicatorDefaultSize = defaultChartMainSize,
  FlexiLayoutMode initialLayoutMode = FlexiLayoutMode.adapt,
  Size? initialFixedSize,
}) {
  return FlexiKlineController(
    configuration: FakeFlexiKlineConfiguration(
      mainIndicatorDefaultSize: mainIndicatorDefaultSize,
    ),
    initialLayoutMode: initialLayoutMode,
    initialFixedSize: initialFixedSize,
  );
}

/// 泵帧直到 [condition] 成立, 超出 [maxFrames] 则以 [description] 失败。
///
/// 超时必须 fail: 静默放行会让"布局未就绪"和"断言不成立"产生同一种报错。
Future<void> pumpUntilChart(
  WidgetTester tester,
  bool Function() condition,
  String description, {
  int maxFrames = 200,
  Duration frameInterval = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < maxFrames; i++) {
    if (condition()) return;
    await tester.pump(frameInterval);
  }
  fail('Timed out waiting for $description');
}

/// 卸载图表、抽干 controller 的收尾 timer, 然后 dispose。
///
/// 先卸载再泵一段时间: 否则 dispose 时仍在飞的 timer 会让测试报未完成的 Timer。
Future<void> disposeChart(
  WidgetTester tester,
  FlexiKlineController controller,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 200));
  controller.dispose();
}

/// 把图表嵌进可垂直滚动的 [ListView], 返回图表与观测外层滚动的 [ScrollController]。
///
/// 手势竞技场的用例必须跑在真实可滚动容器里: 单指拖动的接受阈值恒为外层 Scrollable
/// hitSlop 的两倍([DeviceGestureSettings.panSlop] 是 `touchSlop * 2` 的派生 getter),
/// 只有外层在场才测得出"谁先赢"。
///
/// [touchSlop] 非空时在图表子树外覆盖 `gestureSettings`, 用于模拟 Android 真机上小于
/// [kTouchSlop] 的平台值 —— 外层 Scrollable 与图表读同一份设置。
Future<({FlexiKlineController chart, ScrollController scroll})> pumpChartInListView(
  WidgetTester tester, {
  required KlineSpec spec,
  required List<CandleModel> candles,
  List<Indicator> mainIndicators = const [],
  double? touchSlop,
  bool enableDraw = false,
  Size chartSize = const Size(400, 480),
  double fillerHeight = 800,
}) async {
  final chart = createChartController();
  chart.switchKlineData(spec);
  chart.replaceKlineData(spec, candles);
  if (enableDraw) {
    registerTestDrawObject(chart);
    chart.setDrawVisible(true);
  }
  final scroll = ScrollController();
  addTearDown(scroll.dispose);

  Widget wrapGestureSettings(BuildContext context, Widget child) {
    if (touchSlop == null) return child;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        gestureSettings: DeviceGestureSettings(touchSlop: touchSlop),
      ),
      child: child,
    );
  }

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => wrapGestureSettings(
          context,
          ListView(
            controller: scroll,
            children: [
              SizedBox(
                width: chartSize.width,
                height: chartSize.height,
                child: FlexiKlineWidget(
                  controller: chart,
                  candle: TestCandleIndicator(),
                  time: TestTimeIndicator(),
                  mainIndicators: mainIndicators,
                  isTouchDevice: true,
                ),
              ),
              SizedBox(height: fillerHeight),
            ],
          ),
        ),
      ),
    ),
  );
  await pumpUntilChart(
    tester,
    () => chart.isMounted && chart.mainChartWidth > 0 && chart.klineData.isNotEmpty,
    'chart data and layout',
  );
  return (chart: chart, scroll: scroll);
}

/// 把图表局部坐标换算为全局坐标。
///
/// 手势 API 只接受全局坐标, 而命中区、绘制点、canvasRect 全部是图表局部坐标。
Offset toChartGlobal(WidgetTester tester, Offset local) {
  final box = tester.renderObject<RenderBox>(find.byKey(const ValueKey('TouchListener')));
  return box.localToGlobal(local);
}
