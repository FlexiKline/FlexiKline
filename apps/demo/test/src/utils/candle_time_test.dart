import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/config/my_kline_interval.dart';
import 'package:flexi_kline_demo/src/utils/candle_time.dart';
import 'package:flutter_test/flutter_test.dart';

/// 周期与时间对齐: 周期跨度、标签与蜡烛时间戳的边界对齐。
void main() {
  group('alignToInterval', () {
    test('对齐到周期边界（向下取整）', () {
      const intervalMs = 15 * 60 * 1000;
      expect(alignToInterval(0, intervalMs), 0);
      expect(alignToInterval(intervalMs - 1, intervalMs), 0);
      expect(alignToInterval(intervalMs, intervalMs), intervalMs);
      expect(alignToInterval(intervalMs + 1, intervalMs), intervalMs);
      expect(alignToInterval(2 * intervalMs, intervalMs), 2 * intervalMs);
    });
  });

  group('MyKlineInterval', () {
    test('定义五档周期，默认 15 分钟', () {
      expect(MyKlineInterval.values, hasLength(5));
      expect(MyKlineInterval.initial, MyKlineInterval.minute15);
    });

    test('周期切换栏展示标签', () {
      expect(MyKlineInterval.line.label, '分时');
      expect(MyKlineInterval.minute15.label, '15分');
      expect(MyKlineInterval.hour1.label, '1时');
      expect(MyKlineInterval.day1.label, '1天');
      expect(MyKlineInterval.week1.label, '1周');
    });

    test('每根蜡烛时间跨度（毫秒）', () {
      expect(MyKlineInterval.line.milliseconds, 60 * 1000);
      expect(MyKlineInterval.minute15.milliseconds, 15 * 60 * 1000);
      expect(MyKlineInterval.hour1.milliseconds, 60 * 60 * 1000);
      expect(MyKlineInterval.day1.milliseconds, 24 * 60 * 60 * 1000);
      expect(MyKlineInterval.week1.milliseconds, 7 * 24 * 60 * 60 * 1000);
    });
  });
}
