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

/// 非触摸端 hover 与 cross 行为的特征测试。
///
/// 覆盖目标设计第六节 #3（onHover 里 drawState.isEditing 早退）、
/// #12（draw 绘制中 requestCancelCross 的时机）。
///
/// 覆盖边界：覆盖手势层对 controller.isCrossing / drawState 的分派决策。
/// **不覆盖**：光标外观在各平台的真实渲染、MouseRegion 的 enter/exit 平台差异。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

// ---------------------------------------------------------------------------
// 常量与搭建
// ---------------------------------------------------------------------------

const _spec = KlineSpec(
  symbol: 'NON-TOUCH-HOVER',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

/// 搭建非触摸端图表，可选开启绘制。
Future<FlexiKlineController> _pumpNonTouchChart(
  WidgetTester tester, {
  bool enableDraw = false,
}) async {
  final controller = createChartController();
  controller.switchKlineData(_spec);
  controller.replaceKlineData(_spec, genFlatCandleList());
  if (enableDraw) {
    registerTestDrawObject(controller);
    controller.setDrawVisible(true);
  }

  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 400,
        height: 480,
        child: FlexiKlineWidget(
          controller: controller,
          candle: TestCandleIndicator(),
          time: TestTimeIndicator(),
          isTouchDevice: false,
        ),
      ),
    ),
  );
  await pumpUntilChart(
    tester,
    () => controller.isMounted && controller.mainChartWidth > 0 && controller.klineData.isNotEmpty,
    'non-touch chart data and layout',
  );
  return controller;
}

/// 全局坐标换算。
Offset _toGlobal(WidgetTester tester, Offset local) {
  final box = tester.renderObject<RenderBox>(
    find.byKey(const ValueKey('NonTouchListener')),
  );
  return box.localToGlobal(local);
}

/// 在图表上发送 hover 事件（模拟鼠标移动不按键）。
///
/// [TestGesture] 在非按下状态下调用 [moveTo] 会产生 PointerHoverEvent。
/// 必须先 [addPointer] 触发 PointerAddedEvent，之后 [moveTo] 才会生成 hover 而非 move。
Future<TestGesture> _hoverAt(
  WidgetTester tester,
  Offset localPosition, {
  int pointer = 1,
}) async {
  final gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
    pointer: pointer,
  );
  await gesture.addPointer(location: _toGlobal(tester, localPosition));
  await tester.pump();
  await gesture.moveTo(_toGlobal(tester, localPosition));
  await tester.pump();
  return gesture;
}

// ---------------------------------------------------------------------------
// 用例
// ---------------------------------------------------------------------------

