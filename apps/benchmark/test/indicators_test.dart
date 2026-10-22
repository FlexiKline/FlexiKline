// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_benchmark/src/constants.dart';
import 'package:flexi_kline_benchmark/src/data/candles.dart';
import 'package:flexi_kline_benchmark/src/indicators/ma.dart';
import 'package:flexi_kline_benchmark/src/indicators/macd.dart';
import 'package:flexi_kline_benchmark/src/indicators/vol_ma.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

/// 指标计算的正确性: 基准负载要有真实的计算结果, 不只是「跑过了」。
void main() {
  KlineData load() => KlineData(benchSpec)..replace(benchCandles(count: 300), slotCount: 1);

  double mean(KlineData data, int from, int count, double Function(FlexiCandleModel m) of) {
    var sum = 0.0;
    for (var i = from; i < from + count; i++) {
      sum += of(data[i]);
    }
    return sum / count;
  }

  test('MA and VOLMA equal the window mean of close / volume', () {
    final data = load();
    BenchMaIndicator().createCalculator(0).compute(data, data.computableRange, reset: true);
    for (final (j, param) in BenchMaIndicator().calcParam.indexed) {
      final count = param.count;
      final ma = data[3].getList<FlexiNum>(0)![j]!.toDouble();
      expect(ma, closeTo(mean(data, 3, count, (m) => m.close.toDouble()), 1e-6), reason: 'MA$count');
    }

    final volData = load();
    BenchVolMaIndicator().createCalculator(0).compute(volData, volData.computableRange, reset: true);
    final ma5 = volData[0].getList<FlexiNum>(0)![0]!.toDouble();
    expect(ma5, closeTo(mean(volData, 0, 5, (m) => m.vol.toDouble()), 1e-6));
  });

  test('non-positive MA / VOLMA periods are skipped instead of dividing by zero', () {
    const black = Color(0xFF000000);
    final ma = load();
    BenchMaIndicator(
      calcParam: const [(count: 0, color: black), (count: 5, color: black)],
    ).createCalculator(0).compute(ma, ma.computableRange, reset: true);
    expect(ma[3].getList<FlexiNum>(0)![0], isNull);
    expect(ma[3].getList<FlexiNum>(0)![1], isNotNull);

    final vol = load();
    BenchVolMaIndicator(
      calcParam: const [(count: 0, color: black), (count: 5, color: black)],
    ).createCalculator(0).compute(vol, vol.computableRange, reset: true);
    expect(vol[3].getList<FlexiNum>(0)![0], isNull);
    expect(vol[3].getList<FlexiNum>(0)![1], isNotNull);
  });

  test('MACD matches an independent EMA(12, 26, 9) reference', () {
    final data = load();
    BenchMacdIndicator().createCalculator(0).compute(data, data.computableRange, reset: true);
    // 独立参考: 从最旧一根起顺序递推, 以首根 close 为种子。
    double ema(double prev, double v, int n) => prev + (v - prev) * 2 / (n + 1);
    var short = 0.0, long = 0.0, dea = 0.0, dif = 0.0;
    for (var i = data.length - 1; i >= 0; i--) {
      final close = data[i].close.toDouble();
      if (i == data.length - 1) {
        short = long = close;
        dea = 0;
      } else {
        short = ema(short, close, 12);
        long = ema(long, close, 26);
        dea = ema(dea, short - long, 9);
      }
      dif = short - long;
    }
    final newest = data[0].get<BenchMacdResult>(0)!;
    expect(newest.dif.toDouble(), closeTo(dif, 1e-6), reason: 'DIF');
    expect(newest.dea.toDouble(), closeTo(dea, 1e-6), reason: 'DEA');
    expect(newest.macd.toDouble(), closeTo(2 * (dif - dea), 1e-6), reason: 'MACD bar');
    expect(data[data.length - 1].get<BenchMacdResult>(0)!.macd.toDouble(), 0, reason: '首值种子: DIF = DEA = 0');
  });

  test('MACD compute is a full recompute: the range argument is ignored', () {
    final data = load();
    final calculator = BenchMacdIndicator().createCalculator(0);
    calculator.compute(data, data.computableRange, reset: true);
    final before = data[5].get<BenchMacdResult>(0)!.dea.toDouble();
    calculator.compute(data, const Range(0, 1));
    expect(data[5].get<BenchMacdResult>(0)!.dea.toDouble(), before);
  });
}
