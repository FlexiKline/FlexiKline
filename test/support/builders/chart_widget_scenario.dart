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
import 'package:flutter/gestures.dart' show DeviceGestureSettings, PointerDeviceKind, kTouchSlop;
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
///
/// [isTouchDevice] 置 false 挂非触摸 detector, 用于验证 signal 通道与外层滚动的竞争。
/// 注意 Listener 的 key 随之变成 `NonTouchListener`, 取全局坐标要用 [toNonTouchChartGlobal]。
Future<({FlexiKlineController chart, ScrollController scroll})> pumpChartInListView(
  WidgetTester tester, {
  required KlineSpec spec,
  required List<CandleModel> candles,
  List<Indicator> mainIndicators = const [],
  double? touchSlop,
  bool enableDraw = false,
  Size chartSize = const Size(400, 480),
  double fillerHeight = 800,
  TestCandleIndicator? candle,
  bool isTouchDevice = true,
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
                  candle: candle ?? TestCandleIndicator(),
                  time: TestTimeIndicator(),
                  mainIndicators: mainIndicators,
                  isTouchDevice: isTouchDevice,
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

/// [toChartGlobal] 的非触摸端版本: 两端 detector 的 [Listener] key 不同。
Offset toNonTouchChartGlobal(WidgetTester tester, Offset local) {
  final box = tester.renderObject<RenderBox>(find.byKey(const ValueKey('NonTouchListener')));
  return box.localToGlobal(local);
}

/// 一帧的时长。循环移动必须按帧推进时钟，零时长 `pump()` 会把 `throttleOnFps` 的 timer
/// 全部积压到手势结束之后，测试以「A Timer is still pending」失败。
const chartGestureFrame = Duration(milliseconds: 16);

/// 手势收尾时长：`unaryThrottle` 的尾调用会再起一轮 timer，需要留两个周期。
const chartGestureSettle = Duration(milliseconds: 60);

/// 在图表局部坐标 [center] 两侧各落一指，沿 [axis] 排列、间距 `2 × spreadHalf`。
///
/// 返回 (第一指, 第二指)，前者在 [axis] 负方向（左 / 上），后者在正方向（右 / 下）。
///
/// [axis] 必须可选：纵向捏合与横向捏合走的抢占路径不同（外层可滚动容器只累加纵向分量），
/// 只支持横向排列就测不出「纵向捏合被外层抢走」。
///
/// pointer id 显式给出而不交给自动分配：多指用例常要在中途单独抬起或取消某一指，
/// 断言依赖「哪一指是第一指」。
Future<(TestGesture, TestGesture)> startTwoFingers(
  WidgetTester tester, {
  required Offset center,
  Axis axis = Axis.horizontal,
  double spreadHalf = 40,
  int firstPointer = 1,
  int secondPointer = 2,
}) async {
  final spread = axis == Axis.horizontal ? Offset(spreadHalf, 0) : Offset(0, spreadHalf);
  final first = await tester.startGesture(
    toChartGlobal(tester, center - spread),
    pointer: firstPointer,
    kind: PointerDeviceKind.touch,
  );
  final second = await tester.startGesture(
    toChartGlobal(tester, center + spread),
    pointer: secondPointer,
    kind: PointerDeviceKind.touch,
  );
  await tester.pump(chartGestureFrame);
  return (first, second);
}

/// 让 [gestures] 同向移动 [steps] 步，每步位移 [unit]，逐帧推进，返回最后一个事件的时间戳。
///
/// [since] 是本段起始时间戳，同一手势分多段移动时必须把上一段的返回值传进来。
///
/// **必须显式给时间戳**：[TestGesture.moveBy] 的 `timeStamp` 默认恒为 `Duration.zero`，
/// 而 [VelocityTracker] 按事件时间戳算速度——不传就永远算不出抬手速度，惯性平移不会启动，
/// 于是任何断言「不惯性」的用例都会假通过。
///
/// 反向张开一类「各指位移不同」的场景不走这里：多一个 per-gesture 位移参数只为一两个用例
/// 服务，用例自己写循环更直白。
Future<Duration> movePointers(
  WidgetTester tester,
  List<TestGesture> gestures, {
  required Offset unit,
  required int steps,
  Duration since = Duration.zero,
}) async {
  var at = since;
  for (var i = 0; i < steps; i++) {
    at += chartGestureFrame;
    for (final gesture in gestures) {
      await gesture.moveBy(unit, timeStamp: at);
    }
    await tester.pump(chartGestureFrame);
  }
  return at;
}
