import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/config/app_kline_config.dart';
import 'package:flexi_kline_demo/src/config/app_kline_indicator_config.dart';
import 'package:flexi_kline_demo/src/config/app_kline_logger.dart';
import 'package:flexi_kline_demo/src/data/models/kline_interval.dart';
import 'package:flexi_kline_demo/src/data/repositories/kline_repository.dart';
import 'package:flexi_kline_demo/src/presentation/kline/core/kline_data_center_mixin.dart';
import 'package:flexi_kline_demo/src/presentation/kline/core/kline_state_base.dart';
import 'package:flexi_kline_demo/src/presentation/kline/widgets/kline_interval_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements KlineRepository {
  List<CandleModel> candles = [];
  int fetchCallCount = 0;
  KlineInterval? lastFetchInterval;
  int subscribeCallCount = 0;

  @override
  Future<List<CandleModel>> fetchCandles({
    required String symbol,
    required KlineInterval interval,
    int? end,
    int limit = 500,
  }) async {
    fetchCallCount++;
    lastFetchInterval = interval;
    return candles;
  }

  @override
  Stream<List<CandleModel>> subscribeTicks({
    required String symbol,
    required KlineInterval interval,
  }) {
    subscribeCallCount++;
    return const Stream.empty();
  }
}

class _TestPage extends StatefulWidget {
  const _TestPage({required this.repository});

  final KlineRepository repository;

  @override
  State<_TestPage> createState() => _TestPageState();
}

class _TestPageState extends KlineStateBase<_TestPage> with KlineDataCenterMixin<_TestPage>, AppKlineLoggerMixin {
  late final AppKlineIndicatorConfig _indicatorConfig;
  late final AppKlineConfig _klineConfig;

  @override
  BaseIndicatorConfig get indicatorConfig => _indicatorConfig;

  @override
  IConfiguration get klineConfig => _klineConfig;

  @override
  KlineRepository get klineRepository => widget.repository;

  @override
  KlineInterval get initialInterval => KlineInterval.minute15;

  @override
  void initState() {
    _indicatorConfig = AppKlineIndicatorConfig();
    _klineConfig = AppKlineConfig();
    super.initState();
  }

  @override
  void dispose() {
    klineController.storeFlexiKlineConfig();
    _indicatorConfig.dispose();
    super.dispose();
  }

  @override
  KlineSpec createKlineSpec([KlineSpec? last]) {
    return KlineSpec(
      symbol: 'BTCUSDT',
      interval: last?.interval ?? currentInterval,
      precision: 2,
      limit: 500,
      label: 'BTC-USDT',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: KlineIntervalBar(selected: interval, onSelected: selectInterval),
  );
}

void main() {
  group('KlineDataCenterMixin', () {
    testWidgets('currentInterval 取自 initialInterval', (tester) async {
      final repo = _FakeRepository();
      await tester.pumpWidget(MaterialApp(home: _TestPage(repository: repo)));
      await tester.pumpAndSettle();

      final state = tester.state<_TestPageState>(find.byType(_TestPage));
      expect(state.currentInterval, KlineInterval.minute15);
      expect(repo.lastFetchInterval, KlineInterval.minute15);
    });

    testWidgets('selectInterval 同周期早退，不触发数据请求', (tester) async {
      final repo = _FakeRepository();
      await tester.pumpWidget(MaterialApp(home: _TestPage(repository: repo)));
      await tester.pumpAndSettle();

      final state = tester.state<_TestPageState>(find.byType(_TestPage));
      final initialFetch = repo.fetchCallCount;
      final initialSub = repo.subscribeCallCount;

      state.selectInterval(KlineInterval.minute15);
      expect(repo.fetchCallCount, initialFetch);
      expect(repo.subscribeCallCount, initialSub);
    });

    testWidgets('selectInterval 切换周期后触发 fetch + subscribe', (tester) async {
      final repo = _FakeRepository();
      await tester.pumpWidget(MaterialApp(home: _TestPage(repository: repo)));
      await tester.pumpAndSettle();

      final state = tester.state<_TestPageState>(find.byType(_TestPage));
      final initialFetch = repo.fetchCallCount;
      final initialSub = repo.subscribeCallCount;

      state.selectInterval(KlineInterval.hour1);
      await tester.pumpAndSettle();

      expect(repo.fetchCallCount, greaterThan(initialFetch));
      expect(repo.subscribeCallCount, greaterThan(initialSub));
      expect(state.currentInterval, KlineInterval.hour1);
    });

    testWidgets('点周期栏后 mixin 的 interval 更新，请求用的 spec 也是新周期', (tester) async {
      final repo = _FakeRepository();
      await tester.pumpWidget(MaterialApp(home: _TestPage(repository: repo)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('1时'));
      await tester.pumpAndSettle();

      final state = tester.state<_TestPageState>(find.byType(_TestPage));
      expect(state.interval.value, KlineInterval.hour1);
      expect(repo.lastFetchInterval, KlineInterval.hour1);
      expect(
        tester.widget<TabBar>(find.byType(TabBar)).controller?.index,
        KlineInterval.values.indexOf(KlineInterval.hour1),
      );
    });
  });
}
