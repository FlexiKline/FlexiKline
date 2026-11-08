import 'dart:async';
import 'dart:math' as math;

import 'package:flexi_kline/flexi_kline.dart';

import '../../../utils/candle_time.dart';
import '../../models/candle_dto.dart';
import '../../models/kline_interval.dart';

/// 模拟 WebSocket 实时推送：按周期节奏随机产价，最新价 confirmed=false 持续游走。
///
/// 每次 [subscribe] 返回一条独立的流，状态只属于这次订阅；取消订阅即停止计时，不影响其他订阅。
class MockKlineTicker {
  MockKlineTicker({
    this.tickInterval = const Duration(seconds: 1),
    math.Random? random,
  }) : _random = random ?? math.Random();

  final Duration tickInterval;
  final math.Random _random;

  /// 从 [last] 无缝续走：同一周期内 open 保持不变，high/low 在 [last] 的累计值上继续取 max/min。
  Stream<CandleDto> subscribe(KlineInterval interval, CandleDto last) {
    var cycleStartTs = last.timestamp;
    var open = last.open;
    var price = last.close;
    var high = math.max(last.high, math.max(open, price));
    var low = math.min(last.low, math.min(open, price));

    Timer? timer;
    late final StreamController<CandleDto> controller;

    void tick() {
      final cycleStart = alignToInterval(DateTime.now().millisecondsSinceEpoch, interval.milliseconds);
      if (cycleStart != cycleStartTs) {
        // 倒计时结束后的下一秒：上一根蜡烛的收盘价即新蜡烛的开盘价。
        cycleStartTs = cycleStart;
        open = price;
        high = price;
        low = price;
      }
      price = _nextPrice(price);
      high = math.max(high, price);
      low = math.min(low, price);
      final volume = _volume();
      controller.add(
        CandleDto(
          timestamp: cycleStartTs,
          open: open,
          high: high,
          low: low,
          close: price,
          volume: volume,
          turnover: price * volume,
          confirmed: false,
        ),
      );
    }

    controller = StreamController<CandleDto>(
      onListen: () => timer = Timer.periodic(tickInterval, (_) => tick()),
      onCancel: () => timer?.cancel(),
    );
    return controller.stream;
  }

  double _nextPrice(double p) {
    final delta = (_random.nextDouble() - 0.5) * 0.001; // ±0.05%
    return p * (1 + delta);
  }

  double _volume() => 1 + _random.nextDouble() * 5;
}
