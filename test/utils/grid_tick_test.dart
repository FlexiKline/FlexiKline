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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/utils/grid_tick_util.dart' show niceStep;
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

/// step 由 `fraction * pow(10, exponent)` 得出, 允许 1ulp 尾数, 用相对容差断言。
Matcher stepIs(double expected) => closeTo(expected, expected.abs() * 1e-12);

/// 把 [value] 按 [precision] 格式化后, 换算成最小可辨单位的整数计数。
///
/// 取整数是为了让「相邻刻度的显示差是否相等」这条断言不再引入一层浮点误差 —— 显示层的
/// 等差性本来就是以最小可辨单位为刻度的。
int unitsOf(double value, int precision) {
  return int.parse(value.toStringAsFixed(precision).replaceFirst('.', ''));
}

/// 格式化后相邻刻度的显示差(以最小可辨单位计)。
List<int> unitDiffs(List<double> values, int precision) {
  final units = values.map((v) => unitsOf(v, precision)).toList();
  return [for (int i = 1; i < units.length; i++) units[i] - units[i - 1]];
}

/// 刻度序列的三条不变量: 都是 step 整数倍、单调递增、落在 [bottom], [top] 内。
void expectTickInvariants(({double step, List<double> values}) result, double bottom, double top) {
  expect(result.values, isNotEmpty);
  // 容差为 step 的 1e-9: 起始下标本身带同量级容差, 首条刻度可能低于 bottom 一个 ulp。
  final slack = result.step * 1e-9;
  for (final v in result.values) {
    final quotient = v / result.step;
    expect(
      (quotient - quotient.roundToDouble()).abs(),
      lessThan(1e-6),
      reason: '$v 不是 step ${result.step} 的整数倍',
    );
    expect(v, greaterThanOrEqualTo(bottom - slack), reason: '$v 低于 bottom $bottom');
    expect(v, lessThanOrEqualTo(top), reason: '$v 高于 top $top');
  }
  for (int i = 1; i < result.values.length; i++) {
    expect(result.values[i], greaterThan(result.values[i - 1]), reason: '刻度未单调递增');
  }
}

