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

import '../model/export.dart';
import 'base_data.dart';
import 'common.dart';

mixin CandleData on BaseData {
  @override
  void initData() {
    super.initData();
    logd('init CANDLE');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose CANDLE');
  }

  MinMax? minmax;
  MinMax? minmaxVol;
  // CandleModel? startModel;
  // CandleModel? endModel;

  @override
  void resetCalcuResult() {
    super.resetCalcuResult();
    minmax = null;
    minmaxVol = null;
  }

  /// 根据[start, end]下标计算最大最小值
  MinMax? calculateMaxmin() {
    if (list.isEmpty || start < 0 || end > list.length) return null;
    CandleModel m = list[start];
    Decimal maxHigh = m.high;
    Decimal minLow = m.low;
    Decimal maxVol = m.vol;
    Decimal minVol = m.vol;
    for (var i = start + 1; i < end; i++) {
      m = list[i];

      // if (i == 0) startModel = m;
      // if (i == end - 1) endModel = m;

      maxHigh = m.high > maxHigh ? m.high : maxHigh;
      minLow = m.low < minLow ? m.low : minLow;

      maxVol = m.vol > maxVol ? m.vol : maxVol;
      minVol = m.vol < minVol ? m.vol : minVol;
    }

    minmax = MinMax(max: maxHigh, min: minLow);
    minmaxVol = MinMax(max: maxVol, min: minVol);
    return MinMax(max: maxHigh, min: minLow);
  }
}
