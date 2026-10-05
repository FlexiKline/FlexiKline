import 'dart:math' as math;

import 'package:fake_async/fake_async.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/config/my_kline_interval.dart';
import 'package:flexi_kline_demo/src/data/data_sources/mock/mock_kline_ws.dart';
import 'package:flexi_kline_demo/src/utils/candle_time.dart';
import 'package:flutter_test/flutter_test.dart';

double _price(Object v) => (v as num).toDouble();

void main() {
  group('MockKlineWs', () {
    test('每秒推一根未确认蜡烛，open 延续 startOpen（无缝衔接）', () {
      const interval = MyKlineInterval.minute15;
      final startTs = alignToInterval(
        DateTime.now().millisecondsSinceEpoch,
        interval.milliseconds,
      );
      final ws = MockKlineWs(
        tickInterval: const Duration(seconds: 1),
        random: math.Random(42),
      );

      fakeAsync((async) {
        final events = <List<CandleModel>>[];
        final sub = ws
            .subscribe(
              interval: interval,
              startTs: startTs,
              startOpen: 83624.0,
              startPrice: 84820.49,
            )
            .listen(events.add);

        async.elapse(const Duration(seconds: 3));
        async.flushMicrotasks();

        expect(events, hasLength(3));
        for (final event in events) {
          expect(event, hasLength(1));
          final c = event.single;
          expect(c.confirmed, isFalse);
          // open 保持历史收盘价，避免与上一根产生跳空缺口。
          expect(c.open, 83624.0);
          expect(_price(c.close), closeTo(84820.49, 84820.49 * 0.001));
        }
        // 同一周期内时间戳固定（对齐到周期边界）。
        expect(events[0].single.timestamp, startTs);
        expect(events[1].single.timestamp, startTs);
        expect(events[2].single.timestamp, startTs);

        // 取消订阅后无残留 timer。
        sub.cancel();
        async.flushMicrotasks();
        expect(async.periodicTimerCount, 0);
      });
    });

    test('周期切换后新蜡烛 open 等于上一根收盘价', () {
      final ws = MockKlineWs(
        tickInterval: const Duration(seconds: 1),
        random: math.Random(7),
      );

      fakeAsync((async) {
        final candles = <CandleModel>[];
        final sub = ws
            .subscribe(
              interval: MyKlineInterval.line, // 60s
              startTs: 0, // 故意错位：首 tick 即触发周期切换
              startOpen: 100.0,
              startPrice: 200.0,
              startHigh: 250.0,
              startLow: 50.0,
            )
            .listen((e) => candles.addAll(e));

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(candles, hasLength(1));
        // 切换分支：open 重置为上一根收盘价（此处即 startPrice）。
        expect(candles.single.open, 200.0);
        expect(candles.single.confirmed, isFalse);
        expect(_price(candles.single.close), closeTo(200.0, 200.0 * 0.001));

        sub.cancel();
        async.flushMicrotasks();
      });
    });
  });
}
