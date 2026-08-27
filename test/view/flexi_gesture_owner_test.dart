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

  /// zoom 族排在落点族末位：判据只有「落点在不在某个 Rect 里」，是六种落点归属里意图最弱
  /// 的一档，不能截走已进入模式或已命中对象的手势。见 design.md 决策 8。
  ///
  /// 启用 zoom 并把滑竿区设在 [_onLine] 上：该点同时命中 PaintObject。
  Future<({ControllerScenario scene, TestInteractiveIndicator indicator})> arrangeZoomOn(
    WidgetTester tester, {
    Rect? slideRect,
  }) async {
    final arranged = await arrange();
    arranged.scene.controller.updateGestureConfig((config) => config.copyWith(enableZoom: true));
    arranged.scene.controller.setChartZoomSlideBarRect(
      slideRect ?? Rect.fromCenter(center: _onLine, width: 80, height: 20),
    );
    // setChartZoomSlideBarRect 走 addPostFrameCallback, 必须泵一帧才生效。
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    return arranged;
  }

  testWidgets('zoom slider 让位于编辑中的绘制对象', (tester) async {
    final (:scene, :indicator) = await arrangeZoomOn(tester);
    registerTestDrawObject(scene.controller);
    scene.controller.setDrawVisible(true);
    drawTestLine(scene.controller, from: _lineFrom, to: _lineTo);

    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, _onLine),
      FlexiGestureOwner.drawEditing,
    );
    expect(indicator.object!.hitTestDragStartCount, 0);
  });

  testWidgets('zoom slider 让位于 cross', (tester) async {
    final (:scene, :indicator) = await arrangeZoomOn(tester);
    expect(scene.controller.onCrossStart(GestureData.tap(_onLine)), isTrue);

    // 真机反馈的那类困惑: 已进入十字线, 落在价格轴上却被当成调主区留白。
    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, _onLine),
      FlexiGestureOwner.cross,
    );
    expect(indicator.object!.hitTestDragStartCount, 0);
  });

  testWidgets('zoom slider 让位于同位置 PaintObject', (tester) async {
    final (:scene, indicator: _) = await arrangeZoomOn(tester);

    // 滑竿是价格轴那一整条(全高隐形热区), 与 TP/SL 一类手柄必然重叠; 手柄优先只让滑竿在
    // 少数小区域失效, 反过来则让手柄永久拖不动。
    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, _onLine),
      FlexiGestureOwner.paintObject,
    );
  });

  testWidgets('zooming move 让位于同位置 PaintObject', (tester) async {
    // 滑竿挪到命中区之外, 用它启动 zoom, 再查命中区内的落点。
    const sliderRect = Rect.fromLTWH(300, 0, 40, 200);
    final (:scene, indicator: _) = await arrangeZoomOn(tester, slideRect: sliderRect);
    expect(scene.controller.onChartZoomStart(sliderRect.center, false), isTrue);

    // isChartZooming 是粘性状态、领地是整个 mainRect, 排在前面等于长期接管主区所有拖动。
    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, _onLine),
      FlexiGestureOwner.paintObject,
    );
  });

  testWidgets('其余落点归属都不认领时才归 zoom slider 与 zooming move', (tester) async {
    // 两个查询点都落在 PaintObject 命中区(_sharedHit)之外, 于是只剩 zoom 族可认领。
    const sliderRect = Rect.fromLTWH(300, 0, 40, 200);
    final (:scene, indicator: _) = await arrangeZoomOn(tester, slideRect: sliderRect);

    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, sliderRect.center),
      FlexiGestureOwner.zoomSlider,
    );
    expect(scene.controller.onChartZoomStart(sliderRect.center, false), isTrue);
    expect(
      FlexiGestureOwner.resolveLanded(scene.controller, const Offset(200, 150)),
      FlexiGestureOwner.zoomingMove,
    );
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
