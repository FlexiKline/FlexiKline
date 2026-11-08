import 'dart:math' as math;

import 'package:fake_async/fake_async.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/data/data_sources/mock/mock_kline_ticker.dart';
import 'package:flexi_kline_demo/src/data/models/candle_dto.dart';
import 'package:flexi_kline_demo/src/data/models/kline_interval.dart';
import 'package:flexi_kline_demo/src/utils/candle_time.dart';
import 'package:flutter_test/flutter_test.dart';

CandleDto _last({required int ts, required double open, required double close, double? high, double? low}) =>
    CandleDto(timestamp: ts, open: open, high: high ?? close, low: low ?? close, close: close, volume: 0, turnover: 0);

void main() {
  group('MockKlineTicker', () {
    test('每秒推一根未确认蜡烛，open 延续上一根（无缝衔接）', () {
      const interval = KlineInterval.minute15;
      final startTs = alignToInterval(DateTime.now().millisecondsSinceEpoch, interval.milliseconds);
      final ticker = MockKlineTicker(tickInterval: const Duration(seconds: 1), random: math.Random(42));

      fakeAsync((async) {
        final events = <CandleDto>[];
        final sub = ticker.subscribe(interval, _last(ts: startTs, open: 83624.0, close: 84820.49)).listen(events.add);

        async.elapse(const Duration(seconds: 3));
        async.flushMicrotasks();

        expect(events, hasLength(3));
        for (final c in events) {
          expect(c.confirmed, isFalse);
          // open 保持历史开盘价，避免与上一根产生跳空缺口。
          expect(c.open, 83624.0);
          expect(c.close, closeTo(84820.49, 84820.49 * 0.001));
          // 同一周期内时间戳固定（对齐到周期边界）。
          expect(c.timestamp, startTs);
        }

        // 取消订阅后无残留 timer。
        sub.cancel();
        async.flushMicrotasks();
        expect(async.periodicTimerCount, 0);
      });
    });

    test('周期切换后新蜡烛 open 等于上一根收盘价', () {
      final ticker = MockKlineTicker(tickInterval: const Duration(seconds: 1), random: math.Random(7));

      fakeAsync((async) {
        final candles = <CandleDto>[];
        // 故意错位：首 tick 即触发周期切换。
        final last = _last(ts: 0, open: 100.0, close: 200.0, high: 250.0, low: 50.0);
        final sub = ticker.subscribe(KlineInterval.line, last).listen(candles.add);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(candles, hasLength(1));
        expect(candles.single.open, 200.0);
        expect(candles.single.confirmed, isFalse);
        expect(candles.single.close, closeTo(200.0, 200.0 * 0.001));

        sub.cancel();
        async.flushMicrotasks();
      });
    });

    test('同一 ticker 的两次订阅互不影响：后订阅不关闭先订阅，取消一条另一条继续', () {
      const interval = KlineInterval.minute15;
      final startTs = alignToInterval(DateTime.now().millisecondsSinceEpoch, interval.milliseconds);
      final ticker = MockKlineTicker(tickInterval: const Duration(seconds: 1), random: math.Random(1));

      fakeAsync((async) {
        final a = <CandleDto>[];
        final b = <CandleDto>[];
        var aDone = false;
        final subA = ticker
            .subscribe(interval, _last(ts: startTs, open: 100, close: 100))
            .listen(a.add, onDone: () => aDone = true);
        final subB = ticker.subscribe(interval, _last(ts: startTs, open: 500, close: 500)).listen(b.add);

        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(aDone, isFalse);
        expect(a, hasLength(2));
        expect(b, hasLength(2));
        // 各自从自己的起点续走，不共享价格状态。
        expect(a.last.close, closeTo(100, 100 * 0.002));
        expect(b.last.close, closeTo(500, 500 * 0.002));

        subB.cancel();
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
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
