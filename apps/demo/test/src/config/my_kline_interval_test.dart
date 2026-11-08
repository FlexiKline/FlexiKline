import 'package:flexi_kline_demo/src/config/my_kline_interval.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyKlineInterval.parse', () {
    test('按枚举名解析每一档周期', () {
      for (final interval in MyKlineInterval.values) {
        expect(MyKlineInterval.parse(interval.name), interval);
      }
    });

    test('忽略大小写与首尾空白', () {
      expect(MyKlineInterval.parse(' hour1 '), MyKlineInterval.hour1);
      expect(MyKlineInterval.parse('HOUR1'), MyKlineInterval.hour1);
      expect(MyKlineInterval.parse('Minute15'), MyKlineInterval.minute15);
    });

    test('为空或未命中时回退到默认值', () {
      expect(MyKlineInterval.parse(null), MyKlineInterval.initial);
      expect(MyKlineInterval.parse('unknown'), MyKlineInterval.initial);
      expect(MyKlineInterval.parse('unknown', MyKlineInterval.day1), MyKlineInterval.day1);
    });
  });
}
