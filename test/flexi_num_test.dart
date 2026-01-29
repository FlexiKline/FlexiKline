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

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/flexi_formatter.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

void main() {
  final stopwatch = Stopwatch();
  setUp(() {
    stopwatch.reset();
    stopwatch.start();
  });
  tearDown(() {
    stopwatch.stop();
    logMsg('tearDown spent:${stopwatch.elapsedMicroseconds}');
  });

  const loop = 100;

  const a = 12345.6789;
  const b = 6789.12345;
  final aD = Decimal.parse('12345.6789');
  final bD = Decimal.parse('6789.12345');
  final num1 = FlexiNum.fromNum(a);
  final num2 = FlexiNum.fromNum(b);
  final num1D = FlexiNum.fromDecimal(aD);
  final num2D = FlexiNum.fromDecimal(bD);

  group('FlexiNum +', () {
    test('FlexiNum preheat', () {
      // late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num1 + num2;
        num1 + num2D;
        num1D + num2;
        num1D + num2D;
      }
      logMsg('FlexiNum preheat =>');
    });

    test('FlexiNum double + Decimal', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 + num2D;
      }
      logMsg('FlexiNum double + Decimal =>$num3');
    });

    test('FlexiNum Decimal + double', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D + num2;
      }
      logMsg('FlexiNum Decimal + double =>$num3');
    });

    test('double operator +', () {
      late double num3;
      for (int i = 0; i < loop; i++) {
        num3 = a + b;
      }
      logMsg('double operator + =>$num3');
    });

    test('FlexiNum double + double', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 + num2;
      }

      logMsg('FlexiNum double + double =>$num3');
    });

    test('Decimal operator +', () {
      late Decimal num3;
      for (int i = 0; i < loop; i++) {
        num3 = aD + bD;
      }
      logMsg('Decimal operator + =>$num3');
    });

    test('FlexiNum Decimal + Decimal', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D + num2D;
      }
      logMsg('FlexiNum Decimal + Decimal =>$num3');
    });
  });

  group('FlexiNum -', () {
    test('FlexiNum preheat', () {
      // late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num1 - num2;
        num1 - num2D;
        num1D - num2;
        num1D - num2D;
      }
      logMsg('FlexiNum preheat =>');
    });

    test('FlexiNum double - Decimal', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 - num2D;
      }
      logMsg('FlexiNum double - Decimal =>$num3');
    });

    test('FlexiNum Decimal - double', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D - num2;
      }
      logMsg('FlexiNum Decimal - double =>$num3');
    });

    test('double operator -', () {
      late double num3;
      for (int i = 0; i < loop; i++) {
        num3 = a - b;
      }
      logMsg('double operator - =>$num3');
    });

    test('FlexiNum double - double', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 - num2;
      }

      logMsg('FlexiNum double - double =>$num3');
    });

    test('Decimal operator -', () {
      late Decimal num3;
      for (int i = 0; i < loop; i++) {
        num3 = aD - bD;
      }
      logMsg('Decimal operator - =>$num3');
    });

    test('FlexiNum Decimal - Decimal', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D - num2D;
      }
      logMsg('FlexiNum Decimal - Decimal =>$num3');
    });
  });

  group('FlexiNum *', () {
    test('FlexiNum preheat', () {
      // late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num1 * num2;
        num1 * num2D;
        num1D * num2;
        num1D * num2D;
      }
      logMsg('FlexiNum preheat =>');
    });

    test('FlexiNum double * Decimal', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 * num2D;
      }
      logMsg('FlexiNum double * Decimal =>$num3');
    });

    test('FlexiNum Decimal * double', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D * num2;
      }
      logMsg('FlexiNum Decimal * double =>$num3');
    });

    test('double operator *', () {
      late double num3;
      for (int i = 0; i < loop; i++) {
        num3 = a * b;
      }
      logMsg('double operator * =>$num3');
    });

    test('FlexiNum double * double', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 * num2;
      }

      logMsg('FlexiNum double * double =>$num3');
    });

    test('Decimal operator *', () {
      late Decimal num3;
      for (int i = 0; i < loop; i++) {
        num3 = aD * bD;
      }
      logMsg('Decimal operator * =>$num3');
    });

    test('FlexiNum Decimal * Decimal', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D * num2D;
      }
      logMsg('FlexiNum Decimal * Decimal =>$num3');
    });
  });

  group('FlexiNum /', () {
    test('FlexiNum preheat', () {
      // late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num1 / num2;
        num1 / num2D;
        num1D / num2;
        num1D / num2D;
      }
      logMsg('FlexiNum preheat =>');
    });

    test('FlexiNum double / Decimal', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 / num2D;
      }
      logMsg('FlexiNum double / Decimal =>$num3');
    });

    test('FlexiNum Decimal / double', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D / num2;
      }
      logMsg('FlexiNum Decimal / double =>${num3.valueString()}');
    });

    test('double operator /', () {
      late double num3;
      for (int i = 0; i < loop; i++) {
        num3 = a / b;
      }

      logMsg('double operator / =>$num3');
    });

    test('FlexiNum double / double', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 / num2;
      }

      logMsg('FlexiNum double / double =>$num3');
    });

    test('Decimal operator /', () {
      late Decimal num3;
      for (int i = 0; i < loop; i++) {
        num3 = (aD / bD).toDecimal(
          scaleOnInfinitePrecision: FlexiFormatter.scaleOnInfinitePrecision,
        );
      }

      logMsg('Decimal operator / =>${num3.toStringAsFixed(
        FlexiFormatter.scaleOnInfinitePrecision,
      )}');
    });

    test('FlexiNum Decimal / Decimal', () {
      late FlexiNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D / num2D;
      }
      logMsg('FlexiNum Decimal / Decimal =>${num3.valueString()}');
    });
  });

  group('FlexiNum %', () {
    test('FlexiNum num % num', () {
      logMsg('1 % 5 =>${1 % 5}');
      FlexiNum num1 = FlexiNum.fromInt(1);
      FlexiNum num2 = FlexiNum.fromInt(5);
      logMsg('num1 % num2 =>${num1 % num2}');
    });

    test('FlexiNum decimal % decimal', () {
      logMsg('1.d % 5.d =>${1.d % 5.d}');
      FlexiNum num1 = FlexiNum.fromDecimal(1.d);
      FlexiNum num2 = FlexiNum.fromDecimal(5.d);
      logMsg('num1 % num2 =>${num1 % num2}');
    });

    test('FlexiNum num % decimal', () {
      logMsg('1.d % 5.d =>${1.d % 5.d}');
      FlexiNum num1 = FlexiNum.fromNum(1);
      FlexiNum num2 = FlexiNum.fromDecimal(5.d);
      logMsg('num1 % num2 =>${num1 % num2}');
    });

    test('FlexiNum decimal % num', () {
      logMsg('1.d % 5.d =>${1.d % 5.d}');
      FlexiNum num1 = FlexiNum.fromDecimal(1.d);
      FlexiNum num2 = FlexiNum.fromInt(5);
      logMsg('num1 % num2 =>${num1 % num2}');
    });

    test('FlexiNum remainderNum', () {
      FlexiNum num1 = FlexiNum.fromNum(1);
      num num2 = 5;
      logMsg('num1.remainderNum(num2) =>${num1.remainderNum(num2)}');
      num1 = FlexiNum.fromDecimal(1.d);
      logMsg('num1.remainderNum(num2) =>${num1.remainderNum(num2)}');
    });

    test('FlexiNum remainderDecimal', () {
      FlexiNum num1 = FlexiNum.fromNum(1);
      Decimal num2 = 5.d;
      logMsg('num1.remainderDecimal(num2) =>${num1.remainderDecimal(num2)}');
      num1 = FlexiNum.fromDecimal(1.d);
      logMsg('num1.remainderDecimal(num2) =>${num1.remainderDecimal(num2)}');
    });
  });
}
