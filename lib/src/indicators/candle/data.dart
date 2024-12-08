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

part of 'candle.dart';

mixin CandleDataMixin<T extends CandleIndicator> on SinglePaintObjectBox<T> {
  @override
  void precompute(Range range, {bool reset = false}) {}

  /// 根据[start, end]下标计算最大最小值
  MinMax? calculateMinmax({
    int? start,
    int? end,
  }) {
    start ??= klineData.start;
    end ??= klineData.end;
    if (!klineData.checkStartAndEnd(start, end)) return null;

    CandleModel m = klineData.list[end - 1];
    BagNum maxHigh = m.high;
    BagNum minLow = m.low;
    for (int i = end - 2; i >= start; i--) {
      m = klineData.list[i];
      maxHigh = m.high > maxHigh ? m.high : maxHigh;
      minLow = m.low < minLow ? m.low : minLow;
    }
    return MinMax(max: maxHigh, min: minLow);
  }
}
