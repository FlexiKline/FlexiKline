import 'dart:convert';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../config/my_kline_interval.dart';
import '../../../utils/candle_time.dart';
import '../../models/raw_candle.dart';
import '../kline_api.dart';
import 'mock_kline_ws.dart';

/// [KlineApi] 的 mock 实现：模拟 HTTP 分页 + 实时推送，数据按周期懒加载缓存。
class MockKlineApi implements KlineApi {
  MockKlineApi({this.isRealtime = true});

  /// 是否把历史蜡烛时间戳对齐到当前时间（false 则回放 JSON 里的历史时间）。
  final bool isRealtime;

  final MockKlineWs _ws = MockKlineWs();

  final Map<MyKlineInterval, List<CandleModel>> _cache = {};
  final Map<MyKlineInterval, Future<List<CandleModel>>> _pending = {};

  /// 该周期全量蜡烛（降序，最新在前），懒加载并缓存。
  Future<List<CandleModel>> _ensureAll(MyKlineInterval interval) {
    final cached = _cache[interval];
    if (cached != null) return Future.value(cached);
    return _pending[interval] ??= _build(interval);
  }

  Future<List<CandleModel>> _build(MyKlineInterval interval) async {
    final raw = await _loadRaw(interval);
    final all = _buildCandles(interval, raw);
    _cache[interval] = all;
    return all;
  }

  static Future<List<RawCandle>> _loadRaw(MyKlineInterval interval) async {
    final raw = await rootBundle.loadString(
      'assets/rawdata/btcusdt_kline_${interval.name}.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['candles'] as List<dynamic>).map((e) => RawCandle.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 把 [RawCandle] 序列构建为按时间降序（最新在前）的 [CandleModel]。
  List<CandleModel> _buildCandles(MyKlineInterval interval, List<RawCandle> raw) {
    final n = raw.length;
    if (n == 0) return const [];

    final candles = <CandleModel>[];
    if (isRealtime) {
      // 最新一根对齐当前时间，往前按周期倒推（raw 从旧到新）。
      final intervalMs = interval.milliseconds;
      final latestTs = alignToInterval(DateTime.now().millisecondsSinceEpoch, intervalMs);
      for (var i = 0; i < n; i++) {
        final r = raw[i];
        candles.add(_toCandle(r, latestTs - (n - 1 - i) * intervalMs));
      }
    } else {
      // 直接用 JSON 里的历史时间戳。
      for (final r in raw) {
        candles.add(_toCandle(r, r.timestamp));
      }
    }
    return candles.reversed.toList();
  }

  CandleModel _toCandle(RawCandle r, int ts) => CandleModel(
    timestamp: ts,
    open: r.open,
    high: r.high,
    low: r.low,
    close: r.close,
    volume: r.volume,
    turnover: r.turnover,
    confirmed: true,
  );

  @override
  Future<List<CandleModel>> fetchCandles({
    required String symbol,
    required MyKlineInterval interval,
    int? end,
    int limit = 500,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final all = await _ensureAll(interval);
    if (end == null) {
      return all.take(limit).toList();
    }
    return all.where((c) => c.timestamp < end).take(limit).toList();
  }

  @override
  Stream<List<CandleModel>> subscribeTicks({
    required String symbol,
    required MyKlineInterval interval,
  }) async* {
    final all = await _ensureAll(interval);
    final latest = all.isEmpty ? null : all.first;
    final startTs = latest?.timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final startOpen = (latest?.open as num?)?.toDouble() ?? 0.0;
    final startClose = (latest?.close as num?)?.toDouble() ?? 0.0;
    final startHigh = (latest?.high as num?)?.toDouble();
    final startLow = (latest?.low as num?)?.toDouble();
    yield* _ws.subscribe(
      interval: interval,
      startTs: startTs,
      startOpen: startOpen,
      startPrice: startClose,
      startHigh: startHigh,
      startLow: startLow,
    );
  }
}
