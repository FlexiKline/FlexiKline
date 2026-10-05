import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/config/my_kline_interval.dart';
import 'package:flexi_kline_demo/src/config/my_kline_logger.dart';
import 'package:flexi_kline_demo/src/data/repositories/kline_repository.dart';
import 'package:flexi_kline_demo/src/pages/common/core/my_kline_data_center.dart';
import 'package:flexi_kline_demo/src/pages/common/core/my_kline_state_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements KlineRepository {
  List<CandleModel> candles = [];
  int fetchCallCount = 0;
  int subscribeCallCount = 0;

  @override
  Future<List<CandleModel>> fetchCandles({
    required String symbol,
    required MyKlineInterval interval,
    int? end,
    int limit = 500,
  }) async {
    fetchCallCount++;
    return candles;
  }

  @override
  Stream<List<CandleModel>> subscribeTicks({
    required String symbol,
    required MyKlineInterval interval,
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

class _TestPageState extends MyKlineStateBase<_TestPage> with MyKlineDataCenterMixin<_TestPage>, MyKlineLoggerMixin {
  @override
  KlineRepository get repository => widget.repository;

  @override
  KlineSpec createKlineSpec([KlineSpec? last]) {
    return KlineSpec(
      symbol: 'BTCUSDT',
      interval: last?.interval ?? MyKlineInterval.minute15,
      precision: 2,
      limit: 500,
      label: 'BTC-USDT',
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  group('MyKlineDataCenterMixin', () {
    testWidgets('timeInterval 返回当前 spec 的 interval', (tester) async {
      final repo = _FakeRepository();
      await tester.pumpWidget(MaterialApp(home: _TestPage(repository: repo)));
      await tester.pumpAndSettle();

      final state = tester.state<_TestPageState>(find.byType(_TestPage));
      expect(state.timeInterval, MyKlineInterval.minute15);
    });

    testWidgets('didIntervalChanged 同周期早退，不触发数据请求', (tester) async {
      final repo = _FakeRepository();
      await tester.pumpWidget(MaterialApp(home: _TestPage(repository: repo)));
      await tester.pumpAndSettle();

      final state = tester.state<_TestPageState>(find.byType(_TestPage));
      final initialFetch = repo.fetchCallCount;
      final initialSub = repo.subscribeCallCount;

      state.didIntervalChanged(MyKlineInterval.minute15);
      expect(repo.fetchCallCount, initialFetch);
      expect(repo.subscribeCallCount, initialSub);
    });

    testWidgets('didIntervalChanged 切换周期后触发 fetch + subscribe', (tester) async {
      final repo = _FakeRepository();
      await tester.pumpWidget(MaterialApp(home: _TestPage(repository: repo)));
      await tester.pumpAndSettle();

      final state = tester.state<_TestPageState>(find.byType(_TestPage));
      final initialFetch = repo.fetchCallCount;
      final initialSub = repo.subscribeCallCount;

      state.didIntervalChanged(MyKlineInterval.hour1);
      await tester.pumpAndSettle();

      expect(repo.fetchCallCount, greaterThan(initialFetch));
      expect(repo.subscribeCallCount, greaterThan(initialSub));
      expect(state.timeInterval, MyKlineInterval.hour1);
    });
  });
}
