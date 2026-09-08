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

/// [DrawPainter] 的「无 overlay 整层跳过」守卫。
///
/// 存在动机: [DrawPainter] 与 [CrossPainter] 是同一个 `CustomPaint` 的
/// `painter` / `foregroundPainter`, 两者注册的是同一个 `markNeedsPaint`
/// (见 `RenderCustomPaint.attach`), 所以十字线每移动一步都会带着 draw 层重跑一遍。
/// 守卫让没有 overlay 时这一趟直接返回。
///
/// 被测的是守卫的**判据**而非它省下的开销: 判据取窄了 overlay 会从屏幕上消失, 那是真正
/// 的回归风险。[FlexiKlineController.hasDrawOverlay] 必须覆盖 `paintDraw` 的两条路径 ——
/// 已完成的 overlay 列表, 和只存在于 `drawState` 里的进行中 overlay。
///
/// 观察点是 [TestDrawObject] 的 `drawing` / `draw` 调用计数: 绘制本身不产生像素, 调用
/// 计数是「这一帧画没画」唯一可观察的信号。
///
/// 覆盖边界: `DrawPainter.paint` 的早退判断。
/// **不覆盖**: 手势识别、Widget 布局、真实的重绘调度(RepaintBoundary 的脏标记冒泡),
/// 也不度量守卫省下多少时间。
library;

import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart' show Canvas, Offset, SizedBox;
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'DRAW-PAINTER-GUARD',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

/// 画布宽度：不给则 `mainRect` 宽为 0，`timestampToDx` 无从换算。
const _canvasWidth = 400.0;

void main() {
  /// 驱动一帧 chart 绘制，让主区拿到 minMax —— 绘制点落盘的是蜡烛坐标(ts / value)，
  /// 没有 Y 轴映射时 `updateDrawObjectPointsData` 存不出有意义的值。
  ///
  /// 冲帧要用 `pumpWidget`：绘制排下的 post-frame 回调自己不 `scheduleFrame`，没有
  /// widget 树时 `pump()` 不产生真帧，回调会活到本用例 dispose 之后炸在下一个用例里。
  Future<void> paintChartFrame(WidgetTester tester, FlexiKlineController chart) async {
    chart.paintChart(Canvas(PictureRecorder()), chart.canvasRect.size);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  /// 建一个已挂载、已开启绘制、已注册测试绘制工具的 Controller。
  ///
  /// 注册必须早于 `switchKlineData`，故自己 new controller 而不让 [ControllerScenario] 代建。
  Future<FlexiKlineController> mountChart(WidgetTester tester) async {
    final controller = FlexiKlineController(
      configuration: FakeFlexiKlineConfiguration(enableDraw: true),
    );
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

  /// 走 [DrawPainter.paint] 而非 `controller.paintDraw`：守卫在 painter 里，绕过它
  /// 就测不到早退。
  void paintDrawLayer(FlexiKlineController controller) {
    DrawPainter(controller: controller).paint(
      Canvas(PictureRecorder()),
      controller.canvasRect.size,
    );
  }

  /// 主区内一条水平线段的两端，落在可见蜡烛范围内。
  ({Offset from, Offset to}) lineEnds(FlexiKlineController controller) {
    final mainRect = controller.mainRect;
    final dy = mainRect.center.dy;
    return (
      from: Offset(mainRect.right - 120, dy),
      to: Offset(mainRect.right - 40, dy),
    );
  }

  group('v2.5.0/DrawPainter/overlay-guard', () {
    testWidgets('无任何 overlay 时判据为 false', (tester) async {
      final controller = await mountChart(tester);

      expect(
        controller.hasDrawOverlay,
        isFalse,
        reason: '没画过任何东西时 draw 层无事可做；判据为 true 会让十字线的每一步'
            '都白跑一趟 clip 与遍历。',
      );
    });

    testWidgets('已完成的 overlay 仍被绘制', (tester) async {
      final controller = await mountChart(tester);
      final ends = lineEnds(controller);
      drawTestLine(controller, from: ends.from, to: ends.to);
      // 退出编辑态：让这条线只靠 overlay 列表被判定，不借 drawState 的光。
      controller.exitDraw();

      expect(controller.hasDrawOverlay, isTrue, reason: '前置：列表里有一条已完成的线');
      paintDrawLayer(controller);

      final object = controller.hitTestDrawObject(ends.from);
      expect(object, isA<TestDrawObject>(), reason: '前置：线仍在对象树上且可命中');
      expect(
        (object! as TestDrawObject).drawCallCount,
        greaterThan(0),
        reason: '守卫只该跳过「无事可做」的那一帧。它把有 overlay 的帧也拦掉，'
            '用户已经画好的线就会从屏幕上消失。',
      );
    });

    testWidgets('进行中的 overlay 仍被绘制', (tester) async {
      final controller = await mountChart(tester);
      final ends = lineEnds(controller);
      // 落下第一点、移动到第二点但不确认：停在 Drawing 态。
      controller.startDraw(testDrawLineType, isInitPointer: false);
      controller.onDrawConfirm(ends.from);
      controller.onDrawUpdate(ends.to);
      final object = controller.drawState.object;
      expect(object, isA<TestDrawObject>(), reason: '前置：处于 Drawing 态且持有对象');
      expect(
        controller.hitTestDrawObject(ends.from),
        isNull,
        reason: '前置：进行中的 overlay 要到 onDrawConfirm 判定 isEditing 后才进入'
            'overlayObjectList，此刻列表仍是空的——这正是判据不能只看列表的原因。',
      );

      expect(controller.hasDrawOverlay, isTrue);
      paintDrawLayer(controller);

      expect(
        (object! as TestDrawObject).drawingCallCount,
        greaterThan(0),
        reason: '判据若只看 overlayObjectList，正在画的图形全程不可见——用户落下第一点'
            '后屏幕上什么都没有，直到最后一点确认才突然出现。',
      );
    });

    testWidgets('绘制不可见时早退优先于内容判据', (tester) async {
      final controller = await mountChart(tester);
      final ends = lineEnds(controller);
      drawTestLine(controller, from: ends.from, to: ends.to);
      controller.exitDraw();
      paintDrawLayer(controller);
      final object = controller.hitTestDrawObject(ends.from)! as TestDrawObject;
      final before = object.drawCallCount;

      controller.setDrawVisible(false);
      paintDrawLayer(controller);

      expect(
        object.drawCallCount,
        before,
        reason: 'isDrawVisible 是用户显式的「隐藏所有绘制」，内容判据不该把它推翻。',
      );
    });
  });
}
