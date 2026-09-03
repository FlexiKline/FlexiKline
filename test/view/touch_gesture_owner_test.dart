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
import 'package:flexi_kline/src/view/touch_gesture_owner.dart';
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
    TestCandleIndicator? candle,
  }) async {
    final scene = ControllerScenario();
    addTearDown(scene.dispose);
    final indicator = TestInteractiveIndicator(
      key: const ExternalIndicatorKey('gesture_owner'),
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

  testWidgets('编辑中的绘制对象先于同位置 PaintObject 取得落点归属', (tester) async {
    final (:scene, :indicator) = await arrange();
    registerTestDrawObject(scene.controller);
    scene.controller.setDrawVisible(true);
    drawTestLine(scene.controller, from: _lineFrom, to: _lineTo);

    expect(
      TouchGestureOwner.resolveLanded(scene.controller, _onLine),
      TouchGestureOwner.drawEditing,
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
    final arranged = await arrange(candle: TestCandleIndicator(visibleMinMaxFromData: true));
    arranged.scene.controller.updateGestureConfig((config) => config.copyWith(enableZoom: true));
    arranged.scene.controller.setChartZoomSlideBarRect(
      slideRect ?? Rect.fromCenter(center: _onLine, width: 80, height: 20),
    );
    // setChartZoomSlideBarRect 走 addPostFrameCallback, 必须泵一帧才生效。
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    // onChartZoomStart 要求已有可见价格区间: 没有区间可缩放时不进入缩放态。
    await paintChartFrame(tester, arranged.scene.controller);
    return arranged;
  }

  testWidgets('zoom slider 让位于编辑中的绘制对象', (tester) async {
    final (:scene, :indicator) = await arrangeZoomOn(tester);
    registerTestDrawObject(scene.controller);
    scene.controller.setDrawVisible(true);
    drawTestLine(scene.controller, from: _lineFrom, to: _lineTo);

    expect(
      TouchGestureOwner.resolveLanded(scene.controller, _onLine),
      TouchGestureOwner.drawEditing,
    );
    expect(indicator.object!.hitTestDragStartCount, 0);
  });

  testWidgets('zoom slider 让位于 cross', (tester) async {
    final (:scene, :indicator) = await arrangeZoomOn(tester);
    expect(scene.controller.onCrossStart(GestureData.tap(_onLine)), isTrue);

    // 真机反馈的那类困惑: 已进入十字线, 落在价格轴上却被当成调主区留白。
    expect(
      TouchGestureOwner.resolveLanded(scene.controller, _onLine),
      TouchGestureOwner.cross,
    );
    expect(indicator.object!.hitTestDragStartCount, 0);
  });

  testWidgets('zoom slider 让位于同位置 PaintObject', (tester) async {
    final (:scene, indicator: _) = await arrangeZoomOn(tester);

    // 滑竿是价格轴那一整条(全高隐形热区), 与 TP/SL 一类手柄必然重叠; 手柄优先只让滑竿在
    // 少数小区域失效, 反过来则让手柄永久拖不动。
    expect(
      TouchGestureOwner.resolveLanded(scene.controller, _onLine),
      TouchGestureOwner.paintObject,
    );
  });

  /// zoom 态不再是一档落点归属：Y 轴由谁控制属于模型状态，不在归属层表达。
  ///
  /// 曾有一档 `zoomingMove`，领地是整个 `mainRect`，于是「调过一次留白」之后主区内任何拖动
  /// 都归它 —— 既截走同位置的 PaintObject，又让用户无从感知自己身处何种模式。
  testWidgets('zoom 态下主区落点仍归同位置 PaintObject', (tester) async {
    // 滑竿挪到命中区之外, 用它启动 zoom, 再查命中区内的落点。
    const sliderRect = Rect.fromLTWH(300, 0, 40, 200);
    final (:scene, indicator: _) = await arrangeZoomOn(tester, slideRect: sliderRect);
    expect(scene.controller.onChartZoomStart(sliderRect.center), isTrue);
    expect(scene.controller.isChartZooming, isTrue);

    expect(
      TouchGestureOwner.resolveLanded(scene.controller, _onLine),
      TouchGestureOwner.paintObject,
    );
  });

  testWidgets('zoom 态下无落点归属的主区拖动落到兜底，不再有专属归属', (tester) async {
    const sliderRect = Rect.fromLTWH(300, 0, 40, 200);
    final (:scene, indicator: _) = await arrangeZoomOn(tester, slideRect: sliderRect);

    expect(
      TouchGestureOwner.resolveLanded(scene.controller, sliderRect.center),
      TouchGestureOwner.zoomSlider,
    );
    expect(scene.controller.onChartZoomStart(sliderRect.center), isTrue);
    // 命中区之外、滑竿之外的落点: 落点族全部不认领, 交给兜底族按位移判定。
    expect(
      TouchGestureOwner.resolveLanded(scene.controller, const Offset(200, 150)),
      isNull,
    );
  });

  /// 兜底判据按模型状态分流：自动模式下纯纵向拖动让给外层，缩放态下它是平移价格区间。
  testWidgets('自动模式：纯纵向拖动不认领，让给外层滚动', (tester) async {
    final (:scene, indicator: _) = await arrangeZoomOn(tester);
    expect(scene.controller.isChartZooming, isFalse);

    expect(
      TouchGestureOwner.resolveChartFallback(
        scene.controller,
        delta: const Offset(0, 40),
        spanDelta: 0,
        hitSlop: kTouchSlop,
      ),
      isNull,
    );
  });

  testWidgets('缩放态：纯纵向拖动归 chartPan，方向锥判据不适用', (tester) async {
    const sliderRect = Rect.fromLTWH(300, 0, 40, 200);
    final (:scene, indicator: _) = await arrangeZoomOn(tester, slideRect: sliderRect);
    expect(scene.controller.onChartZoomStart(sliderRect.center), isTrue);

    expect(
      TouchGestureOwner.resolveChartFallback(
        scene.controller,
        delta: const Offset(0, 40),
        spanDelta: 0,
        hitSlop: kTouchSlop,
      ),
      TouchGestureOwner.chartPan,
    );
  });

  testWidgets('缩放态：位移不足 hitSlop 仍不认领', (tester) async {
    const sliderRect = Rect.fromLTWH(300, 0, 40, 200);
    final (:scene, indicator: _) = await arrangeZoomOn(tester, slideRect: sliderRect);
    expect(scene.controller.onChartZoomStart(sliderRect.center), isTrue);

    // 放宽的只有方向判据, 阈值判据照旧 —— 且比旧 zoomingMove 的 claimSlop 更晚抢占。
    expect(
      TouchGestureOwner.resolveChartFallback(
        scene.controller,
        delta: const Offset(0, kTouchSlop - 1),
        spanDelta: 0,
        hitSlop: kTouchSlop,
      ),
      isNull,
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
      TouchGestureOwner.resolveLanded(scene.controller, _onLine),
      TouchGestureOwner.drawDrawing,
    );
    expect(indicator.object!.hitTestDragStartCount, 0);
  });

  testWidgets('cross 先于 PaintObject', (tester) async {
    final (:scene, :indicator) = await arrange();
    expect(scene.controller.onCrossStart(GestureData.tap(_onLine)), isTrue);

    expect(
      TouchGestureOwner.resolveLanded(scene.controller, _onLine),
      TouchGestureOwner.cross,
    );
    expect(indicator.object!.hitTestDragStartCount, 0);
  });

  testWidgets('其余状态未认领时由 PaintObject 取得归属', (tester) async {
    final (:scene, :indicator) = await arrange();

    expect(
      TouchGestureOwner.resolveLanded(scene.controller, _onLine),
      TouchGestureOwner.paintObject,
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
      TouchGestureOwner.resolveLanded(scene.controller, _onLine),
      TouchGestureOwner.paintObject,
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
      TouchGestureOwner.resolveLanded(scene.controller, _onLine),
      TouchGestureOwner.paintObject,
    );
    expect(indicator.object!.hitTestDragStartCount, 1);
  });

  testWidgets('六种归属都不满足时返回 null, 手势让给外层', (tester) async {
    final (:scene, :indicator) = await arrange();
    indicator.object!.acceptDrag = false;

    expect(TouchGestureOwner.resolveLanded(scene.controller, _onLine), isNull);
  });

  group('兜底归属的判定顺序与边界', () {
    testWidgets('指间距变化优先于方向: 双指横向张开是缩放而非平移', (tester) async {
      final (:scene, indicator: _) = await arrange();

      // 双指横向张开时第一指同样是横向位移, 先判方向就会把缩放误判成平移。
      expect(
        TouchGestureOwner.resolveChartFallback(
          scene.controller,
          delta: const Offset(40, 0),
          spanDelta: kScaleSlop + 1,
          hitSlop: kTouchSlop,
        ),
        TouchGestureOwner.chartScale,
      );
    });

    testWidgets('缩放抢占按指间距变化判定, 与外层 hitSlop 同量纲', (tester) async {
      final (:scene, indicator: _) = await arrange();
      expect(scene.controller.gestureConfig.scaleClaimSlopFactor, 1);

      // spanDelta 是「各指到质心的平均距离」之差, 两指时为指间距变化的一半, 判据 × 2 还原。
      // 直接拿 kScaleSlop 与它比会要求 36px 指间距变化, 而外层 VerticalDrag 只要 18px ——
      // 一指锚定的捏合(最常见姿势)因此稳定地输掉竞技场。
      expect(
        TouchGestureOwner.resolveChartFallback(
          scene.controller,
          delta: Offset.zero,
          spanDelta: kTouchSlop / 2,
          hitSlop: kTouchSlop,
        ),
        isNull,
        reason: '指间距变化恰好等于外层阈值时落在边界上, 判据是严格大于',
      );
      expect(
        TouchGestureOwner.resolveChartFallback(
          scene.controller,
          delta: Offset.zero,
          spanDelta: kTouchSlop / 2 + 0.5,
          hitSlop: kTouchSlop,
        ),
        TouchGestureOwner.chartScale,
        reason: '越过外层阈值即抢占, 不等原生 kScaleSlop 的两倍量纲',
      );
    });

    testWidgets('scaleClaimSlopFactor 调大即按比例抬高抢占门槛', (tester) async {
      final (:scene, indicator: _) = await arrange();
      scene.controller.updateGestureConfig((config) => config.copyWith(scaleClaimSlopFactor: 2));

      expect(
        TouchGestureOwner.resolveChartFallback(
          scene.controller,
          delta: Offset.zero,
          spanDelta: kTouchSlop / 2 + 0.5,
          hitSlop: kTouchSlop,
        ),
        isNull,
        reason: '宿主调保守时同一指间距变化不再够用',
      );
      expect(
        TouchGestureOwner.resolveChartFallback(
          scene.controller,
          delta: Offset.zero,
          spanDelta: kTouchSlop + 0.5,
          hitSlop: kTouchSlop,
        ),
        TouchGestureOwner.chartScale,
      );
    });

    testWidgets('样本不足: 位移未越过 hitSlop 且指间距未变时放弃', (tester) async {
      final (:scene, indicator: _) = await arrange();

      // 阈值取外层 hitSlop 而非更小的 claimSlop: TapGestureRecognizer 的
      // preAcceptSlopTolerance 就是同一个 touchSlop, 提前抢占会吃掉点击语义。
      expect(
        TouchGestureOwner.resolveChartFallback(
          scene.controller,
          delta: const Offset(kTouchSlop, 0),
          spanDelta: 0,
          hitSlop: kTouchSlop,
        ),
        isNull,
      );
      expect(
        TouchGestureOwner.resolveChartFallback(
          scene.controller,
          delta: const Offset(kTouchSlop + 1, 0),
          spanDelta: 0,
          hitSlop: kTouchSlop,
        ),
        TouchGestureOwner.chartPan,
      );
    });

    testWidgets('横向占优按 panClaimRatio 取锥: 恰好等于比例不算占优', (tester) async {
      final (:scene, indicator: _) = await arrange();
      final ratio = scene.controller.gestureConfig.panClaimRatio;
      expect(ratio, 2);

      // 等于比例落在锥边界上: 判据是严格大于, 边界归外层。
      expect(
        TouchGestureOwner.resolveChartFallback(
          scene.controller,
          delta: Offset(20 * ratio, -20),
          spanDelta: 0,
          hitSlop: kTouchSlop,
        ),
        isNull,
      );
      expect(
        TouchGestureOwner.resolveChartFallback(
          scene.controller,
          delta: Offset(20 * ratio + 1, -20),
          spanDelta: 0,
          hitSlop: kTouchSlop,
        ),
        TouchGestureOwner.chartPan,
      );
    });

    testWidgets('禁用缩放时张开手指不取得缩放归属, 退回方向判定', (tester) async {
      final (:scene, indicator: _) = await arrange();
      scene.controller.updateGestureConfig((config) => config.copyWith(enableScale: false));

      expect(
        TouchGestureOwner.resolveChartFallback(
          scene.controller,
          delta: const Offset(40, 0),
          spanDelta: kScaleSlop + 1,
          hitSlop: kTouchSlop,
        ),
        TouchGestureOwner.chartPan,
      );
      expect(
        TouchGestureOwner.resolveChartFallback(
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
    TouchGestureOwner.resolveLanded(scene.controller, _onLine);

    expect(scene.controller.drawState.object!.moving, isFalse);
    expect(scene.controller.isPaintObjectDragging, isFalse);
    expect(scene.controller.isCrossing, isFalse);
    expect(indicator.object!.calls, isEmpty);
  });
}
