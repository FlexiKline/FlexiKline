import 'dart:convert';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../utils/candle_time.dart';
import '../../models/candle_dto.dart';
import '../../models/kline_interval.dart';
import '../kline_data_source.dart';
import 'mock_kline_ticker.dart';

/// [KlineDataSource] 的 mock 实现：assets JSON 模拟 HTTP 分页，[MockKlineTicker] 模拟实时推送，数据按周期懒加载缓存。
class MockKlineDataSource implements KlineDataSource {
  MockKlineDataSource({this.isRealtime = true});

  /// 是否把历史蜡烛时间戳对齐到当前时间（false 则回放 JSON 里的历史时间）。
  final bool isRealtime;

  final MockKlineTicker _ticker = MockKlineTicker();

  final Map<KlineInterval, List<CandleDto>> _cache = {};
  final Map<KlineInterval, Future<List<CandleDto>>> _pending = {};

  /// 该周期全量蜡烛（升序，最新在后），懒加载并缓存。
  Future<List<CandleDto>> _ensureAll(KlineInterval interval) {
    final cached = _cache[interval];
    if (cached != null) return Future.value(cached);
    return _pending[interval] ??= _build(interval);
  }

  Future<List<CandleDto>> _build(KlineInterval interval) async {
    final raw = await _loadRaw(interval);
    final all = isRealtime ? _alignToNow(interval, raw) : raw;
    _cache[interval] = all;
    return all;
  }

  static Future<List<CandleDto>> _loadRaw(KlineInterval interval) async {
    final raw = await rootBundle.loadString(
      'assets/rawdata/btcusdt_kline_${interval.name}.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['candles'] as List<dynamic>).map((e) => CandleDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 最新一根对齐当前时间，往前按周期倒推（raw 从旧到新）。
  static List<CandleDto> _alignToNow(KlineInterval interval, List<CandleDto> raw) {
    final n = raw.length;
    final intervalMs = interval.milliseconds;
    final latestTs = alignToInterval(DateTime.now().millisecondsSinceEpoch, intervalMs);
    return [
      for (var i = 0; i < n; i++) _withTimestamp(raw[i], latestTs - (n - 1 - i) * intervalMs),
    ];
  }

  static CandleDto _withTimestamp(CandleDto d, int ts) => CandleDto(
    timestamp: ts,
    open: d.open,
    high: d.high,
    low: d.low,
    close: d.close,
    volume: d.volume,
    turnover: d.turnover,
    confirmed: d.confirmed,
  );

  @override
  Future<List<CandleDto>> fetchCandles({
    required String symbol,
    required KlineInterval interval,
    int? end,
    int limit = 500,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final all = await _ensureAll(interval);
    // all 升序（最新在后）。取满足条件的一段里最新的 limit 根, 仍按升序返回。
    final window = end == null ? all : all.where((c) => c.timestamp < end).toList();
    final from = window.length <= limit ? 0 : window.length - limit;
    return window.sublist(from);
  }

  @override
  Stream<CandleDto> subscribeTicks({
    required String symbol,
    required KlineInterval interval,
  }) async* {
    final all = await _ensureAll(interval);
    final last = all.isNotEmpty
        ? all.last
        : CandleDto(
            timestamp: DateTime.now().millisecondsSinceEpoch,
            open: 0,
            high: 0,
            low: 0,
            close: 0,
            volume: 0,
            turnover: 0,
          );
    yield* _ticker.subscribe(interval, last);
  }
}
