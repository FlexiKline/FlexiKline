import 'package:flexi_kline/flexi_kline.dart';

import '../../config/my_kline_interval.dart';

/// K 线数据源抽象：HTTP 分页 + WS 订阅。
///
/// [end] 为 null 取最新一页，否则向前翻页返回严格早于 [end] 的数据；返回按时间降序。
abstract interface class KlineApi {
  Future<List<CandleModel>> fetchCandles({
    required String symbol,
    required MyKlineInterval interval,
    int? end,
    int limit = 500,
  });

  Stream<List<CandleModel>> subscribeTicks({
    required String symbol,
    required MyKlineInterval interval,
  });
}
