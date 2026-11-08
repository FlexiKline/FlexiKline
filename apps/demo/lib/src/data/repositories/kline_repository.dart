import 'package:flexi_kline/flexi_kline.dart';

import '../models/kline_interval.dart';

/// K 线数据的应用契约，返回 flexi_kline 的 [CandleModel]；UI 测试替换它。
///
/// [end] 为 null 取最新一页，否则返回严格早于 [end] 的数据；结果按时间升序。
abstract interface class KlineRepository {
  Future<List<CandleModel>> fetchCandles({
    required String symbol,
    required KlineInterval interval,
    int? end,
    int limit = 500,
  });

  /// 每条事件是一批需要更新的蜡烛，直接交给 `updateLatestKlineData`。
  Stream<List<CandleModel>> subscribeTicks({
    required String symbol,
    required KlineInterval interval,
  });
}
