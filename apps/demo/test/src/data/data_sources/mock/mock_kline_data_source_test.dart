import 'package:flexi_kline_demo/src/data/data_sources/mock/mock_kline_data_source.dart';
import 'package:flexi_kline_demo/src/data/models/kline_interval.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MockKlineDataSource', () {
    test('首次取最新一页：默认 500 根、升序、confirmed', () async {
      final source = MockKlineDataSource();
      final candles = await source.fetchCandles(
        symbol: 'BTCUSDT',
        interval: KlineInterval.minute15,
      );

      expect(candles, hasLength(500));
      expect(candles.last.confirmed, isTrue);
      for (var i = 0; i < candles.length - 1; i++) {
        expect(candles[i].timestamp, lessThan(candles[i + 1].timestamp));
      }
    });

    test('按 end 向历史翻页，结果严格早于 end 且不重叠', () async {
      final source = MockKlineDataSource();
      final first = await source.fetchCandles(
        symbol: 'BTCUSDT',
        interval: KlineInterval.minute15,
      );
      final end = first.first.timestamp;
      final second = await source.fetchCandles(
        symbol: 'BTCUSDT',
        interval: KlineInterval.minute15,
        end: end,
      );

      expect(second, isNotEmpty);
      for (final c in second) {
        expect(c.timestamp, lessThan(end));
      }
      // 第二页最新一根早于第一页最旧一根，无重叠。
      expect(second.last.timestamp, lessThan(first.first.timestamp));
    });

    test('周期数据缓存：同一周期多次调用返回一致', () async {
      final source = MockKlineDataSource();
      final a = await source.fetchCandles(symbol: 'BTCUSDT', interval: KlineInterval.minute15);
      final b = await source.fetchCandles(symbol: 'BTCUSDT', interval: KlineInterval.minute15);

      expect(a.map((c) => c.timestamp).toList(), orderedEquals(b.map((c) => c.timestamp).toList()));
    });

    test('不同周期加载各自数据（切周期不串数据）', () async {
      final source = MockKlineDataSource();
      final line = await source.fetchCandles(symbol: 'BTCUSDT', interval: KlineInterval.line);
      final day = await source.fetchCandles(symbol: 'BTCUSDT', interval: KlineInterval.day1);

      // 时间跨度不同，相邻蜡烛的间隔应按各自周期错开。
      expect(line, isNotEmpty);
      expect(day, isNotEmpty);
      expect(line.map((c) => c.timestamp).toList(), isNot(orderedEquals(day.map((c) => c.timestamp).toList())));
    });

    test('isRealtime（默认）对齐当前时间，最新蜡烛落在周期边界', () async {
      final source = MockKlineDataSource();
      final candles = await source.fetchCandles(symbol: 'BTCUSDT', interval: KlineInterval.minute15);

      expect(candles.last.timestamp % (15 * 60 * 1000), 0);
    });

    test('isRealtime=false 回放 JSON 历史时间戳', () async {
      final source = MockKlineDataSource(isRealtime: false);
      final candles = await source.fetchCandles(symbol: 'BTCUSDT', interval: KlineInterval.minute15);

      expect(candles, hasLength(500));
      // 最新一根 = 统一锚点 2025-01-01 00:00:00 UTC，相邻间隔 15 分钟（升序）。
      expect(candles.last.timestamp, 1735689600000);
      for (var i = 0; i < candles.length - 1; i++) {
        expect(candles[i + 1].timestamp - candles[i].timestamp, 15 * 60 * 1000);
      }
    });
  });
}
