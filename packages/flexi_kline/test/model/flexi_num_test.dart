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

void main() {
  const a = 12345.6789;
  const b = 6789.12345;
  final aD = Decimal.parse('12345.6789');
  final bD = Decimal.parse('6789.12345');
  final num1 = FlexiNum.fromNum(a);
  final num2 = FlexiNum.fromNum(b);
  final num1D = FlexiNum.fromDecimal(aD);
  final num2D = FlexiNum.fromDecimal(bD);

  // ---------------------------------------------------------------------------
  // 基础四则运算（同类型）
  // ---------------------------------------------------------------------------
  group('FlexiNum 基础四则运算', () {
    test('num + num 结果与 double 一致', () {
      expect((num1 + num2).toDouble(), closeTo(a + b, 1e-6));
    });

    test('decimal + decimal 结果与 Decimal 一致', () {
      expect((num1D + num2D).toDecimal(), aD + bD);
    });

    test('num - num 结果与 double 一致', () {
      expect((num1 - num2).toDouble(), closeTo(a - b, 1e-6));
    });

    test('decimal - decimal 结果与 Decimal 一致', () {
      expect((num1D - num2D).toDecimal(), aD - bD);
    });

    test('num * num 结果与 double 一致', () {
      expect((num1 * num2).toDouble(), closeTo(a * b, 1e-3));
    });

    test('decimal * decimal 结果与 Decimal 一致', () {
      expect((num1D * num2D).toDecimal(), aD * bD);
    });

    test('num / num 结果与 double 一致', () {
      expect((num1 / num2).toDouble(), closeTo(a / b, 1e-9));
    });

    test('decimal / decimal 结果与 Decimal 一致', () {
      final expected = (aD / bD).toDecimal(
        scaleOnInfinitePrecision: FlexiFormatter.scaleOnInfinitePrecision,
      );
      expect((num1D / num2D).toDecimal(), expected);
    });

    test('% 运算：num % num', () {
      expect(
        (FlexiNum.fromInt(6) % FlexiNum.fromInt(4)).toDouble(),
        closeTo(2.0, 1e-9),
      );
    });

    test('% 运算：decimal % decimal', () {
      final n1 = FlexiNum.fromDecimal(Decimal.fromInt(6));
      final n2 = FlexiNum.fromDecimal(Decimal.fromInt(4));
      expect((n1 % n2).toDecimal(), Decimal.fromInt(2));
    });

    test('remainderNum 结果正确', () {
      expect(FlexiNum.fromNum(7).remainderNum(3).toDouble(), closeTo(1.0, 1e-9));
    });

    test('remainderDecimal 结果正确', () {
      final n = FlexiNum.fromDecimal(Decimal.fromInt(7));
      expect(n.remainderDecimal(Decimal.fromInt(3)).toDecimal(), Decimal.fromInt(1));
    });

    test('isZero：0 为 true，非 0 为 false', () {
      expect(FlexiNum.fromNum(0).isZero, isTrue);
      expect(FlexiNum.fromDecimal(Decimal.zero).isZero, isTrue);
      expect(FlexiNum.fromNum(1).isZero, isFalse);
      expect(FlexiNum.fromDecimal(Decimal.fromInt(1)).isZero, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 跨类型运算（num ↔ decimal）
  // ---------------------------------------------------------------------------
  group('FlexiNum 跨类型运算', () {
    final numVal = FlexiNum.fromNum(10.0);
    final decVal = FlexiNum.fromDecimal(Decimal.fromInt(5));

    test('num + decimal', () {
      expect((numVal + decVal).toDouble(), closeTo(15.0, 1e-9));
    });

    test('decimal + num', () {
      expect((decVal + numVal).toDouble(), closeTo(15.0, 1e-9));
    });

    test('num - decimal', () {
      expect((numVal - decVal).toDouble(), closeTo(5.0, 1e-9));
    });

    test('decimal - num', () {
      expect((decVal - numVal).toDouble(), closeTo(-5.0, 1e-9));
    });

    test('num * decimal', () {
      expect((numVal * decVal).toDouble(), closeTo(50.0, 1e-9));
    });

    test('decimal * num', () {
      expect((decVal * numVal).toDouble(), closeTo(50.0, 1e-9));
    });

    test('num / decimal', () {
      expect((numVal / decVal).toDouble(), closeTo(2.0, 1e-9));
    });

    test('decimal / num', () {
      expect((decVal / numVal).toDouble(), closeTo(0.5, 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // fromAny — 4 种类型 × 2 种计算模式
  // ---------------------------------------------------------------------------
  group('FlexiNum.fromAny', () {
    test('num → fast mode：保持 double', () {
      final n = FlexiNum.fromAny(42.5, ComputeMode.fast);
      expect(n.mode, ComputeMode.fast);
      expect(n.toDouble(), closeTo(42.5, 1e-12));
    });

    test('num → accurate mode：转换为 Decimal', () {
      final n = FlexiNum.fromAny(42, ComputeMode.accurate);
      expect(n.mode, ComputeMode.accurate);
      expect(n.toDecimal(), Decimal.fromInt(42));
    });

    test('Decimal → fast mode：转换为 double', () {
      final n = FlexiNum.fromAny(Decimal.fromInt(100), ComputeMode.fast);
      expect(n.mode, ComputeMode.fast);
      expect(n.toDouble(), 100.0);
    });

    test('Decimal → accurate mode：保持 Decimal', () {
      final n = FlexiNum.fromAny(Decimal.parse('100.123'), ComputeMode.accurate);
      expect(n.mode, ComputeMode.accurate);
      expect(n.toDecimal(), Decimal.parse('100.123'));
    });

    test('String → fast mode：解析为 double', () {
      final n = FlexiNum.fromAny('3.14', ComputeMode.fast);
      expect(n.mode, ComputeMode.fast);
      expect(n.toDouble(), closeTo(3.14, 1e-10));
    });

    test('String → accurate mode：解析为 Decimal', () {
      final n = FlexiNum.fromAny('3.14', ComputeMode.accurate);
      expect(n.mode, ComputeMode.accurate);
      expect(n.toDecimal(), Decimal.parse('3.14'));
    });

    test('BigInt → fast mode：转换为 double', () {
      final n = FlexiNum.fromAny(BigInt.from(999), ComputeMode.fast);
      expect(n.mode, ComputeMode.fast);
      expect(n.toDouble(), 999.0);
    });

    test('BigInt → accurate mode：转换为 Decimal', () {
      final n = FlexiNum.fromAny(BigInt.from(999), ComputeMode.accurate);
      expect(n.mode, ComputeMode.accurate);
      expect(n.toDecimal(), Decimal.fromInt(999));
    });

    test('不支持的类型抛出 FlexiNumException', () {
      expect(
        () => FlexiNum.fromAny(true, ComputeMode.fast),
        throwsA(isA<FlexiNumException>()),
      );
    });

    test('fromAnyOrNull：null 输入返回 null', () {
      expect(FlexiNum.fromAnyOrNull(null, ComputeMode.fast), isNull);
    });

    test('fromAnyOrNull：非 null 正常构造', () {
      expect(FlexiNum.fromAnyOrNull(42, ComputeMode.fast)?.toDouble(), 42.0);
    });
  });

  // ---------------------------------------------------------------------------
  // 比较运算符
  // ---------------------------------------------------------------------------
  group('FlexiNum 比较运算符', () {
    final n1 = FlexiNum.fromNum(1.0);
    final n2 = FlexiNum.fromNum(2.0);
    final n1D = FlexiNum.fromDecimal(Decimal.fromInt(1));
    final n2D = FlexiNum.fromDecimal(Decimal.fromInt(2));

    test('< (num)', () {
      expect(n1 < n2, isTrue);
      expect(n2 < n1, isFalse);
      expect(n1 < n1, isFalse);
    });

    test('<= (num)', () {
      expect(n1 <= n2, isTrue);
      expect(n1 <= n1, isTrue);
      expect(n2 <= n1, isFalse);
    });

    test('> (num)', () {
      expect(n2 > n1, isTrue);
      expect(n1 > n2, isFalse);
    });

    test('>= (num)', () {
      expect(n2 >= n1, isTrue);
      expect(n2 >= n2, isTrue);
      expect(n1 >= n2, isFalse);
    });

    test('< (decimal)', () {
      expect(n1D < n2D, isTrue);
      expect(n2D < n1D, isFalse);
    });

    test('ltNum / gtNum / gteNum / lteNum', () {
      final n = FlexiNum.fromNum(5.0);
      expect(n.ltNum(10), isTrue);
      expect(n.gtNum(3), isTrue);
      expect(n.gteNum(5), isTrue);
      expect(n.lteNum(5), isTrue);
      expect(n.ltNum(5), isFalse);
      expect(n.gtNum(5), isFalse);
    });

    test('ltDecimal / gtDecimal / gteDecimal / lteDecimal (decimal mode)', () {
      final n = FlexiNum.fromDecimal(Decimal.fromInt(5));
      expect(n.ltDecimal(Decimal.fromInt(10)), isTrue);
      expect(n.gtDecimal(Decimal.fromInt(3)), isTrue);
      expect(n.gteDecimal(Decimal.fromInt(5)), isTrue);
      expect(n.lteDecimal(Decimal.fromInt(5)), isTrue);
      expect(n.ltDecimal(Decimal.fromInt(5)), isFalse);
      expect(n.gtDecimal(Decimal.fromInt(5)), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // abs
  // ---------------------------------------------------------------------------
  group('FlexiNum.abs', () {
    test('负 num 取绝对值', () {
      expect(FlexiNum.fromNum(-3.5).abs().toDouble(), closeTo(3.5, 1e-12));
    });

    test('正 num 不变', () {
      expect(FlexiNum.fromNum(3.5).abs().toDouble(), closeTo(3.5, 1e-12));
    });

    test('零 num 保持为零', () {
      expect(FlexiNum.fromNum(0.0).abs().isZero, isTrue);
    });

    test('负 decimal 取绝对值', () {
      final n = FlexiNum.fromDecimal(Decimal.parse('-2.5'));
      expect(n.abs().toDecimal(), Decimal.parse('2.5'));
    });
  });

  // ---------------------------------------------------------------------------
  // divSafe — 除零保护
  // ---------------------------------------------------------------------------
  group('FlexiNum.divSafe', () {
    test('除数不为零：正常计算', () {
      expect(
        FlexiNum.fromNum(10.0).divSafe(FlexiNum.fromNum(2.0)).toDouble(),
        closeTo(5.0, 1e-12),
      );
    });

    test('除数为零：返回默认值 zero', () {
      expect(FlexiNum.fromNum(10.0).divSafe(FlexiNum.zero).isZero, isTrue);
    });

    test('除数为零：返回自定义默认值', () {
      final result = FlexiNum.fromNum(10.0).divSafe(FlexiNum.zero, FlexiNum.fromNum(-1.0));
      expect(result.toDouble(), -1.0);
    });

    test('divSafeNum：除数为 0 返回 zero', () {
      expect(FlexiNum.fromNum(5.0).divSafeNum(0).isZero, isTrue);
    });

    test('divSafeNum：除数非 0 正常计算', () {
      expect(FlexiNum.fromNum(5.0).divSafeNum(2).toDouble(), closeTo(2.5, 1e-12));
    });

    test('divSafeDecimal：除数为 0 返回 zero', () {
      final n = FlexiNum.fromDecimal(Decimal.fromInt(5));
      expect(n.divSafeDecimal(Decimal.zero).isZero, isTrue);
    });

    test('divSafeDecimal：除数非 0 正常计算', () {
      final n = FlexiNum.fromDecimal(Decimal.fromInt(10));
      final result = n.divSafeDecimal(Decimal.fromInt(4));
      expect(result.toDouble(), closeTo(2.5, 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // clamp
  // ---------------------------------------------------------------------------
  group('FlexiNum.clamp', () {
    test('在范围内：值不变', () {
      final n = FlexiNum.fromNum(5.0);
      expect(
        n.clamp(FlexiNum.fromNum(0.0), FlexiNum.fromNum(10.0)).toDouble(),
        closeTo(5.0, 1e-12),
      );
    });

    test('低于下界：clamp 到下界', () {
      final n = FlexiNum.fromNum(-5.0);
      expect(
        n.clamp(FlexiNum.fromNum(0.0), FlexiNum.fromNum(10.0)).toDouble(),
        closeTo(0.0, 1e-12),
      );
    });

    test('高于上界：clamp 到上界', () {
      final n = FlexiNum.fromNum(15.0);
      expect(
        n.clamp(FlexiNum.fromNum(0.0), FlexiNum.fromNum(10.0)).toDouble(),
        closeTo(10.0, 1e-12),
      );
    });

    test('clampNum：低于下界 clamp', () {
      expect(FlexiNum.fromNum(15.0).clampNum(0, 10).toDouble(), closeTo(10.0, 1e-12));
    });

    test('clampDecimal：高于上界 clamp', () {
      final n = FlexiNum.fromDecimal(Decimal.fromInt(15));
      expect(
        n.clampDecimal(Decimal.zero, Decimal.fromInt(10)).toDecimal(),
        Decimal.fromInt(10),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // floor / ceil / round（带 scale 参数）
  // ---------------------------------------------------------------------------
  group('FlexiNum floor / ceil / round', () {
    test('floor scale=0 (num)：向下取整', () {
      expect(FlexiNum.fromNum(3.9).floor().toDouble(), closeTo(3.0, 1e-12));
      expect(FlexiNum.fromNum(-3.1).floor().toDouble(), closeTo(-4.0, 1e-12));
    });

    test('floor scale=2 (num)：保留 2 位小数', () {
      expect(FlexiNum.fromNum(3.456).floor(scale: 2).toDouble(), closeTo(3.45, 1e-9));
    });

    test('floor scale=2 (decimal)', () {
      expect(
        FlexiNum.fromDecimal(Decimal.parse('3.456')).floor(scale: 2).toDecimal(),
        Decimal.parse('3.45'),
      );
    });

    test('ceil scale=0 (num)：向上取整', () {
      expect(FlexiNum.fromNum(3.1).ceil().toDouble(), closeTo(4.0, 1e-12));
      expect(FlexiNum.fromNum(-3.9).ceil().toDouble(), closeTo(-3.0, 1e-12));
    });

    test('ceil scale=2 (decimal)', () {
      expect(
        FlexiNum.fromDecimal(Decimal.parse('3.451')).ceil(scale: 2).toDecimal(),
        Decimal.parse('3.46'),
      );
    });

    test('round scale=0 (num)', () {
      expect(FlexiNum.fromNum(3.5).round().toDouble(), closeTo(4.0, 1e-12));
      expect(FlexiNum.fromNum(3.4).round().toDouble(), closeTo(3.0, 1e-12));
    });

    test('round scale=2 (decimal)', () {
      expect(
        FlexiNum.fromDecimal(Decimal.parse('3.455')).round(scale: 2).toDecimal(),
        Decimal.parse('3.46'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // shift
  // ---------------------------------------------------------------------------
  group('FlexiNum.shift', () {
    test('正整数 shift：乘以 10 的幂 (num)', () {
      expect(FlexiNum.fromNum(1.5).shift(2).toDouble(), closeTo(150.0, 1e-9));
    });

    test('负整数 shift：除以 10 的幂 (num)', () {
      expect(FlexiNum.fromNum(150.0).shift(-2).toDouble(), closeTo(1.5, 1e-9));
    });

    test('shift(0)：值不变', () {
      expect(FlexiNum.fromNum(42.0).shift(0).toDouble(), closeTo(42.0, 1e-12));
    });

    test('decimal mode shift', () {
      expect(
        FlexiNum.fromDecimal(Decimal.parse('1.5')).shift(2).toDecimal(),
        Decimal.fromInt(150),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // calcuMin / calcuMax
  // ---------------------------------------------------------------------------
  group('FlexiNum calcuMin / calcuMax', () {
    final small = FlexiNum.fromNum(3.0);
    final large = FlexiNum.fromNum(7.0);

    test('calcuMin：返回两者中的较小值', () {
      expect(small.calcuMin(large).toDouble(), 3.0);
      expect(large.calcuMin(small).toDouble(), 3.0);
    });

    test('calcuMax：返回两者中的较大值', () {
      expect(small.calcuMax(large).toDouble(), 7.0);
      expect(large.calcuMax(small).toDouble(), 7.0);
    });

    test('相等时返回自身', () {
      final n = FlexiNum.fromNum(5.0);
      expect(n.calcuMin(n).toDouble(), 5.0);
      expect(n.calcuMax(n).toDouble(), 5.0);
    });
  });
}
