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

/// 集成测试：FlexiKlineController K线数据流转
library;

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'TEST', interval: FlexiTimeInterval(1, TimeUnit.day));
const _nextSpec = KlineSpec(symbol: 'NEXT', interval: FlexiTimeInterval(1, TimeUnit.day));

List<CandleModel> _candles(int n) => List.generate(
  n,
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
  group('v2.2.0/FlexiKlineController/kline_data', () {
    testWidgets('mount 前切换 spec 只保留最终 Current 的 pending', (tester) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);

      scene.controller.switchKlineData(_spec);
      scene.controller.replaceKlineData(_spec, _candles(3));
      scene.controller.switchKlineData(_nextSpec);
      scene.controller.replaceKlineData(_nextSpec, _candles(2));

      scene.controller.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: const [],
      );
      scene.controller.initState();
      scene.controller.flushPendingKlineData();
      await tester.pumpAndSettle();

      expect(scene.controller.klineData.length, 2);
      expect(scene.controller.switchKlineData(_spec, useCacheFirst: true), isFalse);
      expect(scene.controller.klineData.isEmpty, isTrue);
    });

    testWidgets('mount 前 replace 暂存，initState 后数据可用', (tester) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);

      scene.controller.switchKlineData(_spec);
      scene.controller.replaceKlineData(_spec, _candles(3));

      // mount 前数据尚未合并。
      expect(scene.controller.klineData.isEmpty, isTrue);

      scene.controller.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: const [],
      );
      scene.controller.initState();

      // flushPendingKlineData 模拟 Widget initState 中的调用
      scene.controller.flushPendingKlineData();
      // 内部 scheduleTask 是异步的，需要 pumpAndSettle 让调度执行完成
      await tester.pumpAndSettle();

      // flush 后数据可用。
      expect(scene.controller.klineData.isEmpty, isFalse);
    });

    testWidgets('切换到新建空数据后旧 current 的 latest 不再参与 tick', (tester) async {
      const key = ComputedIndicatorKey('owner');
      final log = LifecycleLog();
      final indicator = SpyComputedIndicator(key: key, log: log);
      final scene = ControllerScenario(
        config: FakeFlexiKlineConfiguration(mainChildren: {key}),
      );
      addTearDown(scene.dispose);
      await scene.initWithData(_spec, _candles(3).reversed.toList(), mainIndicators: [indicator]);
      scene.controller.flushPendingKlineData();
      await tester.pumpAndSettle();
      log.clear();

      scene.controller.updateLatestKlineData(
        _spec,
        [
          CandleModel(
            timestamp: 172801000,
            open: Decimal.one,
            high: Decimal.fromInt(2),
            low: Decimal.zero,
            close: Decimal.one,
            volume: Decimal.one,
          ),
        ],
      );
      scene.controller.switchKlineData(_nextSpec);
      await tester.pump(const Duration(milliseconds: 500));

      expect(log.events.where((event) => event.startsWith('compute:')), isEmpty);
    });

    testWidgets('非 Current spec 的三类更新不会修改冻结缓存', (tester) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      await scene.initWithData(_spec, _candles(3).reversed.toList());
      scene.controller.flushPendingKlineData();
      await tester.pumpAndSettle();

      scene.controller.switchKlineData(_nextSpec);
      scene.controller.replaceKlineData(_nextSpec, _candles(2).reversed.toList());
      await tester.pumpAndSettle();

      final inactiveData = scene.controller.switchKlineData(_spec, useCacheFirst: true)
          ? scene.controller.klineData
          : throw StateError('expected cached data');
      inactiveData.updateState(state: KlineLoadingState.loadingMore);
      scene.controller.switchKlineData(_nextSpec, useCacheFirst: true);
      scene.controller.replaceKlineData(_spec, const []);
      scene.controller.replaceKlineData(_spec, _candles(1));
      scene.controller.updateLatestKlineData(
        _spec,
        [
          CandleModel(
            timestamp: 999999999,
            open: Decimal.one,
            high: Decimal.fromInt(2),
            low: Decimal.zero,
            close: Decimal.one,
            volume: Decimal.one,
          ),
        ],
      );
      scene.controller.appendHistoryKlineData(
        _spec,
        [
          CandleModel(
            timestamp: 1,
            open: Decimal.one,
            high: Decimal.fromInt(2),
            low: Decimal.zero,
            close: Decimal.one,
            volume: Decimal.one,
          ),
        ],
      );

      expect(scene.controller.switchKlineData(_spec, useCacheFirst: true), isTrue);
      expect(scene.controller.klineData.length, 3);
      expect(scene.controller.klineData.loadingState, KlineLoadingState.loadingMore);
      expect(
        scene.controller.klineData.list.map((item) => item.ts),
        _candles(3).reversed.map((item) => item.timestamp),
      );
    });

    testWidgets('命中缓存不计算，fresh replace 只全量计算一次', (tester) async {
      const key = ComputedIndicatorKey('cache');
      final log = LifecycleLog();
      final indicator = SpyComputedIndicator(key: key, log: log);
      final scene = ControllerScenario(
        config: FakeFlexiKlineConfiguration(mainChildren: {key}),
      );
      addTearDown(scene.dispose);
      await scene.initWithData(_spec, _candles(3).reversed.toList(), mainIndicators: [indicator]);
      scene.controller.flushPendingKlineData();
      await tester.pumpAndSettle();

      scene.controller.switchKlineData(_nextSpec);
      scene.controller.replaceKlineData(_nextSpec, _candles(2).reversed.toList());
      await tester.pumpAndSettle();
      log.clear();

      expect(scene.controller.switchKlineData(_spec, useCacheFirst: true), isTrue);
      expect(log.events.where((event) => event.startsWith('compute:')), isEmpty);

      scene.controller.replaceKlineData(_spec, _candles(3).reversed.toList());

      expect(log.events.where((event) => event.startsWith('compute:')), ['compute:cache(reset:true)']);
    });

    testWidgets('显示 computed 指标后丢弃 inactive cache', (tester) async {
      const key = ComputedIndicatorKey('activation');
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      await scene.initWithData(
        _spec,
        _candles(3).reversed.toList(),
        mainIndicators: [SpyComputedIndicator(key: key, log: LifecycleLog())],
      );
      scene.controller.flushPendingKlineData();
      await tester.pumpAndSettle();

      scene.controller.switchKlineData(_nextSpec);
      scene.controller.replaceKlineData(_nextSpec, _candles(2).reversed.toList());
      await tester.pumpAndSettle();

      expect(scene.controller.hasAddedMainIndicator(key), isFalse);
      expect(scene.controller.showMainIndicator(key), isTrue);
      expect(
        scene.controller.switchKlineData(_spec, useCacheFirst: true),
        isFalse,
        reason: '激活 computed 指标后，inactive cache 中的 slots 可能缺失，应重新加载',
      );
    });

    testWidgets('无缓存切换：立即取消 cross 并触发清屏重绘', (tester) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      await scene.initWithData(_spec, _candles(3).reversed.toList());
      scene.controller.flushPendingKlineData();
      await tester.pumpAndSettle();

      // 进入 crossing 状态。
      scene.controller.onCrossToggle(const Offset(10, 10));
      expect(scene.controller.isCrossing, isTrue);

      final repaintChart = scene.controller.repaintChart as ValueNotifier<int>;
      final repaintBefore = repaintChart.value;

      // 切换到无缓存的新 spec：走 _setKlineData 收尾。
      expect(scene.controller.switchKlineData(_nextSpec), isFalse);

      // 立即取消旧 cross，并触发 Chart 图层重绘（清屏）。
      expect(scene.controller.isCrossing, isFalse);
      expect(repaintChart.value, greaterThan(repaintBefore));
    });
  });

  /// WS 推送最新价后蜡烛超出可视区: 数据内容变化(非 replace)必须重算可见区间, 即使
  /// 可见 start/end 不变。修复经数据回调 `markRepaintChart(reset: true)` 跳过早退强制重算。
  /// 参见 bug 文档 `projects/flexi_kline/bugs/2026-10-10-WS推送最新价蜡烛超出可视区根因与修复`。
  group('v2.6.0/FlexiKlineController/visible_minmax_on_data_change', () {
    /// 当前生效区间的上端: 主图区顶边对应的价格。
    double rangeMax(FlexiKlineController chart) {
      return chart.dyToCandleValue(chart.mainChartRect.top)!.toDouble();
    }

    /// 当前生效区间的下端: 主图区底边对应的价格。
    double rangeMin(FlexiKlineController chart) {
      return chart.dyToCandleValue(chart.mainChartRect.bottom)!.toDouble();
    }

    CandleModel candleAt(int timestamp, {required num high, required num low}) => CandleModel(
      timestamp: timestamp,
      open: Decimal.fromInt(100),
      high: Decimal.fromInt(high.toInt()),
      low: Decimal.fromInt(low.toInt()),
      close: Decimal.fromInt(100),
      volume: Decimal.fromInt(1000),
    );

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
      await tester.pumpAndSettle();
      await paintChartFrame(tester, scene.controller);
      return scene;
    }

    testWidgets('原地更新最新一根 high 超出当前区间: 可见上端随之扩展', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;

      // genFlatCandleList: high 110 / low 90, 最新一根 timestamp 为 12000000。
      expect(rangeMax(chart), closeTo(110, 1e-6), reason: '前置条件: 自动区间上端为蜡烛最高价');

      // 原地更新最新一根(同 timestamp), 推一个远高于当前区间的 high。
      chart.updateLatestKlineData(_spec, [candleAt(12000000, high: 200, low: 90)]);
      await tester.pump(const Duration(milliseconds: 500));
      await paintChartFrame(tester, chart);

      expect(
        rangeMax(chart),
        greaterThanOrEqualTo(200 - 1e-6),
        reason: '数据变了却命中早退 => 新 high 落在区间外, 蜡烛被裁到主区外',
      );
    });

    testWidgets('原地更新最新一根 low 跌破当前区间: 可见下端随之扩展', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;

      expect(rangeMin(chart), closeTo(90, 1e-6), reason: '前置条件: 自动区间下端为蜡烛最低价');

      chart.updateLatestKlineData(_spec, [candleAt(12000000, high: 110, low: 10)]);
      await tester.pump(const Duration(milliseconds: 500));
      await paintChartFrame(tester, chart);

      expect(rangeMin(chart), lessThanOrEqualTo(10 + 1e-6));
    });

    testWidgets('推入时间更新的新蜡烛: 可见区间覆盖新蜡烛的高低点', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;

      // 新 timestamp(晚于 12000000), 走头部插入新蜡烛的路径。
      chart.updateLatestKlineData(_spec, [candleAt(12060000, high: 180, low: 20)]);
      await tester.pump(const Duration(milliseconds: 500));
      await paintChartFrame(tester, chart);

      expect(rangeMax(chart), greaterThanOrEqualTo(180 - 1e-6));
      expect(rangeMin(chart), lessThanOrEqualTo(20 + 1e-6));
    });
  });
}
