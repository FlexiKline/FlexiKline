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
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rect = Rect.fromLTRB(0, 0, 14, 10);

  group('pointDistanceToLine', () {
    const offset = Offset(5, 5);
    Offset a;
    Offset b;
    double ret;
    test('test 点在线上', () {
      a = Offset(2, 2);
      b = Offset(8, 8);
      ret = distancePointToLineSegment(offset, a, b);
      debugPrint('$a -> $b = $ret');
    });

    test('test 2', () {
      a = Offset(5, 2);
      b = Offset(8, 8);
      ret = offset.distanceToLineSegment(a, b);
      debugPrint('$a -> $b = $ret');
    });

    test('test 3', () {
      a = Offset(5, 2);
      b = Offset(8, 8);
      ret = offset.distanceToLineSegment(a, b);
      debugPrint('$a -> $b = $ret');
    });
  });

  group('reflectPathOnRect', () {
    Offset A = Offset(5, 5);
    Offset B;

    double convertTo360Degrees(double radians) {
      double degrees = radians * (180 / math.pi); // 将弧度转换为度数
      double positiveDegrees = degrees < 0 ? 360 + degrees : degrees; // 将负值转换为正值

      return positiveDegrees % 360; // 将角度值限制在 0 到 360 度之间
    }

    void printDirection(Offset A, Offset B) {
      final vAB = B - A;
      final direction = (B - A).direction;
      final degrees = convertTo360Degrees(direction);
      debugPrint('$A - $B\t> k:${vAB.slope} \t:$degrees∘ \t:$direction');
    }

    /// PI * 0,         0.0
    /// PI * 1/4,       0.7853981633974483
    /// PI * 2/4,       1.5707963267948966
    /// PI * 3/4,       2.356194490192345
    /// PI * 4/4,       3.141592653589793
    /// PI * -3/4,      -2.356194490192345
    /// PI * -2/4,      -1.5707963267948966
    /// PI * -1/4,      -0.7853981633974483
    test('test PI', () {
      double val = -0.00000000;
      debugPrint(
          '$val -> ${val.sign} -> ${val.toString() == '-0.0'} -> ${val.toString() == '0.0'}');
      val = 0.0;
      debugPrint(
          '$val -> ${val.sign} -> ${val.toString() == '-0.0'} -> ${val.toString() == '0.0'}');
      debugPrint('PI * 0, \t${math.pi * 0}');
      debugPrint('PI * 1/4, \t${math.pi * 1 / 4}');
      debugPrint('PI * 2/4, \t${math.pi * 2 / 4}');
      debugPrint('PI * 3/4, \t${math.pi * 3 / 4}');
      debugPrint('PI * 4/4, \t${math.pi * 1}');
      debugPrint('PI * -3/4, \t${math.pi * -3 / 4}');
      debugPrint('PI * -2/4, \t${math.pi * -2 / 4}');
      debugPrint('PI * -1/4, \t${math.pi * -1 / 4}');
    });

    /// Offset(0.0, 0.0) - Offset(5.0, 0.0)     > k:0.0         :0.0∘   :0.0
    /// Offset(0.0, 0.0) - Offset(5.0, 5.0)     > k:1.0         :45.0∘  :0.7853981633974483
    /// Offset(0.0, 0.0) - Offset(0.0, 5.0)     > k:0.0         :90.0∘  :1.5707963267948966
    /// Offset(0.0, 0.0) - Offset(-5.0, 5.0)    > k:-1.0        :135.0∘ :2.356194490192345
    /// Offset(0.0, 0.0) - Offset(-5.0, 0.0)    > k:-0.0        :180.0∘ :3.141592653589793
    /// Offset(0.0, 0.0) - Offset(-5.0, -5.0)   > k:1.0         :225.0∘ :-2.356194490192345
    /// Offset(0.0, 0.0) - Offset(0.0, -5.0)    > k:0.0         :270.0∘ :-1.5707963267948966
    /// Offset(0.0, 0.0) - Offset(5.0, -5.0)    > k:-1.0        :315.0∘ :-0.7853981633974483
    test('test direction', () {
      A = Offset(0, 0);
      B = Offset(5, 0);
      printDirection(A, B);

      B = Offset(5, 5);
      printDirection(A, B);

      B = Offset(0, 5);
      printDirection(A, B);

      B = Offset(-5, 5);
      printDirection(A, B);

      B = Offset(-5, 0);
      printDirection(A, B);

      B = Offset(-5, -5);
      printDirection(A, B);

      B = Offset(0, -5);
      printDirection(A, B);

      B = Offset(5, -5);
      printDirection(A, B);
    });

    test('test direction2', () {
      bool compareVectorLength(double ab, double ac) {
        if (ab.sign != ac.sign) return false;
        if (ab.sign > 0) return ac > ab;
        if (ab.sign < 0) return ac < ab;
        return false;
      }

      void printResult(double a, double b, double c) {
        double ab = b - a;
        double ac = c - a;
        debugPrint('ab:$ab} vs ac:$ac = ${compareVectorLength(ab, ac)}');
      }

      printResult(5, 8, 14);
      printResult(5, 3, 2);
      printResult(2, 0, -2);
      printResult(-2, 0, 1);

      printResult(-5, -3, -2);
      printResult(4, 3, 8);
    });

    test('test reflectPointsOnRect Points A and B are inside the rect', () {
      List<Offset> points;
      A = Offset(5, 5);

      B = Offset(10, 6);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(5.0, 5.0), Offset(10.0, 6.0), Offset(14.0, 6.8)]

      B = Offset(6, 8);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(5.0, 5.0), Offset(6.0, 8.0), Offset(6.7, 10.0)]

      B = Offset(12, 2);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(5.0, 5.0), Offset(12.0, 2.0), Offset(14.0, 1.1)]

      B = Offset(7, 1);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(5.0, 5.0), Offset(7.0, 1.0), Offset(7.5, 0.0)]

      B = Offset(2, 5);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(5.0, 5.0), Offset(2.0, 5.0), Offset(0.0, 5.0)]

      B = Offset(7, 5);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(5.0, 5.0), Offset(7.0, 5.0), Offset(14.0, 5.0)]

      B = Offset(5, 2);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(5.0, 5.0), Offset(5.0, 2.0), Offset(5.0, 0.0)]

      B = Offset(5, 7);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(5.0, 5.0), Offset(5.0, 7.0), Offset(5.0, 10.0)]
    });

    test('test reflectPointsOnRect Point A or point B is outside the rect', () {
      List<Offset> points;

      /// 从左上向右下射线
      A = Offset(-5, -5);
      B = Offset(1, 1);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // 有重复>>> [Offset(1.0, 1.0), Offset(-0.0, 0.0), Offset(10.0, 10.0), Offset(0.0, 0.0)]

      B = Offset(-3, -2);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(5.0, 10.0), Offset(0.0, 2.5)]

      B = Offset(1, 4);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(1.0, 4.0), Offset(5.0, 10.0), Offset(0.0, 2.5)]

      B = Offset(-2, -3);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(2.5, 0.0), Offset(14.0, 7.7)]

      /// 从左下向右上射线
      A = Offset(-8, 18);
      B = Offset(-4, 16);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(8.0, 10.0), Offset(14.0, 7.0)]

      B = Offset(-7, 14);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // []

      B = Offset(-5, 14);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(5.5, 0.0), Offset(0.0, 7.3)]

      /// 从右上向左下射线
      A = Offset(16, -4);
      B = Offset(15, -1);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(11.3, 10.0), Offset(14.0, 2.0)]

      B = Offset(10, -2);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(4.0, 0.0), Offset(0.0, 1.3)]
    });

    test('test reflectPointsOnRect Point A or point B is vectical or horizonal', () {
      List<Offset> points;

      /// 从下向上射线
      A = Offset(7, 15);
      B = Offset(7, 13);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(7.0, 0.0), Offset(7.0, 10.0)]

      B = Offset(7, 8);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(7.0, 8.0), Offset(7.0, 0.0), Offset(7.0, 10.0)]

      A = Offset(7, 9);
      B = Offset(7, 8);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(7.0, 9.0), Offset(7.0, 8.0), Offset(7.0, 0.0)]

      /// 从上向下射线
      A = Offset(10, -6);
      B = Offset(10, -2);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(10.0, 0.0), Offset(10.0, 10.0)]

      B = Offset(10, 0);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // 有重复>>> [Offset(10.0, 0.0), Offset(10.0, 0.0), Offset(10.0, 10.0)]

      A = Offset(10, 1);
      B = Offset(10, 4);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(10.0, 1.0), Offset(10.0, 4.0), Offset(10.0, 10.0)]

      /// 从左向右射线
      A = Offset(-6, 4);
      B = Offset(-3, 4);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(0.0, 4.0), Offset(14.0, 4.0)]

      B = Offset(2, 4);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(2.0, 4.0), Offset(0.0, 4.0), Offset(14.0, 4.0)]

      A = Offset(1, 4);
      B = Offset(2, 4);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      // [Offset(1.0, 4.0), Offset(2.0, 4.0), Offset(14.0, 4.0)]

      /// 从右向左射线
      A = Offset(15, 4);
      B = Offset(1, 4);
      points = reflectPointsOnRect(A, B, rect);
      debugPrint(points.toString());
      //[Offset(1.0, 4.0), Offset(0.0, 4.0), Offset(14.0, 4.0)]
    });
  });

  group('pointReflectInRect', () {
    const rect = Rect.fromLTRB(0.5, 0.8, 14, 10);
    final offset = Offset(5, 5);
    test('reflectInRect', () {
      Offset other = Offset(10, 6);
      Offset ret = offset.reflectRectSide(other, rect);
      debugPrint("1>$ret"); // 14, 6.8

      other = Offset(6, 8);
      ret = offset.reflectRectSide(other, rect);
      debugPrint("2>$ret"); // 6.7, 10.0

      other = Offset(12, 2);
      ret = offset.reflectRectSide(other, rect);
      debugPrint("3>$ret"); // 14.0, 1.1

      other = Offset(7, 1);
      ret = offset.reflectRectSide(other, rect);
      debugPrint("4>$ret"); // 7.5, 0.0
    });

    test('reflectInRect2', () {
      Offset other = Offset(10, 6);
      Offset ret = other.reflectRectSide(offset, rect);
      debugPrint("1>$ret"); // 0.0, 4.0

      other = Offset(6, 8);
      ret = other.reflectRectSide(offset, rect);
      debugPrint("2>$ret"); // 3.3, 0.0

      other = Offset(12, 2);
      ret = other.reflectRectSide(offset, rect);
      debugPrint("3>$ret"); // 0.0, 7.1

      other = Offset(7, 1);
      ret = other.reflectRectSide(offset, rect);
      debugPrint("4>$ret"); // 2.5, 10.0
    });

    test('reflectInRect vertical horizontal', () {
      Offset other = Offset(2, 5);
      Offset ret = offset.reflectRectSide(other, rect);
      debugPrint("1>$ret"); // 0.0, 5.0

      other = Offset(7, 5);
      ret = offset.reflectRectSide(other, rect);
      debugPrint("2>$ret"); // 14.0, 5.0

      other = Offset(5, 2);
      ret = offset.reflectRectSide(other, rect);
      debugPrint("3>$ret"); // 5.0, 0.0

      other = Offset(5, 7);
      ret = offset.reflectRectSide(other, rect);
      debugPrint("4>$ret"); // 5.0, 10
    });

    test('reflectInRect outside', () {
      Offset other = Offset(2, 5);
      Offset ret = offset.reflectRectSide(other, rect);
      debugPrint("1>$ret"); // 0.0, 5.0

      other = Offset(7, 5);
      ret = offset.reflectRectSide(other, rect);
      debugPrint("2>$ret"); // 14.0, 5.0

      other = Offset(5, 2);
      ret = offset.reflectRectSide(other, rect);
      debugPrint("3>$ret"); // 5.0, 0.0

      other = Offset(5, 7);
      ret = offset.reflectRectSide(other, rect);
      debugPrint("4>$ret"); // 5.0, 10
    });
  });

  group('getDxByDy', () {
    test('getDxByDy', () {
      double dx = getDxAtDyOnAB(Offset(20, 20), Offset(0, 0), 10);
      debugPrint("offset:$dx"); // 10.0

      dx = getDxAtDyOnAB(Offset(0, 0), Offset(20, 20), 10);
      debugPrint("offset:$dx"); // 10.0

      dx = getDxAtDyOnAB(Offset(0, 0), Offset(0, 20), 10);
      debugPrint("offset:$dx"); // 10

      dx = getDxAtDyOnAB(Offset(0, 20), Offset(20, 20), 10);
      debugPrint("offset:$dx"); // 0
    });
  });
}
