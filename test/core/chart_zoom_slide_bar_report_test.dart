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

/// zoom 滑竿热区的**自动**上报路径：由主区 Y 轴刻度文本的实测宽度反推。
///
/// 现有 zoom 相关用例（`chart_zoom_test`、`gesture_owner_priority_test`、
/// `move_to_date_time_widget_test`）一律走 `useCustomZoomRect: true` 并显式调
/// `setChartZoomSlideBarRect` 注入热区，因此**不覆盖**这条自动路径——上报点搬家不会
/// 让它们变红。本用例补上这个空白：默认配置下只驱动一帧绘制，热区必须自行生效。
///
/// 上报由 `CandleBasePaintObject.paintYAxisTickLabels` 发起，而它由
/// `MainPaintObject.doPaintChart` 在遍历子对象之后调用。移除那一行调用，本用例即失败。
library;

import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'ZOOM-BAR-REPORT', interval: FlexiTimeInterval(1, TimeUnit.day));

void main() {
  /// 用 `testWidgets` 而非 `test`：上报走 `addPostFrameCallback`，不泵帧则热区恒为
  /// `Rect.zero`（与 `chart_zoom_test` 同一约束）。
  testWidgets('默认配置下绘制一帧即自动上报 zoom 滑竿热区', (tester) async {
    final scene = ControllerScenario();
    addTearDown(scene.dispose);
    await scene.initWithData(
      _spec,
      genFlatCandleList(),
      canvasWidth: 400,
      candle: TestCandleIndicator(visibleMinMaxFromData: true),
    );
    scene.controller.flushPendingKlineData();

    // 不动 gestureConfig 与 settingConfig：上报绑定在 `!useCustomZoomRect`（默认 false）
    // 与 `showYAxisTick`（默认 true）两个开关上，默认配置正是要守住的那条路径。
    expect(scene.controller.chartZoomSlideBarRect, Rect.zero, reason: '绘制前热区应为空');

    final canvas = Canvas(PictureRecorder());
    scene.controller.paintChart(canvas, scene.controller.canvasRect.size);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    final rect = scene.controller.chartZoomSlideBarRect;
    expect(rect.isEmpty, isFalse, reason: '绘制后热区必须已生效，否则 zoom 手势整体失效');
    expect(rect.right, scene.controller.mainRect.right, reason: '热区贴主区右缘');
  });
}
