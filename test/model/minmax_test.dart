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

MinMax _mm(num max, num min) => MinMax(
      max: FlexiNum.fromNum(max),
      min: FlexiNum.fromNum(min),
    );

FlexiNum _fn(num v) => FlexiNum.fromNum(v);

void main() {
  // ---------------------------------------------------------------------------
  // 构造 / 工厂
  // ---------------------------------------------------------------------------
  group('MinMax 构造 / 工厂', () {
    test('基本构造：max/min 正确赋值', () {
      final mm = _mm(100, 20);
      expect(mm.max.toDouble(), 100.0);
      expect(mm.min.toDouble(), 20.0);
    });

    test('MinMax.same：max == min', () {
      final mm = MinMax.same(_fn(50));
      expect(mm.max.toDouble(), 50.0);
      expect(mm.min.toDouble(), 50.0);
    });

    test('MinMax.from：自动排序，大值为 max', () {
      final mm1 = MinMax.from(_fn(30), _fn(80));
      expect(mm1.max.toDouble(), 80.0);
      expect(mm1.min.toDouble(), 30.0);

      final mm2 = MinMax.from(_fn(80), _fn(30));
      expect(mm2.max.toDouble(), 80.0);
      expect(mm2.min.toDouble(), 30.0);
    });

    test('MinMax.zero：max 和 min 均为 0', () {
      expect(MinMax.zero.max.toDouble(), 0.0);
      expect(MinMax.zero.min.toDouble(), 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // clone
  // ---------------------------------------------------------------------------
  group('MinMax.clone', () {
    test('clone 返回独立副本，修改不影响原对象', () {
      final mm = _mm(100, 20);
      final c = mm.clone();
      c.max = _fn(999);
      expect(mm.max.toDouble(), 100.0);
      expect(c.max.toDouble(), 999.0);
    });

    test('clone 值与原对象相等', () {
      final mm = _mm(100, 20);
      final c = mm.clone();
      expect(c.max.toDouble(), mm.max.toDouble());
      expect(c.min.toDouble(), mm.min.toDouble());
    });
  });

  // ---------------------------------------------------------------------------
  // getters
  // ---------------------------------------------------------------------------
  group('MinMax getters', () {
    test('size = max - min', () {
      expect(_mm(100, 30).size.toDouble(), 70.0);
      expect(_mm(50, 50).size.toDouble(), 0.0);
    });

    test('middle = (max - min) / 2', () {
      expect(_mm(100, 20).middle.toDouble(), 40.0);
      expect(_mm(10, 0).middle.toDouble(), 5.0);
    });

    test('diffDivisor：max != min 时返回 size，相等时返回 1', () {
      expect(_mm(100, 20).diffDivisor.toDouble(), 80.0);
      expect(_mm(50, 50).diffDivisor.toDouble(), 1.0);
    });

    test('isZero：max 和 min 均为 0 时为 true', () {
      expect(_mm(0, 0).isZero, isTrue);
      expect(_mm(0, -1).isZero, isFalse);
      expect(_mm(1, 0).isZero, isFalse);
    });

    test('isSame：max == min 时为 true', () {
      expect(_mm(50, 50).isSame, isTrue);
      expect(_mm(50, 49).isSame, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // updateMinMaxBy / updateMinMaxByNum / updateMinMaxByDecimal
  // ---------------------------------------------------------------------------
  group('MinMax.updateMinMaxBy*', () {
    test('updateMinMaxBy：新值超出范围时更新', () {
      final mm = _mm(100, 20);
      mm.updateMinMaxBy(_fn(150));
      expect(mm.max.toDouble(), 150.0);
      mm.updateMinMaxBy(_fn(10));
      expect(mm.min.toDouble(), 10.0);
    });

    test('updateMinMaxBy：新值在范围内时不更新', () {
      final mm = _mm(100, 20);
      mm.updateMinMaxBy(_fn(50));
      expect(mm.max.toDouble(), 100.0);
      expect(mm.min.toDouble(), 20.0);
    });

    test('updateMinMaxByNum：行为与 updateMinMaxBy 一致', () {
      final mm = _mm(100, 20);
      mm.updateMinMaxByNum(200);
      expect(mm.max.toDouble(), 200.0);
      mm.updateMinMaxByNum(5);
      expect(mm.min.toDouble(), 5.0);
      mm.updateMinMaxByNum(50); // 范围内，不更新
      expect(mm.max.toDouble(), 200.0);
      expect(mm.min.toDouble(), 5.0);
    });

    test('updateMinMaxByDecimal：行为与 updateMinMaxBy 一致', () {
      final mm = _mm(100, 20);
      mm.updateMinMaxByDecimal(Decimal.parse('120.5'));
      expect(mm.max.toDouble(), closeTo(120.5, 1e-9));
      mm.updateMinMaxByDecimal(Decimal.parse('10.25'));
      expect(mm.min.toDouble(), closeTo(10.25, 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // updateMinMax
  // ---------------------------------------------------------------------------
  group('MinMax.updateMinMax', () {
    test('null 参数：不更新', () {
      final mm = _mm(100, 20);
      mm.updateMinMax(null);
      expect(mm.max.toDouble(), 100.0);
      expect(mm.min.toDouble(), 20.0);
    });

    test('传入更大范围时扩展', () {
      final mm = _mm(100, 20);
      mm.updateMinMax(_mm(200, 5));
      expect(mm.max.toDouble(), 200.0);
      expect(mm.min.toDouble(), 5.0);
    });

    test('传入更小范围时不缩小', () {
      final mm = _mm(100, 20);
      mm.updateMinMax(_mm(80, 30));
      expect(mm.max.toDouble(), 100.0);
      expect(mm.min.toDouble(), 20.0);
    });
  });

  // ---------------------------------------------------------------------------
  // expand
  // ---------------------------------------------------------------------------
  group('MinMax.expand', () {
    test('正 margin：max 增大，min 减小', () {
      final mm = _mm(100, 20);
      mm.expand(10);
      expect(mm.max.toDouble(), 110.0);
      expect(mm.min.toDouble(), 10.0);
    });

    test('margin = 0：不改变', () {
      final mm = _mm(100, 20);
      mm.expand(0);
      expect(mm.max.toDouble(), 100.0);
      expect(mm.min.toDouble(), 20.0);
    });

    test('负 margin：不改变（条件 margin > 0）', () {
      final mm = _mm(100, 20);
      mm.expand(-5);
      expect(mm.max.toDouble(), 100.0);
      expect(mm.min.toDouble(), 20.0);
    });
  });

  // ---------------------------------------------------------------------------
  // expandByRatios
  // ---------------------------------------------------------------------------
  group('MinMax.expandByRatios', () {
    test('空列表：不改变', () {
      final mm = _mm(100, 20);
      mm.expandByRatios([]);
      expect(mm.max.toDouble(), 100.0);
      expect(mm.min.toDouble(), 20.0);
    });

    test('一个 ratio（仅 maxRatio）', () {
      final mm = _mm(100, 20);
      mm.expandByRatios([0.1]); // max * 1.1 = 110；minRatio 缺省
      expect(mm.max.toDouble(), closeTo(110.0, 1e-9));
      expect(mm.min.toDouble(), 20.0); // 不变
    });

    test('两个 ratio（maxRatio + minRatio）', () {
      final mm = _mm(100, 20);
      mm.expandByRatios([0.1, 0.2]); // max*1.1=110, min*0.8=16
      expect(mm.max.toDouble(), closeTo(110.0, 1e-9));
      expect(mm.min.toDouble(), closeTo(16.0, 1e-9));
    });

    test('ratio = 0：不改变对应端', () {
      final mm = _mm(100, 20);
      mm.expandByRatios([0.0, 0.0]);
      expect(mm.max.toDouble(), 100.0);
      expect(mm.min.toDouble(), 20.0);
    });
  });

  // ---------------------------------------------------------------------------
  // minToZero
  // ---------------------------------------------------------------------------
  group('MinMax.minToZero', () {
    test('min > 0：强制置 0', () {
      final mm = _mm(100, 30);
      mm.minToZero();
      expect(mm.min.toDouble(), 0.0);
      expect(mm.max.toDouble(), 100.0); // max 不变
    });

    test('min == 0：不变', () {
      final mm = _mm(100, 0);
      mm.minToZero();
      expect(mm.min.toDouble(), 0.0);
    });

    test('min < 0：不变（不置 0）', () {
      final mm = _mm(100, -10);
      mm.minToZero();
      expect(mm.min.toDouble(), -10.0);
    });
  });

  // ---------------------------------------------------------------------------
  // getMinMaxByList
  // ---------------------------------------------------------------------------
  group('MinMax.getMinMaxByList', () {
    test('null / 空列表：返回 null', () {
      expect(MinMax.getMinMaxByList(null), isNull);
      expect(MinMax.getMinMaxByList([]), isNull);
    });

    test('全为 null 的列表：返回 null', () {
      expect(MinMax.getMinMaxByList([null, null]), isNull);
    });

    test('单一元素：max == min == 该值', () {
      final mm = MinMax.getMinMaxByList([_fn(42)])!;
      expect(mm.max.toDouble(), 42.0);
      expect(mm.min.toDouble(), 42.0);
    });

    test('多元素：正确找出最大最小值', () {
      final mm = MinMax.getMinMaxByList([
        _fn(10),
        _fn(50),
        _fn(30),
        _fn(5),
        _fn(80),
      ])!;
      expect(mm.max.toDouble(), 80.0);
      expect(mm.min.toDouble(), 5.0);
    });

    test('含 null 元素：跳过 null，仍正确计算', () {
      final mm = MinMax.getMinMaxByList([null, _fn(10), null, _fn(90), null])!;
      expect(mm.max.toDouble(), 90.0);
      expect(mm.min.toDouble(), 10.0);
    });
  });

  // ---------------------------------------------------------------------------
  // lerp
  // ---------------------------------------------------------------------------
  group('MinMax.lerp', () {
    final a = MinMax(max: _fn(100), min: _fn(0));
    final b = MinMax(max: _fn(200), min: _fn(50));

    test('t=0 返回 a 的值', () {
      final r = MinMax.lerp(a, b, 0.0);
      expect(r.max.toDouble(), 100.0);
      expect(r.min.toDouble(), 0.0);
    });

    test('t=1 返回 b 的值', () {
      final r = MinMax.lerp(a, b, 1.0);
      expect(r.max.toDouble(), 200.0);
      expect(r.min.toDouble(), 50.0);
    });

    test('t=0.5 返回中间值', () {
      final r = MinMax.lerp(a, b, 0.5);
      expect(r.max.toDouble(), 150.0);
      expect(r.min.toDouble(), 25.0);
    });

    test('t=0.15（默认平滑因子）值正确', () {
      final r = MinMax.lerp(a, b, 0.15);
      expect(r.max.toDouble(), closeTo(115.0, 0.01));
      expect(r.min.toDouble(), closeTo(7.5, 0.01));
    });

    test('返回值是独立副本，修改不影响原值', () {
      final r = MinMax.lerp(a, b, 0.5);
      r.max = _fn(999);
      expect(a.max.toDouble(), 100.0);
      expect(b.max.toDouble(), 200.0);
    });

    test('a == b 时直接返回 b 的克隆', () {
      final same = _mm(50, 10);
      final r = MinMax.lerp(same, same, 0.5);
      expect(r.max.toDouble(), 50.0);
      expect(r.min.toDouble(), 10.0);
    });

    test('t 超出范围：t<0 clamp 到 a，t>1 clamp 到 b', () {
      final x = _mm(10, 0);
      final y = _mm(20, 5);

      final rNeg = MinMax.lerp(x, y, -0.5);
      expect(rNeg.max.toDouble(), 10.0);
      expect(rNeg.min.toDouble(), 0.0);

      final rOver = MinMax.lerp(x, y, 1.5);
      expect(rOver.max.toDouble(), 20.0);
      expect(rOver.min.toDouble(), 5.0);
    });

    test('连续平滑逼近：30 帧后接近目标值', () {
      var current = _mm(100, 0);
      final target = _mm(200, 50);

      for (int i = 0; i < 30; i++) {
        current = MinMax.lerp(current, target, 0.15);
      }

      expect(current.max.toDouble(), closeTo(200.0, 1.0));
      expect(current.min.toDouble(), closeTo(50.0, 1.0));
    });
  });
}
