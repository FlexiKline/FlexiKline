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
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

/// ### IEEE 754 双精度浮点数标准
/// `double` 类型在 Dart 中遵循 IEEE 754 双精度浮点数标准。这种表示方法有以下几点需要注意：
///
/// 1. **有效数字**：`double` 类型通常可以精确表示 15-17 位十进制数字。
/// 2. **指数范围**：指数部分可以在 `-308` 到 `308` 之间。
/// 3. **精度限制**：由于浮点数的表示方式，超出这个精度范围的数字会丢失精度，即使在有效范围内。
void main() {
  test('test 0.1+0.2', () {
    double number = 0.1 + 0.2;
    print(number);

    Decimal decimal = Decimal.parse('0.1') + Decimal.parse('0.2');
    print(decimal);

    print(number.d == decimal); // false
    print(number == decimal.toDouble()); // false

    assert(number != decimal.toDouble());
  });

  test('test 123456789.123456789 + 0.000000001', () {
    double a = 123456789.123456789;
    double b = 0.000000001;
    double number = a + b;
    Decimal decimal =
        Decimal.parse('123456789.123456789') + Decimal.parse('0.000000001');

    print('Double : $number'); // 输出  : 123456789.12345679
    print('Decimal: $decimal'); // 输出 : 123456789.123456790

    assert(number.d == decimal); // 断言通过，因为值不相等
    assert(number != decimal.toDouble()); // 断言通过，因为值不相等
  });

  test('test 1e16 + 1.0', () {
    double number = 1e16 + 1.0; // 1 followed by 16 zeros, plus 1
    print(number); // 输出: 10000000000000000.0

    Decimal decimal = Decimal.parse('10000000000000001');
    print(decimal);

    print(number.d == decimal); // true
    print(number == decimal.toDouble()); // true
  });

  test('test 1e-17 + 1e-18', () {
    double number = 1e-17 + 1e-18; // Very small numbers
    print(number); // 输出: 1.1e-16

    Decimal decimal = Decimal.parse('1e-17') + Decimal.parse('1e-18');
    print(decimal);

    print(number.d == decimal); // true
    print(number == decimal.toDouble()); //true
  });

  test('test sub', () {
    double a = 1.0000000000000001;
    double b = 0.0000000000000001;
    double number = a - b;
    Decimal decimal = Decimal.parse('1.0000000000000001') -
        Decimal.parse('0.0000000000000001');

    print('Double: $number'); // 输出: 1.0
    print('Decimal: $decimal'); // 输出: 1.0000000000000000

    assert(number != decimal.toDouble()); // 断言通过，因为值不相等
  });

  test('test mutliply', () {
    double a = 1.234567890123456789;
    double b = 2.123;
    double resultDouble = a * b;
    Decimal resultDecimal =
        Decimal.parse('1.234567890123456789') * Decimal.parse('2.123');

    print('Double: $resultDouble'); // 输出: 1.5241578753238822
    print('Decimal: $resultDecimal'); // 输出: 1.524157875323882095352391557056

    assert(resultDouble != resultDecimal.toDouble()); // 断言通过，因为值不相等
  });

  /// 1. **有效位数**：指的是一个浮点数可以精确表示的数字位数总和。这包括整数部分和小数部分。
  /// 2. **15到17位的范围**：精确表示的位数在15到17之间，这个范围是由于浮点数表示法的二进制特性和数字的分布特性决定的。
  test('test 15~17', () {
    double a = 1.234567890123456; // 16位有效数字
    print(a); // 输出: 1.234567890123456
    double b = 1.2345678901234567; // 17位有效数字
    print(b); // 输出: 1.2345678901234567
    double c = 1.23456789012345678; // 18位有效数字
    print(c); // 输出: 1.2345678901234567 (最后一位不准确)

    print('-----');

    double A = 1234567890123456; // 16位有效数字.
    print(A); // 输出: 123456789012345.0
    double B = 1234567890123456.8; // 17位有效数字.
    print(B); // 输出: 1234567890123456.8
    double C = 12345678901234567.8; // 18位有效数字.
    print(C); // 输出: 12345678901234568.0 (最后一位不准确)
  });

  /// 有效位数17位
  test('test lost precision max', () {
    double num = double.parse('123456789012345678901234567890');
    Decimal decimal = Decimal.parse('123456789012345670000000000000');

    print(num == decimal.toDouble()); // true
    print(num); // 1.2345678901234568e+29
    print(decimal.precision); //30
    print(decimal.scale); //0
    print(decimal); // 123456789012345670000000000000
    print(decimal.toStringAsExponential(30)); // 1.23456789012345670e+29
  });

  /// 有效位数17位
  test('test lost precision min', () {
    double num = double.parse('0.123456789012345678901234567890');
    Decimal decimal = Decimal.parse('0.123456789012345670000000000000');

    print(num == decimal.toDouble()); // true
    print(num); // 0.12345678901234568
    print(decimal.precision); //18
    print(decimal.scale); //17
    print(decimal); // 0.12345678901234567
  });

  /// 有效位数16位
  test('test lost precision minimum', () {
    double num = double.parse('0.000000000000000009876543210123456789');
    Decimal decimal = Decimal.parse('0.000000000000000009876543210123456001');

    print(num == decimal.toDouble()); // true
    print(num); // 9.876543210123456e-18
    print(num.toStringAsPrecision(20)); // 9.8765432101234562766e-18
    print(decimal.precision); //37
    print(decimal.scale); //36
    print(decimal); // 0.000000000000000009876543210123456001
    print(decimal
        .toStringAsExponential(30)); // 9.876543210123456001000000000000e-18
  });

  /// 有效位数16位
  test('test lost precision ', () {
    double num = double.parse('9999988888.987654321097654321');
    Decimal decimal = Decimal.parse('9999988888.987654000097654321');

    print(num == decimal.toDouble()); // true
    print(num); // 9999988888.987654
    print(decimal.precision); //28
    print(decimal.scale); // 18
    print(decimal); // 9999988888.987654000097654321
    print(decimal
        .toStringAsExponential(30)); // 9.999988888987654000097654321000e+9
  });

  /// 有效位数15位
  test('test lost precision 2 ', () {
    double num = double.parse('987654321012344.98765431');
    Decimal decimal = Decimal.parse('987654321012345.000000009');

    print(num == decimal.toDouble()); // true
    print(num); // 987654321012345.0
    print(decimal.precision); //24
    print(decimal.scale); //9
    print(decimal); // 987654321012345.000000009
    print(decimal
        .toStringAsExponential(30)); // 9.876543210123450000000090000000e+14
  });

  test('test double toStringAsPrecision', () {
    print(1.toStringAsPrecision(2)); // 1.0
    print(1e15.toStringAsPrecision(3)); // 1.00e+15
    print(1234567.toStringAsPrecision(3)); // 1.23e+6
    print(1234567.toStringAsPrecision(9)); // 1234567.00
    print(double.parse('12345678901234567890')
        .toStringAsPrecision(20)); // 12345678901234567168
    print(double.parse('12345678901234567890')
        .toStringAsPrecision(14)); // 1.2345678901235e+19
    print(0.00000012345.toStringAsPrecision(15)); // 1.23450000000000e-7
    print(0.0000012345.toStringAsPrecision(15)); // 0.00000123450000000000

    print(double.parse('0.12345678901234567890')
        .toStringAsPrecision(20)); // 0.12345678901234567737
    print(double.parse('0.12345678901234567890')
        .toStringAsPrecision(14)); // 0.12345678901235
  });

  test('test decimal toString', () {
    print(1.d.toStringAsPrecision(2)); // 1.0
    print(1e15.d.toStringAsPrecision(3)); // 1000000000000000
    print(1234567.d.toStringAsPrecision(3)); // 1230000
    print(1234567.d.toStringAsPrecision(9)); // 1234567.00
    print(Decimal.parse('12345678901234567890')
        .toStringAsPrecision(20)); // 12345678901234567890
    print(Decimal.parse('12345678901234567890')
        .toStringAsPrecision(14)); // 12345678901235000000
    print(Decimal.parse('0.00000012345')
        .toStringAsPrecision(15)); // 0.000000123450000000000
    print(Decimal.parse('0.0000012345')
        .toStringAsPrecision(15)); // 0.00000123450000000000

    print(Decimal.parse('0.12345678901234567890')
        .toStringAsPrecision(20)); // 0.12345678901234567890
    print(Decimal.parse('0.12345678901234567890')
        .toStringAsPrecision(14)); // 0.12345678901235
  });
}
