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

/// 交互类场景: 数据不变, 由手势或交互 API 驱动重绘。
library;

import 'package:flexi_kline_benchmark/src/preset.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter_test/flutter_test.dart';

import '../gestures.dart';
import '../scenario.dart';

final interactionScenarios = <String, Scenario>{
  // base 只留 pan 作「只有蜡烛」的参考: 其他动作的 full 包含 base 的全部工作, base 里的回退在 full 里同样出现。
  'pan/base': const Scenario(BenchPreset.base, pan),
  'pan/full': const Scenario(BenchPreset.full, pan),
  'fling/full': const Scenario(BenchPreset.full, _fling),
  'scale/full': const Scenario(BenchPreset.full, _scale),
  'zoom/full': const Scenario(BenchPreset.full, _zoom, features: {BenchFeature.zoom}, prepare: _exitZoom),
  'cross/full': const Scenario(BenchPreset.full, _cross),
  'resize/full': const Scenario(BenchPreset.full, _resize, features: {BenchFeature.resize}),
};

/// 左右往返拖动, 每笔 1s 拖过主图 60% 宽度; 首笔朝历史方向(手指向右)。
///
/// 初始视口贴在最新数据一侧的边界上, 朝新数据拖会被夹住不动。
Future<void> pan(ScenarioContext ctx) async {
  var toHistory = true;
  while (ctx.running) {
    final before = ctx.controller.paintDxOffset;
    await ctx.drag(ctx.mainPoint(toHistory ? 0.2 : 0.8), ctx.mainPoint(toHistory ? 0.8 : 0.2));
    expect(ctx.controller.paintDxOffset, isNot(before), reason: '前置：拖动要让图表平移');
    toHistory = !toHistory;
  }
}

/// 往返快速甩动, 每次等惯性走完(1.5s)再甩下一次; 首笔朝历史方向, 原因同 [pan]。
Future<void> _fling(ScenarioContext ctx) async {
  var toHistory = true;
  final frame = Duration(microseconds: 1e6 ~/ ctx.refreshRate);
  while (ctx.running) {
    final from = ctx.mainPoint(toHistory ? 0.3 : 0.7);
    final to = ctx.mainPoint(toHistory ? 0.7 : 0.3);
    final before = ctx.controller.paintDxOffset;
    await ctx.tester.flingFrom(from, to - from, 3000, frameInterval: frame);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(ctx.controller.paintDxOffset, isNot(before), reason: '前置：甩动要让图表平移');
    toHistory = !toHistory;
  }
}

/// 双指捏合往返(X 轴缩放): 指间距在主图宽度的 20% 与 70% 之间, 单程 0.5s。
Future<void> _scale(ScenarioContext ctx) async {
  final width = ctx.controller.mainRect.width;
  while (ctx.running) {
    final widths = <double>{};
    await ctx.pinch(
      ctx.mainPoint(0.5),
      near: width * 0.2,
      far: width * 0.7,
      onFrame: () => widths.add(ctx.controller.candleWidth),
    );
    expect(widths.length, greaterThan(1), reason: '前置：捏合要改变蜡烛宽度');
  }
}

/// 每个窗口从自动 Y 轴开始。
Future<void> _exitZoom(ScenarioContext ctx) async => ctx.controller.exitChartZoom();

/// 在右侧价格轴上按住纵向往返拖动(Y 轴价格缩放), 每程 0.5s、速度为主图高度 / 秒。
Future<void> _zoom(ScenarioContext ctx) async {
  final bar = ctx.controller.chartZoomSlideBarRect;
  expect(bar.isEmpty, isFalse, reason: '前置：价格轴缩放热区要已画出');
  final speed = ctx.controller.mainRect.height;
  while (ctx.running) {
    final gesture = await ctx.tester.startGesture(ctx.toGlobal(bar.center));
    for (final sign in const [-1.0, 1.0]) {
      await ctx.moveFor(gesture, Offset(0, sign * speed), const Duration(milliseconds: 500));
    }
    await gesture.up();
    await ctx.nextFrame();
    expect(ctx.controller.isChartZooming, isTrue, reason: '前置：拖动价格轴要进入 Y 轴缩放');
  }
}

/// 按住十字线横向匀速往返, 速度 240px/s, 来回扫过主图 60% 宽度。
Future<void> _cross(ScenarioContext ctx) async {
  final start = ctx.mainPoint(0.2);
  if (!ctx.controller.isCrossing) {
    await ctx.tester.tapAt(start);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  expect(ctx.controller.isCrossing, isTrue, reason: '前置：点击要进入十字线');
  const speed = 240.0;
  final sweep = Duration(microseconds: (ctx.controller.mainRect.width * 0.6 / speed * 1e6).round());
  final gesture = await ctx.tester.startGesture(start);
  while (ctx.running) {
    await ctx.moveFor(gesture, const Offset(speed, 0), sweep);
    await ctx.moveFor(gesture, const Offset(-speed, 0), sweep);
  }
  await gesture.up();
}

/// 长按主区与第一个副区的分隔线再上下拖动(手机上调整副区高度的操作), 主区高度在 ±60px 内往返, 每程 0.5s。
///
/// 走完整的触摸链路: 长按判定 → `onGridResizeStart`, 之后的移动 → `onGridResizeUpdate`。
/// 等长按判定([kLongPressTimeout])时手指静止, 几乎不出帧。
Future<void> _resize(ScenarioContext ctx) async {
  final controller = ctx.controller;
  while (ctx.running) {
    final main = controller.mainRect;
    final gesture = await ctx.tester.startGesture(ctx.toGlobal(Offset(main.center.dx, main.bottom)));
    await Future<void>.delayed(kLongPressTimeout + const Duration(milliseconds: 100));
    expect(controller.isStartDragGrid, isTrue, reason: '前置：长按要命中主区下方的分隔线');
    final heights = {controller.mainRect.height};
    for (final sign in const [1.0, -1.0, -1.0, 1.0]) {
      await ctx.moveFor(gesture, Offset(0, sign * 120), const Duration(milliseconds: 500));
      heights.add(controller.mainRect.height);
    }
    await gesture.up();
    await ctx.nextFrame();
    expect(heights.length, greaterThan(1), reason: '前置：拖动分隔线要改变主区高度');
  }
}
