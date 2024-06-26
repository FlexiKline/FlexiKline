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

import 'package:decimal/decimal.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/data/export.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const tipsConfig = TipsConfig();
const candleReq = CandleReq(instId: 'BTC-USDT');

/// RSI相对强弱指数：股票、公式、计算和策略
/// https://bigquant.com/wiki/doc/rsi-eUeAulPIqH
void main() {
  final stopwatch = Stopwatch();
  late KlineData klineData;
  late List<RsiParam> rsiParams;

  setUpAll(() {
    List<String> closeList = [
      '283.46',
      '280.69',
      '285.48',
      '294.08',
      '293.90',
      '299.92',
      '301.15',
      '284.45',
      '294.09',
      '302.77',
      '301.97',
      '306.85',
      '305.02',
      '301.06',
      '291.97',
      '284.18',
      '286.48',
      '284.54',
      '276.82',
      '284.49',
      '275.01',
      '279.07',
      '277.85',
      '278.85',
      '283.76',
      '291.72',
      '284.73',
      '291.82',
      '296.74',
      '291.13'
    ];
    List<CandleModel> list = [];
    for (int i = closeList.length - 1; i >= 0; i--) {
      String close = closeList[i];
      Decimal val = close.d;
      list.add(CandleModel(ts: i, o: val, h: val, l: val, c: val, v: val));
    }

    klineData = KlineData(candleReq, list: list);
    rsiParams = [const RsiParam(count: 14, tips: tipsConfig)];
  });

  setUp(() {
    stopwatch.reset();
    stopwatch.start();
  });
  tearDown(() {
    stopwatch.stop();
    debugPrint('tearDown spent:${stopwatch.elapsedMicroseconds}');
  });

  test('rsi', () {
    // klineData.calcuAndCacheRsi(rsiParams, start: 0, end: klineData.length);
    klineData.calcuAndCacheRsi(rsiParams);

    for (int i = 0; i < klineData.length; i++) {
      debugPrint('rsi $i => ${klineData.list[i].rsiList}');
    }
  });
}
