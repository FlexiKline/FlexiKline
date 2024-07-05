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

import 'dart:math' as math;
import 'package:decimal/decimal.dart';
import 'package:flexi_kline/src/model/export.dart';
import 'package:flutter_test/flutter_test.dart';

Decimal genMinusculeDecimal(double val, int exponent) {
  // 将 val 转换为 Decimal
  Decimal decimalVal = Decimal.parse(val.toString());

  // 计算 10 的 exponent 次方
  Decimal multiplier = Decimal.fromInt(10).pow(exponent).toDecimal();

  // 将 decimalVal 乘以 10 的 exponent 次方
  Decimal result = (decimalVal / multiplier).toDecimal();

  return result;
}

void main() {
  test('Minuscule precision data generate!', () {
    final decimal = genMinusculeDecimal(1.234, 22);
    print(decimal.toString());
    print(decimal.toStringAsExponential());
    print(decimal.toStringAsExponential(3));
    print(decimal.toStringAsPrecision(3));
  });

  test('BagNum test', () {
    final a = BagNum.fromDecimal(Decimal.parse('0.1233'));

    print(a > BagNum.zero);
  });

  test('test double show max', () {
    print(double.maxFinite);
    double max =
        100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.0;
    print(max.toString());
    print(max > double.maxFinite);
  });

  test('test double show min', () {
    print(double.minPositive);
    double min =
        0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000123;
    print(min.toString());
    print(min.toStringAsExponential());
    print((math.sqrt(min)).toStringAsExponential());
    print(min < double.minPositive);
  });
}
