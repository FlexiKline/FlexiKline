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

/// 非触摸端 _resolveScalePosition 不缓存的特征测试。
///
/// 覆盖目标设计第六节 #5：非触摸端每次手势独立，无触摸端「一轮内锚点不变」的约束。
/// `_resolveScalePosition` 在 `scalePosition == auto` 时按滚轮位置所在的三分区就近锚定，
/// 且不缓存——两次落在不同三分区的滚轮事件应各自独立解析锚点。
///
/// 覆盖边界：通过 PointerScrollEvent → onPointerSignal → onChartScale 验证锚定行为。
/// **不覆盖**：真机滚轮的 scrollDelta 量级、scaledSignal 的非线性映射精度、
/// 光标外观。signal 通道的 scale session 用 scaleSessionTimeout（默认 800ms）的
/// 可重置 Timer 管理, 每次 scroll 事件后须 pump 足够时间让 session 结束。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

// ---------------------------------------------------------------------------
// 常量与搭建
// ---------------------------------------------------------------------------

const _spec = KlineSpec(
  symbol: 'NON-TOUCH-SCALE-ANCHOR',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

Future<FlexiKlineController> _pumpNonTouchChart(WidgetTester tester) async {
  final controller = createChartController();
  controller.switchKlineData(_spec);
  controller.replaceKlineData(_spec, genFlatCandleList());

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

Offset _toGlobal(WidgetTester tester, Offset local) {
  final box = tester.renderObject<RenderBox>(
    find.byKey(const ValueKey('NonTouchListener')),
  );
  return box.localToGlobal(local);
}

/// 卸载图表并消耗 `onPointerSignal` 中 `Future.delayed(1000ms)` 留下的 pending timer。
Future<void> _disposeChart(
  WidgetTester tester,
  FlexiKlineController controller,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1200));
  controller.dispose();
}

/// 发送滚轮事件并等待 scale session 超时结束, 使下一轮独立。
Future<void> _scrollAndDrain(
  WidgetTester tester,
  Offset localPosition, {
  double scrollDy = 30,
}) async {
  final global = _toGlobal(tester, localPosition);
  final event = PointerScrollEvent(
    position: global,
    scrollDelta: Offset(0, scrollDy),
  );
  await tester.sendEventToBinding(event);
  await tester.pump();
  // 等待 scaleSessionTimeout (默认 800ms) 触发 session 结束。
  await tester.pump(const Duration(milliseconds: 900));
}

// ---------------------------------------------------------------------------
// 用例
// ---------------------------------------------------------------------------

void main() {
  group('#5 _resolveScalePosition does not cache', () {
    testWidgets('auto 模式下左三分区与右三分区产生不同的锚定行为', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      expect(
        controller.gestureConfig.scalePosition,
        ScalePosition.auto,
        reason: '前置：scalePosition 必须是 auto',
      );

      final canvas = controller.canvasRect;
      final third = canvas.width / 3;
      final leftPos = Offset(canvas.left + third * 0.5, canvas.center.dy);
      final rightPos = Offset(canvas.right - third * 0.5, canvas.center.dy);

      // ---- 在左三分区滚轮放大一次 ----
      final beforeLeftDx = controller.paintDxOffset;
      final beforeLeftWidth = controller.candleWidth;
      await _scrollAndDrain(tester, leftPos, scrollDy: -30);
      final afterLeftDx = controller.paintDxOffset;
      final afterLeftWidth = controller.candleWidth;
      expect(afterLeftWidth, greaterThan(beforeLeftWidth), reason: '放大后 candleWidth 应增大');
      final leftDxDelta = afterLeftDx - beforeLeftDx;

      // ---- 在右三分区滚轮放大一次（基线已变，但锚定行为不同） ----
      final beforeRightDx = controller.paintDxOffset;
      await _scrollAndDrain(tester, rightPos, scrollDy: -30);
      final afterRightDx = controller.paintDxOffset;
      final rightDxDelta = afterRightDx - beforeRightDx;

      // 核心断言：不同三分区的锚定导致 paintDxOffset 的变化量不同。
      // 若 _resolveScalePosition 缓存了第一次的结果，两次 offset 变化量会相近。
      expect(
        leftDxDelta,
        isNot(closeTo(rightDxDelta, 0.01)),
        reason: '不同三分区应产生不同的锚定行为，说明 _resolveScalePosition 不缓存',
      );
    });

    testWidgets('scalePosition 非 auto 时忽略位置，始终用配置值', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      controller.updateGestureConfig(
        (config) => config.copyWith(scalePosition: ScalePosition.right),
      );

      final canvas = controller.canvasRect;
      final third = canvas.width / 3;
      final leftPos = Offset(canvas.left + third * 0.5, canvas.center.dy);
      final rightPos = Offset(canvas.right - third * 0.5, canvas.center.dy);

      // ---- 在左三分区放大 ----
      final before1Dx = controller.paintDxOffset;
      await _scrollAndDrain(tester, leftPos, scrollDy: -30);
      final delta1 = controller.paintDxOffset - before1Dx;

      // ---- 在右三分区放大 ----
      final before2Dx = controller.paintDxOffset;
      await _scrollAndDrain(tester, rightPos, scrollDy: -30);
      final delta2 = controller.paintDxOffset - before2Dx;

      // scalePosition=right 时两处位置都固定用右锚定，offset 变化行为应相近。
      // 允许因 candleWidth 累积不同造成的小差异。
      expect(
        (delta1 - delta2).abs(),
        lessThan(2.0),
        reason: 'scalePosition=right 时忽略位置，两处锚定行为应一致',
      );
    });

    testWidgets('连续事件之间锚点可以跳变（不像触摸端一轮内固定）', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final canvas = controller.canvasRect;
      final third = canvas.width / 3;
      final leftPos = Offset(canvas.left + third * 0.5, canvas.center.dy);
      final rightPos = Offset(canvas.right - third * 0.5, canvas.center.dy);

      // 第一次滚轮在左（drain 后 session 结束）。
      final dx0 = controller.paintDxOffset;
      await _scrollAndDrain(tester, leftPos, scrollDy: -30);
      final dxAfterLeft = controller.paintDxOffset;

      // 第二次滚轮在右。
      await _scrollAndDrain(tester, rightPos, scrollDy: -30);
      final dxAfterRight = controller.paintDxOffset;

      // 两次事件的 offset 增量应不同（锚点跳变了）。
      final delta1 = dxAfterLeft - dx0;
      final delta2 = dxAfterRight - dxAfterLeft;

      expect(
        delta1,
        isNot(closeTo(delta2, 0.01)),
        reason: '紧邻两次事件在不同三分区，锚点应跳变',
      );
    });
  });
}
