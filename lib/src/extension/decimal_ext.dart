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

extension StringExt on String {
  Decimal? get decimal => Decimal.tryParse(this);
  Decimal get d => Decimal.tryParse(this) ?? Decimal.zero;
}

extension DoubleExt on double {
  Decimal get decimal => d;
  Decimal get d => Decimal.tryParse(toString())!;
}

extension IntExt on int {
  Decimal get decimal => d;
  Decimal get d => Decimal.fromInt(this);
}

final Decimal two = Decimal.fromInt(2);
final Decimal three = Decimal.fromInt(3);
final Decimal twentieth = (Decimal.one / Decimal.fromInt(20)).toDecimal();
final Decimal fifty = Decimal.fromInt(50);
final Decimal hundred = Decimal.fromInt(100);

extension DecimalExt on Decimal {
  // String get toCompactBigNumber => compactBigNumber(this);

  Decimal get half => (this / two).toDecimal(
        scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
      );

  String get str => toStringAsFixed(2);

  Decimal divInt(int num) {
    assert(num != 0, 'divisor cannot be zero');
    return div(Decimal.fromInt(num));
  }

  Decimal divDouble(double num) {
    assert(num != 0, 'divisor cannot be zero');
    return div(num.d);
  }

  Decimal div(Decimal other) {
    assert(other != Decimal.zero, 'divisor cannot be zero');
    return (this / other).toDecimal(
      scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
    );
  }
}
