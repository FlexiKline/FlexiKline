import 'package:fake_async/fake_async.dart';
import 'package:flexi_kline_demo/src/data/data_sources/mock/mock_kline_ticker.dart';
import 'package:flexi_kline_demo/src/data/data_sources/mock/mock_price_series.dart';
import 'package:flexi_kline_demo/src/data/models/candle_dto.dart';
import 'package:flexi_kline_demo/src/data/models/kline_interval.dart';
import 'package:flutter_test/flutter_test.dart';

/// 2026-01-01 00:14:57 UTC：离 15 分钟周期结束还有 3 秒。
final _start = DateTime.utc(2026, 1, 1, 0, 14, 57);
final _series = MockPriceSeries('BTCUSDT', const MockSymbolProfile(basePrice: 80000));

void main() {
  group('MockKlineTicker', () {
    test('每秒推一根未确认蜡烛，收盘取当前时刻价格，时间戳对齐周期起点', () {
      fakeAsync((async) {
        final ticker = MockKlineTicker(now: () => _start.add(async.elapsed));
        final events = <CandleDto>[];
        final sub = ticker.subscribe(KlineInterval.minute15, _series).listen(events.add);

        async.elapse(const Duration(seconds: 2));

        expect(events, hasLength(2));
        final cycleStart = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch;
        for (final (i, c) in events.indexed) {
          expect(c.confirmed, isFalse);
          expect(c.timestamp, cycleStart);
          expect(c.open, _series.priceAt(cycleStart));
          expect(c.close, _series.priceAt(_start.add(Duration(seconds: i + 1)).millisecondsSinceEpoch));
        }

        sub.cancel();
        async.flushMicrotasks();
        expect(async.periodicTimerCount, 0);
      });
    });

    test('跨过周期边界后开新蜡烛，开盘取新周期起点价格', () {
      fakeAsync((async) {
        final ticker = MockKlineTicker(now: () => _start.add(async.elapsed));
        final events = <CandleDto>[];
        final sub = ticker.subscribe(KlineInterval.minute15, _series).listen(events.add);

        async.elapse(const Duration(seconds: 4));

        final next = DateTime.utc(2026, 1, 1, 0, 15).millisecondsSinceEpoch;
        expect(events.last.timestamp, next);
        expect(events.last.open, _series.priceAt(next));
        sub.cancel();
      });
    });

    test('同一周期内最高只升、最低只降', () {
      fakeAsync((async) {
        final ticker = MockKlineTicker(now: () => DateTime.utc(2026, 1, 1, 0, 1).add(async.elapsed));
        final events = <CandleDto>[];
        final sub = ticker.subscribe(KlineInterval.minute15, _series).listen(events.add);

        async.elapse(const Duration(seconds: 120));

        for (var i = 1; i < events.length; i++) {
          expect(events[i].high, greaterThanOrEqualTo(events[i - 1].high));
          expect(events[i].low, lessThanOrEqualTo(events[i - 1].low));
        }
        sub.cancel();
      });
    });

    test('两条订阅在同一时刻推出同一价格，取消一条另一条继续', () {
      fakeAsync((async) {
        final ticker = MockKlineTicker(now: () => _start.add(async.elapsed));
        final a = <CandleDto>[];
        final b = <CandleDto>[];
        final subA = ticker.subscribe(KlineInterval.minute15, _series).listen(a.add);
        final subB = ticker.subscribe(KlineInterval.minute15, _series).listen(b.add);

        async.elapse(const Duration(seconds: 2));
        expect([for (final c in a) c.close], [for (final c in b) c.close]);

        subB.cancel();
        async.elapse(const Duration(seconds: 2));
        expect(a, hasLength(4));
        expect(b, hasLength(2));
        expect(async.periodicTimerCount, 1);

        subA.cancel();
        async.flushMicrotasks();
        expect(async.periodicTimerCount, 0);
      });
    });
  });
}