void main() {
  // ---------------------------------------------------------------------------
  // 等分
  // ---------------------------------------------------------------------------
  group('dividedPositions 等分取位 (含两端)', () {
    test('产出 divisions + 1 个位置, 含首末', () {
      expect(dividedPositions(5, start: 0, length: 300), [0.0, 60.0, 120.0, 180.0, 240.0, 300.0]);
      expect(dividedPositions(2, start: 100, length: 300), [100.0, 250.0, 400.0]);
    });

    test('divisions == 1 时只有两端', () {
      expect(dividedPositions(1, start: 0, length: 300), [0.0, 300.0]);
    });

    test('divisions <= 0 时返回空', () {
      for (final divisions in [0, -3]) {
        expect(dividedPositions(divisions, start: 0, length: 300), isEmpty, reason: 'divisions=$divisions');
      }
    });

    test('长度非正或非有限时返回空, 不产出 NaN', () {
      for (final length in [0.0, -300.0, double.nan, double.infinity]) {
        expect(dividedPositions(5, start: 0, length: length), isEmpty, reason: 'length=$length');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 固定间距
  // ---------------------------------------------------------------------------
  group('spacedPositions 固定间距取位', () {
    test('整除时余量为零, 位置数为完整间隔数减一', () {
      expect(spacedPositions(60, start: 0, length: 300), [60.0, 120.0, 180.0, 240.0]);
    });

    test('余量平分两端, 间距仍严格等于 spacing', () {
      // 320 装得下 5 格 60, 余 20 → 两端各 10。
      final positions = spacedPositions(60, start: 0, length: 320);

      expect(positions, [70.0, 130.0, 190.0, 250.0]);
      for (int i = 1; i < positions.length; i++) {
        expect(positions[i] - positions[i - 1], 60.0, reason: '不得为了整除而调整间距');
      }
    });

    test('start 参与偏移, 不假定从 0 起', () {
      expect(spacedPositions(60, start: 100, length: 320), [170.0, 230.0, 290.0, 350.0]);
    });

    test('首位置到起点距离 == 末位置到终点距离', () {
      for (final (length, spacing) in [(320.0, 60.0), (300.0, 60.0), (317.0, 47.0), (500.0, 133.0)]) {
        final positions = spacedPositions(spacing, start: 0, length: length);
        if (positions.isEmpty) continue;
        expect(
          positions.first,
          closeTo(length - positions.last, 1e-9),
          reason: 'length=$length spacing=$spacing 不居中',
        );
      }
    });

    test('装不下、参数非法都返回空且不抛', () {
      final cases = <(String, double, double)>[
        ('恰好一格, 内部无位置', 300, 300),
        ('容不下一格', 60, 50),
        ('spacing 为零', 0, 300),
        ('spacing 为负', -60, 300),
        ('spacing 无穷', double.infinity, 300),
        ('spacing 非数', double.nan, 300),
        ('长度为零', 60, 0),
        ('长度为负', 60, -300),
        ('长度非数', 60, double.nan),
        ('长度无穷', 60, double.infinity),
      ];
      for (final (reason, spacing, length) in cases) {
        expect(spacedPositions(spacing, start: 0, length: length), isEmpty, reason: reason);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // niceStep 档位归整
  // ---------------------------------------------------------------------------
  group('niceStep 档位归整', () {
    test('10 的整数次幂原样返回, 不因 log().floor() 少一位指数而偏移', () {
      // 1000 会走 exponent=2、fraction=10 这条路(log(1000)/ln10 得 2.9999999999999996),
      // 精确返回依赖档位集末尾的 10 兜底。
      for (final rough in [1.0, 10.0, 100.0, 1000.0, 0.1, 0.01, 0.001, 1e-8, 1e8]) {
        expect(niceStep(rough).step, rough, reason: 'rough=$rough');
      }
    });

    test('落在两档之间时取更近的一档, 不是不小于的那一档', () {
      // 档位 1 / 2 / 2.5 / 5 / 10, 分界为相邻两档的算术中点。
      expect(niceStep(1.4).step, stepIs(1));
      expect(niceStep(1.6).step, stepIs(2));
      expect(niceStep(2.1).step, stepIs(2));
      expect(niceStep(2.4).step, stepIs(2.5));
      expect(niceStep(3.0).step, stepIs(2.5));
      expect(niceStep(4.0).step, stepIs(5));
      expect(niceStep(6.0).step, stepIs(5));
      expect(niceStep(8.0).step, stepIs(10));
    });

    test('五个档位各能被命中一次', () {
      expect(niceStep(1.2).fraction, 1);
      expect(niceStep(1.9).fraction, 2);
      expect(niceStep(2.4).fraction, 2.5);
      expect(niceStep(4.0).fraction, 5);
      expect(niceStep(8.0).fraction, 10);
    });
  });

  // ---------------------------------------------------------------------------
  // precision 约束: step 必须是最小可辨单位 u = 10^-precision 的整数倍
  // ---------------------------------------------------------------------------
  group('computeNiceTicks precision 下限', () {
    test('跨度小到理想 step 低于最小可辨单位时, step 被夹到 u 且刻度文本不重复', () {
      // 不夹的话 step 会是 5e-9, 实测得到 0.00002452 连续出现三次。
      const bottom = 2.451e-5;
      const top = bottom + 3e-8;
      final result = computeNiceTicks(bottom: bottom, top: top, targetCount: 5, precision: 8);

      expect(result.step, stepIs(1e-8));
      final texts = result.values.map((v) => v.toStringAsFixed(8)).toList();
      expect(texts.toSet(), hasLength(texts.length), reason: '刻度文本重复: $texts');
    });

    test('更高精度同样被夹住', () {
      for (final (precision, price, span, expectedStep) in [
        (10, 1.2345e-6, 3e-10, 1e-10),
        (12, 1.2345e-9, 3e-12, 1e-12),
      ]) {
        final result = computeNiceTicks(
          bottom: price,
          top: price + span,
          targetCount: 5,
          precision: precision,
        );
        expect(result.step, stepIs(expectedStep), reason: 'precision=$precision');
        final texts = result.values.map((v) => v.toStringAsFixed(precision)).toList();
        expect(texts.toSet(), hasLength(texts.length), reason: 'precision=$precision 文本重复: $texts');
      }
    });
  });

  group('computeNiceTicks precision 整数倍', () {
    test('2.5 档不是 u 的整数倍时提升到同量级的 5 档, 格式化后相邻差相等', () {
      // 价格 5.50、跨度 0.15、precision=2: 不修正会选到 step=0.025, 刻度线等距但文本显示成
      // 5.43 | 5.45 | 5.48 | 5.50 | 5.53, 相邻差在 0.02 与 0.03 之间跳。
      const bottom = 5.5 - 0.075;
      const top = 5.5 + 0.075;
      final result = computeNiceTicks(bottom: bottom, top: top, targetCount: 5, precision: 2);

      expect(result.step, isNot(stepIs(0.025)));
      expect(result.step, stepIs(0.05));
      final diffs = unitDiffs(result.values, 2);
      expect(diffs, isNotEmpty);
      expect(diffs.toSet(), hasLength(1), reason: '格式化后相邻差不相等: $diffs');
    });

    test('precision=4 与 precision=8 上的同一档同样被提升', () {
      for (final (precision, price, span, rejected, expected) in [
        (4, 0.1523, 0.0013, 0.00025, 0.0005),
        (8, 2.4e-5, 1.3e-7, 2.5e-8, 5e-8),
      ]) {
        final result = computeNiceTicks(
          bottom: price - span / 2,
          top: price + span / 2,
          targetCount: 5,
          precision: precision,
        );
        expect(result.step, isNot(stepIs(rejected)), reason: 'precision=$precision');
        expect(result.step, stepIs(expected), reason: 'precision=$precision');
        final diffs = unitDiffs(result.values, precision);
        expect(diffs, isNotEmpty, reason: 'precision=$precision 刻度不足两条');
        expect(diffs.toSet(), hasLength(1), reason: 'precision=$precision 相邻差不相等: $diffs');
      }
    });

    test('商为合法整数时保留 2.5 档, 不被误伤', () {
      // step 2.5e-7 / u 1e-8 = 25, 是整数倍, 应原样保留而不是提升到 5e-7。
      final result = computeNiceTicks(bottom: 2.4e-5, top: 2.55e-5, targetCount: 5, precision: 8);
      expect(result.step, stepIs(2.5e-7));
    });

    test('商带浮点尾数时仍判定为整数倍, 保留 2.5 档', () {
      // step 2.5e-8 / u 1e-9 在 double 下得 24.999999999999996。相等比较会把它误判成非整数
      // 倍而提升到 5e-8, 只有相对容差才正确。
      const bottom = 2.4e-5;
      final result = computeNiceTicks(bottom: bottom, top: bottom + 1.25e-7, targetCount: 5, precision: 9);
      expect(result.step, stepIs(2.5e-8));
    });
  });

  // ---------------------------------------------------------------------------
  // 刻度序列
  // ---------------------------------------------------------------------------
  group('computeNiceTicks 刻度序列', () {
    test('刻度都是 step 整数倍、单调递增、落在区间内', () {
      for (final (bottom, top, precision) in [
        (63375.0, 66625.0, 2),
        (136.8, 148.2, 3),
        (0.14697, 0.15763, 5),
        (2.3775e-5, 2.5245e-5, 8),
        (1.179e-6, 1.29e-6, 10),
      ]) {
        final result = computeNiceTicks(bottom: bottom, top: top, targetCount: 5, precision: precision);
        expectTickInvariants(result, bottom, top);
      }
    });

    test('bottom 恰为 step 整数倍时不丢最边缘那一条', () {
      // bottom 取 3 * 0.1 = 0.30000000000000004, 除以 step 得 3.0000000000000004。
      // 不减容差会 ceil 到 4, 首条刻度变成 0.4, 白丢 0.3 这一条。
      const step = 0.1;
      const bottom = 3 * step;
      final result = computeNiceTicks(bottom: bottom, top: bottom + 0.5, targetCount: 5, precision: 2);

      expect(result.step, stepIs(step));
      expect(result.values.first, bottom);
      expectTickInvariants(result, bottom, bottom + 0.5);
    });
  });

  // ---------------------------------------------------------------------------
  // 退化输入
  // ---------------------------------------------------------------------------
  group('computeNiceTicks 退化输入', () {
    test('跨度为 0 / 负 / NaN / Infinity 时返回空列表且不抛异常', () {
      for (final (label, bottom, top) in [
        ('跨度为 0', 100.0, 100.0),
        ('跨度为负', 150.0, 100.0),
        ('bottom 为 NaN', double.nan, 100.0),
        ('top 为 NaN', 100.0, double.nan),
        ('top 为 +Infinity', 100.0, double.infinity),
        ('bottom 为 -Infinity', double.negativeInfinity, 100.0),
      ]) {
        final result = computeNiceTicks(bottom: bottom, top: top, targetCount: 5, precision: 2);
        expect(result.values, isEmpty, reason: label);
        expect(result.step, 0, reason: label);
      }
    });

    test('targetCount <= 0 时返回空列表', () {
      for (final count in [0, -1, -5]) {
        final result = computeNiceTicks(bottom: 100, top: 150, targetCount: count, precision: 2);
        expect(result.values, isEmpty, reason: 'targetCount=$count');
        expect(result.step, 0, reason: 'targetCount=$count');
      }
    });

    test('targetCount 为 1 或 2 时仍有刻度, 降一档重试生效', () {
      // targetCount=1 时最接近取档给出 step=50, [101, 149] 内没有任何 50 的整数倍。
      // 空刻度会让滑竿宽度归零、zoom 手势失效, 所以要降到 25 重算。
      for (final count in [1, 2]) {
        final result = computeNiceTicks(bottom: 101, top: 149, targetCount: count, precision: 2);
        expect(result.values, isNotEmpty, reason: 'targetCount=$count');
        expectTickInvariants(result, 101, 149);
      }
    });

    test('跨度远小于最小可辨单位且区间内无整数倍时, 重试后仍返回空列表', () {
      // step 被 precision 夹到 0.01, [101.0000005, 101.0000006] 内没有 0.01 的整数倍;
      // 降一档得 0.005 又被 precision 夹回 0.01, 于是放弃。
      final result = computeNiceTicks(bottom: 101.0000005, top: 101.0000006, targetCount: 5, precision: 2);
      expect(result.values, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 场景回归: 固定住各精度档位在自动区间与放大 20x 下的 step 与刻度数
  // ---------------------------------------------------------------------------
  group('computeNiceTicks 场景回归', () {
    // price 与 autoRange 取自设计文档 4.2 的探针数据; step 与 count 是当前实现的实测输出,
    // 与该表的 B 方案一列一致。
    const scenarios = [
      (
        name: 'BTC',
        price: 65000.0,
        autoRange: 3.25e3,
        precision: 2,
        autoStep: 5e2,
        autoCount: 7,
        zoomStep: 2.5e1,
        zoomCount: 7
      ),
      (
        name: 'SOL',
        price: 142.5,
        autoRange: 1.14e1,
        precision: 3,
        autoStep: 2.5,
        autoCount: 5,
        zoomStep: 1e-1,
        zoomCount: 5
      ),
      (
        name: 'DOGE',
        price: 0.1523,
        autoRange: 1.066e-2,
        precision: 5,
        autoStep: 2e-3,
        autoCount: 5,
        zoomStep: 1e-4,
        zoomCount: 5
      ),
      (
        name: 'SHIB',
        price: 2.451e-5,
        autoRange: 1.47e-6,
        precision: 8,
        autoStep: 2.5e-7,
        autoCount: 5,
        zoomStep: 1e-8,
        zoomCount: 7
      ),
      (
        name: 'PEPE',
        price: 1.2345e-6,
        autoRange: 1.11e-7,
        precision: 10,
        autoStep: 2e-8,
        autoCount: 6,
        zoomStep: 1e-9,
        zoomCount: 6
      ),
    ];

    for (final s in scenarios) {
      test('${s.name} 自动区间与放大 20x 的 step 与刻度数', () {
        for (final (label, range, step, count) in [
          ('auto', s.autoRange, s.autoStep, s.autoCount),
          ('20x', s.autoRange / 20, s.zoomStep, s.zoomCount),
        ]) {
          final bottom = s.price - range / 2;
          final top = s.price + range / 2;
          final result = computeNiceTicks(
            bottom: bottom,
            top: top,
            targetCount: 5,
            precision: s.precision,
          );
          logMsg('${s.name} $label step=${result.step} n=${result.values.length} ${result.values}');

          expect(result.step, stepIs(step), reason: '${s.name} $label step');
          expect(result.values, hasLength(count), reason: '${s.name} $label 刻度数');
          expectTickInvariants(result, bottom, top);
        }
      });
    }
  });
}
