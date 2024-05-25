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

import '../model/export.dart';
import 'base_data.dart';

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

  /// 根据[start, end]下标计算最大最小值
  MinMax? calculateMinmax({
    int? start,
    int? end,
  }) {
    start ??= this.start;
    end ??= this.end;
    if (!checkStartAndEnd(start, end)) return null;

    CandleModel m = list[end - 1];
    BagNum maxHigh = m.high;
    BagNum minLow = m.low;
    for (int i = end - 2; i >= start; i--) {
      m = list[i];
      maxHigh = m.high > maxHigh ? m.high : maxHigh;
      minLow = m.low < minLow ? m.low : minLow;
    }
    return MinMax(max: maxHigh, min: minLow);
  }

  MinMax? calculateVolMinmax({
    int? start,
    int? end,
  }) {
    start ??= this.start;
    end ??= this.end;
    if (!checkStartAndEnd(start, end)) return null;

    CandleModel m = list[end - 1];
    BagNum minVol = m.vol;
    BagNum maxVol = m.vol;
    for (int i = end - 2; i >= start; i--) {
      m = list[i];
      maxVol = m.vol > maxVol ? m.vol : maxVol;
      minVol = m.vol < minVol ? m.vol : minVol;
    }
    return MinMax(max: maxVol, min: minVol);
  }
}
