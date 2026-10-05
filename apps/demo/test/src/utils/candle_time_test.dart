import 'package:flexi_kline_demo/src/utils/candle_time.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
