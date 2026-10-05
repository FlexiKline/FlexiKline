import 'dart:async';
import 'dart:math' as math;

import 'package:flexi_kline/flexi_kline.dart';

import '../../../config/my_kline_interval.dart';
import '../../../utils/candle_time.dart';

/// 模拟 WebSocket 实时推送：按周期节奏随机产价，最新价 confirmed=false 持续游走。
class MockKlineWs {
  MockKlineWs({
    this.tickInterval = const Duration(seconds: 1),
    math.Random? random,
  }) : _random = random ?? math.Random();

  final Duration tickInterval;
  final math.Random _random;

  Timer? _timer;
  StreamController<List<CandleModel>>? _controller;

  int _cycleStartTs = 0;
  double _open = 0;
  double _high = 0;
  double _low = 0;
  double _price = 0;

  Stream<List<CandleModel>> subscribe({
    required MyKlineInterval interval,
    required int startTs,
    required double startOpen,
    required double startPrice,
    double? startHigh,
    double? startLow,
  }) {
    cancel();
    _cycleStartTs = startTs;
    // 无缝延续历史最后一根：open 保持不变，high/low 在历史累计值上继续 max/min。
    _open = startOpen;
    _price = startPrice;
    _high = math.max(startHigh ?? startPrice, math.max(startOpen, startPrice));
    _low = math.min(startLow ?? startPrice, math.min(startOpen, startPrice));

    final controller = StreamController<List<CandleModel>>();
    _controller = controller;

    void tick() {
      final now = DateTime.now().millisecondsSinceEpoch;
      final cycleStart = alignToInterval(now, interval.milliseconds);
      if (cycleStart != _cycleStartTs) {
        // 倒计时结束后的下一秒：上一根蜡烛的收盘价即新蜡烛的开盘价。
        _cycleStartTs = cycleStart;
        _open = _price;
        _high = _price;
        _low = _price;
      }
      _price = _nextPrice(_price);
      _high = math.max(_high, _price);
      _low = math.min(_low, _price);
      final volume = _volume();
      controller.add([
        CandleModel(
          timestamp: _cycleStartTs,
          open: _open,
          high: _high,
          low: _low,
          close: _price,
          volume: volume,
          turnover: _price * volume,
          confirmed: false,
        ),
      ]);
    }

    _timer = Timer.periodic(tickInterval, (_) => tick());

    controller.onCancel = () {
      _timer?.cancel();
      _timer = null;
      _controller = null;
    };

    return controller.stream;
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _controller?.close();
    _controller = null;
  }

  double _nextPrice(double p) {
    final delta = (_random.nextDouble() - 0.5) * 0.001; // ±0.05%
    return p * (1 + delta);
  }

  double _volume() => 1 + _random.nextDouble() * 5;
}
