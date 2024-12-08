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

part of 'volume.dart';

mixin VolumeDataMixin<T extends VolumeIndicator> on SinglePaintObjectBox<T> {
  @override
  void precompute(Range range, {bool reset = false}) {}

  MinMax? calculateVolMinmax({
    int? start,
    int? end,
  }) {
    start ??= klineData.start;
    end ??= klineData.end;
    if (!klineData.checkStartAndEnd(start, end)) return null;

    CandleModel m = klineData.list[end - 1];
    BagNum minVol = m.vol;
    BagNum maxVol = m.vol;
    for (int i = end - 2; i >= start; i--) {
      m = klineData.list[i];
      maxVol = m.vol > maxVol ? m.vol : maxVol;
      minVol = m.vol < minVol ? m.vol : minVol;
    }
    return MinMax(max: maxVol, min: minVol);
  }
}
