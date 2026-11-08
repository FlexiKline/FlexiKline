import '../models/candle_dto.dart';
import '../models/kline_interval.dart';

/// K 线传输契约：HTTP 分页与实时推送，只返回 [CandleDto]。接入真实后端时替换 mock 实现。
///
/// [end] 为 null 取最新一页，否则返回严格早于 [end] 的数据；结果按时间升序。
abstract interface class KlineDataSource {
  Future<List<CandleDto>> fetchCandles({
    required String symbol,
    required KlineInterval interval,
    int? end,
    int limit = 500,
  });

  /// 每条事件是当前周期最新的一根蜡烛。
  Stream<CandleDto> subscribeTicks({
    required String symbol,
    required KlineInterval interval,
  });
}
