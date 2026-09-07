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

/// 网格线归主区蜡烛之后的编排：`paintGridLines` 一趟画完横竖两向，由各 pane 的 `doPaintChart`
/// 在自己的可见区间就绪之后、指标图之前调；数据未就绪那一帧走编排层的独立路径，只调这一趟。
///
/// 观察点是**一帧的绘制记录**：既取形状（横线、竖线、蜡烛记号、文本段），也取顺序。顺序是本组
/// 的关键工具——蜡烛落下的记号把「网格线」与「主区指标图」分开，副区落下的记号把「主区那一趟」
/// 与「副区那一趟」分开。
///
/// 四条只会「行为错、不报错」的实现细节由此有了回归网：
///
/// 一是**网格线必须早于本 pane 的指标图**。它收在 `doPaintChart` 的第一步，靠的是方法内部的顺序
/// 而不是 zIndex——`CandleIndicator` 的 zIndex 是 -1、`VolumeIndicator` 用 -2，且宿主能传任意值。
///
/// 二是**横线只画一遍**。两个绘制时机合并之后横线只剩一个入口，但位置重复（同色同宽，肉眼分不出）
/// 仍是这条链路最容易悄悄发生的错。
///
/// 三是**退化判据必须与门禁同源**（`klineData.canPaintChart`）。切标的那一帧 `minMax` 仍是上一帧
/// 的旧值；用 `minMax.isZero` 判退化会让 nice 以为区间可用、按旧标的的价格算位置。
///
/// 四是**数据未就绪时网格线仍要画**，否则加载中的图表只剩 grid 层的边框。
library;

import 'dart:ui' show Paragraph;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_formatter/flexi_formatter.dart' show formatPrice;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/utils/grid_tick_util.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'GRID-LINES', interval: FlexiTimeInterval(1, TimeUnit.day));

/// 主区上下各留白 20：nice 刻度因此可能落到 `minMax` 之外的留白区，值反算那条用例才不空转。
///
/// 留白要声明在**主区** indicator 上：combine 子对象的 `padding` 代理父级。
const _mainPadding = EdgeInsets.symmetric(vertical: 20);

/// 价格恒定的蜡烛：端点 107 / 93 都不是 nice step 的整数倍，最顶/最底刻度必然越过端点。
const _flatHigh = 107.0;
const _flatLow = 93.0;

/// 与 [CandleBaseIndicator.defaultHorizontalGrid] 一致的间隔数。
const _divisions = 5;

const _canvasWidth = 400.0;
const _subHeight = 80.0;

/// 副区那一趟落下的记号，用来把主区画的东西与副区画的东西分开。
///
/// 用有面积的形状而不是竖线：加载态那一帧副区的 `paneIndex` 还没分配（见
/// `IPaintObject.paintGridLines` 的告警），它的 `drawableRect` 读到的是主区区域，画出来的
/// 竖线与主区竖线形状一模一样，分不开。
const _subMarkRect = Rect.fromLTWH(3, 5, 7, 11);

/// 显式给实线：虚线会被 `drawLineByConfig` 拆成多段 path，形状分类随之失效。
const _solidLine = LineConfig(type: LineType.solid);

const _alignedSubKey = DirectIndicatorKey('grid-aligned-sub');

