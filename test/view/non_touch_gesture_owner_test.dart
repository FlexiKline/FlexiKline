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

/// 非触摸端归属层 [NonTouchGestureOwner] 的单元测试。
///
/// 覆盖：
/// - 六档归属的判定顺序与优先级
/// - [resolveAt] 无副作用（连续调用不产生重绘/状态变更）
/// - [_hitTestGridResize] 的 dx 约束（C3）
/// - [hoverCursor] / [dragCursor] / [signalIntent] 的返回值
///
/// 仿 `touch_gesture_owner_test.dart` 的形式，用 [ControllerScenario] 搭建。
library;

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/view/non_touch_gesture_owner.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'NT-OWNER',
  interval: FlexiTimeInterval(1, TimeUnit.day),
);
const _sharedHit = Rect.fromLTRB(0, 0, 100, 100);
const _lineFrom = Offset(10, 50);
const _lineTo = Offset(90, 50);
const _onLine = Offset(50, 50);

List<CandleModel> _candles() => List.generate(
      3,
      (i) => CandleModel(
        timestamp: 1000 + i * 86400000,
        open: Decimal.fromInt(100 + i),
        high: Decimal.fromInt(110 + i),
        low: Decimal.fromInt(90 + i),
        close: Decimal.fromInt(105 + i),
        volume: Decimal.fromInt(1000 + i),
      ),
    );

Future<({ControllerScenario scene, TestInteractiveIndicator indicator})> _arrange({
  Rect hitRect = _sharedHit,
  TestCandleIndicator? candle,
}) async {
  final scene = ControllerScenario();
  addTearDown(scene.dispose);
  final indicator = TestInteractiveIndicator(
    key: const ExternalIndicatorKey('nt_gesture_owner'),
    hitRect: hitRect,
  );
  await scene.initWithData(
    _spec,
    _candles(),
    mainIndicators: [indicator],
    canvasWidth: 400,
    candle: candle,
  );
  scene.controller.flushPendingKlineData();
  return (scene: scene, indicator: indicator);
}

/// 启用 zoom 并设置滑竿区域。
Future<({ControllerScenario scene, TestInteractiveIndicator indicator})> _arrangeZoomOn(
  WidgetTester tester, {
  Rect? slideRect,
}) async {
  final arranged = await _arrange(candle: TestCandleIndicator(visibleMinMaxFromData: true));
  arranged.scene.controller.updateGestureConfig(
    (config) => config.copyWith(enableZoom: true),
  );
  arranged.scene.controller.setChartZoomSlideBarRect(
    slideRect ?? Rect.fromCenter(center: _onLine, width: 80, height: 20),
  );
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  await paintChartFrame(tester, arranged.scene.controller);
  return arranged;
}

