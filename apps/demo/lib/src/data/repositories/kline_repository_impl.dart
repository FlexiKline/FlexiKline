import 'package:flexi_kline/flexi_kline.dart';

import '../data_sources/kline_data_source.dart';
import '../models/candle_dto.dart';
import '../models/kline_interval.dart';
import 'kline_repository.dart';

/// [KlineRepository] 的实现：持有 [KlineDataSource]，[CandleDto] 到 [CandleModel] 的转换只在这里发生。
class KlineRepositoryImpl implements KlineRepository {
  KlineRepositoryImpl(this._dataSource);

  final KlineDataSource _dataSource;

  @override
  Future<List<CandleModel>> fetchCandles({
    required String symbol,
    required KlineInterval interval,
    int? end,
    int limit = 500,
  }) async {
    final dtos = await _dataSource.fetchCandles(
      symbol: symbol,
      interval: interval,
      end: end,
      limit: limit,
    );
    return dtos.map(_toModel).toList();
  }

  @override
  Stream<List<CandleModel>> subscribeTicks({
    required String symbol,
    required KlineInterval interval,
  }) {
    return _dataSource.subscribeTicks(symbol: symbol, interval: interval).map((dto) => [_toModel(dto)]);
  }

  static CandleModel _toModel(CandleDto d) => CandleModel(
    timestamp: d.timestamp,
    open: d.open,
    high: d.high,
    low: d.low,
    close: d.close,
    volume: d.volume,
    turnover: d.turnover,
    confirmed: d.confirmed,
  );
}
