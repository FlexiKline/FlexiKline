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

/// overlay 删除与 drawState 归属的追平。
///
/// 被测不变量：**[DrawBinding.drawState] 不得指向一个已被移出对象树的 overlay**。
/// 一旦分叉，后续每条走 `drawState.object` 的路径（确认、移动、改样式、画刻度）都在操作
/// 一个不会再被绘制的对象，而屏幕上什么都不会变——是典型的「点了没反应」类问题。
///
/// 观察点取 `drawState`（object / pointer / moving）与存储内容，都是公开可读的量。
///
/// 覆盖边界：Controller 与 `OverlayDrawObjectManager` 之间的删除编排、以及切换绘制工具时
/// 对半成品的收尾。**不覆盖**：手势识别、Widget 布局、命中判据本身。
library;

import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
// overlay 的存储读写是框架内部契约，[IConfigurationExt] 被公开 barrel 显式 hide。
import 'package:flexi_kline/src/framework/configuration.dart' show IConfigurationExt;
import 'package:flutter/widgets.dart' show Canvas, Offset, SizedBox;
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'DRAW-OBJECT-LIFECYCLE',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

/// 画布宽度：不给则 `mainRect` 宽为 0，`timestampToDx` 无从换算。
const _canvasWidth = 400.0;

void main() {
  Future<void> paintChartFrame(WidgetTester tester, FlexiKlineController chart) async {
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

  /// 取主区内一条水平线段的两端，线段落在可见蜡烛范围内。
  ({Offset from, Offset to}) lineEnds(FlexiKlineController controller, {double dyShift = 0}) {
    final mainRect = controller.mainRect;
    final dy = mainRect.center.dy + dyShift;
    return (
      from: Offset(mainRect.right - 120, dy),
      to: Offset(mainRect.right - 40, dy),
    );
  }

  group('v2.5.4/FlexiKlineController/draw-object-removal', () {
    /// 删掉的正是当前选中对象时，`drawState` 必须一起退。
    ///
    /// 之前只有「不传参数」那条分支重置状态，显式传对象的分支不重置——而工具栏的删除按钮
    /// 拿得到对象引用，正好走的是显式那条。
    testWidgets('显式删除当前选中对象 → drawState 退回 Prepared', (tester) async {
      final controller = await mountChart(tester, newConfig());
      final ends = lineEnds(controller);
      drawTestLine(controller, from: ends.from, to: ends.to);
      final selected = controller.drawState.object;
      expect(selected, isNotNull, reason: '前置：绘制完成后应停在 Editing 态并持有该对象');

      controller.removeDrawObject(object: selected);

      expect(
        controller.drawState.object,
        isNull,
        reason:
            '对象已被移出对象树并 dispose，drawState 再指着它就是悬空引用：'
            '后续确认/移动/改样式都会作用在一个不再被绘制的对象上。',
      );
      expect(controller.hitTestDrawObject(ends.from.translate(20, 0)), isNull);
    });

    /// 反向护栏：删的不是选中对象时不能顺手把选中态也清掉。
    testWidgets('删除非选中对象 → 保留当前选中态', (tester) async {
      final controller = await mountChart(tester, newConfig());
      final first = lineEnds(controller, dyShift: -60);
      final second = lineEnds(controller);

      drawTestLine(controller, from: first.from, to: first.to);
      final other = controller.drawState.object;
      // 同类型再次 startDraw 是「取消选中」语义，换类型才能接着画第二条。
      controller.prepareDraw(force: true);
      drawTestLine(
        controller,
        from: second.from,
        to: second.to,
        type: testDrawLineType2,
      );
      final selected = controller.drawState.object;
      expect(selected, isNot(same(other)), reason: '前置：两条线应是两个不同对象');

      controller.removeDrawObject(object: other);

      expect(controller.drawState.object, same(selected));
    });

    /// 删空之后 `drawState` 同样要退：它持有的可能是尚未入列表的半成品，
    /// manager 的清空管不到它。
    testWidgets('removeAllDrawObjects → drawState 退回 Prepared 且存储清空', (tester) async {
      final config = newConfig();
      final controller = await mountChart(tester, config);
      final ends = lineEnds(controller);
      drawTestLine(controller, from: ends.from, to: ends.to);

      controller.removeAllDrawObjects();

      expect(controller.drawState.object, isNull);
      expect(config.getDrawOverlayList(_spec.symbol), isEmpty);
      expect(controller.hasDrawOverlay, isFalse);
      // 断言到原始存储项而不止于「读出来是空的」: 之前删空之后还会再走一次
      // removeDrawObject, 它内部的 saveDrawOverlayList 把 delDrawOverlayList 刚清掉的
      // 键又写成 `{列表: []}`。两者读回来都是空列表, 只有原始项能区分「已删除」与
      // 「存了个空列表」。
      expect(
        config.getConfig('${_spec.symbol}-$drawOverlayListConfigKey'),
        isEmpty,
        reason: 'removeAllDrawObjects 的语义是删除该键，不该在删除之后又写回一个空列表。',
      );
    });

    /// 无选中时的层级查询不能抛。工具栏的置顶/置底按钮用它算可用态，
    /// 那正是「什么都没选」的时刻。
    testWidgets('无选中时 isDrawOnTop / isDrawOnBottom 返回 false', (tester) async {
      final controller = await mountChart(tester, newConfig());
      expect(controller.drawState.object, isNull, reason: '前置：初始无选中');

      expect(controller.isDrawOnTop(), isFalse);
      expect(controller.isDrawOnBottom(), isFalse);
    });
  });

  group('v2.5.4/FlexiKlineController/draw-state-handoff', () {
    /// 再点同一个工具是「收起」语义，被丢下的半成品要清掉交互残留。
    ///
    /// 与 prepareDraw / exitDraw / setDrawContinuous 同源：那三处都先 dispose，
    /// 只有 startDraw 这条同类型分支漏了，半成品会带着旧 pointer 被丢弃。
    testWidgets('同类型再次 startDraw → 半成品的交互残留被清掉', (tester) async {
      final controller = await mountChart(tester, newConfig());
      final ends = lineEnds(controller);

      controller.startDraw(testDrawLineType, isInitPointer: false);
      controller.onDrawConfirm(ends.from);
      controller.onDrawUpdate(ends.to);
      final pending = controller.drawState.object;
      expect(pending?.pointer, isNotNull, reason: '前置：第二个点尚未确认，pointer 还在');
      expect(pending!.isDrawing, isTrue, reason: '前置：这是个未落满点的半成品');

      controller.startDraw(testDrawLineType, isInitPointer: false);

      expect(controller.drawState.isPrepared, isTrue);
      expect(pending.pointer, isNull);
      expect(pending.moving, isFalse);
    });
  });
}
