import 'package:flexi_kline_demo/src/data/data_sources/mock/mock_price_series.dart';
import 'package:flutter_test/flutter_test.dart';

const _btc = MockSymbolProfile(basePrice: 80000);
const _minute = 60 * 1000;
const _hour = 60 * _minute;
const _day = 24 * _hour;

/// 2026-01-01 00:00:00 UTC。
const _t0 = 1767225600000;

void main() {
  group('MockPriceSeries', () {
    test('同一 symbol 的两个实例在同一时刻给出同一价格', () {
      final a = MockPriceSeries('BTCUSDT', _btc);
      final b = MockPriceSeries('BTCUSDT', _btc);
      for (var i = 0; i < 200; i++) {
        final ms = _t0 + i * 7919 * 1000;
        expect(a.priceAt(ms), b.priceAt(ms));
      }
    });

    test('固定时间戳的价格不变：算法或平台差异改动了结果时这里会失败', () {
      final s = MockPriceSeries('BTCUSDT', _btc);
      expect([s.priceAt(_t0), s.priceAt(_t0 + _hour), s.priceAt(_t0 + _day), s.priceAt(_t0 - 365 * _day)], _golden);
    });

    test('不同 symbol 的走势不同', () {
      final btc = MockPriceSeries('BTCUSDT', _btc);
      final other = MockPriceSeries('BTCUSD', _btc);
      final same = [for (var i = 0; i < 50; i++) btc.priceAt(_t0 + i * _hour) == other.priceAt(_t0 + i * _hour)];
      expect(same.where((e) => e).length, lessThan(5));
    });

    test('价格围绕 basePrice，偏离不超过 swing；ETH 一档 2500 同理', () {
      for (final (symbol, profile) in [('BTCUSDT', _btc), ('ETHUSDT', const MockSymbolProfile(basePrice: 2500))]) {
        final s = MockPriceSeries(symbol, profile);
        final limit = profile.basePrice * profile.swing;
        for (var i = 0; i < 3000; i++) {
          final p = s.priceAt(_t0 - i * 6 * _hour);
          expect((p - profile.basePrice).abs(), lessThanOrEqualTo(limit + 0.01), reason: '$symbol @ $i');
        }
      }
    });

    test('已收盘蜡烛：开盘接上一根收盘，高低包住开收，已确认', () {
      final s = MockPriceSeries('BTCUSDT', _btc);
      final candles = [for (var i = 0; i < 100; i++) s.candle(_t0 + i * 15 * _minute, 15 * _minute)];
      for (var i = 0; i < candles.length; i++) {
        final c = candles[i];
        expect(c.confirmed, isTrue);
        expect(c.high, greaterThanOrEqualTo(c.open > c.close ? c.open : c.close));
        expect(c.low, lessThanOrEqualTo(c.open < c.close ? c.open : c.close));
        expect(c.volume, greaterThan(0));
        if (i > 0) expect(c.open, candles[i - 1].close);
      }
    });

    test('跨周期一致：1 小时蜡烛的开收等于其中首末两根 15 分钟蜡烛的开收', () {
      final s = MockPriceSeries('BTCUSDT', _btc);
      final hour = s.candle(_t0, _hour);
      final quarters = [for (var i = 0; i < 4; i++) s.candle(_t0 + i * 15 * _minute, 15 * _minute)];
      expect(hour.open, quarters.first.open);
      expect(hour.close, quarters.last.close);
    });

    test('进行中的蜡烛：收盘取 until 时刻价格，未确认，成交量随时间增长', () {
      final s = MockPriceSeries('BTCUSDT', _btc);
      final early = s.candle(_t0, _hour, until: _t0 + 10 * _minute);
      final late = s.candle(_t0, _hour, until: _t0 + 40 * _minute);
      expect(early.confirmed, isFalse);
      expect(early.close, s.priceAt(_t0 + 10 * _minute));
      expect(early.open, late.open);
      expect(late.volume, greaterThan(early.volume));
    });
  });
}

/// 由当前实现算出后写死；数值变了说明同一时间戳不再得到同一价格。
const _golden = <double>[75797.07, 75584.36, 76487.29, 83207.19];
