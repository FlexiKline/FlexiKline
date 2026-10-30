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

/// 指标动画在真实 widget 树里的端到端接线。
///
/// 单元层（`test/framework/paint_animation_test.dart`）用假 context 覆盖了 mixin 自身的静音与
/// 释放逻辑；这里要验的是**接线**：`TickerModeData` 确实从 widget 树整体流到 Ticker（含
/// `forceFrames`），而 `requestRepaint` 确实落到 `repaintChart` 这条通道上。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'ANIM-WIDGET', interval: FlexiTimeInterval(1, TimeUnit.day));
const _animKey = ExternalIndicatorKey('anim-widget');

void main() {
  /// 挂一个带动画指标的图表，可选包一层 [TickerMode]。
  ///
  /// 返回 controller 与指标，用例据此取到 PaintObject 并在其上建 `AnimationController`。
  Future<({FlexiKlineController chart, TestAnimatedIndicator indicator})> pumpChart(
    WidgetTester tester, {
    bool? tickerModeEnabled,
  }) async {
    final chart = createChartController();
    chart.switchKlineData(_spec);
    chart.replaceKlineData(_spec, genFlatCandleList());
    final indicator = TestAnimatedIndicator(key: _animKey);

    Widget kline = SizedBox(
      width: 400,
      height: 400,
      child: FlexiKlineWidget(
        controller: chart,
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        subIndicators: [indicator],
      ),
    );
    if (tickerModeEnabled != null) {
      kline = TickerMode(enabled: tickerModeEnabled, child: kline);
    }

    await tester.pumpWidget(MaterialApp(home: kline));
    await pumpUntilChart(
      tester,
      () => chart.isMounted && chart.mainChartWidth > 0,
      'chart layout',
    );
    return (chart: chart, indicator: indicator);
  }

  group('v2.5.0/指标动画/TickerMode 接线', () {
    testWidgets('无外层 TickerMode 时默认启用', (tester) async {
      final (chart: chart, indicator: _) = await pumpChart(tester);
      addTearDown(() => disposeChart(tester, chart));

      expect(chart.tickerModeListenable.value.enabled, isTrue);
    });

    testWidgets('外层 TickerMode 关闭时同步为 false', (tester) async {
      final (chart: chart, indicator: _) = await pumpChart(tester, tickerModeEnabled: false);
      addTearDown(() => disposeChart(tester, chart));

      expect(chart.tickerModeListenable.value.enabled, isFalse);
    });

    testWidgets('forceFrames 从 Widget 树一路传到 Ticker', (tester) async {
      // 端到端验证中继没有裁剪字段：TickerMode → controller → PaintContext → Ticker。
      final chart = createChartController();
      chart.switchKlineData(_spec);
      chart.replaceKlineData(_spec, genFlatCandleList());
      final indicator = TestAnimatedIndicator(key: _animKey);
      addTearDown(() => disposeChart(tester, chart));

      await tester.pumpWidget(
        MaterialApp(
          home: TickerMode(
            enabled: true,
            forceFrames: true,
            child: SizedBox(
              width: 400,
              height: 400,
              child: FlexiKlineWidget(
                controller: chart,
                candle: TestCandleIndicator(),
                time: TestTimeIndicator(),
                subIndicators: [indicator],
              ),
            ),
          ),
        ),
      );
      await pumpUntilChart(tester, () => chart.isMounted && chart.mainChartWidth > 0, 'chart layout');

      expect(chart.tickerModeListenable.value.forceFrames, isTrue);

      final ticker = indicator.object!.createTicker((_) {});
      addTearDown(ticker.dispose);
      expect(ticker.forceFrames, isTrue);
    });

    testWidgets('运行时切换 TickerMode 时跟随', (tester) async {
      // 这条用例是「订阅挂在 didChangeDependencies」的回归网: 挂在 initState 时首帧值正确、
      // 但后续变化收不到。
      final chart = createChartController();
      chart.switchKlineData(_spec);
      chart.replaceKlineData(_spec, genFlatCandleList());
      addTearDown(() => disposeChart(tester, chart));

      Future<void> pumpWith(bool enabled) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TickerMode(
              enabled: enabled,
              child: SizedBox(
                width: 400,
                height: 400,
                child: FlexiKlineWidget(
                  controller: chart,
                  candle: TestCandleIndicator(),
                  time: TestTimeIndicator(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await pumpWith(true);
      expect(chart.tickerModeListenable.value.enabled, isTrue);

      await pumpWith(false);
      expect(chart.tickerModeListenable.value.enabled, isFalse);

      await pumpWith(true);
      expect(chart.tickerModeListenable.value.enabled, isTrue);
    });

    testWidgets('图表被搬到另一个 TickerMode 祖先下时重新解析 notifier', (tester) async {
      // 「订阅必须能重做」的回归网。上一条覆盖不到：同一个 TickerMode State 的 notifier 是同一
      // 实例，只在 initState 订阅一次也收得到；只有祖先真的换了（GlobalKey 搬移子树、State
      // 保留）实例才变。
      final chart = createChartController();
      chart.switchKlineData(_spec);
      chart.replaceKlineData(_spec, genFlatCandleList());
      addTearDown(() => disposeChart(tester, chart));

      final klineKey = GlobalKey();
      Widget kline() => SizedBox(
        width: 400,
        height: 400,
        child: FlexiKlineWidget(
          key: klineKey,
          controller: chart,
          candle: TestCandleIndicator(),
          time: TestTimeIndicator(),
        ),
      );

      Future<void> pumpWithKlineUnderEnabled({required bool underEnabled}) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Stack(
              children: [
                TickerMode(enabled: true, child: underEnabled ? kline() : const SizedBox.shrink()),
                TickerMode(enabled: false, child: underEnabled ? const SizedBox.shrink() : kline()),
              ],
            ),
          ),
        );
        await tester.pump();
      }

      await pumpWithKlineUnderEnabled(underEnabled: true);
      expect(chart.tickerModeListenable.value.enabled, isTrue);

      await pumpWithKlineUnderEnabled(underEnabled: false);
      expect(
        chart.tickerModeListenable.value.enabled,
        isFalse,
        reason: '祖先换了, 必须重新解析 notifier',
      );
    });
  });

  group('v2.5.0/指标动画/重绘驱动', () {
    testWidgets('动画运行期间持续请求 chart 重绘, 完成后停止', (tester) async {
      final (chart: chart, indicator: indicator) = await pumpChart(tester);
      addTearDown(() => disposeChart(tester, chart));

      final object = indicator.object!;
      final animation = AnimationController(
        vsync: object,
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(animation.dispose);

      var repaintCount = 0;
      void onRepaint() => repaintCount++;
      chart.repaintChart.addListener(onRepaint);
      addTearDown(() => chart.repaintChart.removeListener(onRepaint));

      animation.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(repaintCount, greaterThan(0), reason: '动画帧应经 requestRepaint 落到 chart 图层');

      await tester.pump(const Duration(milliseconds: 60));
      expect(animation.isCompleted, isTrue);

      final afterCompleted = repaintCount;
      await tester.pump(const Duration(milliseconds: 32));
      expect(
        repaintCount,
        afterCompleted,
        reason: '动画结束后 Ticker 停止, 不再有动画来源的重绘',
      );
    });

    testWidgets('TickerMode 关闭时动画冻结, 恢复后继续', (tester) async {
      final (chart: chart, indicator: indicator) = await pumpChart(tester, tickerModeEnabled: false);
      addTearDown(() => disposeChart(tester, chart));

      final object = indicator.object!;
      final animation = AnimationController(
        vsync: object,
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(animation.dispose);

      animation.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(animation.value, 0, reason: '静音期间不 tick');

      // 恢复可见性: 尚未 tick 过的 Ticker 没有记录起始时刻, 因此从头开始跑而不是跳到 50ms。
      chart.setTickerMode(const TickerModeData(enabled: true, forceFrames: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(animation.value, greaterThan(0));
      expect(animation.value, lessThan(1));

      // 必须在用例体内停止: 动画未跑完, 而 flutter_test 在 body 结束时就检查还有没有
      // transient callback, tearDown 里的 dispose 跑得太晚。
      animation.stop();
    });
  });
}
