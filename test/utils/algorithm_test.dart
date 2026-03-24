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

import 'package:flexi_kline/src/utils/algorithm_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_utils.dart';

void main() {
  // ---------------------------------------------------------------------------
  // scaledSingal
  // ---------------------------------------------------------------------------
  group('scaledSingal', () {
    test('x < 1 返回 null', () {
      expect(scaledSingal(0.0, 15), isNull);
      expect(scaledSingal(0.9, 15), isNull);
      expect(scaledSingal(0.5, 15), isNull);
    });

    test('x 为负且绝对值 < 1 返回 null', () {
      expect(scaledSingal(-0.5, 15), isNull);
      expect(scaledSingal(-0.9, 15), isNull);
    });

    test('x = 1（边界）k=1 时返回 0.5', () {
      // kNorm = (1-1)/(30-1) = 0；sigmoid(0) = 0.5；sign=+1
      final y = scaledSingal(1.0, 1);
      expect(y, isNotNull);
      expect(y!, closeTo(0.5, 1e-9));
    });

    test('k = 1 时对任意 x >= 1 结果均为 ±0.5（kNorm=0 → sigmoid 固定）', () {
      for (final x in [1.0, 2.0, 10.0, 100.0]) {
        final y = scaledSingal(x, 1)!;
        expect(y, closeTo(0.5, 1e-9), reason: 'x=$x');
      }
    });

    test('正 x 返回正值，负 x 返回负值（符号保留）', () {
      final pos = scaledSingal(5.0, 15)!;
      final neg = scaledSingal(-5.0, 15)!;
      expect(pos, greaterThan(0));
      expect(neg, lessThan(0));
      expect(pos, closeTo(-neg, 1e-9)); // 绝对值相等
    });

    test('输出值在 (0, 1) 范围内（绝对值）', () {
      for (final x in [1.0, 2.0, 5.0, 10.0, 100.0, 1000.0]) {
        final y = scaledSingal(x, 15)!;
        expect(y.abs(), greaterThan(0.0));
        expect(y.abs(), lessThan(1.0));
      }
    });

    test('k 越大，相同 x 时输出越接近 1（更强压缩）', () {
      final y5 = scaledSingal(10.0, 5)!;
      final y15 = scaledSingal(10.0, 15)!;
      final y25 = scaledSingal(10.0, 25)!;
      expect(y5, lessThan(y15));
      expect(y15, lessThan(y25));
    });

    test('x 越大，相同 k 时输出单调增（压缩越多）', () {
      final y1 = scaledSingal(1.0, 15)!;
      final y10 = scaledSingal(10.0, 15)!;
      final y100 = scaledSingal(100.0, 15)!;
      expect(y1, lessThan(y10));
      expect(y10, lessThan(y100));
    });

    test('自定义 kMax 影响归一化系数', () {
      // kMax=10, k=10 → kNorm=1；kMax=30, k=10 → kNorm=9/29 ≈ 0.31
      final yBig = scaledSingal(5.0, 10, kMax: 10)!;
      final ySmall = scaledSingal(5.0, 10, kMax: 30)!;
      expect(yBig, greaterThan(ySmall));
    });
  });

  // ---------------------------------------------------------------------------
  // scaledDecelerate
  // ---------------------------------------------------------------------------
  group('scaledDecelerate', () {
    test('scale = 1 原样返回', () {
      expect(scaledDecelerate(1.0), 1.0);
    });

    test('scale > 1 返回值仍大于 1，但增幅被压缩', () {
      final y2 = scaledDecelerate(2.0);
      final y4 = scaledDecelerate(4.0);
      expect(y2, greaterThan(1.0));
      expect(y4, greaterThan(1.0));
      // 原始差 4-2=2；压缩后差更小
      expect(y4 - y2, lessThan(4.0 - 2.0));
    });

    test('scale = 2 结果精确值', () {
      // log(2) + 1 ≈ 1.6931...
      expect(scaledDecelerate(2.0), closeTo(math.log(2) + 1, 1e-12));
    });

    test('0 < scale < 1 返回值小于 1（减速仍适用）', () {
      final y = scaledDecelerate(0.5);
      expect(y, lessThan(1.0));
      expect(y, closeTo(math.log(0.5) + 1, 1e-12));
    });

    test('连续缩放时输出单调递增', () {
      final ys = [1.5, 2.0, 3.0, 5.0, 10.0].map(scaledDecelerate).toList();
      for (int i = 1; i < ys.length; i++) {
        expect(ys[i], greaterThan(ys[i - 1]));
      }
    });

    test('减速效果：大 scale 的相对增幅明显小于线性', () {
      // scale 从 2 翻倍到 4，线性增幅 100%，对数增幅应 < 50%
      final y2 = scaledDecelerate(2.0);
      final y4 = scaledDecelerate(4.0);
      final linearGrowth = (4.0 - 2.0) / 2.0;       // 100%
      final logGrowth = (y4 - y2) / y2;
      expect(logGrowth, lessThan(linearGrowth));
    });
  });

  // ---------------------------------------------------------------------------
  // calcuInertialPanDuration
  // ---------------------------------------------------------------------------
  group('calcuInertialPanDuration', () {
    test('速度 <= 1 返回 0', () {
      expect(calcuInertialPanDuration(0, maxDuration: 2000), 0);
      expect(calcuInertialPanDuration(1, maxDuration: 2000), 0);
      expect(calcuInertialPanDuration(-1, maxDuration: 2000), 0);
    });

    test('负数取绝对值，结果与正数一致', () {
      expect(
        calcuInertialPanDuration(-3000, maxDuration: 2000),
        calcuInertialPanDuration(3000, maxDuration: 2000),
      );
    });

    test('结果单调递增，速度越大时长越长', () {
      const maxDur = 2000;
      final d500 = calcuInertialPanDuration(500, maxDuration: maxDur);
      final d1000 = calcuInertialPanDuration(1000, maxDuration: maxDur);
      final d2000 = calcuInertialPanDuration(2000, maxDuration: maxDur);
      final d5000 = calcuInertialPanDuration(5000, maxDuration: maxDur);
      final d10000 = calcuInertialPanDuration(10000, maxDuration: maxDur);

      debugPrint('v=500=>$d500  v=1000=>$d1000  v=2000=>$d2000  v=5000=>$d5000  v=10000=>$d10000');

      expect(d500, lessThan(d1000));
      expect(d1000, lessThan(d2000));
      expect(d2000, lessThan(d5000));
      expect(d5000, lessThanOrEqualTo(d10000));
      // 不超过 maxDuration
      expect(d10000, lessThanOrEqualTo(maxDur));
    });

    test('中速滑动结果在合理范围内', () {
      final d1000 = calcuInertialPanDuration(1000, maxDuration: 2000);
      expect(d1000, greaterThanOrEqualTo(500));
      expect(d1000, lessThanOrEqualTo(1500));
    });
  });

  // ---------------------------------------------------------------------------
  // ensureMinDistance
  // ---------------------------------------------------------------------------
  group('ensureMinDistance', () {
    test('|d2-d1| < 1 时：调整后两值差的绝对值恰为 1', () {
      var (a, b) = ensureMinDistance(0.1, 0.2);
      logMsg('a:$a ~ b:$b');
      expect((a - b).abs(), closeTo(1.0, 1e-9));

      (a, b) = ensureMinDistance(0.2, 0.1);
      logMsg('a:$a ~ b:$b');
      expect((a - b).abs(), closeTo(1.0, 1e-9));

      (a, b) = ensureMinDistance(10.2, 11.0);
      logMsg('a:$a ~ b:$b');
      expect((a - b).abs(), closeTo(1.0, 1e-9));

      (a, b) = ensureMinDistance(11.0, 10.2);
      logMsg('a:$a ~ b:$b');
      expect((a - b).abs(), closeTo(1.0, 1e-9));
    });

    test('d1 == d2（距离为 0）：对称调整，差为 ±1', () {
      final (a, b) = ensureMinDistance(5.0, 5.0);
      logMsg('equal: a:$a ~ b:$b');
      // dist=0, sign=0, half=0.5 → (4.5, 5.5)
      expect(a, closeTo(4.5, 1e-9));
      expect(b, closeTo(5.5, 1e-9));
      expect((b - a).abs(), closeTo(1.0, 1e-9));
    });

    test('距离恰好等于 1：不做调整', () {
      final (a, b) = ensureMinDistance(0.0, 1.0);
      expect(a, 0.0);
      expect(b, 1.0);
    });

    test('距离恰好等于 -1：不做调整', () {
      final (a, b) = ensureMinDistance(1.0, 0.0);
      expect(a, 1.0);
      expect(b, 0.0);
    });

    test('距离大于 1：不做调整', () {
      final (a, b) = ensureMinDistance(0.0, 2.0);
      expect(a, 0.0);
      expect(b, 2.0);
    });

    test('距离小于 -1：不做调整', () {
      final (a, b) = ensureMinDistance(3.0, 0.0);
      expect(a, 3.0);
      expect(b, 0.0);
    });

    test('d1 > d2 且 |差| < 1：d1 增大，d2 减小，绝对距离恰为 1', () {
      // dist = d2 - d1 = 0.1 - 0.9 = -0.8；half = -1*(1-0.8)*0.5 = -0.1
      // 结果: (d1-(-0.1), d2+(-0.1)) = (1.0, 0.0)
      final (a, b) = ensureMinDistance(0.9, 0.1);
      expect((a - b).abs(), closeTo(1.0, 1e-9));
      expect(a, greaterThan(b)); // 保持 d1 > d2 的方向
    });

    test('调整后中点不变（对称扩张）', () {
      const d1 = 3.3;
      const d2 = 3.6;
      final mid = (d1 + d2) / 2;
      final (a, b) = ensureMinDistance(d1, d2);
      expect((a + b) / 2, closeTo(mid, 1e-9));
    });
  });

}