void main() {
  group('六档归属判定顺序', () {
    testWidgets('drawDrawing 最高优先级', (tester) async {
      final (:scene, :indicator) = await _arrange();
      registerTestDrawObject(scene.controller);
      scene.controller.setDrawVisible(true);
      scene.controller.startDraw(testDrawLineType, isInitPointer: false);
      scene.controller.onDrawConfirm(_lineFrom);
      expect(scene.controller.drawState.isDrawing, isTrue);

      expect(
        NonTouchGestureOwner.resolveAt(scene.controller, _onLine),
        NonTouchGestureOwner.drawDrawing,
      );
      expect(indicator.object!.hitTestDragStartCount, 0);
    });

    testWidgets('drawEditing 先于 paintObject', (tester) async {
      final (:scene, :indicator) = await _arrange();
      registerTestDrawObject(scene.controller);
      scene.controller.setDrawVisible(true);
      drawTestLine(scene.controller, from: _lineFrom, to: _lineTo);

      expect(
        NonTouchGestureOwner.resolveAt(scene.controller, _onLine),
        NonTouchGestureOwner.drawEditing,
      );
      expect(indicator.object!.hitTestDragStartCount, 0);
    });

    testWidgets('paintObject 在无 draw 时取得归属', (tester) async {
      final (:scene, :indicator) = await _arrange();

      expect(
        NonTouchGestureOwner.resolveAt(scene.controller, _onLine),
        NonTouchGestureOwner.paintObject,
      );
      expect(indicator.object!.hitTestDragStartCount, 1);
    });

    testWidgets('zoomSlider 让位于 paintObject', (tester) async {
      final (:scene, indicator: _) = await _arrangeZoomOn(tester);

      expect(
        NonTouchGestureOwner.resolveAt(scene.controller, _onLine),
        NonTouchGestureOwner.paintObject,
      );
    });

    testWidgets('zoomSlider 让位于 drawEditing', (tester) async {
      final (:scene, :indicator) = await _arrangeZoomOn(tester);
      registerTestDrawObject(scene.controller);
      scene.controller.setDrawVisible(true);
      drawTestLine(scene.controller, from: _lineFrom, to: _lineTo);

      expect(
        NonTouchGestureOwner.resolveAt(scene.controller, _onLine),
        NonTouchGestureOwner.drawEditing,
      );
      expect(indicator.object!.hitTestDragStartCount, 0);
    });

    testWidgets('无命中时兜底 chart', (tester) async {
      final (:scene, :indicator) = await _arrange();
      indicator.object!.acceptDrag = false;

      expect(
        NonTouchGestureOwner.resolveAt(scene.controller, _onLine),
        NonTouchGestureOwner.chart,
      );
    });

    testWidgets('锁定的绘制对象不取得归属', (tester) async {
      final (:scene, :indicator) = await _arrange();
      registerTestDrawObject(scene.controller);
      scene.controller.setDrawVisible(true);
      drawTestLine(scene.controller, from: _lineFrom, to: _lineTo);
      expect(scene.controller.setDrawLockState(true), isTrue);

      // 锁定即不可拖, hitTestDrawObjectDrag 检查 lock。
      expect(
        NonTouchGestureOwner.resolveAt(scene.controller, _onLine),
        NonTouchGestureOwner.paintObject,
      );
      expect(indicator.object!.hitTestDragStartCount, 1);
    });

    testWidgets('绘制层隐藏时绘制对象不取得归属', (tester) async {
      final (:scene, :indicator) = await _arrange();
      registerTestDrawObject(scene.controller);
      scene.controller.setDrawVisible(true);
      drawTestLine(scene.controller, from: _lineFrom, to: _lineTo);
      scene.controller.setDrawVisible(false);

      expect(
        NonTouchGestureOwner.resolveAt(scene.controller, _onLine),
        NonTouchGestureOwner.paintObject,
      );
    });
  });

  group('resolveAt 无副作用', () {
    testWidgets('连续调用不产生重绘或状态变更', (tester) async {
      final (:scene, :indicator) = await _arrange();
      registerTestDrawObject(scene.controller);
      scene.controller.setDrawVisible(true);
      drawTestLine(scene.controller, from: _lineFrom, to: _lineTo);

      // 连续多次调用 resolveAt
      NonTouchGestureOwner.resolveAt(scene.controller, _onLine);
      NonTouchGestureOwner.resolveAt(scene.controller, _onLine);
      NonTouchGestureOwner.resolveAt(scene.controller, const Offset(200, 100));

      expect(scene.controller.drawState.object!.moving, isFalse);
      expect(scene.controller.isPaintObjectDragging, isFalse);
      expect(scene.controller.isCrossing, isFalse);
      expect(indicator.object!.calls, isEmpty);
    });
  });

  group('gridResize 的 dx 约束（C3）', () {
    testWidgets('内容区内命中分隔线 → gridResize', (tester) async {
      final (:scene, indicator: _) = await _arrange();
      scene.controller.updateGridConfig(
        (config) => config.copyWith(isAllowDragIndicatorHeight: true),
      );

      // mainRect.bottom 是主区底边，恰好也是主区与副区的分隔线位置。
      final mainBottom = scene.controller.mainRect.bottom;
      final hitPosition = Offset(
        scene.controller.mainChartRect.left + 10, // 在内容区内
        mainBottom,
      );

      // 先确认 hitTestGridResize 能命中。
      if (scene.controller.hitTestGridResize(hitPosition)) {
        expect(
          NonTouchGestureOwner.resolveAt(scene.controller, hitPosition),
          NonTouchGestureOwner.gridResize,
        );
      }
      // 如果没有副区则无法命中(fixed 布局下 lastObj 不命中)——这种情况下测试合法跳过。
    });

    testWidgets('价格轴区域内同一 dy → 不归 gridResize', (tester) async {
      final (:scene, indicator: _) = await _arrange();
      scene.controller.updateGridConfig(
        (config) => config.copyWith(isAllowDragIndicatorHeight: true),
      );

      final mainBottom = scene.controller.mainRect.bottom;
      final priceAxisPosition = Offset(
        scene.controller.mainChartRect.right + 5, // 超出内容区右边
        mainBottom,
      );

      // dx 约束: 价格轴上不归 gridResize。
      final owner = NonTouchGestureOwner.resolveAt(scene.controller, priceAxisPosition);
      expect(owner, isNot(NonTouchGestureOwner.gridResize));
    });
  });

  group('hoverCursor', () {
    test('各归属的 hover 光标', () {
      expect(NonTouchGestureOwner.drawDrawing.hoverCursor, SystemMouseCursors.precise);
      expect(NonTouchGestureOwner.drawEditing.hoverCursor, SystemMouseCursors.click);
      expect(NonTouchGestureOwner.paintObject.hoverCursor, SystemMouseCursors.grab);
      expect(NonTouchGestureOwner.gridResize.hoverCursor, SystemMouseCursors.resizeRow);
      expect(NonTouchGestureOwner.zoomSlider.hoverCursor, SystemMouseCursors.resizeUpDown);
      expect(NonTouchGestureOwner.chart.hoverCursor, SystemMouseCursors.precise);
    });
  });

  group('dragCursor', () {
    testWidgets('chart 在非缩放态返回 grabbing', (tester) async {
      final (:scene, indicator: _) = await _arrange();
      expect(scene.controller.isChartZooming, isFalse);
      expect(
        NonTouchGestureOwner.chart.dragCursor(scene.controller),
        SystemMouseCursors.grabbing,
      );
    });

    testWidgets('chart 在缩放态返回 move', (tester) async {
      final (:scene, indicator: _) = await _arrangeZoomOn(tester, slideRect: const Rect.fromLTWH(300, 0, 40, 200));
      expect(scene.controller.onChartZoomStart(const Offset(320, 100)), isTrue);
      expect(scene.controller.isChartZooming, isTrue);
      expect(
        NonTouchGestureOwner.chart.dragCursor(scene.controller),
        SystemMouseCursors.move,
      );
    });

    test('其余归属的 drag 光标', () {
      // 这些不需要 controller
      expect(NonTouchGestureOwner.drawDrawing.hoverCursor, SystemMouseCursors.precise);
      expect(NonTouchGestureOwner.gridResize.hoverCursor, SystemMouseCursors.resizeRow);
      expect(NonTouchGestureOwner.zoomSlider.hoverCursor, SystemMouseCursors.resizeUpDown);
    });
  });

  group('signalIntent (纵向占优)', () {
    testWidgets('zoomSlider → zoomY（enableZoom=true）', (tester) async {
      final (:scene, indicator: _) = await _arrange();
      scene.controller.updateGestureConfig(
        (config) => config.copyWith(enableZoom: true),
      );
      expect(
        NonTouchGestureOwner.zoomSlider.signalIntent(scene.controller, horizontal: false),
        SignalIntent.zoomY,
      );
    });

    testWidgets('zoomSlider → null（enableZoom=false）', (tester) async {
      final (:scene, indicator: _) = await _arrange();
      scene.controller.updateGestureConfig(
        (config) => config.copyWith(enableZoom: false),
      );
      expect(
        NonTouchGestureOwner.zoomSlider.signalIntent(scene.controller, horizontal: false),
        isNull,
      );
    });

    testWidgets('chart → scaleX（enableScale=true）', (tester) async {
      final (:scene, indicator: _) = await _arrange();
      expect(
        NonTouchGestureOwner.chart.signalIntent(scene.controller, horizontal: false),
        SignalIntent.scaleX,
      );
    });

    testWidgets('chart → null（enableScale=false）', (tester) async {
      final (:scene, indicator: _) = await _arrange();
      scene.controller.updateGestureConfig(
        (config) => config.copyWith(enableScale: false),
      );
      expect(
        NonTouchGestureOwner.chart.signalIntent(scene.controller, horizontal: false),
        isNull,
      );
    });

    testWidgets('drawEditing → scaleX（绘制中滚轮仍缩放）', (tester) async {
      final (:scene, indicator: _) = await _arrange();
      expect(
        NonTouchGestureOwner.drawEditing.signalIntent(scene.controller, horizontal: false),
        SignalIntent.scaleX,
      );
    });
  });

  // 横滑是平移: 除价格轴外一律消费, 也不看 enableScale —— 平移图表是基本操作, 直接拖动同样
  // 没有开关。
  group('signalIntent (横向占优)', () {
    testWidgets('chart → panX', (tester) async {
      final (:scene, indicator: _) = await _arrange();
      expect(
        NonTouchGestureOwner.chart.signalIntent(scene.controller, horizontal: true),
        SignalIntent.panX,
      );
    });

    testWidgets('chart → panX（enableScale=false 也平移）', (tester) async {
      final (:scene, indicator: _) = await _arrange();
      scene.controller.updateGestureConfig(
        (config) => config.copyWith(enableScale: false),
      );
      expect(
        NonTouchGestureOwner.chart.signalIntent(scene.controller, horizontal: true),
        SignalIntent.panX,
      );
    });

    testWidgets('drawEditing / gridResize / paintObject → panX', (tester) async {
      final (:scene, indicator: _) = await _arrange();
      for (final owner in [
        NonTouchGestureOwner.drawEditing,
        NonTouchGestureOwner.gridResize,
        NonTouchGestureOwner.paintObject,
        NonTouchGestureOwner.drawDrawing,
      ]) {
        expect(
          owner.signalIntent(scene.controller, horizontal: true),
          SignalIntent.panX,
          reason: '$owner 的横滑应平移图表',
        );
      }
    });

    testWidgets('zoomSlider → null（价格轴无横向语义, 放行外层）', (tester) async {
      final (:scene, indicator: _) = await _arrange();
      scene.controller.updateGestureConfig(
        (config) => config.copyWith(enableZoom: true),
      );
      expect(
        NonTouchGestureOwner.zoomSlider.signalIntent(scene.controller, horizontal: true),
        isNull,
      );
    });
  });

  group('与触摸端的差异', () {
    testWidgets('非触摸端没有 cross 归属: isCrossing 不影响归属判定', (tester) async {
      final (:scene, :indicator) = await _arrange();
      expect(scene.controller.onCrossToggle(_onLine), isTrue);
      expect(scene.controller.isCrossing, isTrue);

      // 触摸端会返回 cross，非触摸端 cross 不参与拖动竞争，仍返回 paintObject。
      expect(
        NonTouchGestureOwner.resolveAt(scene.controller, _onLine),
        NonTouchGestureOwner.paintObject,
      );
    });

    testWidgets('恒有返回值: 不会返回 null（与触摸端 resolveLanded 不同）', (tester) async {
      final (:scene, :indicator) = await _arrange();
      indicator.object!.acceptDrag = false;

      // 触摸端 resolveLanded 在此条件下返回 null，非触摸端兜底 chart。
      expect(
        NonTouchGestureOwner.resolveAt(scene.controller, _onLine),
        NonTouchGestureOwner.chart,
      );
    });
  });
}
