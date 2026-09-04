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
/// - 横向占优的滚轮 → 图表平移（onChartPanStep），一个事件只做一件事
/// - enableZoom / enableScale 关闭时不消费事件（放行外层）
///
/// 覆盖边界：经 PointerSignalEvent → Listener → onPointerSignal → controller API。
/// **不覆盖**：真机滚轮 scrollDelta 的量级与 dx/dy 比例、光标外观。
/// **未经真机验证**：浏览器给出的真实 delta 手感、`-scrollDelta.dx` 的符号方向。
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

/// 把鼠标移入图表，建立 hover 态的 cross（非触摸端 cross 只由 hover 开启）。
Future<void> _enterMouse(WidgetTester tester, Offset localPosition) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: _toGlobal(tester, localPosition));
  addTearDown(() => mouse.removePointer());
  await tester.pump();
}

/// 稳定落在蜡烛区的 cross 焦点：往左第 5 根。空白区（`dx > startCandleDx`）另有
/// `crossConfig.moveByCandleInBlank` 决定吸不吸附，本组不测那条分支。
Offset _candleAreaFocus(FlexiKlineController chart) => Offset(
      chart.startCandleDx - chart.candleActualWidth * 5,
      chart.mainRect.center.dy,
    );

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
  // 横向平移（横向占优的滚轮 / Web 触控板双指横滑）
  // =========================================================================
  //
  // 判据 `|dx| >= |dy| × 2`，在意图解析之前判。位移 1:1，与外层 Scrollable 同一口径。
  group('signal pan (horizontal scroll)', () {
    testWidgets('横滑平移视口，不缩放也不进入 Y 轴缩放', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final chartCenter = controller.mainRect.center;
      final initDx = controller.paintDxOffset;
      final initWidth = controller.candleWidth;
      final initSpan = _rangeSpan(controller);

      await _sendScroll(tester, chartCenter, scrollDy: 0, scrollDx: 50);
      await _paintFrame(tester, controller);

      expect(controller.paintDxOffset, isNot(closeTo(initDx, precisionError)), reason: '横滑应平移视口');
      expect(controller.candleWidth, equals(initWidth), reason: '横滑不改蜡烛宽度');
      expect(_rangeSpan(controller), closeTo(initSpan, 0.01), reason: '横滑不改价格区间');
      expect(controller.isChartZooming, isFalse, reason: '横滑不该让 Y 轴进入用户接管态');
    });

    testWidgets('dx > 0 视口向新数据方向移动，位移 1:1', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final chartCenter = controller.mainRect.center;
      final initDx = controller.paintDxOffset;

      await _sendScroll(tester, chartCenter, scrollDy: 0, scrollDx: 50);
      expect(
        controller.paintDxOffset,
        closeTo(initDx - 50, precisionError),
        reason: 'dx > 0 → paintDxOffset 减小, 且量为 1:1',
      );

      await _sendScroll(tester, chartCenter, scrollDy: 0, scrollDx: -50);
      expect(controller.paintDxOffset, closeTo(initDx, precisionError), reason: '反向等量应回到原位');
    });

    testWidgets('一个事件只做一件事：按 2:1 分派平移或缩放', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final chartCenter = controller.mainRect.center;

      // 横向主导 100 : 40 → 平移。
      var dxBefore = controller.paintDxOffset;
      var widthBefore = controller.candleWidth;
      await _sendScroll(tester, chartCenter, scrollDy: 40, scrollDx: 100);
      expect(controller.paintDxOffset, closeTo(dxBefore - 100, precisionError), reason: '横向主导应平移');
      expect(controller.candleWidth, equals(widthBefore), reason: '横向主导不该同时缩放');

      // 纵向主导 40 : 100 → 缩放。
      dxBefore = controller.paintDxOffset;
      widthBefore = controller.candleWidth;
      await _sendScroll(tester, chartCenter, scrollDy: 100, scrollDx: 40);
      expect(controller.candleWidth, lessThan(widthBefore), reason: '纵向主导应缩放');
      // X 轴缩放本身会按锚点改写 paintDxOffset, 所以只断言没有额外平移 40。
      expect(
        controller.paintDxOffset,
        isNot(closeTo(dxBefore - 40, precisionError)),
        reason: '纵向主导不该同时按 dx 平移',
      );

      // 恰好 2:1 → 归横滑，固定判据取 `>=` 而非 `>`。
      await tester.pump(const Duration(milliseconds: 900)); // 结束上一段 scale session
      dxBefore = controller.paintDxOffset;
      widthBefore = controller.candleWidth;
      await _sendScroll(tester, chartCenter, scrollDy: 50, scrollDx: 100);
      expect(controller.paintDxOffset, closeTo(dxBefore - 100, precisionError), reason: '恰好 2:1 应判为横滑');
      expect(controller.candleWidth, equals(widthBefore), reason: '恰好 2:1 不该缩放');
    });

    testWidgets('价格轴上的横滑不消费', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final initDx = controller.paintDxOffset;
      final initSpan = _rangeSpan(controller);

      await _sendScroll(tester, _sliderRect(controller).center, scrollDy: 0, scrollDx: 50);
      await _paintFrame(tester, controller);

      expect(controller.paintDxOffset, equals(initDx), reason: '价格轴横滑没有图表语义, 不该平移');
      expect(_rangeSpan(controller), closeTo(initSpan, 0.01));
      expect(controller.isChartZooming, isFalse);
    });

    testWidgets('横滑后 cross 按新视口重新吸附', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final focus = _candleAreaFocus(controller);
      expect(controller.canvasRect.include(focus), isTrue, reason: '前置：焦点必须落在画布内');

      await _enterMouse(tester, focus);
      expect(controller.isCrossing, isTrue, reason: '前置：hover 应开启 cross');
      final crossBefore = controller.crossOffset;
      expect(crossBefore, isNotNull);

      // 错开半根：整根位移下吸附结果不变, 测不出有没有重算。
      final scrollDx = controller.candleActualWidth * 1.5;
      await _sendScroll(tester, focus, scrollDy: 0, scrollDx: scrollDx);

      expect(controller.isCrossing, isTrue, reason: '横滑不该关闭 cross');
      expect(
        controller.crossOffset!.dx,
        isNot(closeTo(crossBefore!.dx, precisionError)),
        reason: '指针没动但 startCandleDx 变了, 焦点该吸附到另一根蜡烛',
      );
    });

    testWidgets('连续横滑跨过 loadMore 阈值只请求一次', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      expect(
        controller.klineData.loadingState.isLoadMore,
        isFalse,
        reason: '前置：初始不应已在 loadMore',
      );

      var loadMoreCount = 0;
      controller.onLoadMoreCandles = (spec) async => loadMoreCount++;
      // FakeFlexiKlineConfiguration 默认关掉自动加载(免得别的用例意外发请求), 这条要测它。
      controller.updateSettingConfig((c) => c.copyWith(autoLoadMoreData: true));
      // 阈值放到远大于数据总宽, 一次横滑就跨过。
      controller.updateGestureConfig(
        (c) => c.copyWith(loadMoreWhenNoEnoughCandles: 100000),
      );

      final chartCenter = controller.mainRect.center;
      // dx < 0 → paintDxOffset 增大 → 趋向历史边界。
      await _sendScroll(tester, chartCenter, scrollDy: 0, scrollDx: -100);
      expect(loadMoreCount, 1, reason: '首次跨过阈值应请求一次');

      await _sendScroll(tester, chartCenter, scrollDy: 0, scrollDx: -100);
      await _sendScroll(tester, chartCenter, scrollDy: 0, scrollDx: -100);
      expect(loadMoreCount, 1, reason: '已在 loadMore 态, 后续横滑不得重复请求');
    });
  });

  // =========================================================================
  // 边界
  // =========================================================================
  group('edge cases', () {
    testWidgets('dx 与 dy 同为 0 的空事件不产生任何变化', (tester) async {
      final controller = await _pumpNonTouchChart(tester);
      addTearDown(() => _disposeChart(tester, controller));

      final chartCenter = controller.mainRect.center;
      final initWidth = controller.candleWidth;
      final initDx = controller.paintDxOffset;

      await _sendScroll(tester, chartCenter, scrollDy: 0, scrollDx: 0);
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

  // =========================================================================
  // 与外层 Scrollable 的竞争
  // =========================================================================
  //
  // 「不注册 resolver = 放行」只有真实可滚动容器在场才测得出。另外纵向 Scrollable 对纯横滑
  // 本来就不注册（它按 axisDirection 取 delta，横滑在纵向轴上为 0），所以图表消费横滑与外层
  // 无冲突——第一条固定这个事实。
  group('nested Scrollable', () {
    Future<({FlexiKlineController chart, ScrollController scroll})> arrange(
      WidgetTester tester,
    ) async {
      final scene = await pumpChartInListView(
        tester,
        spec: _spec,
        candles: genFlatCandleList(),
        candle: TestCandleIndicator(visibleMinMaxFromData: true),
        isTouchDevice: false,
      );
      addTearDown(() => disposeChart(tester, scene.chart));
      return scene;
    }

    Future<void> sendScroll(
      WidgetTester tester,
      FlexiKlineController chart,
      Offset localPosition, {
      double scrollDy = 0,
      double scrollDx = 0,
    }) async {
      await tester.sendEventToBinding(PointerScrollEvent(
        position: toNonTouchChartGlobal(tester, localPosition),
        scrollDelta: Offset(scrollDx, scrollDy),
      ));
      await tester.pump();
    }

    testWidgets('图表消费横滑时外层不滚动', (tester) async {
      final (:chart, :scroll) = await arrange(tester);

      final initDx = chart.paintDxOffset;
      final scrollBefore = scroll.offset;

      await sendScroll(tester, chart, chart.mainRect.center, scrollDx: 50);

      expect(chart.paintDxOffset, closeTo(initDx - 50, precisionError), reason: '图表应消费横滑');
      expect(scroll.offset, scrollBefore, reason: '外层不该跟着滚');
    });

    testWidgets('图表消费纵滑缩放时外层不滚动', (tester) async {
      final (:chart, :scroll) = await arrange(tester);

      final initWidth = chart.candleWidth;
      final scrollBefore = scroll.offset;

      await sendScroll(tester, chart, chart.mainRect.center, scrollDy: 60);

      expect(chart.candleWidth, lessThan(initWidth), reason: '图表应消费纵滑');
      expect(scroll.offset, scrollBefore, reason: '外层不该跟着滚');

      await tester.pump(const Duration(milliseconds: 900)); // 结束 scale session
    });

    testWidgets('两种缩放都关闭时纵滑放行给外层', (tester) async {
      final (:chart, :scroll) = await arrange(tester);

      chart.updateGestureConfig(
        (c) => c.copyWith(enableZoom: false, enableScale: false),
      );
      final initWidth = chart.candleWidth;

      await sendScroll(tester, chart, chart.mainRect.center, scrollDy: 60);

      expect(chart.candleWidth, equals(initWidth), reason: '图表不该消费');
      expect(scroll.offset, greaterThan(0), reason: '事件应放行给外层滚动');
    });
  });
}
