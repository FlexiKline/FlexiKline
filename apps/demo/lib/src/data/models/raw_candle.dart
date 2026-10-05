/// JSON 里一根蜡烛的原始 OHLCV（带历史时间戳）。
class RawCandle {
  const RawCandle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.turnover,
  });

  /// 历史时间戳（毫秒）。
  final int timestamp;

  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final double turnover;

  factory RawCandle.fromJson(Map<String, dynamic> json) => RawCandle(
    timestamp: (json['ts'] as num).toInt(),
    open: (json['open'] as num).toDouble(),
    high: (json['high'] as num).toDouble(),
    low: (json['low'] as num).toDouble(),
    close: (json['close'] as num).toDouble(),
    volume: (json['volume'] as num).toDouble(),
    turnover: (json['turnover'] as num).toDouble(),
  );
}
