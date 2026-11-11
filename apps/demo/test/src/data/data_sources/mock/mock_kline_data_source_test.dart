import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/data/data_sources/mock/mock_kline_data_source.dart';
import 'package:flexi_kline_demo/src/data/data_sources/mock/mock_price_series.dart';
import 'package:flexi_kline_demo/src/data/models/candle_dto.dart';
import 'package:flexi_kline_demo/src/data/models/kline_interval.dart';
import 'package:flutter_test/flutter_test.dart';

/// 2026-01-01 12:07:30 UTC。
final _now = DateTime.utc(2026, 1, 1, 12, 7, 30);

MockKlineDataSource _source([DateTime? now]) => MockKlineDataSource(now: () => now ?? _now);

void main() {
  group('MockKlineDataSource', () {
    test('最新一页：升序、相邻差一个周期，最后一根是当前周期进行中的蜡烛', () async {
      final candles = await _source().fetchCandles(symbol: 'BTCUSDT', interval: KlineInterval.minute15);

      expect(candles, hasLength(500));
      const step = 15 * 60 * 1000;
      for (var i = 1; i < candles.length; i++) {
        expect(candles[i].timestamp - candles[i - 1].timestamp, step);
        expect(candles[i].open, candles[i - 1].close);
      }
      expect(candles.last.timestamp, DateTime.utc(2026, 1, 1, 12).millisecondsSinceEpoch);
      expect(candles.last.confirmed, isFalse);
      expect(candles.where((c) => !c.confirmed), hasLength(1));
    });

    test('按 end 翻页：结果严格早于 end，与上一页首尾相接', () async {
      final source = _source();
      final first = await source.fetchCandles(symbol: 'BTCUSDT', interval: KlineInterval.hour1);
      final second = await source.fetchCandles(
        symbol: 'BTCUSDT',
        interval: KlineInterval.hour1,
        end: first.first.timestamp,
        limit: 200,
      );

      expect(second, hasLength(200));
      expect(second.last.timestamp, first.first.timestamp - KlineInterval.hour1.milliseconds);
      expect(second.last.close, first.first.open);
      expect(second.every((c) => c.confirmed), isTrue);
    });

    test('历史无限：翻到多年以前仍返回满页', () async {
      final candles = await _source().fetchCandles(
        symbol: 'BTCUSDT',
        interval: KlineInterval.day1,
        end: DateTime.utc(2001, 1, 1).millisecondsSinceEpoch,
      );
      expect(candles, hasLength(500));
      expect(candles.last.timestamp, lessThan(DateTime.utc(2001, 1, 1).millisecondsSinceEpoch));
    });

    test('确定性：不同实例、不同时刻请求同一段历史，结果相同', () async {
      final end = DateTime.utc(2025, 12, 1).millisecondsSinceEpoch;
      final a = await _source().fetchCandles(symbol: 'BTCUSDT', interval: KlineInterval.line, end: end);
      final b = await _source(DateTime.utc(2026, 3, 1)).fetchCandles(
        symbol: 'BTCUSDT',
        interval: KlineInterval.line,
        end: end,
      );
      String dump(List<CandleDto> list) =>
          list.map((c) => '${c.timestamp},${c.open},${c.high},${c.low},${c.close}').join(';');
      expect(dump(b), dump(a));
    });

    test('profiles 决定价位：未登记的 symbol 抛 ArgumentError', () async {
      final source = MockKlineDataSource(
        profiles: const {'ETHUSDT': MockSymbolProfile(basePrice: 2500)},
        now: () => _now,
      );
      final eth = await source.fetchCandles(symbol: 'ETHUSDT', interval: KlineInterval.hour1);
      expect(eth.map((c) => c.close).every((p) => p > 2500 * 0.84 && p < 2500 * 1.16), isTrue);

      await expectLater(
        source.fetchCandles(symbol: 'BTCUSDT', interval: KlineInterval.hour1),
        throwsArgumentError,
      );
    });

    test('默认登记 BTCUSDT，价位在 80000 附近', () async {
      final candles = await _source().fetchCandles(symbol: 'BTCUSDT', interval: KlineInterval.week1);
      expect(candles.map((c) => c.close).every((p) => p > 80000 * 0.84 && p < 80000 * 1.16), isTrue);
    });
  });
}
