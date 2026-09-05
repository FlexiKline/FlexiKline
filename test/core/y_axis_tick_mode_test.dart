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

/// 主区 Y 轴价格刻度的两种取值方式：[GridTickMode.average] 与 [GridTickMode.nice]。
///
/// 观察点取**绘制产物**而非内部字段：横线经 `drawPath` 落在 Canvas 上，刻度值再由
/// `dyToCandleValue` 从横线位置反算。这样两条只会「行为错、不报错」的实现细节才有回归网——
/// `dyToValue` 漏传 `check: false` 会让刻度整体消失（横线数归零），`valueToDy` 漏传
/// `correct: false` 会把留白区的刻度钳到边缘（反算出的值不再是 step 整数倍）。
///
/// 最关键的一条是「算法不碰 `minMax`」：它是 Y 轴 zoom 的数据载体，一旦被 nice 算法外扩，
/// 用户精确控制的跨度就会被撑回去，平滑插值也会在换档时整幅跳一下。缩放与平移两组各守一端。
library;

import 'dart:ui' show Paragraph;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

/// `precision` 是 nice 算法的选档约束：step 必须是 `10^-precision` 的整数倍。取默认 4，
/// 让 2.5 档在本组的价格量级上合法，覆盖「step 不是 10 的整数次幂」这一路。
const _spec = KlineSpec(symbol: 'Y-TICK-MODE', interval: FlexiTimeInterval(1, TimeUnit.day));

/// 主区高 300、上下各留白 20：`chartRect` 因此比 `drawableRect` 矮 40，nice 刻度才可能落到
/// `minMax` 之外的留白区里。留白为零时那条用例是空转的。
///
/// 留白要声明在**主区** indicator 上：combine 子对象的 `padding` 代理父级（`object.dart:129`），
/// 给蜡烛 indicator 自己传 padding 不起作用。
const _mainPadding = EdgeInsets.symmetric(vertical: 20);

/// 价格恒定的蜡烛：`minMax` 端点 107 / 93 都不是 nice step 的整数倍，所以最顶/最底刻度必然
/// 越过端点落进留白区。取 110 / 90 这类整数档会让那条用例假绿。
const _flatHigh = 107.0;
const _flatLow = 93.0;

