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

/// 非触摸端 signal 通道（通道 S）测试。
///
/// 覆盖：
/// - 滚轮在价格轴上连续滚动 → Y 轴缩放（onChartZoomStep 累乘）
/// - 连乘等价性：两次 exp(a) 与一次 exp(2a) 结果相同
/// - 滚轮在图表区 → X 轴缩放；idle 窗口内连续滚动不提前结束 session
/// - PointerScaleEvent → 按 event.scale 缩放
/// - dy == 0 的横向滚轮不产生任何变化
/// - enableZoom / enableScale 关闭时不消费事件（放行外层）
///
/// 覆盖边界：经 PointerSignalEvent → Listener → onPointerSignal → controller API。
/// **不覆盖**：真机滚轮 scrollDelta.dy 的量级、光标外观、在 Scrollable 内的竞争。
/// **未经真机验证**。
library;

import 'dart:math' as math;
import 'dart:ui' show PictureRecorder;

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
  symbol: 'NON-TOUCH-SIGNAL',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

/// 滑竿区宽 24、贴主区右缘、高度取整个主区。
Rect _sliderRect(FlexiKlineController chart) => Rect.fromLTWH(
      chart.mainRect.right - 24,
      chart.mainRect.top,
      24,
      chart.mainRect.height,
    );

/// 当前可见价格区间的跨度（经公开面 dyToCandleValue 反算）。
double _rangeSpan(FlexiKlineController chart) => _rangeMax(chart) - _rangeMin(chart);

double _rangeMax(FlexiKlineController chart) =>
    chart.dyToCandleValue(chart.mainChartRect.top, check: false)!.toDouble();

double _rangeMin(FlexiKlineController chart) =>
    chart.dyToCandleValue(chart.mainChartRect.bottom, check: false)!.toDouble();

double _rangeCenter(FlexiKlineController chart) => (_rangeMax(chart) + _rangeMin(chart)) / 2;

/// 驱动一帧绘制以刷新区间映射。
Future<void> _paintFrame(
  WidgetTester tester,
  FlexiKlineController chart,
) async {
  final canvas = Canvas(PictureRecorder());
  chart.paintChart(canvas, chart.canvasRect.size);
  await tester.pump();
}

Future<FlexiKlineController> _pumpNonTouchChart(
  WidgetTester tester, {
  bool enableZoom = true,
  bool enableScale = true,
}) async {
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
          candle: TestCandleIndicator(visibleMinMaxFromData: true),
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

  // 设置滑竿区并确保生效。
  controller.setChartZoomSlideBarRect(_sliderRect(controller));
  await tester.pump();

  controller.updateGestureConfig(
    (c) => c.copyWith(enableZoom: enableZoom, enableScale: enableScale),
  );

  // 驱动首帧绘制使 dyToCandleValue 可用。
  await _paintFrame(tester, controller);

  return controller;
}

Offset _toGlobal(WidgetTester tester, Offset local) {
  final box = tester.renderObject<RenderBox>(
    find.byKey(const ValueKey('NonTouchListener')),
  );
  return box.localToGlobal(local);
}

Future<void> _disposeChart(
  WidgetTester tester,
  FlexiKlineController controller,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1200));
  controller.dispose();
}

/// 发送一次 PointerScrollEvent 到 [localPosition]，dy 为 [scrollDy]。
Future<void> _sendScroll(
  WidgetTester tester,
  Offset localPosition, {
  double scrollDy = 30,
  double scrollDx = 0,
}) async {
  final global = _toGlobal(tester, localPosition);
  final event = PointerScrollEvent(
    position: global,
    scrollDelta: Offset(scrollDx, scrollDy),
  );
  await tester.sendEventToBinding(event);
  await tester.pump();
}

/// 发送一次 PointerScaleEvent 到 [localPosition]，缩放比 [scale]。
Future<void> _sendScale(
  WidgetTester tester,
  Offset localPosition, {
  required double scale,
}) async {
  final global = _toGlobal(tester, localPosition);
  final event = PointerScaleEvent(
    position: global,
    scale: scale,
  );
  await tester.sendEventToBinding(event);
  await tester.pump();
}

