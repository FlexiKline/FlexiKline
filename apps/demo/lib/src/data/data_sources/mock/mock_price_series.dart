import 'dart:math' as math;

import '../../models/candle_dto.dart';

/// 一个 mock 标的的价位参数：价格围绕 [basePrice] 波动，幅度不超过 [basePrice] × [swing]。
class MockSymbolProfile {
  const MockSymbolProfile({required this.basePrice, this.swing = 0.15});

  final double basePrice;

  /// 相对 [basePrice] 的最大偏离比例。
  final double swing;
}

/// 按时间戳确定价格的 mock 行情：同一 symbol、同一时间戳在任何设备、任何次运行都得到同一个值。
///
/// 价格是多层值噪声的叠加，只用整数哈希与四则运算（不用 `dart:math` 的 `Random` 和三角函数），
/// 所以不随 SDK 版本、编译目标变化；结果按 [pricePrecision] 位小数取整。
/// 不同周期共用 [priceAt]，同一时刻的开盘、收盘价在各周期之间一致；最高、最低价按采样估算。
class MockPriceSeries {
  MockPriceSeries(String symbol, this.profile) : _seed = _fnv1a(symbol);

  final MockSymbolProfile profile;
  final int _seed;

  static const int pricePrecision = 2;

  /// 估算一根蜡烛最高、最低价时，在周期内部取的采样点数。
  static const int _samplesPerCandle = 6;

  static const int _minute = 60 * 1000;

  /// 噪声层：周期从长到短，越短的层振幅越小。
  static const List<(int, double)> _octaves = [
    (30 * 24 * 60 * _minute, 1.0),
    (7 * 24 * 60 * _minute, 0.5),
    (24 * 60 * _minute, 0.3),
    (4 * 60 * _minute, 0.15),
    (60 * _minute, 0.08),
    (15 * _minute, 0.04),
    (3 * _minute, 0.02),
  ];

  static final double _amplitudeSum = _octaves.fold(0.0, (sum, o) => sum + o.$2);

  /// [ms] 时刻的价格。
  double priceAt(int ms) {
    var noise = 0.0;
    for (var i = 0; i < _octaves.length; i++) {
      final (period, amplitude) = _octaves[i];
      noise += amplitude * _valueNoise(ms, period, i);
    }
    return _round(profile.basePrice * (1 + profile.swing * noise / _amplitudeSum), pricePrecision);
  }

  /// 起点为 [start]、跨度 [intervalMs] 的蜡烛。[until] 早于周期结束时生成进行中的蜡烛：收盘取 [until] 时刻的价格，未确认。
  CandleDto candle(int start, int intervalMs, {int? until}) {
    final end = until == null ? start + intervalMs : until.clamp(start, start + intervalMs);
    final open = priceAt(start);
    final close = priceAt(end);
    var high = math.max(open, close);
    var low = math.min(open, close);
    for (var i = 1; i <= _samplesPerCandle; i++) {
      final p = priceAt(start + (end - start) * i ~/ (_samplesPerCandle + 1));
      high = math.max(high, p);
      low = math.min(low, p);
    }
    // 影线：在采样极值外再延伸一点，幅度取蜡烛内的确定性噪声。
    final wick = profile.basePrice * 0.0005;
    high = _round(high + wick * _unit(start, 1), pricePrecision);
    low = _round(low - wick * _unit(start, 2), pricePrecision);
    // 成交量按已走过的时长计，进行中的蜡烛随时间增长。
    final volume = _round((end - start) / _minute * (0.5 + _unit(start, 3)), 4);
    return CandleDto(
      timestamp: start,
      open: open,
      high: high,
      low: low,
      close: close,
      volume: volume,
      turnover: _round(volume * (open + close) / 2, pricePrecision),
      confirmed: until == null || end >= start + intervalMs,
    );
  }

  /// 第 [layer] 层在 [ms] 处的值噪声，范围 [-1, 1]：相邻格点取哈希值，中间用 smoothstep 插值。
  double _valueNoise(int ms, int period, int layer) {
    final index = ms ~/ period;
    final t = (ms - index * period) / period;
    final a = _signed(index, layer);
    final b = _signed(index + 1, layer);
    final s = t * t * (3 - 2 * t);
    return a + (b - a) * s;
  }

  /// 噪声层格点的确定性数；盐值从 16 起，与蜡烛内影线、成交量用的 1～3 错开，互不相关。
  double _signed(int index, int layer) => _unit(index, layer + 16) * 2 - 1;

  /// [key]（非负，可超过 32 位）、[salt] 对应的 [0, 1) 确定性数。
  ///
  /// 高低 32 位用整数除法和取模拆开：Web 上移位只取次数的低 5 位，`>> 32` 不可靠。
  double _unit(int key, int salt) {
    const word = 4294967296;
    final h = _hash32(_hash32((key % word) ^ _hash32(_seed ^ salt)) ^ (key ~/ word));
    return h / word;
  }

  static double _round(double v, int digits) {
    var factor = 1.0;
    for (var i = 0; i < digits; i++) {
      factor *= 10;
    }
    return (v * factor).round() / factor;
  }

  /// murmur3 的 32 位收尾混合；乘法拆成 16 位两半，避免 Web 上超出 53 位整数精度。
  static int _hash32(int x) {
    x &= 0xffffffff;
    x ^= x >> 16;
    x = _mul32(x, 0x85ebca6b);
    x ^= x >> 13;
    x = _mul32(x, 0xc2b2ae35);
    x ^= x >> 16;
    return x;
  }

  static int _mul32(int a, int b) {
    final lo = (a & 0xffff) * b;
    final hi = ((a >> 16) & 0xffff) * b & 0xffff;
    return (lo + (hi << 16)) & 0xffffffff;
  }

  /// symbol 的 32 位 FNV-1a 哈希，作为种子；不用 `String.hashCode`，它不保证跨运行稳定。
  static int _fnv1a(String s) {
    var h = 0x811c9dc5;
    for (final unit in s.codeUnits) {
      h ^= unit;
      h = _mul32(h, 0x01000193);
    }
    return h;
  }
}
