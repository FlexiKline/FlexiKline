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

import '../constant.dart';
import '../extension/export.dart';

/// Base数据
abstract class BaseResult {
  final int ts;
  final bool dirty;

  BaseResult({required this.ts, required this.dirty});
}

/// MA, WMA, EMA计算结果
class CalcuData {
  final int count;
  final int ts;
  final Decimal val;
  final bool dirty;

  CalcuData({
    required this.count,
    required this.ts,
    required this.val,
    this.dirty = false,
  });
}

/// MACD 计算结果
class MacdResult extends BaseResult {
  final Decimal emaShort;
  final Decimal emaLong;
  final Decimal dif;
  final Decimal dea;
  final Decimal macd;

  MacdResult({
    required super.ts,
    super.dirty = true,
    required this.dif,
    required this.dea,
    required this.macd,
    required this.emaShort,
    required this.emaLong,
  });

  MinMax get minmax {
    Decimal max = dif.compareTo(dea) > 0 ? dif : dea;
    max = max.compareTo(macd) > 0 ? max : macd;
    Decimal min = dif.compareTo(dea) < 0 ? dif : dea;
    min = min.compareTo(macd) < 0 ? min : macd;
    return MinMax(max: max, min: min);
  }

  @override
  String toString() {
    return 'MacdResult(ts:$ts, dif:${dif.str}, dea:${dea.str}, macd:${macd.str})';
  }
}

class MinMax {
  MinMax({required this.max, required this.min});
  Decimal max;
  Decimal min;

  static final MinMax zero = MinMax(max: Decimal.zero, min: Decimal.zero);

  MinMax clone() => MinMax(max: max, min: min);

  void updateMinMaxByVal(Decimal val) {
    max = val > max ? val : max;
    min = val < min ? val : min;
  }

  void updateMinMax(MinMax? newVal) {
    if (newVal == null) return;
    max = newVal.max > max ? newVal.max : max;
    min = newVal.min < min ? newVal.min : min;
  }

  void minToZero() {
    min = min > Decimal.zero ? Decimal.zero : min;
  }

  Decimal get middle => (size / two).toDecimal(
        scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
      );

  Decimal get size => max - min;

  bool get isZero => max == Decimal.zero && min == Decimal.zero;

  @override
  String toString() {
    return 'MinMax(max:${max.toStringAsFixed(4)}, min:${min.toStringAsFixed(4)})';
  }
}
