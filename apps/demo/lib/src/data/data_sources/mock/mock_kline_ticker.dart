import 'dart:async';
import 'dart:math' as math;

import 'package:flexi_kline/flexi_kline.dart';

import '../../../utils/candle_time.dart';
import '../../models/candle_dto.dart';
import '../../models/kline_interval.dart';
import 'mock_price_series.dart';

/// 模拟 WebSocket 实时推送：每 [tickInterval] 推一次当前周期未确认的蜡烛，价格取自 [MockPriceSeries]。
///
/// 价格只由时间戳决定，同一时刻的多个订阅推出的收盘价相同；每次 [subscribe] 是一条独立的流，取消订阅即停止计时。
class MockKlineTicker {
  MockKlineTicker({this.tickInterval = const Duration(seconds: 1), DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Duration tickInterval;
  final DateTime Function() _now;

  Stream<CandleDto> subscribe(KlineInterval interval, MockPriceSeries series) {
    final intervalMs = interval.milliseconds;
    var cycleStart = -1;
    var high = 0.0;
    var low = 0.0;

    Timer? timer;
    late final StreamController<CandleDto> controller;

    void tick() {
      final nowMs = _now().millisecondsSinceEpoch;
      final candle = series.candle(alignToInterval(nowMs, intervalMs), intervalMs, until: nowMs);
      // 同一周期内最高、最低只扩不缩：采样点随时间移动，单次估算可能比之前推过的值窄。
      if (candle.timestamp == cycleStart) {
        high = math.max(high, candle.high);
        low = math.min(low, candle.low);
      } else {
        cycleStart = candle.timestamp;
        high = candle.high;
        low = candle.low;
      }
      controller.add(
        CandleDto(
          timestamp: candle.timestamp,
          open: candle.open,
          high: high,
          low: low,
          close: candle.close,
          volume: candle.volume,
          turnover: candle.turnover,
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
}
