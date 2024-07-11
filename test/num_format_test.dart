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
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/extension/num_ext.dart';
import 'package:flexi_kline/src/utils/num_format_util.dart';
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

  test('double show', () {
    double a = 0.123456789012345678901234567890;
    print(a.toString());
    print(a.toStringAsFixed(16));
    double b = 100000000000000000001.0;
    print(b.formatAsString(3));
    print(b.toStringAsFixed(3));
  });

  test('test double show max', () {
    print(double.maxFinite.toString());
    String maxStr =
        '100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.0';
    double max = double.parse(maxStr);
    print(max.toString());
    print(max > double.maxFinite);

    final dMax = Decimal.parse(double.maxFinite.toString());
    print(Decimal.parse(maxStr) * Decimal.ten > dMax);
    print(dMax.toString());
    print(dMax.toStringAsExponential(10));
    print(double.maxFinite.toString());
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

  test('formatNumber', () {
    print('------a');
    double a = 0.00000000001;
    print(a.toString());
    print(a.toStringAsExponential(15));
    // print(formatNum(a, precision: 15, isClean: true));

    print('------b');
    double b = 12345678901234567890123.0;
    print(b.toString());
    print(b.toStringAsExponential(20));
    // print(formatNum(b, precision: 22, isClean: true));

    print('------c');
    double c = 100000000000000000.0;
    print(c.toString());
    print(c.toStringAsExponential(20));
    // print(formatNum(c, mode: RoundMode.truncate, precision: 22, isClean: true));
  });

  test('test thousands', () {
    double number1 = 1234567890;
    double number2 = 1000;
    double number3 = 123456.789;
    double number4 = 9876543210.12345;
    double number5 = 9876543210.1;

    print(number1.thousands(0)); // 输出: 1,234,567,890
    print(number2.thousands(0)); // 输出: 1,000
    print(number3.thousands(0)); // 输出: 123,456.789
    print(number4.thousands(3)); // 输出: 9,876,543,210.12345
    print(number5.thousands(3)); // 输出: 9,876,543,210.12345

    print(number1.tenThousands(0));
    print(number2.tenThousands(0));
    print(number3.tenThousands(0));
    print(number4.tenThousands(4));
    print(number5.tenThousands(4));
  });

  test('test formatDecimal', () {
    List<(String, int)> decimals = [
      // 0.12345678901234567899
      ('0.123456789012345678998765421', 20),
      // 9.8765432109876543210987654321e+28
      ('98765432109876543210987654321', 30),
      // 9.8765e-16
      ('0.000000000000000987654321', 20),
    ];

    for ((String, int) item in decimals) {
      print('${item.$1}\t => \t ${formatNumber(
        item.$1.d,
        precision: item.$2,
        mode: RoundMode.floor,
      )}');
    }
  });

  test('test formatNum', () {
    List<(String, int)> decimals = [
      // 0.12345678901234566349
      ('0.123456789012345678998765421', 20),
      // 1.81671721133551034022
      ('98765432109876543210987654321', 30),
      // 9.87602863144107682e-16
      ('0.000000000000000987654321', 20),
    ];

    for ((String, int) item in decimals) {
      print('${item.$1}\t => \t ${formatNum(
        double.parse(item.$1),
        precision: item.$2,
        mode: RoundMode.floor,
      )}');
    }
  });
}
