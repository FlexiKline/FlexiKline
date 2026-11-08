import 'dart:async';

import 'package:flexi_kline_demo/src/data/data_sources/kline_data_source.dart';
import 'package:flexi_kline_demo/src/data/models/candle_dto.dart';
import 'package:flexi_kline_demo/src/data/models/kline_interval.dart';
import 'package:flexi_kline_demo/src/data/repositories/kline_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录调用参数并返回固定 DTO 的假数据源。
class _RecordingDataSource implements KlineDataSource {
  _RecordingDataSource(this.result);

  final List<CandleDto> result;
  final StreamController<CandleDto> ticks = StreamController<CandleDto>();

  String? symbol;
  KlineInterval? interval;
  int? end;
  int? limit;

  @override
  Future<List<CandleDto>> fetchCandles({
    required String symbol,
    required KlineInterval interval,
    int? end,
    int limit = 500,
  }) async {
    this.symbol = symbol;
    this.interval = interval;
    this.end = end;
    this.limit = limit;
    return result;
  }

  @override
  Stream<CandleDto> subscribeTicks({
    required String symbol,
    required KlineInterval interval,
  }) {
    this.symbol = symbol;
    this.interval = interval;
    return ticks.stream;
  }
}

const _dto = CandleDto(timestamp: 1, open: 2, high: 3, low: 1, close: 2.5, volume: 10, turnover: 25);

void main() {
  group('KlineRepositoryImpl', () {
    test('fetchCandles 透传参数，并把 DTO 逐字段转成 CandleModel', () async {
      final source = _RecordingDataSource([_dto]);
      final repo = KlineRepositoryImpl(source);

      final result = await repo.fetchCandles(
        symbol: 'BTCUSDT',
        interval: KlineInterval.hour1,
        end: 123,
        limit: 50,
      );

      expect(source.symbol, 'BTCUSDT');
      expect(source.interval, KlineInterval.hour1);
      expect(source.end, 123);
      expect(source.limit, 50);
      final c = result.single;
      expect(c.timestamp, 1);
      expect(c.open, 2);
      expect(c.high, 3);
      expect(c.low, 1);
      expect(c.close, 2.5);
      expect(c.volume, 10);
      expect(c.turnover, 25);
      expect(c.confirmed, isTrue);
    });

    test('subscribeTicks 把每个推送 DTO 转成一批，保留 confirmed=false', () async {
      final source = _RecordingDataSource(const []);
      final repo = KlineRepositoryImpl(source);

      final first = repo.subscribeTicks(symbol: 'BTCUSDT', interval: KlineInterval.line).first;
      source.ticks.add(
        const CandleDto(
          timestamp: 60000,
          open: 1,
          high: 2,
          low: 1,
          close: 1.5,
          volume: 3,
          turnover: 4.5,
          confirmed: false,
        ),
      );
      final batch = await first;

      expect(source.interval, KlineInterval.line);
      expect(batch, hasLength(1));
      expect(batch.single.timestamp, 60000);
      expect(batch.single.close, 1.5);
      expect(batch.single.confirmed, isFalse);
    });
  });
}
