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

import 'bag_num.dart';

class MinMax {
  static final MinMax zero = MinMax(max: BagNum.zero, min: BagNum.zero);

  MinMax({required this.max, required this.min});

  factory MinMax.same(BagNum val) => MinMax(max: val, min: val);

  MinMax clone() => MinMax(max: max, min: min);

  BagNum max;
  BagNum min;

  void updateMinMaxBy(BagNum val) {
    if (max < val) max = val;
    if (min > val) min = val;
  }

  void updateMinMaxByNum(num val) {
    if (max.ltNum(val)) max = BagNum.fromNum(val);
    if (min.gtNum(val)) min = BagNum.fromNum(val);
  }

  void updateMinMaxByDecimal(Decimal val) {
    if (max.ltDecimal(val)) max = BagNum.fromDecimal(val);
    if (min.gtDecimal(val)) min = BagNum.fromDecimal(val);
  }

  void updateMinMax(MinMax? minmax) {
    if (minmax == null) return;
    if (max < minmax.max) max = minmax.max;
    if (min > minmax.min) min = minmax.min;
  }

  void minToZero() {
    min = min > BagNum.zero ? BagNum.zero : min;
  }

  BagNum get middle => size / BagNum.two;

  BagNum get size => max - min;

  BagNum get divisor => max == min ? BagNum.one : max - min;

  bool get isZero => max == BagNum.zero && min == BagNum.zero;

  @override
  String toString() {
    return 'MinMax(max:${max.toString()}, min:${min.toString()})';
  }
}
