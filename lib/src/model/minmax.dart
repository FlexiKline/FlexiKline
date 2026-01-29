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

import 'flexi_num.dart';
import '../extension/collections_ext.dart';

class MinMax {
  static final MinMax zero = MinMax(max: FlexiNum.zero, min: FlexiNum.zero);

  MinMax({required this.max, required this.min});

  factory MinMax.same(FlexiNum val) => MinMax(max: val, min: val);

  factory MinMax.from(FlexiNum a, FlexiNum b) {
    if (a < b) (a, b) = (b, a);
    return MinMax(max: a, min: b);
  }

  MinMax clone() => MinMax(max: max, min: min);

  FlexiNum max;
  FlexiNum min;

  void updateMinMaxBy(FlexiNum val) {
    if (max < val) max = val;
    if (min > val) min = val;
  }

  void updateMinMaxByNum(num val) {
    if (max.ltNum(val)) max = FlexiNum.fromNum(val);
    if (min.gtNum(val)) min = FlexiNum.fromNum(val);
  }

  void updateMinMaxByDecimal(Decimal val) {
    if (max.ltDecimal(val)) max = FlexiNum.fromDecimal(val);
    if (min.gtDecimal(val)) min = FlexiNum.fromDecimal(val);
  }

  void updateMinMax(MinMax? minmax) {
    if (minmax == null) return;
    if (max < minmax.max) max = minmax.max;
    if (min > minmax.min) min = minmax.min;
  }

  void expand(num margin) {
    if (margin > 0) {
      max = max.addNum(margin);
      min = min.subNum(margin);
    }
  }

  void expandByRatios(List<double> ratios) {
    if (ratios.isEmpty) return;
    final maxRatio = ratios.firstOrNull;
    final minRatio = ratios.secondOrNull;
    if (maxRatio != null && maxRatio > 0) {
      max = max.mulNum(1 + maxRatio);
    }
    if (minRatio != null && minRatio > 0) {
      min = min.mulNum(1 - minRatio);
    }
  }

  void minToZero() {
    min = min > FlexiNum.zero ? FlexiNum.zero : min;
  }

  FlexiNum get middle => size / FlexiNum.two;

  FlexiNum get size => max - min;

  /// 最大最小值做为除数
  FlexiNum get diffDivisor => max == min ? FlexiNum.one : max - min;

  bool get isZero => max == FlexiNum.zero && min == FlexiNum.zero;

  bool get isSame => max == min;

  /// 计算给定集合[list]中的所有[FlexiNum]的最大最小值
  static MinMax? getMinMaxByList(List<FlexiNum?>? list) {
    if (list == null || list.isEmpty) return null;
    MinMax? minmax;
    for (final val in list) {
      if (val != null) {
        minmax ??= MinMax.same(val);
        minmax.updateMinMaxBy(val);
      }
    }
    return minmax;
  }

  @override
  String toString() {
    return 'MinMax(max:${max.toString()}, min:${min.toString()})';
  }
}
