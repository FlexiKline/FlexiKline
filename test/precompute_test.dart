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
import 'package:flexi_kline/src/data/export.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base/compute.dart' as dio;
import 'base/random_candle_list.dart';
import 'base/test_flexi_kline_configuration.dart';

void main() {
  final stopwatch = Stopwatch();

  KlineData data = KlineData(
    CandleReq(instId: 'BTC-USDT', bar: TimeBar.D1.bar),
  );

  final configuration = TestFlexiKlineConfiguration().getFlexiKlineConfig();

  final calcParams = configuration.indicators.getIndicatorCalcParams();

  List<CandleModel> newList = [];

  setUp(() async {
    stopwatch.reset();
    stopwatch.start();
    debugPrint(
      'genRandomCandleList start spent:${stopwatch.elapsedMilliseconds}',
    );
    newList = await genRandomCandleList(
      count: 50000,
      bar: data.timeBar!,
    );
    debugPrint(
      'genRandomCandleList end spent:${stopwatch.elapsedMilliseconds}',
    );
    stopwatch.reset();
    stopwatch.start();
  });

  tearDown(() {
    stopwatch.stop();
    debugPrint('total spent:${stopwatch.elapsedMilliseconds}');
  });

  test('flutter compute1', () async {
    /// 使用compute方式运行
    Future<KlineData> precomputeKlineData(PrecomputeData data) async {
      debugPrint('zp:::>>> precomputeKlineData before > ${DateTime.now()}');
      debugPrint('zp:::>>> precomputeKlineData before > $data');
      final klinedata = await KlineData.precomputeKlineData(
        data.data,
        newList: data.newList,
        computeMode: data.computeMode,
        calcParams: data.calcParams,
        reset: data.reset,
      );

      debugPrint('zp:::>>> precomputeKlineData after > ${klinedata.length}');
      debugPrint('zp:::>>> precomputeKlineData after > ${DateTime.now()}');
      return klinedata;
    }

    final precomputeData = PrecomputeData(
      data: data,
      newList: newList,
      computeMode: ComputeMode.fast,
      calcParams: calcParams,
      reset: true,
    );
    debugPrint('zp:::>>> compute before >>> $precomputeData');
    debugPrint('zp:::>>> compute before >>> ${DateTime.now()}');
    data = await compute(
      precomputeKlineData,
      precomputeData,
      debugLabel: 'ZP:::Compute',
    );
    debugPrint('zp:::>>> compute after >>> ${data.length}');
    debugPrint('zp:::>>> compute after >>> ${DateTime.now()}');
  });
}