void main() {
  /// 建 controller、灌数据并按 [tickMode] 配置主区横向轴。
  Future<ControllerScenario> arrange(
    WidgetTester tester, {
    GridTickMode tickMode = GridTickMode.average,
    List<CandleModel>? candles,
    EdgeInsets padding = _mainPadding,
    bool gridShow = true,
    bool showYAxisTick = true,
  }) async {
    final scene = ControllerScenario(
      config: FakeFlexiKlineConfiguration(mainIndicatorDefaultPadding: padding),
    );
    addTearDown(scene.dispose);
    await scene.initWithData(
      _spec,
      candles ?? genFlatCandleList(high: _flatHigh, low: _flatLow),
      canvasWidth: 400,
      candle: TestCandleIndicator(visibleMinMaxFromData: true),
    );
    scene.controller.flushPendingKlineData();
    scene.controller.updateGridConfig(
      (config) => config.copyWith(
        horizontal: config.horizontal.copyWith(tickMode: tickMode, show: gridShow),
      ),
    );
    scene.controller.updateSettingConfig((config) => config.copyWith(showYAxisTick: showYAxisTick));
    scene.controller.updateGestureConfig((config) => config.copyWith(enableZoom: true));
    return scene;
  }

  /// 驱动一帧绘制并交回本帧的 Canvas 记录。
  ///
  /// 冲帧要用 `pumpWidget` 而不是 `pump`：绘制排下的 post-frame 回调（滑竿热区上报、可见区间
  /// notifier）自己不 `scheduleFrame`，没有 widget 树时 `pump()` 不产生真帧，回调既不生效、也
  /// 会活到本用例 dispose 之后，在下一个用例的首帧里炸「used after disposed」。
  Future<_TickSpyCanvas> paintFrame(WidgetTester tester, FlexiKlineController chart) async {
    final spy = _TickSpyCanvas();
    chart.paintChart(spy, chart.canvasRect.size);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    return spy;
  }

  /// 本帧横线的 dy，按绘制顺序。
  List<double> tickDys(_TickSpyCanvas spy, FlexiKlineController chart) {
    return spy.pathBounds.where((r) => r.height == 0 && r.width == chart.mainRect.width).map((r) => r.top).toList();
  }

  /// 由横线位置反算刻度值，升序返回。
  ///
  /// 反算而不是读内部缓存：它同时校验了 dy 是由 `valueToDy(correct: false)` 换算来的——若走
  /// 默认的钳制版本，留白区刻度的 dy 会挤到边缘，反算值随之不再是 step 整数倍。
  ///
  /// 代价是 `Path` 的坐标按 float32 存储，反算值带 1e-6 量级的相对噪声，见 [expectNiceMultiples]。
  List<double> tickValues(_TickSpyCanvas spy, FlexiKlineController chart) {
    final values = tickDys(spy, chart).map((dy) => chart.dyToCandleValue(dy, check: false)!.toDouble()).toList();
    return values..sort();
  }

  /// 当前生效区间的上端，即 `minMax.max`。
  ///
  /// `mainPaintObject` 只在 package 内可见，所以经映射读端点（与 `chart_zoom_test` 同一口径）：
  /// `dyToValue(chartRect.top)` 按定义恰好等于 `minMax.max`，不引入任何误差。
  double rangeMax(FlexiKlineController chart) {
    return chart.dyToCandleValue(chart.mainChartRect.top, check: false)!.toDouble();
  }

  /// 当前生效区间的下端，即 `minMax.min`。
  double rangeMin(FlexiKlineController chart) {
    return chart.dyToCandleValue(chart.mainChartRect.bottom, check: false)!.toDouble();
  }

  /// 断言 [values] 等距，且每个值都是这个步长的整数倍。返回步长。
  ///
  /// 「整数倍」是 nice 模式的核心不变量：等分模式下刻度值是由像素位置反算的任意小数，只有取值
  /// 方向反过来之后才可能落在整数倍上。
  ///
  /// 余数容差取步长的 1e-4：观测链经过 `Path` 的 float32 坐标，实测噪声在 1e-6 个步长量级，而
  /// 真实的失败（钳制、外扩、错步长）会偏掉一个步长的可观比例，两者相距四个数量级。
  double expectNiceMultiples(List<double> values) {
    expect(values.length, greaterThanOrEqualTo(3), reason: '刻度少于 3 条, 整数倍断言会空转');
    final step = values[1] - values[0];
    expect(step, greaterThan(0));
    for (var i = 1; i < values.length; i++) {
      expect(values[i] - values[i - 1], closeTo(step, step * 1e-4), reason: '刻度必须等距');
    }
    for (final value in values) {
      final quotient = value / step;
      expect(
        (quotient - quotient.roundToDouble()).abs(),
        lessThan(1e-4),
        reason: '$value 不是步长 $step 的整数倍',
      );
    }
    return step;
  }

  group('v2.5.0/主区Y轴/刻度模式', () {
    testWidgets('默认是 average: 刻度按像素等分, 位置与值都不变', (tester) async {
      final scene = ControllerScenario(
        config: FakeFlexiKlineConfiguration(mainIndicatorDefaultPadding: _mainPadding),
      );
      addTearDown(scene.dispose);
      await scene.initWithData(
        _spec,
        genFlatCandleList(high: _flatHigh, low: _flatLow),
        canvasWidth: 400,
        candle: TestCandleIndicator(visibleMinMaxFromData: true),
      );
      scene.controller.flushPendingKlineData();
      final chart = scene.controller;

      // 不动任何配置: 默认值本身就是本条用例要守的东西。
      expect(chart.gridConfig.horizontal.tickMode, GridTickMode.average);

      final spy = await paintFrame(tester, chart);
      final count = chart.gridConfig.horizontal.count;
      final dyStep = chart.mainRect.height / count;

      expect(
        tickDys(spy, chart),
        [for (var i = 1; i <= count; i++) i * dyStep],
        reason: '等分模式的位置由 count 精确决定, 末条落在 drawableRect 底边',
      );
      expect(
        tickValues(spy, chart).first,
        closeTo(chart.dyToCandleValue(count * dyStep, check: false)!.toDouble(), 1e-9),
        reason: '值由位置反算, 不经过任何取整',
      );
    });

    testWidgets('nice + 自动区间: 刻度值是同一 step 的整数倍', (tester) async {
      final scene = await arrange(tester, tickMode: GridTickMode.nice);
      final chart = scene.controller;

      final spy = await paintFrame(tester, chart);
      final values = tickValues(spy, chart);

      expect(values, isNotEmpty, reason: '刻度为空说明 dyToValue 漏了 check: false');
      expectNiceMultiples(values);
    });

    /// 本组最重要的一条回归网。参考实现里的 nice-number 都会把 min/max 外扩到 step 整数倍上；
    /// 照搬到这里就等于让算法改写 `minMax`，而缩放态下 `minMax` 就是用户拖出来的那个区间。
    testWidgets('nice + Y 轴放大: 刻度仍整数化, 且 minMax 恒等于 zoom 写入值', (tester) async {
      final scene = await arrange(tester, tickMode: GridTickMode.nice);
      final chart = scene.controller;
      await paintFrame(tester, chart);
      final autoSpan = rangeMax(chart) - rangeMin(chart);
      final autoCenter = (rangeMax(chart) + rangeMin(chart)) / 2;

      // zoom 的写入契约: 跨度乘系数、中点不动(`_applyZoomFactor` → `scaleAroundCenter`)。
      // 直接和这个值比, 而不是和「上一帧读到的值」比 —— 后者在外扩实现下会一起被污染。
      const coeff = 0.5;
      expect(chart.onChartZoomStep(coeff), isTrue, reason: '前置条件: 缩放必须真的生效');
      final spy = await paintFrame(tester, chart);

      expect(
        rangeMax(chart) - rangeMin(chart),
        closeTo(autoSpan * coeff, 1e-9),
        reason: '刻度算法不得改写 minMax 跨度',
      );
      expect(
        (rangeMax(chart) + rangeMin(chart)) / 2,
        closeTo(autoCenter, 1e-9),
        reason: '外扩会把中点也一起挪走',
      );
      expectNiceMultiples(tickValues(spy, chart));
    });

    /// 外扩口径的另一面：`minMax` 会被吸附到 step 整数倍上，于是平移时它不再连续跟随数据，而是
    /// 一段不动、换档时整幅跳一格。两种模式逐帧比对能同时排除吸附与任何其它写入。
    testWidgets('nice + 平移: minMax 逐帧与 average 模式一致, 无按 step 量化的台阶', (tester) async {
      /// 沿历史方向平移 12 步，返回每帧的 `minMax.max` 以及末帧的刻度值。
      Future<({List<double> series, List<double> lastTicks})> panSeries(GridTickMode tickMode) async {
        final scene = await arrange(tester, tickMode: tickMode, candles: genRampCandleList());
        final chart = scene.controller;
        var spy = await paintFrame(tester, chart);

        final series = <double>[];
        // 正 dx 抬高 `paintDxOffset`, 即向历史平移。初始位置贴在最新一根上, 反向会被夹住,
        // 可见区间一动不动, 整条用例随之空转。
        for (var i = 0; i < 12; i++) {
          chart.onChartMove(const Offset(8, 0));
          spy = await paintFrame(tester, chart);
          series.add(rangeMax(chart));
        }
        return (series: series, lastTicks: tickValues(spy, chart));
      }

      final nice = await panSeries(GridTickMode.nice);
      final average = await panSeries(GridTickMode.average);

      expect(nice.series.toSet().length, greaterThan(1), reason: '前置条件: minMax 必须真的随平移变化');
      expect(nice.series, average.series, reason: '换刻度模式不得改变任何一帧的 minMax');

      // 斜坡数据每平移一根蜡烛只挪一个 slope, 远小于一个 step; 被吸附到整数倍上则相邻差会是
      // 0 或整整一个 step。
      final step = expectNiceMultiples(nice.lastTicks);
      for (var i = 1; i < nice.series.length; i++) {
        expect(
          (nice.series[i] - nice.series[i - 1]).abs(),
          lessThan(step / 2),
          reason: 'minMax 出现了一个 step 量级的台阶, 说明它被吸附到刻度上了',
        );
      }
    });

    testWidgets('nice: 刻度可越过 minMax 落进留白区, 但不出 drawableRect', (tester) async {
      final scene = await arrange(tester, tickMode: GridTickMode.nice);
      final chart = scene.controller;

      final spy = await paintFrame(tester, chart);
      final values = tickValues(spy, chart);
      final max = rangeMax(chart);
      final min = rangeMin(chart);

      // 取值范围来自 drawableRect 反算的价格区间, 比 minMax 宽出 padding 那一截。
      expect(
        values.where((v) => v > max || v < min),
        isNotEmpty,
        reason: '留白区应当也有刻度, 与 TradingView 一致',
      );
      for (final dy in tickDys(spy, chart)) {
        expect(dy, greaterThanOrEqualTo(chart.mainRect.top));
        expect(dy, lessThanOrEqualTo(chart.mainRect.bottom));
      }
      // 越界的刻度必须还落在留白里, 而不是被 clamp 压到 chartRect 边缘叠在一起。
      expect(tickDys(spy, chart).toSet().length, tickDys(spy, chart).length, reason: '刻度位置不得重合');
    });

    testWidgets('nice: zoom 滑竿热区照常上报', (tester) async {
      final scene = await arrange(tester, tickMode: GridTickMode.nice);
      final chart = scene.controller;
      expect(chart.chartZoomSlideBarRect, Rect.zero, reason: '绘制前热区应为空');

      await paintFrame(tester, chart);

      expect(
        chart.chartZoomSlideBarRect.isEmpty,
        isFalse,
        reason: '热区宽度由刻度文本实测而来, 刻度为空会让 zoom 手势整体失效',
      );
    });

    testWidgets('horizontal.show = false: 不画横线, 刻度文本照旧', (tester) async {
      final scene = await arrange(tester, tickMode: GridTickMode.nice, gridShow: false);
      final chart = scene.controller;

      final spy = await paintFrame(tester, chart);

      expect(tickDys(spy, chart), isEmpty, reason: 'show 关掉即不画横线');
      expect(spy.paragraphs, greaterThan(0), reason: '文本只受 showYAxisTick 约束, 与横线开关无关');
    });

    testWidgets('showYAxisTick = false: 只剩横线, 无刻度文本', (tester) async {
      final scene = await arrange(tester, tickMode: GridTickMode.nice, showYAxisTick: false);
      final chart = scene.controller;

      final spy = await paintFrame(tester, chart);

      expect(tickDys(spy, chart), isNotEmpty);
      expect(spy.paragraphs, 0);
    });
  });
}

/// 只记录 `drawPath` 的路径包围盒与 `drawParagraph` 次数的 Canvas 替身。
///
/// 用替身而不是 `Canvas(PictureRecorder())`：真 Canvas 收下了指令却读不回来，而「画了几条横线、
/// 画了几段文本」是本组唯一的观察点。
class _TickSpyCanvas implements Canvas {
  final List<Rect> pathBounds = [];
  int paragraphs = 0;

  @override
  void drawPath(Path path, Paint paint) => pathBounds.add(path.getBounds());

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) => paragraphs++;

  @override
  void noSuchMethod(Invocation invocation) {}
}