void main() {
  /// 建 controller、灌数据并按参数配置主区网格线。
  ///
  /// 默认挂一个覆写了 `paintGridLines` 的副区指标：它既收下主区产出的 dx（「副区能借主区 dx
  /// 对齐」这条能力的被测对象），也在同一时刻落下 [_subMarkRect] 与自己那一刻的 `drawableRect`。
  Future<ControllerScenario> arrange(
    WidgetTester tester, {
    GridTickMode horizontalMode = const GridTickMode.nice(targetDivisions: _divisions),
    GridTickMode verticalMode = const GridTickMode.count(_divisions),
    LineConfig? horizontalLine = _solidLine,
    LineConfig? verticalLine = _solidLine,
    List<CandleModel>? candles,
    bool paintMarker = false,
    bool alignedSub = true,
  }) async {
    final scene = ControllerScenario(
      config: FakeFlexiKlineConfiguration(mainIndicatorDefaultPadding: _mainPadding),
    );
    addTearDown(scene.dispose);
    await scene.initWithData(
      _spec,
      candles ?? genFlatCandleList(high: _flatHigh, low: _flatLow),
      canvasWidth: _canvasWidth,
      candle: TestCandleIndicator(
        visibleMinMaxFromData: true,
        paintMarker: paintMarker,
        horizontalGrid: GridAxisConfig(mode: horizontalMode, line: horizontalLine),
        verticalGrid: GridAxisConfig(mode: verticalMode, line: verticalLine),
      ),
      subIndicators: alignedSub ? [_AlignedGridIndicator()] : const [],
    );
    scene.controller.flushPendingKlineData();
    return scene;
  }

  /// 驱动一帧 chart 绘制并交回记录。
  ///
  /// 冲帧要用 `pumpWidget`：绘制排下的 post-frame 回调自己不 `scheduleFrame`，没有 widget 树
  /// 时 `pump()` 不产生真帧，回调会活到本用例 dispose 之后，在下一个用例的首帧里炸。
  Future<_PaintLog> paintFrame(WidgetTester tester, FlexiKlineController chart) async {
    final log = _PaintLog();
    chart.paintChart(log, chart.canvasRect.size);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    return log;
  }

  group('v2.5.0/网格线/编排', () {
    testWidgets('count 竖线: dx 与旧 grid 层的等分口径逐值一致', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;

      final log = await paintFrame(tester, chart);

      // 旧 grid 层的口径: `step = mainRect.right / count`, `dx = i * step, i ∈ [1, count)`。
      // 主区 left 恒为 0, 所以它与 `evenPositions(count, start: left, length: width)` 同值。
      final step = chart.mainRect.width / _divisions;
      expect(
        log.mainVerticalDxs(chart),
        [for (var i = 1; i < _divisions; i++) i * step],
        reason: '竖线搬到蜡烛之后位置必须一模一样, 否则宿主会看到网格整体偏移',
      );
    });

    /// 网格线是 `doPaintChart` 的第一步，此刻主区的 `save() + clipRect(mainRect)` 已经生效；
    /// 坐标本来就落在 `mainRect` 内，裁不到它。
    testWidgets('z 序: 横竖网格都早于蜡烛与主区指标', (tester) async {
      final scene = await arrange(
        tester,
        paintMarker: true,
        candles: genFlatCandleList(high: _flatHigh, low: _flatLow),
      );
      final chart = scene.controller;

      final log = await paintFrame(tester, chart);

      final lastLine = log.lastIndexOf([...log.mainVerticalOps(chart), ...log.mainHorizontalOps(chart)]..sort());
      final marker = log.indexOfMarker();
      expect(log.mainVerticalOps(chart), isNotEmpty, reason: '前置条件: 本帧必须有主区竖线');
      expect(log.mainHorizontalOps(chart), isNotEmpty, reason: '前置条件: 本帧必须有主区横线');
      expect(marker, isNonNegative, reason: '前置条件: 蜡烛必须落下记号');
      expect(lastLine, lessThan(marker), reason: '网格压在蜡烛上就成了前景, 不再是网格');

      // 横线的 x 跨度恒等于 mainRect 宽度, 只有 dy 可能越界。容差放到 1e-9: nice 刻度可以越过
      // 端点一个浮点误差(见「刻度顶在 drawableRect 边界外」那条), 那点越界肉眼与像素都看不出。
      for (final dy in log.mainHorizontalDys(chart)) {
        expect(dy, greaterThanOrEqualTo(chart.mainRect.top - 1e-9), reason: '横线越出 mainRect 会被 clipRect 裁掉');
        expect(dy, lessThanOrEqualTo(chart.mainRect.bottom + 1e-9), reason: '横线越出 mainRect 会被 clipRect 裁掉');
      }
    });

    /// 门禁前那一趟不是「数据没来时的兜底」，而是所有位置此刻已确定的网格线的正常路径：
    /// 竖线与非 nice 横线的位置只依赖几何，nice 在区间不可用时退化为同 divisions 的 count。
    testWidgets('加载态(无数据 + nice): 横竖网格都在, 无刻度文本', (tester) async {
      final scene = await arrange(tester, candles: const []);
      final chart = scene.controller;
      expect(chart.klineData.canPaintChart, isFalse, reason: '前置条件: 本条要的就是无数据态');

      final log = await paintFrame(tester, chart);

      final dyStep = chart.mainRect.height / _divisions;
      expect(
        log.mainHorizontalDys(chart),
        [for (var i = 1; i < _divisions; i++) i * dyStep],
        reason: 'nice 在无区间时退化为 count, 加载中的主区不该只剩边框',
      );
      expect(log.mainVerticalDxs(chart), hasLength(_divisions - 1));
      expect(log.paragraphs, 0, reason: '没有区间就取不到值, 不该画文本');
    });

    /// 加载态走的是编排层直接调 `doPaintGridLines` 的那条路，不经 `doPaintChart`。dx 的写入必须
    /// 在那个方法里，否则副区读到的是上一帧的值——冷启动时是空列表，整个加载期间主区有竖线、副区
    /// 没有。
    testWidgets('加载态: 副区仍收到本帧主区的 dx', (tester) async {
      final scene = await arrange(tester, candles: const []);
      final chart = scene.controller;

      final log = await paintFrame(tester, chart);

      final main = log.mainVerticalDxs(chart);
      expect(main, isNotEmpty, reason: '前置条件: 加载态也该有主区竖线');
      expect(_AlignedGridIndicator.lastObject!.receivedDxs, main, reason: '加载态副区拿不到 dx 就只能自己算, 对齐失去结构保证');
    });

    /// 退化判据取 `canPaintChart` 而非 `minMax.isZero` 的唯一理由：这一帧里两者的取值相反。
    testWidgets('切标的瞬间(canPaintChart 转 false, minMax 仍是旧值): 横线不闪断', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      // 换到一个还没有数据的标的, 但主区区间不会跟着清: doUpdateVisibleMinMax 在门禁之后,
      // 这一帧根本走不到那里。
      chart.switchKlineData(const KlineSpec(symbol: 'GRID-LINES-NEXT', interval: FlexiTimeInterval(1, TimeUnit.day)));
      chart.flushPendingKlineData();
      expect(chart.klineData.canPaintChart, isFalse, reason: '前置条件: 新标的的数据还没到');
      expect(
        chart.dyToCandleValue(chart.mainChartRect.top, check: false)!.toDouble(),
        closeTo(_flatHigh, 1e-9),
        reason: '前置条件: minMax 仍是上一帧的旧值, 否则本用例分辨不出两个判据',
      );

      final log = await paintFrame(tester, chart);

      final dyStep = chart.mainRect.height / _divisions;
      expect(
        log.mainHorizontalDys(chart),
        [for (var i = 1; i < _divisions; i++) i * dyStep],
        reason: '用 minMax.isZero 判退化, 这一帧的横线会两头都不画, 闪断一帧',
      );
    });

    /// 横线只有一个入口之后，「画一遍」不再靠两处判据互补维持；这条改为直接盯位置：nice 用的是
    /// 本帧区间取整的结果，逐值等于 `computePriceTicks` 的产出，而不是退化后的等分。
    ///
    /// 区间取自绘制后的 `candle`：本组的 `TestCandleIndicator` 不画 tips，`_tipsAreaHeight` 全程
    /// 为 0，所以帧内帧后的 `chartRect` 相同，反算得到的位置与绘制时用的是同一批。
    testWidgets('有数据 + nice: 横线按本帧区间取整, 只画一遍', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      final candle = scene.candle.object!;

      final log = await paintFrame(tester, chart);
      final dys = log.mainHorizontalDys(chart);

      final bounds = candle.drawableRect;
      final ticks = computePriceTicks(
        bottom: candle.dyToValue(bounds.bottom, check: false)!.toDouble(),
        top: candle.dyToValue(bounds.top, check: false)!.toDouble(),
        targetCount: _divisions,
        precision: candle.klineData.precision,
      ).values;

      expect(ticks, hasLength(greaterThanOrEqualTo(3)), reason: '前置条件: 刻度太少断言会空转');
      expect(dys, hasLength(ticks.length), reason: '条数对不上即 nice 没用本帧区间; 条数翻倍即同一批横线画了两遍');
      expect(dys, hasLength(dys.toSet().length), reason: '位置重复即同一批横线画了两遍');

      // 逐值给容差: [_PaintLog] 的位置取自 `Path.getBounds()`, 经 Skia 存成 float32, 相对误差
      // 约 1e-7。等分位置恰好都能精确表示, nice 的不能, 所以只有这里要 closeTo。
      final expected = [for (final value in ticks) candle.valueToDy(value.toFlexiNum(), correct: false)];
      for (var i = 0; i < expected.length; i++) {
        expect(dys[i], closeTo(expected[i], 1e-3), reason: '第 $i 条横线不在 nice 取整的位置上');
      }
    });

    testWidgets('有数据 + count: 横线按等分画一遍, 文本随后补上', (tester) async {
      final scene = await arrange(tester, horizontalMode: const GridTickMode.count(_divisions));
      final chart = scene.controller;

      final log = await paintFrame(tester, chart);
      final dys = log.mainHorizontalDys(chart);
      final dyStep = chart.mainRect.height / _divisions;

      expect(dys, [for (var i = 1; i < _divisions; i++) i * dyStep]);
      expect(
        log.lastIndexOf(log.mainHorizontalOps(chart)),
        lessThan(log.subMarkIndex()),
        reason: '主区网格线必须在主区那一趟内画完',
      );
      expect(log.paragraphs, greaterThan(0), reason: '线画完之后仍要补刻度文本');
    });

    testWidgets('verticalGrid.line = null: 不画竖线, gridVerticalDxs 仍非空', (tester) async {
      final scene = await arrange(tester, verticalLine: null);
      final chart = scene.controller;

      final log = await paintFrame(tester, chart);

      expect(log.mainVerticalDxs(chart), isEmpty, reason: 'line 置 null 即主区不画竖线');
      expect(
        (chart as PaintContext).gridVerticalDxs,
        hasLength(_divisions - 1),
        reason: '产出与绘制分开: 主区不画, 副区仍可能想按同一位置画',
      );
    });

    /// grid 层的左右边框与蜡烛的竖线是两回事：关掉边框不该带走网格。
    testWidgets('grid 边框关闭: 无左右边框, 竖线仍在', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      chart.updateGridConfig((config) => config.copyWith(vertical: const GridBorder(show: false)));

      final log = _PaintLog();
      chart.paintGrid(log, chart.canvasRect.size);
      final borders = log.verticalDxsAt(chart.mainRect.height);
      chart.paintChart(log, chart.canvasRect.size);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(borders, isEmpty, reason: 'vertical.show = false 只该关掉 grid 层的左右边框');
      expect(log.mainVerticalDxs(chart), hasLength(_divisions - 1), reason: '网格竖线归蜡烛, 不受边框开关影响');
    });

    /// 位置各算一遍也能对上（同宽 + 同 mode 必然相同），但那把对齐建立在「宿主两处配一样」的
    /// 约定上。经 `context.gridVerticalDxs` 拿主区的产出，对齐才是结构保证。
    ///
    /// 断言的是副区**收到**的 dx，不是它画出的线：线的位置还要看该副区自己怎么摆，那是下一条
    /// 用例的事。这条只守值的传递与编排顺序——主区那一趟必须先跑完，否则副区读到的是空列表或
    /// 上一帧的值。
    testWidgets('副区对齐: 收到的 dx 与主区逐值相同', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;

      final log = await paintFrame(tester, chart);

      final main = log.mainVerticalDxs(chart);
      expect(main, isNotEmpty, reason: '前置条件: 主区必须有竖线');
      expect(_AlignedGridIndicator.lastObject!.receivedDxs, main, reason: '副区与主区错位就是两套网格');
      expect(
        log.subMarkIndex(),
        greaterThan(log.lastIndexOf(log.mainVerticalOps(chart))),
        reason: '副区必须在主区之后被调, 否则读到的 dx 是上一帧的',
      );
    });

    /// 网格线挪到区间就绪之后，附带解掉了副区的 pane 几何约束：`paintGridLines` 现在是副区
    /// `doPaintChart` 的第一步，排在给它分配 `paneIndex` 的 `doUpdateVisibleMinMax` 之后，于是
    /// 副区终于能按自己的 `drawableRect` 画网格线。
    ///
    /// 加载态那一帧仍不可信（编排层直接调这一趟，`paneIndex` 还没分配），所以这条只断言正常路径。
    testWidgets('副区几何: 正常路径下 drawableRect 已是本 pane 的区域', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;

      await paintFrame(tester, chart);

      final bounds = _AlignedGridIndicator.lastObject!.paintedBounds;
      expect(bounds, isNotNull, reason: '前置条件: 副区那一趟必须已跑过');
      expect(bounds, isNot(chart.mainRect), reason: 'pane 几何未就绪时读到的就是 mainRect, 副区网格线会画到主区上');
      expect(bounds!.height, _subHeight, reason: '高度必须是本指标的高度, 不是主区高度');
      expect(bounds.top, greaterThanOrEqualTo(chart.subRect.top));
      expect(bounds.bottom, lessThanOrEqualTo(chart.subRect.bottom));
    });

    /// nice 的值不再由算法一路传下来，改由画文本时 `dyToValue(check: false)` 现算。观察点取
    /// `formatTicksValue` 钩子的入参——文本一旦交给 `Paragraph` 就读不回来了。
    ///
    /// `check: false` 守的是「刻度落在 `drawableRect` 边界上」这一路：`includeDy` 是闭区间，
    /// 理论上边界能过，但浮点误差足以让它差之毫厘被判出界，整条刻度静默消失。本用例断言
    /// **每条刻度都有值**，那条路径一旦发生就会少一个。
    testWidgets('刻度文本: 值与算法原值格式化后逐个相同', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      final candle = scene.candle.object!;

      await paintFrame(tester, chart);

      final bounds = candle.drawableRect;
      final expected = computePriceTicks(
        bottom: candle.dyToValue(bounds.bottom, check: false)!.toDouble(),
        top: candle.dyToValue(bounds.top, check: false)!.toDouble(),
        targetCount: _divisions,
        precision: candle.klineData.precision,
      ).values;

      expect(expected.length, greaterThanOrEqualTo(3), reason: '前置条件: 刻度太少断言会空转');
      expect(
        candle.formattedTickValues,
        hasLength(expected.length),
        reason: '每条刻度都该有文本; 少一条就是 dyToValue 把边界上的那条判出界了',
      );

      // 8 位是本仓库最深的显示精度: 往返只经一次乘、一次除, 相对误差约 1e-16, 在这个量级的
      // 价格上是 1e-14 绝对误差, formatPrice 的四舍五入会吸收掉。
      for (final precision in [2, 8]) {
        for (var i = 0; i < expected.length; i++) {
          expect(
            formatPrice(candle.formattedTickValues[i].toDecimal(), precision: precision, cutInvalidZero: false),
            formatPrice(expected[i].toFlexiNum().toDecimal(), precision: precision, cutInvalidZero: false),
            reason: 'precision $precision 下第 $i 条刻度的反算值与算法原值不一致',
          );
        }
      }
    });

    /// 上一条断言「每条刻度都有值」，但它守不住 `check: false`——那组数据的刻度全落在
    /// `drawableRect` 内部，闭区间的边界判定对它们没有区别。这条把刻度**顶到边界上**：
    ///
    /// 区间 `[0, 11]`、可绘制高度 100，于是 `dyFactor = 100/11 = 9.090909090909092`，最顶刻度
    /// 11 换算回去是 `100 - 11 × dyFactor = -1.42e-14`——差之毫厘落在 `drawableRect.top` 之外。
    /// 带检查的 `dyToValue` 会把它判成 null，那条刻度静默消失且不抛异常。
    ///
    /// 不经 controller：既要区间端点精确落在 step 整数倍上（最顶刻度才等于端点），又要
    /// `跨度 × dyFactor` 的舍入方向朝上（差值才为负），controller 那条路上 `minMax` 由蜡烛
    /// 数据算出，凑不出这个巧合。
    testWidgets('刻度顶在 drawableRect 边界外的浮点误差内: 仍取得到值', (tester) async {
      final object = _EdgeTickPaintObject();
      final context = FakePaintContext()..mainRect = const Rect.fromLTWH(0, 0, _canvasWidth, 100);
      object.bind(TestCandleIndicator(height: 100), context);
      object.setMinMax(MinMax(min: FlexiNum.zero, max: FlexiNum.fromNum(11)));

      // 与 `resolveHorizontalDys` 的 nice 分支同一步换算: 算法定值, `valueToDy(correct: false)`
      // 换位置。
      final topDy = object.valueToDy(FlexiNum.fromNum(11), correct: false);
      expect(topDy, lessThan(object.drawableRect.top), reason: '前置条件: 刻度必须真的越过边界');
      expect(topDy, closeTo(object.drawableRect.top, 1e-9), reason: '前置条件: 越界量必须只是浮点误差');

      object.paintTicks(_PaintLog(), [topDy]);

      expect(
        object.formattedTickValues,
        hasLength(1),
        reason: 'dyToValue 漏了 check: false, 落在边界上的刻度会静默消失',
      );
    });
  });
}

