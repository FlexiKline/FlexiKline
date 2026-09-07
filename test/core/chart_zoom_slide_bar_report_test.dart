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

/// zoom 滑竿热区的**自动**路径：绘制编排每帧从主区蜡烛拉取，见
/// `ChartBinding._syncChartZoomSlideBarRect`。
///
/// 现有 zoom 相关用例（`chart_zoom_test`、`gesture_owner_priority_test`、
/// `move_to_date_time_widget_test`）一律走 `useCustomZoomRect: true` 并显式调
/// `setChartZoomSlideBarRect` 注入热区，因此**不覆盖**这条自动路径。本文件守它的三件事：
/// 默认配置下一帧即生效、宿主接管时一次都不提交、稳定态不重复提交。
///
/// 蜡烛侧收敛出的宽度是否单调增长由 `framework/zoom_slide_bar_width_test` 守。
library;

import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'ZOOM-BAR-REPORT', interval: FlexiTimeInterval(1, TimeUnit.day));

void main() {
  /// 用 `testWidgets` 而非 `test`：提交走 `addPostFrameCallback`，不泵帧则热区恒为
  /// `Rect.zero`（与 `chart_zoom_test` 同一约束）。
  Future<ControllerScenario> arrange(WidgetTester tester) async {
    final scene = ControllerScenario();
    addTearDown(scene.dispose);
    await scene.initWithData(
      _spec,
      genFlatCandleList(),
      canvasWidth: 400,
      candle: TestCandleIndicator(visibleMinMaxFromData: true),
    );
    scene.controller.flushPendingKlineData();
    return scene;
  }

  /// 让提交落地。
  ///
  /// 提交走 `addPostFrameCallback`，而它本身不调度帧；`tester.pump()` 只在有帧已被调度时才
  /// 真跑一帧。所以这里显式排一帧，否则回调永不执行、热区恒为 `Rect.zero`。
  Future<void> pumpPostFrame(WidgetTester tester) async {
    tester.binding.scheduleFrame();
    await tester.pump();
  }

  /// 画一帧并让提交落地。
  Future<void> paintFrame(WidgetTester tester, FlexiKlineController chart) async {
    chart.paintChart(Canvas(PictureRecorder()), chart.canvasRect.size);
    await pumpPostFrame(tester);
  }

  testWidgets('默认配置下绘制一帧即拉取到 zoom 滑竿热区', (tester) async {
    final scene = await arrange(tester);

    // 不动 gestureConfig 与 settingConfig：拉取绑定在 `!useCustomZoomRect`（默认 false）
    // 与 `showYAxisTick`（默认 true）两个开关上，默认配置正是要守住的那条路径。
    expect(scene.controller.chartZoomSlideBarRect, Rect.zero, reason: '绘制前热区应为空');

    await paintFrame(tester, scene.controller);

    final rect = scene.controller.chartZoomSlideBarRect;
    expect(rect.isEmpty, isFalse, reason: '绘制后热区必须已生效，否则 zoom 手势整体失效');
    expect(rect.right, scene.controller.mainRect.right, reason: '热区贴主区右缘');
  });

  testWidgets('宿主接管热区(useCustomZoomRect): 拉取到的值一次都不提交', (tester) async {
    final scene = await arrange(tester);
    scene.controller.updateGestureConfig((config) => config.copyWith(useCustomZoomRect: true));

    await paintFrame(tester, scene.controller);
    await paintFrame(tester, scene.controller);

    // 蜡烛照常收敛宽度（见 framework/zoom_slide_bar_width_test），这里守的是它不落进 notifier。
    expect(scene.controller.chartZoomSlideBarRect, Rect.zero);
  });

  testWidgets('稳定态: 拉取端不重复提交', (tester) async {
    final scene = await arrange(tester);
    final chart = scene.controller;

    await paintFrame(tester, chart);
    final auto = chart.chartZoomSlideBarRect;
    expect(auto.isEmpty, isFalse, reason: '前置条件: 自动路径已提交过一次');

    // 数不到 post-frame 回调本身（没有公开 API），所以借一次外部写入当哨兵：注入一个与自动值
    // 不同的热区，稳定态若还提交就会把它盖回去。
    //
    // 哨兵只收窄、不平移：`setChartZoomSlideBarRect` 会把越出 `canvasRect` 的矩形整体挪回来，
    // 平移出去的哨兵会被挪成自动值本身，那样这条断言在两种实现下都成立、什么也守不住。
    final sentinel = Rect.fromLTRB(auto.left + 8, auto.top, auto.right, auto.bottom);
    chart.setChartZoomSlideBarRect(sentinel);
    await pumpPostFrame(tester);
    expect(chart.chartZoomSlideBarRect, sentinel, reason: '前置条件: 哨兵已生效');

    await paintFrame(tester, chart);
    await paintFrame(tester, chart);

    expect(chart.chartZoomSlideBarRect, sentinel, reason: '蜡烛交出的值没变, 不该再提交一次');
  });
}
