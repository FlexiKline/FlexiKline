import 'dart:math' as math;

import 'package:flexi_kline/flexi_kline.dart';

import '../../../utils/candle_time.dart';
import '../../models/candle_dto.dart';
import '../../models/kline_interval.dart';
import '../kline_data_source.dart';
import 'mock_kline_ticker.dart';
import 'mock_price_series.dart';

/// [KlineDataSource] 的 mock 实现：按时间戳生成确定性的历史与推送，历史可以无限向前翻页。
///
/// 每个 symbol 的价位由 [profiles] 决定；最新一根是当前周期进行中的蜡烛。
class MockKlineDataSource implements KlineDataSource {
  MockKlineDataSource({this.profiles = defaultProfiles, DateTime Function()? now})
    : _now = now ?? DateTime.now,
      _ticker = MockKlineTicker(now: now);

  /// 内置标的的价位；新增标的在这里加一行。
  static const Map<String, MockSymbolProfile> defaultProfiles = {
    'BTCUSDT': MockSymbolProfile(basePrice: 80000),
  };

  final Map<String, MockSymbolProfile> profiles;
  final DateTime Function() _now;
  final MockKlineTicker _ticker;
  final Map<String, MockPriceSeries> _series = {};

  MockPriceSeries _seriesOf(String symbol) {
    final profile = profiles[symbol];
    if (profile == null) throw ArgumentError.value(symbol, 'symbol', '没有 mock 价位参数，在 profiles 里添加');
    return _series[symbol] ??= MockPriceSeries(symbol, profile);
  }

  @override
  Future<List<CandleDto>> fetchCandles({
    required String symbol,
    required KlineInterval interval,
    int? end,
    int limit = 500,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final series = _seriesOf(symbol);
    final intervalMs = interval.milliseconds;
    final nowMs = _now().millisecondsSinceEpoch;
    final current = alignToInterval(nowMs, intervalMs);
    // 最后一根：取最新一页时是当前周期；翻页时是严格早于 end 的那一根，且不晚于当前周期。
    final last = end == null ? current : math.min(alignToInterval(end - 1, intervalMs), current);
    final first = last - (limit - 1) * intervalMs;
    return [
      for (var ts = first; ts <= last; ts += intervalMs)
        ts == current ? series.candle(ts, intervalMs, until: nowMs) : series.candle(ts, intervalMs),
    ];
  }

  @override
  Stream<CandleDto> subscribeTicks({
    required String symbol,
    required KlineInterval interval,
  }) {
    return _ticker.subscribe(interval, _seriesOf(symbol));
  }
}