/// 一帧的绘制记录：按顺序存下每次 `drawPath` 的包围盒，并数 `drawParagraph`。
///
/// 用替身而不是 `Canvas(PictureRecorder())`：真 Canvas 收下了指令却读不回来，而「画了什么、
/// 按什么顺序画」是本组唯一的观察点。
class _PaintLog implements Canvas {
  /// 每次 `drawPath` 的包围盒，按绘制顺序。索引即 z 序。
  final List<Rect> paths = [];
  int paragraphs = 0;

  @override
  void drawPath(Path path, Paint paint) => paths.add(path.getBounds());

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) => paragraphs++;

  @override
  void noSuchMethod(Invocation invocation) {}

  /// 横穿主区的横线在 [paths] 中的索引。
  List<int> mainHorizontalOps(FlexiKlineController chart) {
    return _indicesWhere((r) => r.height == 0 && r.width == chart.mainRect.width);
  }

  List<double> mainHorizontalDys(FlexiKlineController chart) {
    return [for (final i in mainHorizontalOps(chart)) paths[i].top];
  }

  /// 贯穿主区高度的竖线在 [paths] 中的索引。
  List<int> mainVerticalOps(FlexiKlineController chart) {
    return _verticalOpsAt(chart.mainRect.height);
  }

  List<double> mainVerticalDxs(FlexiKlineController chart) {
    return [for (final i in mainVerticalOps(chart)) paths[i].left];
  }

  /// 高度恰为 [height] 的竖线的 dx，按绘制顺序。grid 层的左右边框靠它取。
  List<double> verticalDxsAt(double height) {
    return [for (final i in _verticalOpsAt(height)) paths[i].left];
  }

  /// 蜡烛记号（[TestCandlePaintObject.markerPath]）的索引；-1 表示未落下。
  int indexOfMarker() {
    final bounds = TestCandlePaintObject.markerPath.getBounds();
    return paths.indexWhere((r) => r == bounds);
  }

  /// 主区与副区的分界：副区指标落下的 [_subMarkRect]。
  ///
  /// 两条路径上副区都排在主区之后（正常路径是副区遍历，加载态是紧随主区的那一趟），所以索引
  /// 小于它的都是主区画的。
  int subMarkIndex() {
    final index = paths.indexWhere((r) => r == _subMarkRect);
    expect(index, isNonNegative, reason: '前置条件: 副区记号必须已落下');
    return index;
  }

  int firstIndexOf(List<int> ops) => ops.isEmpty ? -1 : ops.first;

  int lastIndexOf(List<int> ops) => ops.isEmpty ? -1 : ops.last;

  List<int> _verticalOpsAt(double height) {
    return _indicesWhere((r) => r.width == 0 && r.height == height);
  }

  List<int> _indicesWhere(bool Function(Rect) test) {
    return [
      for (var i = 0; i < paths.length; i++)
        if (test(paths[i])) i,
    ];
  }
}

