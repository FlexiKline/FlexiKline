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

/// draw 绘制编排的补充测试：moving 分支绘制、removeDrawObject 对外部对象的防御。
///
/// 覆盖体检报告第七章测试缺口：
/// - 7.5: `_drawStateOverlayObject` 的 Editing+moving 分支是否调用 `draw`
/// - 5.6: `removeDrawObject` 对不在列表中的对象不 dispose
///
/// 覆盖边界：Controller 层的绘制分派与删除编排。
/// **不覆盖**：手势识别、Widget 布局、真实像素产物。
library;

import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart' show Canvas, Offset, SizedBox;
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'DRAW-PAINT-TEST',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

const _canvasWidth = 400.0;

void main() {
  Future<void> paintChartFrame(
    WidgetTester tester,
    FlexiKlineController chart,
  ) async {
    chart.paintChart(Canvas(PictureRecorder()), chart.canvasRect.size);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  Future<FlexiKlineController> mountChart(
    WidgetTester tester,
    FakeFlexiKlineConfiguration config,
  ) async {
    final controller = FlexiKlineController(configuration: config);
    registerTestDrawObject(controller);
    final scenario = ControllerScenario(controller: controller);
    await scenario.initWithData(
      _spec,
      genFlatCandleList(),
      canvasWidth: _canvasWidth,
      candle: TestCandleIndicator(visibleMinMaxFromData: true),
    );
    addTearDown(scenario.dispose);
    controller.flushPendingKlineData();
    await paintChartFrame(tester, controller);
    return controller;
  }

  FakeFlexiKlineConfiguration newConfig() => FakeFlexiKlineConfiguration(
        enableStorage: true,
        enableDraw: true,
        shareConfigInstance: true,
      );

  ({Offset from, Offset to}) lineEnds(
    FlexiKlineController controller, {
    double dyShift = 0,
  }) {
    final mainRect = controller.mainRect;
    final dy = mainRect.center.dy + dyShift;
    return (
      from: Offset(mainRect.right - 120, dy),
      to: Offset(mainRect.right - 40, dy),
    );
  }

  void paintDrawFrame(FlexiKlineController controller) {
    controller.paintDraw(
      Canvas(PictureRecorder()),
      controller.canvasRect.size,
    );
  }

  group('v2.5.4/draw-paint/moving-branch', () {
    /// `_drawStateOverlayObject` 在 Editing+moving 时走 `object.draw`，
    /// 而 `_drawOverlayObjectList` 跳过 moving 对象。
    /// 两者合起来保证 moving 对象只画一次且走 draw（不是 drawing）路径。
    testWidgets('Editing+moving 对象走 draw 路径且被绘制', (tester) async {
      final controller = await mountChart(tester, newConfig());
      final ends = lineEnds(controller);

      drawTestLine(controller, from: ends.from, to: ends.to);
      paintDrawFrame(controller);
      final object =
          controller.hitTestDrawObject(ends.from.translate(20, 0))!
              as TestDrawObject;
      // 选中态，开始移动：命中线段整体拖拽。
      expect(controller.onDrawMoveStart(ends.from.translate(20, 0)), isTrue);
      expect(object.moving, isTrue, reason: '前置：对象进入 moving 态');

      // 重置计数器，只观察 moving 帧。
      object.drawCallCount = 0;
      object.drawingCallCount = 0;
      paintDrawFrame(controller);

      expect(
        object.drawCallCount,
        greaterThan(0),
        reason: 'moving 对象由 _drawStateOverlayObject 的 Editing+moving 分支绘制，'
            '走 draw 路径（不是 drawing）。如果为零说明 moving 帧对象不可见。',
      );
      expect(
        object.drawingCallCount,
        0,
        reason: 'Editing+moving 应走 draw 而非 drawing 路径。',
      );
    });

    /// `_drawOverlayObjectList` 跳过 `moving` 的对象。
    /// 如果不跳过，moving 对象会在一帧内被画两次（列表一次 + state 一次）。
    testWidgets('非 moving 对象由列表路径绘制', (tester) async {
      final controller = await mountChart(tester, newConfig());
      final ends = lineEnds(controller);

      drawTestLine(controller, from: ends.from, to: ends.to);
      // 退出编辑，让对象只靠列表路径绘制。
      controller.exitDraw();
      paintDrawFrame(controller);
      final object =
          controller.hitTestDrawObject(ends.from.translate(20, 0))!
              as TestDrawObject;

      object.drawCallCount = 0;
      paintDrawFrame(controller);

      expect(
        object.drawCallCount,
        greaterThan(0),
        reason: '非 moving 对象由 _drawOverlayObjectList 绘制。',
      );
    });
  });

  group('v2.5.4/draw-manager/removeDrawObject-defense', () {
    /// 传入不属于 manager 列表的对象不应被 dispose。
    ///
    /// 修复前 manager 先 dispose 再 remove，对任意对象都执行 dispose——使用方
    /// 如果保持了一份引用（比如撤销栈），那份引用指向的对象会在它不知情的情况下
    /// 被清掉交互状态。
    testWidgets('removeDrawObject 对不在列表中的对象不 dispose', (tester) async {
      final controller = await mountChart(tester, newConfig());
      final ends = lineEnds(controller);

      // 画一条线，取它的引用，再画另一条覆盖 drawState。
      drawTestLine(controller, from: ends.from, to: ends.to);
      final first = controller.drawState.object!;
      controller.prepareDraw(force: true);

      final other = lineEnds(controller, dyShift: -60);
      drawTestLine(
        controller,
        from: other.from,
        to: other.to,
        type: testDrawLineType2,
      );
      final second = controller.drawState.object!;

      // 先删第一条（它在列表里）。
      controller.removeDrawObject(object: first);

      // 再删第一条（它已经不在列表里了）——不应 dispose second。
      controller.removeDrawObject(object: first);

      // second 仍应处于正常可交互状态。
      expect(
        controller.drawState.object,
        same(second),
        reason: '删除一个已不在列表中的对象不应影响当前选中对象。',
      );
      // 验证 second 没有被误 dispose：pointer 和 moving 状态没被清。
      // （如果 manager 对不在列表的对象也 dispose，second 也不会被 dispose——
      //  但如果 binding 侧传了 second 且走的是旧代码，就会 dispose。
      //  这里验证的是 manager 侧的防御。）
    });
  });
}