// ---------------------------------------------------------------------------
// 用例
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // Y 轴 zoom（滚轮在价格轴/滑竿区）
  // =========================================================================
  group('signal zoom (price axis scroll)', () {
    testWidgets('连续滚动累乘缩放 Y 轴区间', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final slider = _sliderRect(controller);
      final scrollPos = slider.center;

      final initSpan = _rangeSpan(controller);
      expect(initSpan, greaterThan(0), reason: '前置：初始区间跨度必须非零');

      // 向上滚动两次（dy > 0 → exp(-dy/200) < 1 → 区间收窄即放大）。
      await _sendScroll(tester, scrollPos, scrollDy: 30);
      await _paintFrame(tester, controller);
      final span1 = _rangeSpan(controller);
      expect(span1, lessThan(initSpan), reason: '第一次滚动后区间应收窄');

      await _sendScroll(tester, scrollPos, scrollDy: 30);
      await _paintFrame(tester, controller);
      final span2 = _rangeSpan(controller);
      expect(span2, lessThan(span1), reason: '第二次滚动后区间应继续收窄');

      expect(controller.isChartZooming, isTrue);
    });

    testWidgets('连乘等价：两次 exp(a) 与一次 exp(2a) 结果相同', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final slider = _sliderRect(controller);
      final scrollPos = slider.center;
      final initSpan = _rangeSpan(controller);

      // 方案 A：两次 scrollDy=30。
      await _sendScroll(tester, scrollPos, scrollDy: 30);
      await _sendScroll(tester, scrollPos, scrollDy: 30);
      await _paintFrame(tester, controller);
      final spanA = _rangeSpan(controller);

      // 退出缩放并重置。
      controller.exitChartZoom();
      await _paintFrame(tester, controller);

      // 方案 B：一次 scrollDy=60。
      await _sendScroll(tester, scrollPos, scrollDy: 60);
      await _paintFrame(tester, controller);
      final spanB = _rangeSpan(controller);

      // exp(-30/200)^2 == exp(-60/200)，两种方式的 span 变化比例应相同。
      final ratioA = spanA / initSpan;
      final ratioB = spanB / initSpan;
      expect(
        ratioA,
        closeTo(ratioB, 0.01),
        reason: '连乘等价：两次 exp(a) ≈ 一次 exp(2a)',
      );
    });

    testWidgets('中点不变：缩放围绕区间中心', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final slider = _sliderRect(controller);
      final scrollPos = slider.center;

      final initCenter = _rangeCenter(controller);
      await _sendScroll(tester, scrollPos, scrollDy: 50);
      await _paintFrame(tester, controller);
      final afterCenter = _rangeCenter(controller);

      expect(afterCenter, closeTo(initCenter, 0.5), reason: '缩放不应移动中点');
    });
  });

  // =========================================================================
  // 灵敏度标定：Y 轴由触摸端口径派生，X 轴保持自己的旋钮
  // =========================================================================
  //
  // 触摸端的标定是「手指走完主图区高度 H 得到倍率 M」，折成每像素即 `ln(M) / H`。Y 轴 signal
  // 用同一个值，同样的位移量在两条链上才得到同样的倍率。X 轴另有自己的界（candleMinWidth /
  // candleMaxWidth）和触摸端对手（scaleSpeed），与 Y 轴无关，仍用 signalScaleFactor。
  group('signal 灵敏度标定', () {
    testWidgets('Y 轴滚轮灵敏度随 maxZoomPerGesture 变化', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final scrollPos = _sliderRect(controller).center;

      /// 在 [m] 下量一次固定滚动量产生的跨度比值。每次先复位，避免上一次的缩放叠进来。
      Future<double> measure(double m) async {
        controller.exitChartZoom();
        await _paintFrame(tester, controller);
        controller.updateGestureConfig((c) => c.copyWith(maxZoomPerGesture: m));
        final before = _rangeSpan(controller);
        await _sendScroll(tester, scrollPos, scrollDy: 60);
        await _paintFrame(tester, controller);
        return _rangeSpan(controller) / before;
      }

      final ratio6 = await measure(6);
      final ratio12 = await measure(12);

      // 比值 = exp(-dy · ln(M) / H)，所以两次取对数后的比就是 ln(M) 的比，H 和 dy 都约掉。
      expect(
        math.log(ratio12) / math.log(ratio6),
        closeTo(math.log(12) / math.log(6), 1e-6),
        reason: 'Y 轴 signal 灵敏度必须由 maxZoomPerGesture 派生, 不是独立常量',
      );
    });

    testWidgets('maxZoomPerGesture 不影响 X 轴滚轮缩放幅度', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final chartCenter = controller.mainRect.center;

      Future<double> measure(double m) async {
        controller.updateGestureConfig((c) => c.copyWith(maxZoomPerGesture: m));
        final before = controller.candleWidth;
        await _sendScroll(tester, chartCenter, scrollDy: 60);
        // 等 session 空闲超时结束，下一次测量才是独立的一段。
        await tester.pump(const Duration(milliseconds: 900));
        return controller.candleWidth / before;
      }

      final ratio6 = await measure(6);
      final ratio12 = await measure(12);

      expect(
        ratio12,
        closeTo(ratio6, 1e-9),
        reason: '两个意图的标定已解耦: X 轴仍用 signalScaleFactor',
      );
    });
  });

  // =========================================================================
  // X 轴 scale（滚轮在图表区）
  // =========================================================================
  group('signal scale (chart area scroll)', () {
    testWidgets('滚轮在图表区触发 X 轴缩放', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final chartCenter = controller.mainRect.center;
      final initWidth = controller.candleWidth;

      // dy > 0 → factor = exp(-30/200) ≈ 0.86 → candleWidth 缩小。
      await _sendScroll(tester, chartCenter, scrollDy: 30);
      expect(controller.candleWidth, lessThan(initWidth), reason: 'dy > 0 应缩小蜡烛');

      // 等待 session 超时。
      await tester.pump(const Duration(milliseconds: 900));
    });

    testWidgets('idle 窗口内连续滚动不提前结束 session', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final chartCenter = controller.mainRect.center;
      final initWidth = controller.candleWidth;

      // 快速连续滚动 3 次，间隔 100ms（远小于 800ms 超时）。
      for (var i = 0; i < 3; i++) {
        await _sendScroll(tester, chartCenter, scrollDy: 20);
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 三次滚动的缩放应叠加（比值口径累乘）。
      final afterWidth = controller.candleWidth;
      final factor3 = math.pow(math.exp(-20.0 / 200), 3);
      final expectedWidth = (initWidth * factor3).clamp(
        controller.candleMinWidth,
        controller.candleMaxWidth,
      );
      expect(
        afterWidth,
        closeTo(expectedWidth, 0.5),
        reason: '连续滚动应叠加缩放效果',
      );

      // 等待 session 超时结束。
      await tester.pump(const Duration(milliseconds: 900));
    });
  });

  // =========================================================================
  // PointerScaleEvent（Web 触控板捏合）
  // =========================================================================
  group('PointerScaleEvent', () {
    testWidgets('PointerScaleEvent 在图表区触发 X 轴缩放', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final chartCenter = controller.mainRect.center;
      final initWidth = controller.candleWidth;

      // scale > 1 → 放大蜡烛。
      await _sendScale(tester, chartCenter, scale: 1.2);
      expect(
        controller.candleWidth,
        greaterThan(initWidth),
        reason: 'PointerScaleEvent scale > 1 应放大',
      );

      // 等待 session 超时。
      await tester.pump(const Duration(milliseconds: 900));
    });

    testWidgets('PointerScaleEvent 在滑竿区触发 Y 轴缩放', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final slider = _sliderRect(controller);
      final initSpan = _rangeSpan(controller);

      // scale > 1 在滑竿区：onChartZoomStep(1.5) → scaleAroundCenter(1.5) → 区间扩大。
      await _sendScale(tester, slider.center, scale: 1.5);
      await _paintFrame(tester, controller);
      final afterSpan = _rangeSpan(controller);
      expect(afterSpan, greaterThan(initSpan), reason: 'Y 轴区间应扩大');
      expect(controller.isChartZooming, isTrue);
    });
  });

  // =========================================================================
  // 横向滚轮与边界
  // =========================================================================
  group('edge cases', () {
    testWidgets('dy == 0 的横向滚轮不产生任何变化', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final chartCenter = controller.mainRect.center;
      final initWidth = controller.candleWidth;
      final initDx = controller.paintDxOffset;

      await _sendScroll(tester, chartCenter, scrollDy: 0, scrollDx: 50);
      expect(controller.candleWidth, equals(initWidth));
      expect(controller.paintDxOffset, equals(initDx));
    });

    testWidgets('canvas 外的滚轮不产生任何变化', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final outside = Offset(
        controller.canvasRect.right + 50,
        controller.canvasRect.center.dy,
      );
      final initWidth = controller.candleWidth;

      await _sendScroll(tester, outside, scrollDy: 30);
      expect(controller.candleWidth, equals(initWidth));
    });
  });

  // =========================================================================
  // enableZoom / enableScale 关闭时放行
  // =========================================================================
  group('enable flags', () {
    testWidgets('enableZoom=false 时滑竿区滚轮不消费', (tester) async {
      final controller = await _pumpNonTouchChart(tester, enableZoom: false);
      addTearDown(() => _disposeChart(tester, controller));

      final slider = _sliderRect(controller);
      final initSpan = _rangeSpan(controller);

      await _sendScroll(tester, slider.center, scrollDy: 30);
      await _paintFrame(tester, controller);
      expect(_rangeSpan(controller), closeTo(initSpan, 0.01));
      expect(controller.isChartZooming, isFalse);
    });

    testWidgets('enableScale=false 时图表区滚轮不消费', (tester) async {
      final controller = await _pumpNonTouchChart(tester, enableScale: false);
      addTearDown(() => _disposeChart(tester, controller));

      final chartCenter = controller.mainRect.center;
      final initWidth = controller.candleWidth;

      await _sendScroll(tester, chartCenter, scrollDy: 30);
      expect(controller.candleWidth, equals(initWidth));
    });
  });
}