/// 副区指标：竖线借主区产出的 dx，验证跨 pane 对齐。
///
/// 只在本组用，所以留在测试文件内而不进 `support/`。
class _AlignedGridIndicator extends DirectIndicator {
  _AlignedGridIndicator()
      : super(
          key: _alignedSubKey,
          height: _subHeight,
          padding: EdgeInsets.zero,
          autoActivate: true,
        );

  /// 最近一次创建的绘制对象。
  static _AlignedGridPaintObject? lastObject;

  @override
  DirectPaintObject<DirectIndicator> createPaintObject() => lastObject = _AlignedGridPaintObject();
}

/// 直接驱动刻度文本那一趟的蜡烛对象：区间与几何都由用例精确给定。
///
/// 不用 [TestCandlePaintObject]：`paintYAxisTicks` 是 `@protected`，它服务实现者而不是公开
/// API，用例只能经子类转发。
class _EdgeTickPaintObject extends CandleBasePaintObject<TestCandleIndicator> {
  /// 挂载入口：`mount` 对外受保护，子类内调用是它的正常用法。
  void bind(TestCandleIndicator indicator, PaintContext context) => mount(indicator, context);

  /// [formatTicksValue] 每次收到的刻度值。
  final List<FlexiNum> formattedTickValues = [];

