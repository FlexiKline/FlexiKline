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

/// 二期：zoom 作用于可见价格区间，不再借道 `padding`。
///
/// 核心断言是「像素几何全程不动」：`padding` 恒等于声明值，`mainChartRect` 的上下边界与
/// 高度不变，缩放只改价格→像素映射的分母。
///
/// 观察点取 `dyToCandleValue`（经蜡烛的映射反算区间端点）而非主区内部字段：它同时验证了
/// 缩放区间向 combine 子对象的下发链路，且是公开面。
///
/// 用 `testWidgets` 而非 `test`：`setChartZoomSlideBarRect` 走 `addPostFrameCallback`，
/// 不泵帧则滑竿区恒为 `Rect.zero`，`onChartZoomStart` 永远返回 false。
library;

import 'dart:ui' show ClipOp, PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'CHART-ZOOM', interval: FlexiTimeInterval(1, TimeUnit.day));

/// 蜡烛价量恒定：high 110 / low 90，自动区间跨度 20、中点 100，断言可写精确值。
const _autoMax = 110.0;
const _autoMin = 90.0;
const _autoSpan = _autoMax - _autoMin;
const _autoCenter = (_autoMax + _autoMin) / 2;

/// 拖动距离：主区高 300，60px 足以产生可断言的系数又不贴边界。
const _dragDy = 60.0;

/// 滑竿区宽 24、贴主区右缘、高度取整个主区，与生产实现（价格轴全高热区）同形。
Rect _sliderRect(FlexiKlineController chart) => Rect.fromLTWH(
      chart.mainRect.right - 24,
      chart.mainRect.top,
      24,
      chart.mainRect.height,
    );

/// 当前生效区间的上端：主图区顶边对应的价格。
double _rangeMax(FlexiKlineController chart) {
  return chart.dyToCandleValue(chart.mainChartRect.top, check: false)!.toDouble();
}

/// 当前生效区间的下端：主图区底边对应的价格。
double _rangeMin(FlexiKlineController chart) {
  return chart.dyToCandleValue(chart.mainChartRect.bottom, check: false)!.toDouble();
}

double _rangeSpan(FlexiKlineController chart) => _rangeMax(chart) - _rangeMin(chart);

double _rangeCenter(FlexiKlineController chart) => (_rangeMax(chart) + _rangeMin(chart)) / 2;

