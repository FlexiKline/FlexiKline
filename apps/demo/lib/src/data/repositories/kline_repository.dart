import 'package:flexi_kline/flexi_kline.dart';

import '../../config/my_kline_interval.dart';
import '../data_sources/kline_api.dart';
import '../data_sources/mock/mock_kline_api.dart';

/// K 线数据仓库契约，方法与数据源 [KlineApi] 保持一致，仅注入并委托给底层数据源。
abstract interface class KlineRepository {
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

/// 注入 [KlineApi] 的默认仓库实现，默认使用 mock 数据源，测试可注入假实现。
class KlineRepositoryImpl implements KlineRepository {
  KlineRepositoryImpl({KlineApi? api}) : _api = api ?? MockKlineApi();

  final KlineApi _api;

  @override
  Future<List<CandleModel>> fetchCandles({
    required String symbol,
    required MyKlineInterval interval,
    int? end,
    int limit = 500,
  }) {
    return _api.fetchCandles(
      symbol: symbol,
      interval: interval,
      end: end,
      limit: limit,
    );
  }

  @override
  Stream<List<CandleModel>> subscribeTicks({
    required String symbol,
    required MyKlineInterval interval,
  }) {
    return _api.subscribeTicks(symbol: symbol, interval: interval);
  }
}
