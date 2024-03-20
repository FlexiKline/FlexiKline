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

Future<List<CandleModel>> genRandomCandleList({int count = 500}) async {
  double open = 50000;
  double close = open + deltaPrice;
  double high = max(open, close) + deltaPrice.abs();
  double low = min(open, close) - deltaPrice.abs();
  DateTime date = DateTime.now();
  final List<CandleModel> r = <CandleModel>[];
  for (int i = 0; i < count; i++) {
    r.add(CandleModel(
      close: Decimal.parse(close.toString()),
      high: Decimal.parse(high.toString()),
      low: Decimal.parse(low.toString()),
      open: Decimal.parse(open.toString()),
      vol: Decimal.parse((10000000 * _random.nextDouble()).toString()),
      timestamp: date.millisecondsSinceEpoch,
    ));
    open = close;
    close = open + deltaPrice;
    high = max(open, close) + deltaPrice.abs() * 0.2;
    low = min(open, close) - deltaPrice.abs() * 0.3;
    date = date.add(const Duration(days: -1));
  }
  return r;
}

Future<List<CandleModel>> genCustomCandleList({
  int count = 500,
}) async {
  DateTime dateTime = DateTime.now();
  return <CandleModel>[
    CandleModel.fromJson({
      "timestamp": dateTime.add(Duration(days: 0)).millisecondsSinceEpoch,
      "high": 120,
      "open": 100,
      "close": 60,
      "low": 20,
      "vol": 800,
    }),
    CandleModel.fromJson({
      "timestamp": dateTime.add(Duration(days: -1)).millisecondsSinceEpoch,
      "high": 220,
      "open": 60,
      "close": 200,
      "low": 50,
      "vol": 900,
    }),
    CandleModel.fromJson({
      "timestamp": dateTime.add(Duration(days: -1)).millisecondsSinceEpoch,
      "high": 320,
      "open": 200,
      "close": 100,
      "low": 50,
      "vol": 900,
    }),
    CandleModel.fromJson({
      "timestamp": dateTime.add(Duration(days: -1)).millisecondsSinceEpoch,
      "high": 140,
      "open": 90,
      "close": 120,
      "low": 80,
      "vol": 900,
    }),
    CandleModel.fromJson({
      "timestamp": dateTime.add(Duration(days: -1)).millisecondsSinceEpoch,
      "high": 200,
      "open": 120,
      "close": 10,
      "low": 0,
      "vol": 900,
    }),
    CandleModel.fromJson({
      "timestamp": dateTime.add(Duration(days: -1)).millisecondsSinceEpoch,
      "high": 130,
      "open": 20,
      "close": 110,
      "low": -20,
      "vol": 900,
    }),
  ];
}
