/// 服务端的一根蜡烛：assets JSON 与推送都产出它，由 Repository 转成 `CandleModel`。
class CandleDto {
  const CandleDto({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.turnover,
    this.confirmed = true,
  });

  /// 周期起点时间戳（毫秒）。
  final int timestamp;

  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final double turnover;

  /// 推送中未收盘的蜡烛为 false。
  final bool confirmed;

  factory CandleDto.fromJson(Map<String, dynamic> json) => CandleDto(
    timestamp: (json['ts'] as num).toInt(),
    open: (json['open'] as num).toDouble(),
    high: (json['high'] as num).toDouble(),
    low: (json['low'] as num).toDouble(),
    close: (json['close'] as num).toDouble(),
    volume: (json['volume'] as num).toDouble(),
    turnover: (json['turnover'] as num).toDouble(),
  );
}