void main() {
  /// 建 controller、灌数据、启用 zoom 并把滑竿区泵到生效。
  Future<ControllerScenario> arrange(WidgetTester tester) async {
    final scene = ControllerScenario();
    addTearDown(scene.dispose);
    await scene.initWithData(
      _spec,
      genFlatCandleList(),
      canvasWidth: 400,
      candle: TestCandleIndicator(visibleMinMaxFromData: true),
    );
    scene.controller.flushPendingKlineData();
    scene.controller.updateGestureConfig(
      (config) => config.copyWith(enableZoom: true, useCustomZoomRect: true),
    );
    scene.controller.setChartZoomSlideBarRect(_sliderRect(scene.controller));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(scene.controller.chartZoomSlideBarRect.isEmpty, isFalse, reason: '滑竿区必须已生效');
    return scene;
  }

  /// 驱动一帧绘制，让 `doUpdateVisibleMinMax` 走完一轮，并泵掉这一帧。
  ///
  /// 必须泵帧：`calculatePaintChartRange` 会排一个 post-frame 回调去写 notifier，
  /// 不泵掉它会活到本用例 dispose 之后，在下一个用例的首帧里炸「used after disposed」。
  Future<void> paintFrame(WidgetTester tester, FlexiKlineController chart) async {
    final canvas = Canvas(PictureRecorder());
    chart.paintChart(canvas, chart.canvasRect.size);
    await tester.pump();
  }

  /// 在滑竿上按下并拖到 `起点 + [dy]`。
  void dragSlider(FlexiKlineController chart, double dy) {
    final from = Offset(_sliderRect(chart).center.dx, chart.mainRect.center.dy);
    expect(chart.onChartZoomStart(from), isTrue);
    chart.onChartZoomUpdate(GestureData.zoom(from)..update(from + Offset(0, dy)));
  }

  group('v2.4.1/zoom/作用于可见价格区间', () {
    testWidgets('自动模式下区间取可见蜡烛的最高最低价', (tester) async {
      final scene = await arrange(tester);
      await paintFrame(tester, scene.controller);

      expect(_rangeMax(scene.controller), closeTo(_autoMax, 1e-9));
      expect(_rangeMin(scene.controller), closeTo(_autoMin, 1e-9));
    });

    testWidgets('缩放全程 padding 恒等于声明值，mainChartRect 不动', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final declaredPadding = chart.mainPadding;
      final rectBefore = chart.mainChartRect;

      dragSlider(chart, _dragDy);
      await paintFrame(tester, chart);

      expect(chart.mainPadding, declaredPadding, reason: 'zoom 不得写 padding');
      expect(chart.mainChartRect, rectBefore, reason: '像素几何全程不参与 Y 轴缩放');
    });

    testWidgets('向下拖动：区间跨度变大、中点不变，内容视觉被压缩', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, _dragDy);
      await paintFrame(tester, chart);

      expect(_rangeSpan(chart), greaterThan(_autoSpan));
      expect(_rangeCenter(chart), closeTo(_autoCenter, 1e-6), reason: '缩放围绕区间中点');
    });

    testWidgets('向上拖动：区间跨度变小、中点不变', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, -_dragDy);
      await paintFrame(tester, chart);

      expect(_rangeSpan(chart), lessThan(_autoSpan));
      expect(_rangeCenter(chart), closeTo(_autoCenter, 1e-6));
    });

    testWidgets('基于按下快照重算：拖回起点即还原，不逐帧累乘', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final from = Offset(_sliderRect(chart).center.dx, chart.mainRect.center.dy);
      expect(chart.onChartZoomStart(from), isTrue);

      final data = GestureData.zoom(from);
      // 中途来回若干帧, 最后停回起点。
      for (final dy in [20.0, 45.0, -30.0, 10.0, 0.0]) {
        data.update(from + Offset(0, dy));
        chart.onChartZoomUpdate(data);
      }
      await paintFrame(tester, chart);

      expect(
        _rangeSpan(chart),
        closeTo(_autoSpan, 1e-6),
        reason: '快照口径下停回起点即系数为 1',
      );
    });

    testWidgets('缩放期间横向平移：Y 轴区间不变', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, _dragDy);
      await paintFrame(tester, chart);
      final zoomedMax = _rangeMax(chart);
      final zoomedMin = _rangeMin(chart);

      // 横向平移改变可见蜡烛范围, 自动模式下会重算区间。
      chart.onChartMove(GestureData.pan(Offset.zero)..update(const Offset(-120, 0)));
      await paintFrame(tester, chart);

      expect(_rangeMax(chart), closeTo(zoomedMax, 1e-9));
      expect(_rangeMin(chart), closeTo(zoomedMin, 1e-9));
    });

    testWidgets('缩放态下纵向拖动：跨度不变、中点按 dyDelta / dyFactor 位移', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, _dragDy);
      await paintFrame(tester, chart);
      final spanBefore = _rangeSpan(chart);
      final centerBefore = _rangeCenter(chart);
      final factor = chart.mainChartRect.height / spanBefore;

      const dy = 24.0;
      chart.onChartMove(GestureData.pan(Offset.zero)..update(const Offset(0, dy)));
      await paintFrame(tester, chart);

      expect(_rangeSpan(chart), closeTo(spanBefore, 1e-6), reason: '平移不改变跨度');
      expect(
        _rangeCenter(chart),
        closeTo(centerBefore + dy / factor, 1e-6),
        reason: '向下拖动使区间上移, 内容随手指下移',
      );
    });

    testWidgets('自动模式下纵向拖动不改变 Y 轴区间', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      chart.onChartMove(GestureData.pan(Offset.zero)..update(const Offset(0, 24)));
      await paintFrame(tester, chart);

      expect(_rangeMax(chart), closeTo(_autoMax, 1e-9));
      expect(_rangeMin(chart), closeTo(_autoMin, 1e-9));
    });

    testWidgets('exitChartZoom 后回到自动区间', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, _dragDy);
      await paintFrame(tester, chart);
      expect(_rangeSpan(chart), isNot(closeTo(_autoSpan, 1e-6)));

      chart.exitChartZoom();
      await paintFrame(tester, chart);

      expect(chart.isChartZooming, isFalse);
      expect(_rangeMax(chart), closeTo(_autoMax, 1e-9));
      expect(_rangeMin(chart), closeTo(_autoMin, 1e-9));
    });

    testWidgets('点一下滑竿未产生缩放：onChartZoomEnd 直接退出，不留待复位状态', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final from = Offset(_sliderRect(chart).center.dx, chart.mainRect.center.dy);
      expect(chart.onChartZoomStart(from), isTrue);
      expect(chart.isChartZooming, isTrue);

      chart.onChartZoomEnd();
      await paintFrame(tester, chart);

      expect(chart.isChartZooming, isFalse, reason: '没缩放过就不该留下一个要按 A 才能清的状态');
      expect(_rangeSpan(chart), closeTo(_autoSpan, 1e-9));
    });

    testWidgets('缩放后 onChartZoomEnd 保持缩放态，只有显式复位才交还自动', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, _dragDy);
      await paintFrame(tester, chart);

      chart.onChartZoomEnd();
      await paintFrame(tester, chart);

      expect(chart.isChartZooming, isTrue);
      expect(_rangeSpan(chart), isNot(closeTo(_autoSpan, 1e-6)));
    });

    testWidgets('未命中滑竿：不进入缩放、不取快照', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      expect(chart.onChartZoomStart(chart.mainRect.centerLeft), isFalse);
      expect(chart.isChartZooming, isFalse);

      // 没有快照, update 必须是 no-op。
      chart.onChartZoomUpdate(GestureData.zoom(Offset.zero)..update(const Offset(0, _dragDy)));
      await paintFrame(tester, chart);

      expect(_rangeSpan(chart), closeTo(_autoSpan, 1e-9));
    });

    /// 触摸端传给 `onChartZoomStart` 的是**当前**手指位置而非按下位置（归属在 PointerDown
    /// 判定、缩放要等纵向位移够 `zoomStartMinDistance`），所以斜向甩动可能在此之前已横向移出
    /// 滑竿。若那时把 `isChartZooming` 置 false 而不清缩放区间，就会留下「退出按钮消失、Y 轴
    /// 仍锁在缩放区间」的失同步状态 —— 用户看不到复位入口。
    testWidgets('缩放态下未命中滑竿：保持缩放态，不与缩放区间失同步', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, _dragDy);
      await paintFrame(tester, chart);
      final zoomedSpan = _rangeSpan(chart);

      expect(chart.onChartZoomStart(chart.mainRect.centerLeft), isFalse);
      await paintFrame(tester, chart);

      expect(chart.isChartZooming, isTrue, reason: '交还 Y 轴只有 exitChartZoom 一条路径');
      expect(_rangeSpan(chart), closeTo(zoomedSpan, 1e-9));
    });
  });

  /// 缩放系数的取值边界由 `maxZoomPerGesture` 单参数决定。
  ///
  /// 观察量取「跨度倍数」= 缩放后跨度 / 缩放前跨度，它就是 `scaleAroundCenter` 收到的系数。
  group('v2.4.1/zoom/系数边界', () {
    /// 沿滑竿从 [fromDy] 拖到 [toDy]，返回本轮实际生效的缩放系数。
    ///
    /// 每次先复位到自动区间，避免上一轮的缩放区间成为本轮快照。
    Future<double> measureCoeff(
      WidgetTester tester,
      FlexiKlineController chart,
      double fromDy,
      double toDy,
    ) async {
      chart.exitChartZoom();
      await paintFrame(tester, chart);
      final baseSpan = _rangeSpan(chart);

      final dx = _sliderRect(chart).center.dx;
      final from = Offset(dx, fromDy);
      expect(chart.onChartZoomStart(from), isTrue);
      chart.onChartZoomUpdate(GestureData.zoom(from)..update(Offset(dx, toDy)));
      await paintFrame(tester, chart);

      return _rangeSpan(chart) / baseSpan;
    }

    testWidgets('角点取到 [1 / M, M]，两端互为倒数', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final m = chart.gestureConfig.maxZoomPerGesture;
      final rect = chart.mainChartRect;

      // 抓顶边拖到底边 = 距底距离从 height 变 0, 取到最大压缩。
      expect(await measureCoeff(tester, chart, rect.top, rect.bottom), closeTo(m, 1e-6));
      // 抓底边拖到顶边 = 反向, 取到最大放大。
      expect(await measureCoeff(tester, chart, rect.bottom, rect.top), closeTo(1 / m, 1e-6));
    });

    testWidgets('边界与主图区高度无关', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final rectBefore = chart.mainChartRect;
      final before = await measureCoeff(tester, chart, rectBefore.top, rectBefore.bottom);

      chart.exitChartZoom();
      chart.setMainSize(Size(chart.mainSize.width, chart.mainSize.height + 120));
      await paintFrame(tester, chart);
      expect(chart.mainChartRect.height, isNot(closeTo(rectBefore.height, 1)), reason: '前置条件: 高度必须真的变了');

      final rectAfter = chart.mainChartRect;
      final after = await measureCoeff(tester, chart, rectAfter.top, rectAfter.bottom);

      // 软化项按高度成比例派生, 所以比值与高度约掉 —— 换了主区高度手感不变。
      expect(after, closeTo(before, 1e-6));
    });

    testWidgets('maxZoomPerGesture 调大即按比例放宽边界', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);
      chart.updateGestureConfig((config) => config.copyWith(maxZoomPerGesture: 12));

      final rect = chart.mainChartRect;
      expect(await measureCoeff(tester, chart, rect.top, rect.bottom), closeTo(12, 1e-6));
      expect(await measureCoeff(tester, chart, rect.bottom, rect.top), closeTo(1 / 12, 1e-6));
    });

    testWidgets('系数恒为正：拉满缩小也不会越过 0 让 Y 轴翻转', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);
      // 取配置允许的最灵敏值, 这是系数最容易接近 0 的一端。
      chart.updateGestureConfig((config) => config.copyWith(maxZoomPerGesture: 20));

      final rect = chart.mainChartRect;
      final coeff = await measureCoeff(tester, chart, rect.bottom, rect.top);

      expect(coeff, greaterThan(0), reason: '负系数会让 max/min 互换、dyFactor 变负');
      expect(_rangeMax(chart), greaterThan(_rangeMin(chart)), reason: '区间不得反转');
    });
  });

  group('v2.4.1/zoom/生命周期', () {
    testWidgets('换周期保持缩放区间', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, _dragDy);
      await paintFrame(tester, chart);
      final zoomedSpan = _rangeSpan(chart);

      chart.switchKlineData(
        const KlineSpec(symbol: 'CHART-ZOOM', interval: FlexiTimeInterval(1, TimeUnit.hour)),
      );
      chart.replaceKlineData(
        const KlineSpec(symbol: 'CHART-ZOOM', interval: FlexiTimeInterval(1, TimeUnit.hour)),
        genFlatCandleList(),
      );
      chart.flushPendingKlineData();
      await paintFrame(tester, chart);

      expect(chart.isChartZooming, isTrue, reason: '同一标的的视野应当保留');
      expect(_rangeSpan(chart), closeTo(zoomedSpan, 1e-6));
    });

    testWidgets('换标的交还 Y 轴：退出缩放态', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, _dragDy);
      await paintFrame(tester, chart);
      expect(chart.isChartZooming, isTrue);

      const other = KlineSpec(symbol: 'OTHER-SYMBOL', interval: FlexiTimeInterval(1, TimeUnit.day));
      chart.switchKlineData(other);
      chart.replaceKlineData(other, genFlatCandleList());
      chart.flushPendingKlineData();
      await paintFrame(tester, chart);

      expect(chart.isChartZooming, isFalse, reason: '另一个标的的价格区间没有意义');
      expect(_rangeMax(chart), closeTo(_autoMax, 1e-9));
      expect(_rangeMin(chart), closeTo(_autoMin, 1e-9));
    });

    testWidgets('主区尺寸变化不改变缩放区间，也不产生 padding 补偿', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final paddingBefore = chart.mainPadding;
      dragSlider(chart, _dragDy);
      await paintFrame(tester, chart);
      final zoomedMax = _rangeMax(chart);
      final zoomedMin = _rangeMin(chart);

      chart.setMainSize(Size(chart.mainSize.width, chart.mainSize.height + 80));
      await paintFrame(tester, chart);

      expect(_rangeMax(chart), closeTo(zoomedMax, 1e-9));
      expect(_rangeMin(chart), closeTo(zoomedMin, 1e-9));
      expect(chart.mainPadding, paddingBefore, reason: '不产生按高度比例的 padding 补偿');
    });
  });

  group('v2.4.1/zoom/主区裁剪范围', () {
    /// 带平滑因子横向平移一步：只给 dx，避免顺带平移价格区间。
    void panWithSmoothing(FlexiKlineController chart) {
      final from = chart.mainChartRect.center;
      chart.onChartMove(GestureData.pan(from)..update(from - const Offset(12, 0)), 0.15);
    }

    /// 驱动一帧绘制并捕获主区的裁剪矩形。
    Future<_ClipSpyCanvas> paintFrameWithClipSpy(
      WidgetTester tester,
      FlexiKlineController chart,
    ) async {
      final spy = _ClipSpyCanvas();
      chart.paintChart(spy, chart.canvasRect.size);
      await tester.pump();
      return spy;
    }

    testWidgets('自动模式平滑期放宽到 canvasRect', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      panWithSmoothing(chart);
      final spy = await paintFrameWithClipSpy(tester, chart);

      expect(spy.mainClip, chart.canvasRect, reason: '插值中的区间滞后于数据, 溢出不该被裁在主区边缘');
    });

    testWidgets('缩放态平移不放宽裁剪，溢出的蜡烛画不进副区', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      dragSlider(chart, _dragDy);
      await paintFrame(tester, chart);
      expect(_rangeSpan(chart), isNot(closeTo(_autoSpan, 1e-9)), reason: '前置条件: 缩放区间必须已生效');

      panWithSmoothing(chart);
      final spy = await paintFrameWithClipSpy(tester, chart);

      expect(spy.mainClip, chart.mainRect, reason: '缩放态不插值, 放宽裁剪只会让溢出画进副区');
    });
  });
}

/// 只记录 `clipRect` 的 Canvas 替身，其余绘制指令一律吞掉。
///
/// 用替身而不是 `Canvas(PictureRecorder())`：真 Canvas 记下了裁剪却读不回来，而裁剪范围是
/// 本组用例唯一的观察点。
class _ClipSpyCanvas implements Canvas {
  final List<Rect> clipRects = [];

  /// 主区裁剪是 `paintChart` 的第一次 `clipRect`——它发生在任何绘制之前，
  /// 后续可能还有指标自己的局部裁剪（如 time 指标的 `clipToDrawableRect`）。
  Rect get mainClip => clipRects.first;

  @override
  void clipRect(Rect rect, {ClipOp clipOp = ClipOp.intersect, bool doAntiAlias = true}) {
    clipRects.add(rect);
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}
