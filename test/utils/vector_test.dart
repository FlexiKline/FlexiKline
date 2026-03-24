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
import 'dart:ui';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_utils.dart';

void main() {
  const rect = Rect.fromLTRB(0, 0, 14, 10);

  // ---------------------------------------------------------------------------
  // distancePointToLineSegment / distanceToLineSegment
  // ---------------------------------------------------------------------------
  group('pointDistanceToLine', () {
    const offset = Offset(5, 5);

    test('点在线段上，距离为 0', () {
      const a = Offset(2, 2);
      const b = Offset(8, 8);
      final ret = distancePointToLineSegment(offset, a, b);
      logMsg('$a -> $b = $ret');
      expect(ret, closeTo(0.0, 1e-9));
    });

    test('点不在线段上，距离精确为 3/√5', () {
      // P=(5,5), A=(5,2), B=(8,8)
      // lenPG = sqrt(|AP|²  - (AP·AB/|AB|)²) = sqrt(9 - 36/5) = 3/√5
      const a = Offset(5, 2);
      const b = Offset(8, 8);
      final ret = offset.distanceToLineSegment(a, b);
      logMsg('$a -> $b = $ret');
      expect(ret, closeTo(3 / math.sqrt(5), 1e-9));
    });

    test('两种调用方式结果一致', () {
      const a = Offset(5, 2);
      const b = Offset(8, 8);
      final ret1 = distancePointToLineSegment(offset, a, b);
      final ret2 = offset.distanceToLineSegment(a, b);
      expect(ret1, closeTo(ret2, 1e-9));
    });

    test('点在 A 端点前方，取 |AP| 距离', () {
      // P=(-1,0), A=(2,2), B=(8,8): dotProduct<0 → return |AP|
      const p = Offset(-1, 0);
      const a = Offset(2, 2);
      const b = Offset(8, 8);
      final ret = distancePointToLineSegment(p, a, b);
      expect(ret, closeTo((p - a).distance, 1e-9));
    });

    test('点超出 B 端点，取 |PB| 距离', () {
      // P=(12,12), A=(2,2), B=(8,8): 投影超出 AB → return |PB|
      const p = Offset(12, 12);
      const a = Offset(2, 2);
      const b = Offset(8, 8);
      final ret = distancePointToLineSegment(p, a, b);
      expect(ret, closeTo((p - b).distance, 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // reflectPointsOnRect
  // ---------------------------------------------------------------------------
  group('reflectPointsOnRect — A、B 在矩形内', () {
    const A = Offset(5, 5);

    void expectPointsOnRect(List<Offset> points) {
      // 所有延伸交点应落在矩形边界上
      for (int i = 2; i < points.length; i++) {
        final p = points[i];
        final onBoundary = (p.dx - rect.left).abs() < 1e-6 ||
            (p.dx - rect.right).abs() < 1e-6 ||
            (p.dy - rect.top).abs() < 1e-6 ||
            (p.dy - rect.bottom).abs() < 1e-6;
        expect(onBoundary, isTrue, reason: 'Point $p should be on rect boundary');
      }
    }

    test('向右下方延伸交于右边界', () {
      // k=0.2, b=4; x=14 → y=0.2*14+4=6.8
      final B = Offset(10, 6);
      final points = reflectPointsOnRect(A, B, rect);
      logMsg(points.toString());
      expect(points, isNotEmpty);
      expectPointsOnRect(points);
      expect(points.last.dx, closeTo(rect.right, 1e-6));
      expect(points.last.dy, closeTo(6.8, 1e-6));
    });

    test('向右下方延伸交于下边界', () {
      // k=3, b=-10; y=10 → x=20/3≈6.667
      final B = Offset(6, 8);
      final points = reflectPointsOnRect(A, B, rect);
      logMsg(points.toString());
      expect(points, isNotEmpty);
      expectPointsOnRect(points);
      expect(points.last.dy, closeTo(rect.bottom, 1e-6));
      expect(points.last.dx, closeTo(20.0 / 3, 1e-6));
    });

    test('向右上方延伸交于右边界', () {
      // k=-3/7, b=50/7; x=14 → y=8/7
      final B = Offset(12, 2);
      final points = reflectPointsOnRect(A, B, rect);
      logMsg(points.toString());
      expect(points, isNotEmpty);
      expectPointsOnRect(points);
      expect(points.last.dx, closeTo(rect.right, 1e-6));
      expect(points.last.dy, closeTo(8.0 / 7, 1e-6));
    });

    test('向左延伸交于左边界', () {
      final B = Offset(2, 5);
      final points = reflectPointsOnRect(A, B, rect);
      logMsg(points.toString());
      expect(points, isNotEmpty);
      // 水平线：dx=left, dy 不变
      final endpoint = points.last;
      expect(endpoint.dy, closeTo(A.dy, 1e-6));
      expect(endpoint.dx, closeTo(rect.left, 1e-6));
    });

    test('向右延伸交于右边界', () {
      final B = Offset(7, 5);
      final points = reflectPointsOnRect(A, B, rect);
      logMsg(points.toString());
      expect(points, isNotEmpty);
      // 水平线终点 dx=right，dy 不变
      final endpoint = points.last;
      expect(endpoint.dx, closeTo(rect.right, 1e-6));
      expect(endpoint.dy, closeTo(A.dy, 1e-6));
    });

    test('垂直向上交于上边界', () {
      final B = Offset(5, 2);
      final points = reflectPointsOnRect(A, B, rect);
      logMsg(points.toString());
      expect(points, isNotEmpty);
      final endpoint = points.last;
      expect(endpoint.dy, closeTo(rect.top, 1e-6));
      expect(endpoint.dx, closeTo(A.dx, 1e-6));
    });

    test('垂直向下交于下边界', () {
      final B = Offset(5, 7);
      final points = reflectPointsOnRect(A, B, rect);
      logMsg(points.toString());
      expect(points, isNotEmpty);
      final endpoint = points.last;
      expect(endpoint.dy, closeTo(rect.bottom, 1e-6));
      expect(endpoint.dx, closeTo(A.dx, 1e-6));
    });

    test('携带 compare 参数按升序排列', () {
      final B = Offset(10, 6);
      final sorted = reflectPointsOnRect(A, B, rect, compare: compareOffsetByAsc);
      expect(sorted.length, greaterThanOrEqualTo(2));
      // 升序后首点 dx 不大于末点 dx
      expect(sorted.first.dx, lessThanOrEqualTo(sorted.last.dx));
    });

    test('reflectPathOnRect 有效时返回非 null Path', () {
      final path = reflectPathOnRect(A, const Offset(10, 6), rect);
      expect(path, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // reflectRectSide (Offset.reflectRectSide)
  // ---------------------------------------------------------------------------
  group('pointReflectInRect', () {
    const testRect = Rect.fromLTRB(0.5, 0.8, 14, 10);
    final offset = Offset(5, 5);

    test('向右下延伸落在右边界', () {
      final other = Offset(10, 6);
      final ret = offset.reflectRectSide(other, testRect);
      logMsg('1>$ret');
      expect(ret.dx, closeTo(testRect.right, 1e-6));
    });

    test('向右下延伸落在下边界', () {
      final other = Offset(6, 8);
      final ret = offset.reflectRectSide(other, testRect);
      logMsg('2>$ret');
      expect(ret.dy, closeTo(testRect.bottom, 1e-6));
    });

    test('向右上延伸落在右边界', () {
      final other = Offset(12, 2);
      final ret = offset.reflectRectSide(other, testRect);
      logMsg('3>$ret');
      expect(ret.dx, closeTo(testRect.right, 1e-6));
    });

    test('向左上延伸落在上边界', () {
      final other = Offset(7, 1);
      final ret = offset.reflectRectSide(other, testRect);
      logMsg('4>$ret');
      expect(ret.dy, closeTo(testRect.top, 1e-6));
    });

    test('水平向左延伸落在左边界', () {
      final other = Offset(2, 5);
      final ret = offset.reflectRectSide(other, testRect);
      logMsg('1>$ret');
      expect(ret.dx, closeTo(testRect.left, 1e-6));
      expect(ret.dy, closeTo(offset.dy, 1e-6));
    });

    test('水平向右延伸落在右边界', () {
      final other = Offset(7, 5);
      final ret = offset.reflectRectSide(other, testRect);
      logMsg('2>$ret');
      expect(ret.dx, closeTo(testRect.right, 1e-6));
      expect(ret.dy, closeTo(offset.dy, 1e-6));
    });

    test('垂直向上延伸落在上边界', () {
      final other = Offset(5, 2);
      final ret = offset.reflectRectSide(other, testRect);
      logMsg('3>$ret');
      expect(ret.dy, closeTo(testRect.top, 1e-6));
      expect(ret.dx, closeTo(offset.dx, 1e-6));
    });

    test('垂直向下延伸落在下边界', () {
      final other = Offset(5, 7);
      final ret = offset.reflectRectSide(other, testRect);
      logMsg('4>$ret');
      expect(ret.dy, closeTo(testRect.bottom, 1e-6));
      expect(ret.dx, closeTo(offset.dx, 1e-6));
    });

    test('P 与 O 重合时返回 P 本身', () {
      final ret = offset.reflectRectSide(offset, testRect);
      expect(ret.dx, closeTo(offset.dx, 1e-6));
      expect(ret.dy, closeTo(offset.dy, 1e-6));
    });
  });

  // ---------------------------------------------------------------------------
  // getDxAtDyOnAB
  // ---------------------------------------------------------------------------
  group('getDxAtDyOnAB', () {
    test('斜线 y=x，dy=10 时 dx=10', () {
      final dx = getDxAtDyOnAB(const Offset(20, 20), const Offset(0, 0), 10);
      logMsg('offset:$dx');
      expect(dx, closeTo(10.0, 1e-9));
    });

    test('斜线 y=x 颠倒端点，结果一致', () {
      final dx = getDxAtDyOnAB(const Offset(0, 0), const Offset(20, 20), 10);
      logMsg('offset:$dx');
      expect(dx, closeTo(10.0, 1e-9));
    });

    /// 垂直线（A.dx == B.dx）时，函数按约定返回 dy 本身（参见 vector_util.dart line 57）
    test('垂直线 A.dx==B.dx 时，返回 dy 参数值', () {
      final dx = getDxAtDyOnAB(const Offset(0, 0), const Offset(0, 20), 10);
      logMsg('offset:$dx');
      expect(dx, closeTo(10.0, 1e-9)); // 约定：vertical → return dy
    });

    test('水平线 A.dy==B.dy 时，返回 A.dx', () {
      // A.dy == B.dy → return A.dx = 0.0
      final dx = getDxAtDyOnAB(const Offset(0, 20), const Offset(20, 20), 10);
      logMsg('offset:$dx');
      expect(dx, closeTo(0.0, 1e-9));
    });

    test('斜率为 2 的直线，dy=4 时 dx=2', () {
      // y=2x → A=(0,0), B=(10,20); dx=(4-20)/2+10=2
      final dx = getDxAtDyOnAB(const Offset(0, 0), const Offset(10, 20), 4);
      expect(dx, closeTo(2.0, 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // getDyAtDxOnAB
  // ---------------------------------------------------------------------------
  group('getDyAtDxOnAB', () {
    test('斜线 y=x，dx=10 时 dy=10', () {
      final dy = getDyAtDxOnAB(const Offset(0, 0), const Offset(20, 20), 10);
      expect(dy, closeTo(10.0, 1e-9));
    });

    test('斜线 y=x 颠倒端点，结果一致', () {
      final dy = getDyAtDxOnAB(const Offset(20, 20), const Offset(0, 0), 10);
      expect(dy, closeTo(10.0, 1e-9));
    });

    test('水平线 A.dy==B.dy 时，返回 A.dy', () {
      final dy = getDyAtDxOnAB(const Offset(0, 5), const Offset(20, 5), 10);
      expect(dy, closeTo(5.0, 1e-9));
    });

    test('垂直线 A.dx==B.dx 时，返回 dx 参数值', () {
      // A.dx == B.dx → return dx (参见 vector_util.dart line 65)
      final dy = getDyAtDxOnAB(const Offset(0, 0), const Offset(0, 20), 10);
      expect(dy, closeTo(10.0, 1e-9));
    });

    test('斜率为 2 的直线，dx=3 时 dy=6', () {
      // y=2x → A=(0,0), B=(10,20); dy=(3-10)*2+20=6
      final dy = getDyAtDxOnAB(const Offset(0, 0), const Offset(10, 20), 3);
      expect(dy, closeTo(6.0, 1e-9));
    });

    test('getDxAtDyOnAB 与 getDyAtDxOnAB 在 y=x 上互逆', () {
      const A = Offset(0, 0);
      const B = Offset(20, 20);
      const val = 7.0;
      final dx = getDxAtDyOnAB(A, B, val);
      final dy = getDyAtDxOnAB(A, B, val);
      expect(dx, closeTo(dy, 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // LineEquation
  // ---------------------------------------------------------------------------
  group('LineEquation', () {
    test('端点代入方程结果为 0', () {
      const a = Offset(0, 0);
      const b = Offset(3, 4);
      final eq = LineEquation.fromPoints(a, b);
      expect(eq.test(a), closeTo(0.0, 1e-9));
      expect(eq.test(b), closeTo(0.0, 1e-9));
    });

    test('斜线 (0,0)-(3,4) 的斜率为 4/3', () {
      // A_coeff=4, B_coeff=-3, C=0 → slope=-A/B=4/3
      final eq = LineEquation.fromPoints(const Offset(0, 0), const Offset(3, 4));
      expect(eq.slope, closeTo(4.0 / 3, 1e-9));
    });

    test('水平线斜率为 0', () {
      final eq = LineEquation.fromPoints(const Offset(0, 3), const Offset(10, 3));
      expect(eq.slope, closeTo(0.0, 1e-9));
    });

    test('点在直线上，距离为 0', () {
      final eq = LineEquation.fromPoints(const Offset(0, 0), const Offset(0, 10));
      expect(eq.distanceFrom(const Offset(0, 5)), closeTo(0.0, 1e-9));
    });

    test('点到垂直线 x=0 的距离', () {
      // P=(3,0) → distance=3
      final eq = LineEquation.fromPoints(const Offset(0, 0), const Offset(0, 10));
      expect(eq.distanceFrom(const Offset(3, 0)), closeTo(3.0, 1e-9));
    });

    test('点到水平线 y=3 的距离', () {
      // P=(0,5) → distance=2
      final eq = LineEquation.fromPoints(const Offset(0, 3), const Offset(10, 3));
      expect(eq.distanceFrom(const Offset(0, 5)), closeTo(2.0, 1e-9));
    });

    test('distanceToLine 扩展方法与 LineEquation.distanceFrom 结果一致', () {
      const p = Offset(3, 0);
      const a = Offset(0, 0);
      const b = Offset(0, 10);
      expect(p.distanceToLine(a, b), closeTo(LineEquation.fromPoints(a, b).distanceFrom(p), 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // distancePointToExtendedLine / distanceToExtendedLine（无限延伸直线）
  // ---------------------------------------------------------------------------
  group('distancePointToExtendedLine', () {
    test('点在直线延长线上，距离为 0', () {
      // P=(-2,-2) 在 y=x 延长线（A 之前）上；sqrt 运算精度约 1e-7
      expect(distancePointToExtendedLine(const Offset(-2, -2), const Offset(0, 0), const Offset(8, 8)),
          closeTo(0.0, 1e-6));
    });

    test('点在线段内部，距离为 0', () {
      expect(
          distancePointToExtendedLine(const Offset(5, 5), const Offset(0, 0), const Offset(8, 8)), closeTo(0.0, 1e-6));
    });

    test('点垂直偏离水平线，距离等于垂直分量', () {
      // P=(3,5) 到 y=0 → 距离=5
      expect(
          distancePointToExtendedLine(const Offset(3, 5), const Offset(0, 0), const Offset(10, 0)), closeTo(5.0, 1e-9));
    });

    test('点垂直偏离竖直线，距离等于水平分量', () {
      // P=(3,5) 到 x=0 → 距离=3
      expect(
          distancePointToExtendedLine(const Offset(3, 5), const Offset(0, 0), const Offset(0, 10)), closeTo(3.0, 1e-9));
    });

    test('扩展方法 distanceToExtendedLine 与全局函数结果一致', () {
      const p = Offset(3, 7);
      const a = Offset(1, 2);
      const b = Offset(9, 4);
      expect(p.distanceToExtendedLine(a, b), closeTo(distancePointToExtendedLine(p, a, b), 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // distancePointToRayLine / distanceToRayLine（射线：从 A 向 B 方向无限延伸）
  // ---------------------------------------------------------------------------
  group('distancePointToRayLine', () {
    // 射线：从 A=(0,0) 向 B=(10,0) 方向延伸
    const a = Offset(0, 0);
    const b = Offset(10, 0);

    test('点在射线范围内（AB 之间），距离为 0', () {
      // P=(5,0): lenAP==lenAG → return 0
      expect(distancePointToRayLine(const Offset(5, 0), a, b), closeTo(0.0, 1e-9));
    });

    test('点在射线上（超出 B 之后），距离仍为 0', () {
      // 射线无限延伸；P=(15,0) → lenAP-lenAG=0 → return 0
      expect(distancePointToRayLine(const Offset(15, 0), a, b), closeTo(0.0, 1e-9));
    });

    test('点在 A 之前（反方向），距离为到 A 的距离', () {
      // P=(-5,0): dotProduct<0 → return |vAP|=5
      expect(distancePointToRayLine(const Offset(-5, 0), a, b), closeTo(5.0, 1e-9));
    });

    test('点垂直于射线，距离为垂直分量', () {
      // P=(5,5): lenPG=sqrt(50-25)=5
      expect(distancePointToRayLine(const Offset(5, 5), a, b), closeTo(5.0, 1e-9));
    });

    test('点在射线延长方向上方，仍可正确计算垂直距离', () {
      // P=(15,3): lenAG=15, lenAP=sqrt(234), lenPG=3
      expect(distancePointToRayLine(const Offset(15, 3), a, b), closeTo(3.0, 1e-9));
    });

    test('扩展方法 distanceToRayLine 与全局函数结果一致', () {
      const p = Offset(3, 4);
      expect(p.distanceToRayLine(a, b), closeTo(distancePointToRayLine(p, a, b), 1e-9));
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
  // rotateVector / Offset.rotate
  // ---------------------------------------------------------------------------
  group('rotateVector', () {
    test('旋转 0° 结果不变', () {
      const v = Offset(3, 4);
      final r = v.rotate(0);
      expect(r.dx, closeTo(3.0, 1e-9));
      expect(r.dy, closeTo(4.0, 1e-9));
    });

    test('(1,0) 旋转 90° 得 (0,1)', () {
      final r = const Offset(1, 0).rotate(math.pi / 2);
      expect(r.dx, closeTo(0.0, 1e-9));
      expect(r.dy, closeTo(1.0, 1e-9));
    });

    test('(5,0) 旋转 180° 得 (-5,0)', () {
      final r = const Offset(5, 0).rotate(math.pi);
      expect(r.dx, closeTo(-5.0, 1e-9));
      expect(r.dy, closeTo(0.0, 1e-6)); // sin(π) ≈ 1.2e-16
    });

    test('(1,0) 旋转 45° 得 (√2/2, √2/2)', () {
      final r = const Offset(1, 0).rotate(math.pi / 4);
      expect(r.dx, closeTo(math.sqrt2 / 2, 1e-9));
      expect(r.dy, closeTo(math.sqrt2 / 2, 1e-9));
    });

    test('旋转后向量长度不变', () {
      const v = Offset(3, 4);
      final r = v.rotate(math.pi / 3);
      expect(r.distance, closeTo(v.distance, 1e-9));
    });

    test('全局函数 rotateVector 与扩展方法 rotate 结果一致', () {
      const v = Offset(3, 4);
      const angle = 1.2;
      final r1 = rotateVector(v, angle);
      final r2 = v.rotate(angle);
      expect(r1.dx, closeTo(r2.dx, 1e-9));
      expect(r1.dy, closeTo(r2.dy, 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // Rect 扩展方法：include、includeDx、includeDy、origin、shiftYAxis、clampRect、hitTest
  // ---------------------------------------------------------------------------
  group('Rect extensions', () {
    // rect = Rect.fromLTRB(0, 0, 14, 10)

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
  // compareOffsetByAsc / compareOffsetByDesc
  // ---------------------------------------------------------------------------
  group('compareOffset', () {
    test('compareOffsetByAsc 使 sort 结果升序', () {
      final list = [const Offset(8, 8), const Offset(2, 2), const Offset(5, 5)];
      list.sort(compareOffsetByAsc);
      expect(list[0], equals(const Offset(2, 2)));
      expect(list[1], equals(const Offset(5, 5)));
      expect(list[2], equals(const Offset(8, 8)));
    });

    test('compareOffsetByDesc 使 sort 结果降序', () {
      final list = [const Offset(2, 2), const Offset(8, 8), const Offset(5, 5)];
      list.sort(compareOffsetByDesc);
      expect(list[0], equals(const Offset(8, 8)));
      expect(list[1], equals(const Offset(5, 5)));
      expect(list[2], equals(const Offset(2, 2)));
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
  // Parallelogram
  // ---------------------------------------------------------------------------
  group('Parallelogram', () {
    // A=(0,0), B=(10,0), P=(5,5) → 生成矩形通道 ABCD：(0,0),(10,0),(10,5),(0,5)
    const pA = Offset(0, 0);
    const pB = Offset(10, 0);
    const pP = Offset(5, 5);
    late Parallelogram pl;

    setUp(() {
      pl = Parallelogram.fromChannelPoint(pA, pB, pP);
    });

    test('fromChannelPoint 生成正确顶点', () {
      expect(pl.A, equals(pA));
      expect(pl.B, equals(pB));
      expect(pl.C.dx, closeTo(10.0, 1e-9));
      expect(pl.C.dy, closeTo(5.0, 1e-9));
      expect(pl.D.dx, closeTo(0.0, 1e-9));
      expect(pl.D.dy, closeTo(5.0, 1e-9));
    });

    test('points 返回长度为 4 的顶点列表', () {
      expect(pl.points.length, equals(4));
    });

    test('include（向量法）：内部点返回 true', () {
      expect(pl.include(const Offset(5, 2.5)), isTrue);
    });

    test('include（向量法）：超出 CD 边的点返回 false', () {
      expect(pl.include(const Offset(5, 7)), isFalse);
    });

    test('include（向量法）：超出 AD 边的点返回 false', () {
      expect(pl.include(const Offset(-1, 2)), isFalse);
    });

    test('include（LineEquation 法，带 deviation）：边界外微小偏移仍可命中', () {
      // P=(5,5.05) 稍超出 CD 边，deviation=0.2 时仍在通道内
      expect(pl.include(const Offset(5, 5.05), deviation: 0.2), isTrue);
    });

    test('include（LineEquation 法，带 deviation）：明显超出边界返回 false', () {
      expect(pl.include(const Offset(5, 10), deviation: 0.2), isFalse);
    });

    test('middleLine 位于 AB 与 CD 的中间（y=2.5）', () {
      final mid = pl.middleLine;
      expect(mid.length, equals(2));
      expect(mid[0].dy, closeTo(2.5, 1e-9));
      expect(mid[1].dy, closeTo(2.5, 1e-9));
    });

    test('bounds 包含所有四顶点', () {
      final bounds = pl.bounds;
      for (final point in pl.points) {
        expect(bounds.include(point), isTrue);
      }
    });

    test('genParalleChannelByLine 与 fromChannelPoint 等价', () {
      final pl2 = pP.genParalleChannelByLine(pA, pB);
      expect(pl2.C.dy, closeTo(pl.C.dy, 1e-9));
      expect(pl2.D.dy, closeTo(pl.D.dy, 1e-9));
    });

    test('isInsideOfParallelogramByVector：边界顶点视为在内', () {
      // 顶点 A 本身：s=0,t=0 → 在边界上
      expect(isInsideOfParallelogramByVector(pA, pl), isTrue);
    });

    test('isInsideParallelogramByLineEquation：内部点与向量法结论一致', () {
      const inside = Offset(5, 2.5);
      const outside = Offset(5, 7);
      expect(isInsideParallelogramByLineEquation(inside, pl), isTrue);
      expect(isInsideParallelogramByLineEquation(outside, pl), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // isInsideOfPolygon / Offset.isInsideOf
  // ---------------------------------------------------------------------------
  group('isInsideOfPolygon', () {
    // 闭合正方形（重复起点以覆盖全部 4 条边）
    final square = [
      const Offset(0, 0),
      const Offset(10, 0),
      const Offset(10, 10),
      const Offset(0, 10),
      const Offset(0, 0),
    ];

    test('内部点返回 true', () {
      expect(isInsideOfPolygon(const Offset(5, 5), square), isTrue);
    });

    test('外部点返回 false', () {
      expect(isInsideOfPolygon(const Offset(15, 5), square), isFalse);
      expect(isInsideOfPolygon(const Offset(-1, 5), square), isFalse);
    });

    test('顶点数不足 3 时返回 false', () {
      expect(
        isInsideOfPolygon(const Offset(0, 0), [const Offset(0, 0), const Offset(5, 5)]),
        isFalse,
      );
    });

    test('Offset.isInsideOf 与 isInsideOfPolygon 结果一致', () {
      const p = Offset(5, 5);
      expect(p.isInsideOf(square), equals(isInsideOfPolygon(p, square)));
    });
  });

  // ---------------------------------------------------------------------------
  // direction helper（探索性打印，有正确性验证）
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