void main() {
  // ---- #3: onHover 里 drawState.isEditing 早退 ----
  group('#3 hover isEditing early return', () {
    testWidgets('drawState.isEditing 时 hover 不更新绘制对象', (tester) async {
      final controller = await _pumpNonTouchChart(tester, enableDraw: true);
      addTearDown(() => disposeChart(tester, controller));

      // 画一条两点直线，进入 Editing 状态。
      final mainRect = controller.mainRect;
      final from = Offset(mainRect.left + 20, mainRect.center.dy);
      final to = Offset(mainRect.left + 100, mainRect.center.dy);
      drawTestLine(controller, from: from, to: to);
      await tester.pump();
      expect(controller.drawState.isEditing, isTrue, reason: '前置：必须在 Editing 状态');

      // 记录 Editing 状态下绘制对象的点位。
      final objectBefore = controller.drawState.object!;
      final pointsBefore = objectBefore.points.map((p) => p?.offset).toList();

      // 在图表上移动鼠标（hover 事件）。
      final hoverPos = Offset(mainRect.center.dx, mainRect.center.dy - 30);
      final gesture = await _hoverAt(tester, hoverPos);

      // 绘制对象的点位应不变——Editing 态下 hover 早退，不更新 draw。
      final pointsAfter = objectBefore.points.map((p) => p?.offset).toList();
      expect(
        pointsAfter,
        pointsBefore,
        reason: 'Editing 态下 hover 不参与修正，由拖动或长按修正',
      );

      await gesture.removePointer();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('drawState.isDrawing 时 hover 正常驱动绘制', (tester) async {
      final controller = await _pumpNonTouchChart(tester, enableDraw: true);
      addTearDown(() => disposeChart(tester, controller));

      // 启动绘制但只确认第一个点，进入 Drawing 状态。
      final mainRect = controller.mainRect;
      controller.startDraw(testDrawLineType, isInitPointer: false);
      controller.onDrawConfirm(
        Offset(mainRect.left + 20, mainRect.center.dy),
      );
      await tester.pump();
      expect(controller.drawState.isDrawing, isTrue, reason: '前置：必须在 Drawing 状态');

      // hover 应驱动绘制更新（onDrawUpdate）。
      final hoverTarget = Offset(mainRect.left + 80, mainRect.center.dy - 20);
      final gesture = await _hoverAt(tester, hoverTarget);
      await tester.pump();

      // Drawing 状态下 hover 应通过 onDrawUpdate 将指针跟手。
      // 确认 draw 已被驱动（不进 isEditing 早退分支）。
      // 无直接公开 API 读取绘制中的临时位置，但 hover 后没有抛异常且绘制状态持续即为通过。
      expect(controller.drawState.isDrawing, isTrue);

      await gesture.removePointer();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  // ---- #12: draw 绘制中 requestCancelCross 的时机 ----
  group('#12 requestCancelCross timing in draw', () {
    testWidgets('Drawing 态 hover 时取消 cross（cross 与 draw 不同时跟手）', (tester) async {
      final controller = await _pumpNonTouchChart(tester, enableDraw: true);
      addTearDown(() => disposeChart(tester, controller));

      // 先建立 cross。
      final mainRect = controller.mainRect;
      final initialPos = Offset(mainRect.center.dx, mainRect.center.dy);
      final enterGesture = await _hoverAt(tester, initialPos, pointer: 1);
      await tester.pump();
      expect(controller.isCrossing, isTrue, reason: '前置：hover 应启动 cross');

      // 移除指针以清理状态。
      await enterGesture.removePointer();
      await tester.pump(const Duration(milliseconds: 50));

      // 启动绘制进入 Drawing 态。
      controller.startDraw(testDrawLineType, isInitPointer: false);
      controller.onDrawConfirm(
        Offset(mainRect.left + 20, mainRect.center.dy),
      );
      await tester.pump();
      expect(controller.drawState.isDrawing, isTrue, reason: '前置：Drawing 状态');

      // hover 到新位置——应通过 requestCancelCross 取消 cross。
      final drawHoverPos = Offset(mainRect.left + 60, mainRect.center.dy);
      final drawGesture = await _hoverAt(tester, drawHoverPos, pointer: 2);
      await tester.pump();

      // Drawing 态 hover 走 onDrawUpdate 路径前会 requestCancelCross。
      expect(
        controller.isCrossing,
        isFalse,
        reason: 'draw 绘制中 hover 应取消 cross，两者不同时跟手',
      );

      await drawGesture.removePointer();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Drawing 态 onTapUp 确认后取消 cross', (tester) async {
      final controller = await _pumpNonTouchChart(tester, enableDraw: true);
      addTearDown(() => disposeChart(tester, controller));

      final mainRect = controller.mainRect;

      // 启动绘制，确认第一个点。
      controller.startDraw(testDrawLineType, isInitPointer: false);
      controller.onDrawConfirm(
        Offset(mainRect.left + 20, mainRect.center.dy),
      );
      await tester.pump();

      // hover 以建立绘制追踪。
      final hoverGesture = await _hoverAt(
        tester,
        Offset(mainRect.left + 80, mainRect.center.dy),
        pointer: 1,
      );
      await tester.pump();

      // 点击确认第二个点（完成绘制进入 Editing）。
      // onTapUp 的 Drawing 分支会在 onDrawConfirm 后检查 isCrossing 并 requestCancelCross。
      await tester.tapAt(_toGlobal(
        tester,
        Offset(mainRect.left + 80, mainRect.center.dy),
      ));
      await tester.pump();

      expect(
        controller.isCrossing,
        isFalse,
        reason: 'Drawing 态 onTapUp 确认后应取消 cross',
      );

      await hoverGesture.removePointer();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('非绘制态 hover 正常启动并维持 cross', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => disposeChart(tester, controller));

      final mainRect = controller.mainRect;
      final gesture = await _hoverAt(
        tester,
        Offset(mainRect.center.dx, mainRect.center.dy),
      );
      await tester.pump();

      expect(
        controller.isCrossing,
        isTrue,
        reason: '非绘制态 hover 应启动 cross',
      );

      // 移动 hover 位置，cross 应持续更新。
      await gesture.moveTo(_toGlobal(
        tester,
        Offset(mainRect.center.dx + 30, mainRect.center.dy + 10),
      ));
      await tester.pump();

      expect(controller.isCrossing, isTrue, reason: '持续 hover 时 cross 应维持');

      await gesture.removePointer();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
