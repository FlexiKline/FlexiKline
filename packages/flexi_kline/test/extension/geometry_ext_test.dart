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

/// 几何扩展：Offset / Rect 的向量运算、包含与命中判断、线上取点与方向角。
library;

import 'dart:math' as math;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rect.distanceFromBottom', () {
    const rect = Rect.fromLTRB(0, 100, 200, 400);

    test('从底边量起, 底边为 0、顶边为 height', () {
      expect(rect.distanceFromBottom(400), 0);
      expect(rect.distanceFromBottom(100), 300);
      expect(rect.distanceFromBottom(250), 150);
    });

    test('落在矩形之外时停在边界, 不继续增长', () {
      expect(rect.distanceFromBottom(500), 0, reason: '底边之下');
      expect(rect.distanceFromBottom(-50), 300, reason: '顶边之上');
    });

    test('高度为 0 返回 null', () {
      expect(const Rect.fromLTRB(0, 100, 200, 100).distanceFromBottom(100), isNull);
    });

    /// 上下翻转的矩形（`bottom < top`）高度为负，`clamp` 的上界小于下界会抛 `ArgumentError`。
    /// `chartRect` 的高度是 `size.height - padding.vertical - tipsAreaHeight`，主区很矮而
    /// 主区指标很多时确实会翻转，所以这条是真实可达的输入而非防御性洁癖。
    test('高度为负返回 null 而不抛异常', () {
      const inverted = Rect.fromLTRB(0, 40, 100, 20);
      expect(inverted.height, isNegative, reason: '前置条件: 必须是翻转矩形');
      expect(inverted.distanceFromBottom(30), isNull);
    });

    test('高度小于 1px 仍是合法输入', () {
      // 阈值曾是 `<= 1`，理由是 zoom 软化项由 `height - 1` 派生；软化项改为与高度成正比
      // 之后那个理由已消失，只有非正高度才是真正的危险输入。
      expect(const Rect.fromLTRB(0, 0, 10, 0.5).distanceFromBottom(0.2), closeTo(0.3, 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // Offset 扩展方法：dot、cross、slope、normalized、distanceTo、angleTo 等
  // ---------------------------------------------------------------------------
  group('Offset extensions', () {
    test('dot 点乘：(3,4)·(4,3) = dx*odx + dy*ody = 3*4+4*3 = 24', () {
      expect(const Offset(3, 4).dot(const Offset(4, 3)), closeTo(24.0, 1e-9));
    });

    test('dot 点乘：正交向量结果为 0', () {
      expect(const Offset(1, 0).dot(const Offset(0, 1)), closeTo(0.0, 1e-9));
    });

    test('cross 叉乘：(3,0)×(0,3) = dx*ody - dy*odx = 3*3-0*0 = 9', () {
      expect(const Offset(3, 0).cross(const Offset(0, 3)), closeTo(9.0, 1e-9));
    });

    test('cross 叉乘：反序结果取反', () {
      final c1 = const Offset(3, 0).cross(const Offset(0, 3));
      final c2 = const Offset(0, 3).cross(const Offset(3, 0));
      expect(c1, closeTo(-c2, 1e-9));
    });

    test('cross 叉乘：同向向量结果为 0', () {
      expect(const Offset(2, 4).cross(const Offset(1, 2)), closeTo(0.0, 1e-9));
    });

    test('slope 斜率：Offset(3,6) 的斜率为 2', () {
      expect(const Offset(3, 6).slope, closeTo(2.0, 1e-9));
    });

    test('slope 斜率：dx=0 时返回 0', () {
      expect(const Offset(0, 5).slope, closeTo(0.0, 1e-9));
    });

    test('slope 斜率：水平向量斜率为 0', () {
      expect(const Offset(5, 0).slope, closeTo(0.0, 1e-9));
    });

    test('normalized 归一化：长度为 1，方向不变', () {
      final n = const Offset(3, 4).normalized();
      expect(n.distance, closeTo(1.0, 1e-9));
      expect(n.dx, closeTo(0.6, 1e-9));
      expect(n.dy, closeTo(0.8, 1e-9));
    });

    test('normalized 零向量返回 Offset.zero', () {
      expect(Offset.zero.normalized(), equals(Offset.zero));
    });

    test('length 与 distance 等价', () {
      const o = Offset(3, 4);
      expect(o.length, closeTo(o.distance, 1e-9));
      expect(o.length, closeTo(5.0, 1e-9));
    });

    test('distanceTo：(0,0) 到 (3,4) = 5', () {
      expect(const Offset(0, 0).distanceTo(const Offset(3, 4)), closeTo(5.0, 1e-9));
    });

    test('angleTo：(1,0) 与 (0,1) 夹角为 π/2', () {
      expect(const Offset(1, 0).angleTo(const Offset(0, 1)), closeTo(math.pi / 2, 1e-9));
    });

    test('angleTo：相同向量夹角为 0', () {
      expect(const Offset(3, 4).angleTo(const Offset(3, 4)), closeTo(0.0, 1e-9));
    });

    test('angleTo：结果始终为非负值', () {
      // angleTo 返回无符号夹角，始终 >= 0
      final angle = const Offset(0, 1).angleTo(const Offset(1, 0));
      expect(angle, greaterThanOrEqualTo(0.0));
    });

    test('angleToSigned：(1,0) 到 (0,1) 为正 π/2（screen 坐标系逆时针）', () {
      expect(const Offset(1, 0).angleToSigned(const Offset(0, 1)), closeTo(math.pi / 2, 1e-9));
    });

    test('angleToSigned：(0,1) 到 (1,0) 为负 π/2（顺时针）', () {
      expect(const Offset(0, 1).angleToSigned(const Offset(1, 0)), closeTo(-math.pi / 2, 1e-9));
    });

    test('angleToSigned 正负与 angleTo 绝对值一致', () {
      const u = Offset(3, 1);
      const v = Offset(1, 3);
      expect(u.angleToSigned(v).abs(), closeTo(u.angleTo(v), 1e-9));
    });

    test('clamp：将 Offset 限制在矩形范围内', () {
      const r = Rect.fromLTRB(0, 0, 10, 10);
      expect(const Offset(15, 5).clamp(r), equals(const Offset(10, 5)));
      expect(const Offset(-2, -3).clamp(r), equals(const Offset(0, 0)));
      expect(const Offset(5, 5).clamp(r), equals(const Offset(5, 5)));
    });

    test('min：取每个分量的较小值', () {
      expect(const Offset(3, 7).min(const Offset(5, 4)), equals(const Offset(3, 4)));
    });

    test('min：参数为 null 时返回自身', () {
      const o = Offset(3, 7);
      expect(o.min(null), equals(o));
    });

    test('max：取每个分量的较大值', () {
      expect(const Offset(3, 7).max(const Offset(5, 4)), equals(const Offset(5, 7)));
    });

    test('max：参数为 null 时返回自身', () {
      const o = Offset(3, 7);
      expect(o.max(null), equals(o));
    });
  });

  // ---------------------------------------------------------------------------
  // Rect 扩展方法：include、includeDx、includeDy、origin、shiftYAxis、clampRect、hitTest
  // ---------------------------------------------------------------------------
  group('Rect extensions', () {
    const rect = Rect.fromLTRB(0, 0, 14, 10);

    group('include / includeDx / includeDy', () {
      test('内部点返回 true', () {
        expect(rect.include(const Offset(5, 5)), isTrue);
      });

      test('左上角边界点返回 true', () {
        expect(rect.include(const Offset(0, 0)), isTrue);
      });

      test('右下角边界点返回 true', () {
        expect(rect.include(const Offset(14, 10)), isTrue);
      });

      test('右侧外部点返回 false', () {
        expect(rect.include(const Offset(15, 5)), isFalse);
      });

      test('下方外部点返回 false', () {
        expect(rect.include(const Offset(5, 11)), isFalse);
      });

      test('includeDx：在 [0,14] 内为 true，超出为 false', () {
        expect(rect.includeDx(0), isTrue);
        expect(rect.includeDx(7), isTrue);
        expect(rect.includeDx(14), isTrue);
        expect(rect.includeDx(-1), isFalse);
        expect(rect.includeDx(15), isFalse);
      });

      test('includeDy：在 [0,10] 内为 true，超出为 false', () {
        expect(rect.includeDy(0), isTrue);
        expect(rect.includeDy(5), isTrue);
        expect(rect.includeDy(10), isTrue);
        expect(rect.includeDy(-1), isFalse);
        expect(rect.includeDy(11), isFalse);
      });
    });

    test('origin 返回左上角坐标', () {
      expect(rect.origin, equals(const Offset(0, 0)));
      expect(const Rect.fromLTRB(3, 5, 14, 10).origin, equals(const Offset(3, 5)));
    });

    test('shiftYAxis 正常收缩顶部', () {
      final shifted = rect.shiftYAxis(3);
      expect(shifted.top, closeTo(3.0, 1e-9));
      expect(shifted.bottom, closeTo(rect.bottom, 1e-9));
      expect(shifted.left, closeTo(rect.left, 1e-9));
      expect(shifted.right, closeTo(rect.right, 1e-9));
    });

    test('shiftYAxis height 超出 bottom 时被夹至 bottom', () {
      final shifted = rect.shiftYAxis(20);
      expect(shifted.top, closeTo(rect.bottom, 1e-9));
    });

    test('clampRect 将超出范围的边限制到外框内', () {
      const outer = Rect.fromLTRB(0, 0, 14, 10);
      const overRect = Rect.fromLTRB(-2, -3, 16, 12);
      final clamped = overRect.clampRect(outer);
      expect(clamped.left, closeTo(0.0, 1e-9));
      expect(clamped.top, closeTo(0.0, 1e-9));
      expect(clamped.right, closeTo(14.0, 1e-9));
      expect(clamped.bottom, closeTo(10.0, 1e-9));
    });

    test('clampRect 已在范围内的矩形不变', () {
      const inner = Rect.fromLTRB(2, 3, 10, 8);
      final clamped = inner.clampRect(rect);
      expect(clamped.left, closeTo(inner.left, 1e-9));
      expect(clamped.top, closeTo(inner.top, 1e-9));
      expect(clamped.right, closeTo(inner.right, 1e-9));
      expect(clamped.bottom, closeTo(inner.bottom, 1e-9));
    });

    test('hitTestBottom：精确命中 bottom', () {
      expect(rect.hitTestBottom(10.0), isTrue);
    });

    test('hitTestBottom：在 minDistance 范围内命中', () {
      expect(rect.hitTestBottom(10.5, minDistance: 1.0), isTrue);
      expect(rect.hitTestBottom(12.0, minDistance: 1.0), isFalse);
    });

    test('hitTestTop：精确命中 top', () {
      expect(rect.hitTestTop(0.0), isTrue);
    });

    test('hitTestTop：在 minDistance 范围内命中', () {
      expect(rect.hitTestTop(1.0, minDistance: 1.0), isTrue);
      expect(rect.hitTestTop(2.0, minDistance: 1.0), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // FlexiOffsetDoubleExt：offsetWithDyOnAB / offsetWithDxOnAB
  // ---------------------------------------------------------------------------
  group('FlexiOffsetDoubleExt', () {
    const A = Offset(0, 0);
    const B = Offset(20, 20);

    test('offsetWithDyOnAB：y=x 线上 dy=10 → Offset(10,10)', () {
      final offset = 10.0.offsetWithDyOnAB(A, B);
      expect(offset.dx, closeTo(10.0, 1e-9));
      expect(offset.dy, closeTo(10.0, 1e-9));
    });

    test('offsetWithDxOnAB：y=x 线上 dx=10 → Offset(10,10)', () {
      final offset = 10.0.offsetWithDxOnAB(A, B);
      expect(offset.dx, closeTo(10.0, 1e-9));
      expect(offset.dy, closeTo(10.0, 1e-9));
    });

    test('offsetWithDyOnAB：y=2x 线上 dy=6 → Offset(3,6)', () {
      // A=(0,0), B=(10,20); dx=(6-20)/2+10=3
      final offset = 6.0.offsetWithDyOnAB(const Offset(0, 0), const Offset(10, 20));
      expect(offset.dx, closeTo(3.0, 1e-9));
      expect(offset.dy, closeTo(6.0, 1e-9));
    });

    test('offsetWithDxOnAB：y=2x 线上 dx=3 → Offset(3,6)', () {
      final offset = 3.0.offsetWithDxOnAB(const Offset(0, 0), const Offset(10, 20));
      expect(offset.dx, closeTo(3.0, 1e-9));
      expect(offset.dy, closeTo(6.0, 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // Offset.direction：相对原点的方向角
  // ---------------------------------------------------------------------------
  group('Offset.direction', () {
    double toDegrees(double radians) {
      final degrees = radians * (180 / math.pi);
      return degrees < 0 ? 360 + degrees : degrees % 360;
    }

    test('向右方向为 0°', () {
      const A = Offset(0, 0);
      const B = Offset(5, 0);
      expect(toDegrees((B - A).direction), closeTo(0.0, 1e-9));
    });

    test('向右下方向为 45°', () {
      const A = Offset(0, 0);
      const B = Offset(5, 5);
      expect(toDegrees((B - A).direction), closeTo(45.0, 1e-9));
    });

    test('向下方向为 90°', () {
      const A = Offset(0, 0);
      const B = Offset(0, 5);
      expect(toDegrees((B - A).direction), closeTo(90.0, 1e-9));
    });

    test('向左方向为 180°', () {
      const A = Offset(0, 0);
      const B = Offset(-5, 0);
      expect(toDegrees((B - A).direction), closeTo(180.0, 1e-9));
    });

    test('向左下方向为 225°', () {
      // atan2(-5,-5) = -135° → 360-135 = 225°
      expect(toDegrees(const Offset(-5, -5).direction), closeTo(225.0, 1e-9));
    });

    test('向上方向为 270°', () {
      // atan2(-5,0) = -90° → 270°
      expect(toDegrees(const Offset(0, -5).direction), closeTo(270.0, 1e-9));
    });

    test('向右上方向为 315°', () {
      // atan2(-5,5) = -45° → 315°
      expect(toDegrees(const Offset(5, -5).direction), closeTo(315.0, 1e-9));
    });
  });
}