  void paintTicks(Canvas canvas, List<double> dys) {
    paintYAxisTicks(canvas, dys: dys, precision: 2);
  }

  @override
  String formatTicksValue(FlexiNum value, {required int precision}) {
    formattedTickValues.add(value);
    return super.formatTicksValue(value, precision: precision);
  }

  @override
  FlexiChartType resolveChartType() => FlexiChartType.barSolid;

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

class _AlignedGridPaintObject extends DirectPaintObject<_AlignedGridIndicator> {
  /// 本帧从 context 读到的主区 dx 序列。
  List<double> receivedDxs = const [];

  /// 本帧落笔那一刻读到的 `drawableRect`，用来验证 pane 几何是否已就绪。
  Rect? paintedBounds;

  @override
  ({List<double> dxs, List<double> dys}) paintGridLines(Canvas canvas, Size size) {
    receivedDxs = context.gridVerticalDxs;
    paintedBounds = drawableRect;
    // 落一笔记号而不是竖线: 加载态那一帧副区的 pane 几何还没分配, 画出来的线落在主区上, 与主区
    // 竖线分不开。
    canvas.drawPath(Path()..addRect(_subMarkRect), Paint());
    // 副区不产出自己的位置: 竖线借的是主区的 dx, 也没有横线。
    return (dxs: const [], dys: const []);
  }

  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}
