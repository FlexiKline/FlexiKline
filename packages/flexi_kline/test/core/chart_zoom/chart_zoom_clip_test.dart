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

/// 主区裁剪范围：自动模式平滑期放宽到 canvasRect，缩放态不放宽，溢出的蜡烛画不进副区。
library;

import 'dart:ui' show ClipOp;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'zoom_scene.dart';

void main() {
  group('主区裁剪范围', () {
    /// 带平滑因子横向平移一步：只给 dx，避免顺带平移价格区间。
    void panWithSmoothing(FlexiKlineController chart) {
      chart.onChartMove(const Offset(-12, 0), smoothFactor: 0.15);
    }

    /// 驱动一帧绘制并捕获主区的裁剪矩形。
    Future<_ClipSpyCanvas> paintFrameWithClipSpy(
      WidgetTester tester,
      FlexiKlineController chart,
    ) async {
      final spy = _ClipSpyCanvas();
      chart.paintChart(spy, chart.canvasRect.size);
      await tester.pump();
      return spy;
    }

    testWidgets('自动模式平滑期放宽到 canvasRect', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      panWithSmoothing(chart);
      final spy = await paintFrameWithClipSpy(tester, chart);

      expect(spy.mainClip, chart.canvasRect, reason: '插值中的区间滞后于数据, 溢出不该被裁在主区边缘');
    });

    testWidgets('缩放态平移不放宽裁剪，溢出的蜡烛画不进副区', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, dragDy);
      await paintFrame(tester, chart);
      expect(rangeSpan(chart), isNot(closeTo(autoSpan, 1e-9)), reason: '前置条件: 缩放区间必须已生效');

      panWithSmoothing(chart);
      final spy = await paintFrameWithClipSpy(tester, chart);

      expect(spy.mainClip, chart.mainRect, reason: '缩放态不插值, 放宽裁剪只会让溢出画进副区');
    });
  });
}

/// 只记录 `clipRect` 的 Canvas 替身，其余绘制指令一律吞掉。
///
/// 用替身而不是 `Canvas(PictureRecorder())`：真 Canvas 记下了裁剪却读不回来，而裁剪范围是
/// 本组用例唯一的观察点。
class _ClipSpyCanvas implements Canvas {
  final List<Rect> clipRects = [];

  /// 主区裁剪是 `paintChart` 的第一次 `clipRect`——它发生在任何绘制之前，
  /// 后续可能还有指标自己的局部裁剪（如 time 指标的 `clipToDrawableRect`）。
  Rect get mainClip => clipRects.first;

  @override
  void clipRect(Rect rect, {ClipOp clipOp = ClipOp.intersect, bool doAntiAlias = true}) {
    clipRects.add(rect);
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}
