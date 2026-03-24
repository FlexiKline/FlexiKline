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

// ignore_for_file: prefer_final_locals

/// ### IEEE 754 双精度浮点数标准 — 精度探索演示
///
/// 这些测试用于演示 double 与 Decimal 在精度上的行为差异，属于探索性用例。
/// 不对外暴露业务逻辑问题，CI 可视情况跳过此目录。
library;

import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/flexi_formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_utils.dart';

void main() {
  test('0.1 + 0.2 精度差异', () {
    double number = 0.1 + 0.2;
    logMsg(number); // 0.30000000000000004

    Decimal decimal = Decimal.parse('0.1') + Decimal.parse('0.2');
    logMsg(decimal); // 0.3

    // double 与 Decimal.toDouble() 在此处不相等
    expect(number, isNot(equals(decimal.toDouble())));
  });

  /// 注意：此用例说明某些情况下 double 加法与 Decimal 加法的 toDouble() 结果一致，
  /// 即 IEEE 754 精度丢失并不总能体现在 double 比较层面。
  test('123456789.123456789 + 0.000000001 精度一致性', () {
    double a = 123456789.123456789;
    double b = 0.000000001;
    double number = a + b;
    Decimal decimal = Decimal.parse('123456789.123456789') + Decimal.parse('0.000000001');

    logMsg('Double : $number');   // 123456789.12345679
    logMsg('Decimal: $decimal');  // 123456789.123456790

    // 在当前 Dart/decimal 版本下两者 toDouble() 相等（精度丢失在同一位）
    expect(number, equals(decimal.toDouble()));
  });

  test('1e16 + 1.0 溢出精度', () {
    double number = 1e16 + 1.0;
    logMsg(number); // 10000000000000000.0

    Decimal decimal = Decimal.parse('10000000000000001');
    logMsg(decimal);

    // double 无法表示 1e16 + 1，两者 toDouble() 相等（精度截断到同位）
    expect(number, equals(decimal.toDouble()));
  });

  test('1e-17 + 1e-18 极小数精度', () {
    double number = 1e-17 + 1e-18;
    logMsg(number); // 1.1e-17

    Decimal decimal = Decimal.parse('1e-17') + Decimal.parse('1e-18');
    logMsg(decimal);

    expect(number, equals(decimal.toDouble()));
  });

  /// 注意：`1.0000000000000001` 在 double 中 IS 1.0（精度不足），
  /// 但减去 `b ≈ 1.1e-16` 后得到 `0.9999999999999999`，与 Decimal 的 1.0 **不等**。
  /// 这里展示的是"double 精度不足但仍产生差异"的微妙场景。
  test('减法精度演示', () {
    double a = 1.0000000000000001;
    double b = 0.0000000000000001;
    double number = a - b;
    Decimal decimal = Decimal.parse('1.0000000000000001') - Decimal.parse('0.0000000000000001');

    logMsg('Double: $number');    // 0.9999999999999999
    logMsg('Decimal: $decimal');  // 1.0000000000000000

    // a - b 在 double 层面产生了细微差异，与 Decimal 结果不同
    expect(number, isNot(equals(decimal.toDouble())));
  });

  test('乘法精度差异', () {
    double a = 1.234567890123456789;
    double b = 2.123;
    double resultDouble = a * b;
    Decimal resultDecimal = Decimal.parse('1.234567890123456789') * Decimal.parse('2.123');

    logMsg('Double: $resultDouble');    // 1.5241578753238822
    logMsg('Decimal: $resultDecimal');  // 更高精度

    // 乘法结果不相等
    expect(resultDouble, isNot(equals(resultDecimal.toDouble())));
  });

  test('有效数字范围 15~17 位演示', () {
    double a = 1.234567890123456;  // 16位
    logMsg(a);
    double b = 1.2345678901234567; // 17位
    logMsg(b);
    double c = 1.23456789012345678; // 18位，最后一位不准确
    logMsg(c);

    // b 与 c 在 double 层面相同（超出精度范围）
    expect(b, equals(c));
  });

  test('有效位数 17 位 - 大数', () {
    double num = double.parse('123456789012345678901234567890');
    Decimal decimal = Decimal.parse('123456789012345670000000000000');

    logMsg(num == decimal.toDouble()); // true
    logMsg(num);
    logMsg(decimal.precision);
    logMsg(decimal);

    expect(num, equals(decimal.toDouble()));
  });

  test('有效位数 17 位 - 小数', () {
    double num = double.parse('0.123456789012345678901234567890');
    Decimal decimal = Decimal.parse('0.123456789012345670000000000000');

    logMsg(num == decimal.toDouble()); // true
    logMsg(num);
    logMsg(decimal);

    expect(num, equals(decimal.toDouble()));
  });

  test('double toStringAsPrecision 演示', () {
    logMsg(1.toStringAsPrecision(2));
    logMsg(1e15.toStringAsPrecision(3));
    logMsg(1234567.toStringAsPrecision(3));
    logMsg(1234567.toStringAsPrecision(9));
    logMsg(double.parse('12345678901234567890').toStringAsPrecision(20));
    logMsg(double.parse('12345678901234567890').toStringAsPrecision(14));
    logMsg(0.00000012345.toStringAsPrecision(15));
    logMsg(0.0000012345.toStringAsPrecision(15));
    logMsg(double.parse('0.12345678901234567890').toStringAsPrecision(20));
    logMsg(double.parse('0.12345678901234567890').toStringAsPrecision(14));
  });

  test('Decimal toStringAsPrecision 演示', () {
    logMsg(1.d.toStringAsPrecision(2));
    logMsg(1e15.d.toStringAsPrecision(3));
    logMsg(1234567.d.toStringAsPrecision(3));
    logMsg(1234567.d.toStringAsPrecision(9));
    logMsg(Decimal.parse('12345678901234567890').toStringAsPrecision(20));
    logMsg(Decimal.parse('12345678901234567890').toStringAsPrecision(14));
    logMsg(Decimal.parse('0.00000012345').toStringAsPrecision(15));
    logMsg(Decimal.parse('0.0000012345').toStringAsPrecision(15));
    logMsg(Decimal.parse('0.12345678901234567890').toStringAsPrecision(20));
    logMsg(Decimal.parse('0.12345678901234567890').toStringAsPrecision(14));
  });

  // ---------------------------------------------------------------------------
  // 从 dart_async_test.dart 迁入：RSI 精度与对数函数演示
  // ---------------------------------------------------------------------------
  test('RSI Decimal 精度演示', () {
    Decimal hundred = Decimal.fromInt(100);
    Decimal sumUp = Decimal.fromJson('14.9');
    Decimal sumDown = Decimal.fromJson('15.4');
    Decimal ret = sumUp.div(sumUp + sumDown) * hundred;
    debugPrint(ret.toString());

    Decimal ret2 = sumUp.divNum(9).div(sumUp.divNum(9) + sumDown.divNum(9)) * hundred;
    debugPrint(ret2.toString());
  });

  test('math.log 各值演示', () {
    debugPrint('math.log(0) ${math.log(0)}');
    debugPrint('math.log(0.1) ${math.log(0.1)}');
    debugPrint('math.log(0.9) ${math.log(0.9)}');
    debugPrint('math.log(1) ${math.log(1)}');
    debugPrint('math.log(1.1) ${math.log(1.1)}');
    debugPrint('math.log(2) ${math.log(2)}');
    debugPrint('math.log(2000) ${math.log(2000)}');
    debugPrint('math.log(-1) ${math.log(-1)}');
  });

  test('math.log 自然对数缩放演示', () {
    for (double i = 0.1; i < 2.5; i += 0.2) {
      final x = double.parse(i.toStringAsFixed(2));
      final scaleFactor = math.log(x);
      debugPrint('math.log(${i.toStringAsFixed(2)}) \t $scaleFactor');
    }
  });
}
