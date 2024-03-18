import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:kline/kline.dart';

final Random _random = Random();

int get randomCount => _random.nextInt(5);
double get deltaPrice =>
    (1.0 *
        pow(_random.nextDouble(), _random.nextInt(10) + 3) *
        (_random.nextBool() ? 1 : -1)) *
    10;

Future<List<CandleModel>> genCandleModelList({
  int count = 500,
}) async {
  double open = 50000;
  double close = open + deltaPrice;
  double high = max(open, close) + deltaPrice.abs();
  double low = min(open, close) - deltaPrice.abs();
  DateTime date = DateTime(2017, 9, 1, 0);
  final List<CandleModel> r = <CandleModel>[];
  for (int i = 0; i < count; i++) {
    final item = CandleModel(
      open: open.d,
      close: close.d,
      low: low.d,
      high: high.d,
      vol: (10000000 * _random.nextDouble()).d,
      timestamp: date.millisecondsSinceEpoch,
    );
    r.add(item);
    open = close;
    close = open + deltaPrice;
    high = max(open, close) + deltaPrice.abs() * 0.2;
    low = min(open, close) - deltaPrice.abs() * 0.3;
    date = date.add(const Duration(days: 1));
  }
  return r;
}
