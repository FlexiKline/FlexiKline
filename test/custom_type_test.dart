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
  final num1 = BagNum.fromNum(a);
  final num2 = BagNum.fromNum(b);
  final num1D = BagNum.fromDecimal(aD);
  final num2D = BagNum.fromDecimal(bD);

  group('BagNum +', () {
    test('BagNum preheat', () {
      // late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num1 + num2;
        num1 + num2D;
        num1D + num2;
        num1D + num2D;
      }
      logMsg('BagNum preheat =>');
    });

    test('BagNum double + Decimal', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 + num2D;
      }
      logMsg('BagNum double + Decimal =>$num3');
    });

    test('BagNum Decimal + double', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D + num2;
      }
      logMsg('BagNum Decimal + double =>$num3');
    });

    test('double operator +', () {
      late double num3;
      for (int i = 0; i < loop; i++) {
        num3 = a + b;
      }
      logMsg('double operator + =>$num3');
    });

    test('BagNum double + double', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 + num2;
      }

      logMsg('BagNum double + double =>$num3');
    });

    test('Decimal operator +', () {
      late Decimal num3;
      for (int i = 0; i < loop; i++) {
        num3 = aD + bD;
      }
      logMsg('Decimal operator + =>$num3');
    });

    test('BagNum Decimal + Decimal', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D + num2D;
      }
      logMsg('BagNum Decimal + Decimal =>$num3');
    });
  });

  group('BagNum -', () {
    test('BagNum preheat', () {
      // late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num1 - num2;
        num1 - num2D;
        num1D - num2;
        num1D - num2D;
      }
      logMsg('BagNum preheat =>');
    });

    test('BagNum double - Decimal', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 - num2D;
      }
      logMsg('BagNum double - Decimal =>$num3');
    });

    test('BagNum Decimal - double', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D - num2;
      }
      logMsg('BagNum Decimal - double =>$num3');
    });

    test('double operator -', () {
      late double num3;
      for (int i = 0; i < loop; i++) {
        num3 = a - b;
      }
      logMsg('double operator - =>$num3');
    });

    test('BagNum double - double', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 - num2;
      }

      logMsg('BagNum double - double =>$num3');
    });

    test('Decimal operator -', () {
      late Decimal num3;
      for (int i = 0; i < loop; i++) {
        num3 = aD - bD;
      }
      logMsg('Decimal operator - =>$num3');
    });

    test('BagNum Decimal - Decimal', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D - num2D;
      }
      logMsg('BagNum Decimal - Decimal =>$num3');
    });
  });

  group('BagNum *', () {
    test('BagNum preheat', () {
      // late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num1 * num2;
        num1 * num2D;
        num1D * num2;
        num1D * num2D;
      }
      logMsg('BagNum preheat =>');
    });

    test('BagNum double * Decimal', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 * num2D;
      }
      logMsg('BagNum double * Decimal =>$num3');
    });

    test('BagNum Decimal * double', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D * num2;
      }
      logMsg('BagNum Decimal * double =>$num3');
    });

    test('double operator *', () {
      late double num3;
      for (int i = 0; i < loop; i++) {
        num3 = a * b;
      }
      logMsg('double operator * =>$num3');
    });

    test('BagNum double * double', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 * num2;
      }

      logMsg('BagNum double * double =>$num3');
    });

    test('Decimal operator *', () {
      late Decimal num3;
      for (int i = 0; i < loop; i++) {
        num3 = aD * bD;
      }
      logMsg('Decimal operator * =>$num3');
    });

    test('BagNum Decimal * Decimal', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D * num2D;
      }
      logMsg('BagNum Decimal * Decimal =>$num3');
    });
  });

  group('BagNum /', () {
    test('BagNum preheat', () {
      // late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num1 / num2;
        num1 / num2D;
        num1D / num2;
        num1D / num2D;
      }
      logMsg('BagNum preheat =>');
    });

    test('BagNum double / Decimal', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 / num2D;
      }
      logMsg('BagNum double / Decimal =>$num3');
    });

    test('BagNum Decimal / double', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D / num2;
      }
      logMsg('BagNum Decimal / double =>${num3.doubleString()}');
    });

    test('double operator /', () {
      late double num3;
      for (int i = 0; i < loop; i++) {
        num3 = a / b;
      }

      logMsg('double operator / =>$num3');
    });

    test('BagNum double / double', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1 / num2;
      }

      logMsg('BagNum double / double =>$num3');
    });

    test('Decimal operator /', () {
      late Decimal num3;
      for (int i = 0; i < loop; i++) {
        num3 = (aD / bD).toDecimal(
          scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
        );
      }

      logMsg('Decimal operator / =>${num3.toStringAsFixed(
        defaultScaleOnInfinitePrecision,
      )}');
    });

    test('BagNum Decimal / Decimal', () {
      late BagNum num3;
      for (int i = 0; i < loop; i++) {
        num3 = num1D / num2D;
      }
      logMsg('BagNum Decimal / Decimal =>${num3.doubleString()}');
    });
  });
}
