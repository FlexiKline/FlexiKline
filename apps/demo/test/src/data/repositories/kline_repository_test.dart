import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/config/my_kline_interval.dart';
import 'package:flexi_kline_demo/src/data/data_sources/kline_api.dart';
import 'package:flexi_kline_demo/src/data/repositories/kline_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录调用参数并返回固定数据的假数据源。
class _RecordingApi implements KlineApi {
  _RecordingApi(this.result);

  final List<CandleModel> result;

  String? symbol;
  MyKlineInterval? interval;
  int? end;
  int? limit;
  bool subscribeCalled = false;

  @override
  Future<List<CandleModel>> fetchCandles({
    required String symbol,
    required MyKlineInterval interval,
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
  Stream<List<CandleModel>> subscribeTicks({
    required String symbol,
    required MyKlineInterval interval,
  }) {
    subscribeCalled = true;
    this.symbol = symbol;
    this.interval = interval;
    return Stream.value(result);
  }
}

void main() {
  group('KlineRepositoryImpl', () {
    test('fetchCandles 委托注入的 KlineApi 并透传参数', () async {
      final candle = CandleModel(timestamp: 1, open: 2.0, high: 3.0, low: 1.0, close: 2.5, volume: 10.0);
      final api = _RecordingApi([candle]);
      final repo = KlineRepositoryImpl(api: api);

      final result = await repo.fetchCandles(
        symbol: 'BTCUSDT',
        interval: MyKlineInterval.hour1,
        end: 123,
        limit: 50,
      );

      expect(result, hasLength(1));
      expect(result.single, same(candle));
      expect(api.symbol, 'BTCUSDT');
      expect(api.interval, MyKlineInterval.hour1);
      expect(api.end, 123);
      expect(api.limit, 50);
    });

    test('subscribeTicks 委托注入的 KlineApi', () async {
      final candle = CandleModel(timestamp: 1, open: 2.0, high: 3.0, low: 1.0, close: 2.5, volume: 10.0);
      final api = _RecordingApi([candle]);
      final repo = KlineRepositoryImpl(api: api);

      final stream = repo.subscribeTicks(symbol: 'BTCUSDT', interval: MyKlineInterval.line);

      expect(api.subscribeCalled, isTrue);
      final emitted = await stream.first;
      expect(emitted, hasLength(1));
      expect(emitted.single, same(candle));
    });
  });
}
