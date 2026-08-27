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

/// 归属判定的唯一入口与优先级：落点归属六种，兜底归属两种。
library;

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/view/flexi_gesture_owner.dart';
import 'package:flutter/gestures.dart' show kScaleSlop, kTouchSlop;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'GESTURE-OWNER', interval: FlexiTimeInterval(1, TimeUnit.day));
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

void main() {
  Future<({ControllerScenario scene, TestInteractiveIndicator indicator})> arrange({
    Rect hitRect = _sharedHit,
  }) async {
    final scene = ControllerScenario();
    addTearDown(scene.dispose);
    final indicator = TestInteractiveIndicator(
      key: const ExternalIndicatorKey('gesture_owner'),
      hitRect: hitRect,
    );
    await scene.initWithData(_spec, _candles(), mainIndicators: [indicator], canvasWidth: 400);
    scene.controller.flushPendingKlineData();
    return (scene: scene, indicator: indicator);
  }

  testWidgets('编辑中的绘制对象先于同位置 PaintObject 取得落点归属', (tester) async {
    final (:scene, :indicator) = await arrange();
    registerTestDrawObject(scene.controller);
    scene.controller.setDrawVisible(true);
    drawTestLine(scene.controller, from: _lineFrom, to: _lineTo);

    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, _onLine),
      FlexiGestureOwner.drawEditing,
    );
    expect(indicator.object!.hitTestDragStartCount, 0);
  });

  testWidgets('zoom slider 先于其他落点归属', (tester) async {
    final (:scene, :indicator) = await arrange(hitRect: const Rect.fromLTWH(0, 0, 400, 480));
    scene.controller.updateGestureConfig((config) => config.copyWith(enableZoom: true));
    final position = scene.controller.mainRect.center;
    final slideRect = Rect.fromCenter(center: position, width: 80, height: 20);
    scene.controller.setChartZoomSlideBarRect(slideRect);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    registerTestDrawObject(scene.controller);
    scene.controller.setDrawVisible(true);
    drawTestLine(
      scene.controller,
      from: position - const Offset(40, 0),
      to: position + const Offset(40, 0),
    );

    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, position),
      FlexiGestureOwner.zoomSlider,
    );
    expect(indicator.object!.hitTestDragStartCount, 0);
  });

  testWidgets('zooming move 先于绘制、cross 与 PaintObject', (tester) async {
    final (:scene, :indicator) = await arrange(hitRect: const Rect.fromLTWH(0, 0, 400, 480));
    scene.controller.updateGestureConfig((config) => config.copyWith(enableZoom: true));
    final sliderPosition = scene.controller.mainRect.center;
    final slideRect = Rect.fromCenter(center: sliderPosition, width: 80, height: 20);
    scene.controller.setChartZoomSlideBarRect(slideRect);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(scene.controller.onChartZoomStart(sliderPosition, false), isTrue);
    final position = Offset(scene.controller.mainRect.center.dx, scene.controller.mainRect.top + 30);
    registerTestDrawObject(scene.controller);
    scene.controller.setDrawVisible(true);
    drawTestLine(
      scene.controller,
      from: position - const Offset(40, 0),
      to: position + const Offset(40, 0),
    );

    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, position),
      FlexiGestureOwner.zoomingMove,
    );
    expect(indicator.object!.hitTestDragStartCount, 0);
  });

  testWidgets('未完成绘制先于 cross 与 PaintObject', (tester) async {
    final (:scene, :indicator) = await arrange();
    registerTestDrawObject(scene.controller);
    scene.controller.setDrawVisible(true);
    scene.controller.startDraw(testDrawLineType, isInitPointer: false);
    scene.controller.onDrawConfirm(GestureData.tap(_lineFrom));
    expect(scene.controller.drawState.isDrawing, isTrue);

    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, _onLine),
      FlexiGestureOwner.drawDrawing,
    );
    expect(indicator.object!.hitTestDragStartCount, 0);
  });

  testWidgets('cross 先于 PaintObject', (tester) async {
    final (:scene, :indicator) = await arrange();
    expect(scene.controller.onCrossStart(GestureData.tap(_onLine)), isTrue);

    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, _onLine),
      FlexiGestureOwner.cross,
    );
    expect(indicator.object!.hitTestDragStartCount, 0);
  });

  testWidgets('其余状态未认领时由 PaintObject 取得归属', (tester) async {
    final (:scene, :indicator) = await arrange();

    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, _onLine),
      FlexiGestureOwner.paintObject,
    );
    expect(indicator.object!.hitTestDragStartCount, 1);
  });

  testWidgets('锁定的绘制对象不取得归属, 让位给同位置 PaintObject', (tester) async {
    final (:scene, :indicator) = await arrange();
    registerTestDrawObject(scene.controller);
    scene.controller.setDrawVisible(true);
    drawTestLine(scene.controller, from: _lineFrom, to: _lineTo);
    expect(scene.controller.setDrawLockState(true), isTrue);

    // 锁定即不可拖, 判据与 onDrawMoveStart 的 lock 检查同源。
    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, _onLine),
      FlexiGestureOwner.paintObject,
    );
    expect(indicator.object!.hitTestDragStartCount, 1);
  });

  testWidgets('绘制层隐藏时绘制对象不取得归属', (tester) async {
    final (:scene, :indicator) = await arrange();
    registerTestDrawObject(scene.controller);
    scene.controller.setDrawVisible(true);
    drawTestLine(scene.controller, from: _lineFrom, to: _lineTo);
    scene.controller.setDrawVisible(false);

    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, _onLine),
      FlexiGestureOwner.paintObject,
    );
    expect(indicator.object!.hitTestDragStartCount, 1);
  });

  testWidgets('六种归属都不满足时返回 null, 手势让给外层', (tester) async {
    final (:scene, :indicator) = await arrange();
    indicator.object!.acceptDrag = false;

    expect(FlexiGestureOwner.resolveLanded(scene.controller, _onLine), isNull);
  });

  group('兜底归属的判定顺序与边界', () {
    testWidgets('指间距变化优先于方向: 双指横向张开是缩放而非平移', (tester) async {
      final (:scene, indicator: _) = await arrange();

      // 双指横向张开时第一指同样是横向位移, 先判方向就会把缩放误判成平移。
      expect(
        FlexiGestureOwner.resolveChartFallback(
          scene.controller,
          delta: const Offset(40, 0),
          spanDelta: kScaleSlop + 1,
          hitSlop: kTouchSlop,
        ),
        FlexiGestureOwner.chartScale,
      );
    });

    testWidgets('样本不足: 位移未越过 hitSlop 且指间距未变时放弃', (tester) async {
      final (:scene, indicator: _) = await arrange();

      // 阈值取外层 hitSlop 而非更小的 claimSlop: TapGestureRecognizer 的
      // preAcceptSlopTolerance 就是同一个 touchSlop, 提前抢占会吃掉点击语义。
      expect(
        FlexiGestureOwner.resolveChartFallback(
          scene.controller,
          delta: const Offset(kTouchSlop, 0),
          spanDelta: 0,
          hitSlop: kTouchSlop,
        ),
        isNull,
      );
      expect(
        FlexiGestureOwner.resolveChartFallback(
          scene.controller,
          delta: const Offset(kTouchSlop + 1, 0),
          spanDelta: 0,
          hitSlop: kTouchSlop,
        ),
        FlexiGestureOwner.chartPan,
      );
    });

    testWidgets('横向占优按 panClaimRatio 取锥: 恰好等于比例不算占优', (tester) async {
      final (:scene, indicator: _) = await arrange();
      final ratio = scene.controller.gestureConfig.panClaimRatio;
      expect(ratio, 2);

      // 等于比例落在锥边界上: 判据是严格大于, 边界归外层。
      expect(
        FlexiGestureOwner.resolveChartFallback(
          scene.controller,
          delta: Offset(20 * ratio, -20),
          spanDelta: 0,
          hitSlop: kTouchSlop,
        ),
        isNull,
      );
      expect(
        FlexiGestureOwner.resolveChartFallback(
          scene.controller,
          delta: Offset(20 * ratio + 1, -20),
          spanDelta: 0,
          hitSlop: kTouchSlop,
        ),
        FlexiGestureOwner.chartPan,
      );
    });

    testWidgets('禁用缩放时张开手指不取得缩放归属, 退回方向判定', (tester) async {
      final (:scene, indicator: _) = await arrange();
      scene.controller.updateGestureConfig((config) => config.copyWith(enableScale: false));

      expect(
        FlexiGestureOwner.resolveChartFallback(
          scene.controller,
          delta: const Offset(40, 0),
          spanDelta: kScaleSlop + 1,
          hitSlop: kTouchSlop,
        ),
        FlexiGestureOwner.chartPan,
      );
      expect(
        FlexiGestureOwner.resolveChartFallback(
          scene.controller,
          delta: const Offset(0, -40),
          spanDelta: kScaleSlop + 1,
          hitSlop: kTouchSlop,
        ),
        isNull,
      );
    });
  });

  testWidgets('判定不产生任何状态变更', (tester) async {
    final (:scene, :indicator) = await arrange();
    registerTestDrawObject(scene.controller);
    scene.controller.setDrawVisible(true);
    drawTestLine(scene.controller, from: _lineFrom, to: _lineTo);

    // 每次 PointerDown 都会走一遍判定, 包括最终只是点击或长按的手势。
    FlexiGestureOwner.resolveLanded(scene.controller, _onLine);

    expect(scene.controller.drawState.object!.moving, isFalse);
    expect(scene.controller.isPaintObjectDragging, isFalse);
    expect(scene.controller.isCrossing, isFalse);
    expect(indicator.object!.calls, isEmpty);
  });
}
