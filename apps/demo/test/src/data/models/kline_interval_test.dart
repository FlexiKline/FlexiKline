import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/data/models/kline_interval.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KlineInterval.parse', () {
    test('按枚举名解析每一档周期', () {
      for (final interval in KlineInterval.values) {
        expect(KlineInterval.parse(interval.name), interval);
      }
    });

    test('忽略大小写与首尾空白', () {
      expect(KlineInterval.parse(' hour1 '), KlineInterval.hour1);
      expect(KlineInterval.parse('HOUR1'), KlineInterval.hour1);
      expect(KlineInterval.parse('Minute15'), KlineInterval.minute15);
    });

    test('为空或未命中时回退到默认值', () {
      expect(KlineInterval.parse(null), KlineInterval.initial);
      expect(KlineInterval.parse('unknown'), KlineInterval.initial);
      expect(KlineInterval.parse('unknown', KlineInterval.day1), KlineInterval.day1);
    });
  });

  group('KlineInterval', () {
    test('定义五档周期，默认 15 分钟', () {
      expect(KlineInterval.values, hasLength(5));
      expect(KlineInterval.initial, KlineInterval.minute15);
    });

    test('每根蜡烛时间跨度（毫秒）', () {
      expect(KlineInterval.line.milliseconds, 60 * 1000);
      expect(KlineInterval.minute15.milliseconds, 15 * 60 * 1000);
      expect(KlineInterval.hour1.milliseconds, 60 * 60 * 1000);
      expect(KlineInterval.day1.milliseconds, 24 * 60 * 60 * 1000);
      expect(KlineInterval.week1.milliseconds, 7 * 24 * 60 * 60 * 1000);
    });
  });
}
