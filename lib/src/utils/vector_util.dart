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

import '../constant.dart';
import '../extension/geometry_ext.dart';

/// 直线的一般式方程 Ax + By + C = 0
final class LineEquation {
  const LineEquation._(
    this.A,
    this.B,
    this.C,
  ) : assert(A != 0 || B != 0, 'A and B cannot both be 0');

  factory LineEquation.fromPoints(Offset p1, Offset p2) {
    return LineEquation._(
      p2.dy - p1.dy,
      p1.dx - p2.dx,
      -p1.cross(p2),
    );
  }

  final double A;
  final double B;
  final double C;

  /// 斜率
  double get slope => B != 0 ? -A / B : 0;

  /// 计算点[point]在直线一般式方程中的结果
  double test(Offset point) {
    return A * point.dx + B * point.dy + C;
  }

  double get sqrtaabb => math.sqrt(A * A + B * B);

  /// 计算点[point]到直线的距离
  double distanceFrom(Offset point) {
    return test(point).abs() / sqrtaabb;
  }
}

/// 计算Y轴坐标[dy]在由[A]-[B]两点组成的直线的斜率上对应的X轴坐标[dx]
double getDxAtDyOnAB(Offset A, Offset B, double dy) {
  if (A.dy == B.dy) return A.dx;
  if (A.dx == B.dx) return dy;
  final k = (B.dy - A.dy) / (B.dx - A.dx);
  return (dy - B.dy) / k + B.dx;
}

/// 计算X轴坐标[dx]在由[A]-[B]两点组成的直线的斜率上对应的Y轴坐标[dy]
double getDyAtDxOnAB(Offset A, Offset B, double dx) {
  if (A.dy == B.dy) return A.dy;
  if (A.dx == B.dx) return dx;
  final k = (B.dy - A.dy) / (B.dx - A.dx);
  return (dx - B.dx) * k + B.dy;
}

/// 计算点[P]到由[A]  与[B]两点组成延长线的距离
double distancePointToExtendedLine(Offset P, Offset A, Offset B) {
  final vAB = B - A;
  final vAP = P - A;

  final dotProduct = vAB.dot(vAP);
  final lenAB = vAB.length;
  final lenAG = dotProduct / lenAB;
  final lenAP = vAP.length;

  // 计算点P在AB上的垂线PG
  final lenPG = math.sqrt(lenAP * lenAP - lenAG * lenAG);
  return lenPG;
}

/// 计算点[P]到由[A]与[B]两点组成射线的距离
double distancePointToRayLine(Offset P, Offset A, Offset B) {
  final vAB = B - A;
  final vAP = P - A;

  final dotProduct = vAB.dot(vAP);
  if (dotProduct <= 0) {
    // AP与AB的夹角为垂直或钝角, 取AP长度.
    return vAP.length;
  }

  final lenAB = vAB.length;
  final lenAG = dotProduct / lenAB;
  final lenAP = vAP.length;
  if (lenAP - lenAG < precisionError) {
    // 锐角情况下, AP与AG相等, 说明点P在点AB上.
    return 0;
  }

  // 计算点P在AB上的垂线PG
  final lenPG = math.sqrt(lenAP * lenAP - lenAG * lenAG);
  return lenPG;
}

/// 计算点[P]到由[A]与[B]两点组成线段的距离
/// 注: 如果超出[A]-[B]计算到[A]或[B]的距离
/// 点积公式: AB∙AP = |AB| × |AP| × cos𝜃 = |AB| × |AG|
/// 注: AG为AP在AB上投影; PG为P点到AB上的垂线
/// dotProduct: 为AP与AB上的点积结果
/// 1. dotProduct < 0: AP与AB方向相反, 取AP的长度.
/// 2. dotProduct == 0: AP垂直于AB, 取AP的长度.
///
/// 点到线公式: sqrt√(|AP|² - |AP∙ū|²)
/// ū: AB上的单位向量
double distancePointToLineSegment(Offset P, Offset A, Offset B) {
  final vAB = B - A;
  final vAP = P - A;

  final dotProduct = vAB.dot(vAP);
  if (dotProduct <= 0) {
    // AP与AB的夹角为垂直或钝角, 取AP长度.
    return vAP.length;
  }

  final lenAB = vAB.length;
  final lenAG = dotProduct / lenAB;
  if (lenAG - lenAB > precisionError) {
    // 投影AG大于AB长度, 说明超出AB范围, 取BP长度.
    return (P - B).length;
  }

  final lenAP = vAP.length;
  if (lenAP - lenAG < precisionError) {
    // 锐角情况下, AP与AG相等, 说明点P在点AB上.
    return 0;
  }

  // 计算点P在AB上的垂线PG
  final lenPG = math.sqrt(lenAP * lenAP - lenAG * lenAG);
  return lenPG;
}

/// 计算[A]与[B]两点射在[rect]上的路径.
Path? reflectPathOnRect(Offset A, Offset B, Rect rect) {
  final points = reflectPointsOnRect(A, B, rect);
  if (points.isEmpty) return null;
  return Path()..addPolygon(points, false);
}

/// 以[base]为基点, 以[sign]为方向, 判断[p]是否在此方向上
bool _isExtendPoint(double base, double sign, double p) {
  if (sign > 0) return p > base;
  if (sign < 0) return p < base;
  return false;
}

/// 计算[A]与[B]两点射在[rect]上的坐标集合.
/// 以canvas绘制建立2D坐标系: 左上角为原点, 向右为x轴, 向下为y轴
/// 公式: y = kx + b; x = (y - b) / k;
/// 斜率: k = (By-Ay) / (Bx-Ax)
/// 截距: b = By - Bx * k = Ay - Ax * k
List<Offset> reflectPointsOnRect(
  Offset A,
  Offset B,
  Rect rect, {
  Comparator<Offset>? compare,
}) {
  final vAB = B - A;
  final k = vAB.dx == 0 ? 0 : vAB.dy / vAB.dx;
  final b = B.dy - B.dx * k;

  final points = <Offset>[];

  if (rect.include(A)) points.add(A);
  if (rect.include(B)) points.add(B);
  final dxLen = vAB.dx;
  final dyLen = vAB.dy;

  /// top
  double dx = k != 0 ? (rect.top - b) / k : B.dx;
  if (rect.includeDx(dx) && _isExtendPoint(A.dy, dyLen, rect.top)) {
    points.add(Offset(dx, rect.top));
  }

  /// bottom
  dx = k != 0 ? dx = (rect.bottom - b) / k : B.dx;
  if (rect.includeDx(dx) && _isExtendPoint(A.dy, dyLen, rect.bottom)) {
    points.add(Offset(dx, rect.bottom));
  }

  /// left
  double dy = rect.left * k + b;
  if (rect.includeDy(dy) && _isExtendPoint(A.dx, dxLen, rect.left)) {
    points.add(Offset(rect.left, dy));
  }

  /// right
  dy = rect.right * k + b;
  if (rect.includeDy(dy) && _isExtendPoint(A.dx, dxLen, rect.right)) {
    points.add(Offset(rect.right, dy));
  }

  if (compare != null) {
    return points..sort(compare);
  }
  return points;
}

/// 升序(从小到大)
int compareOffsetByAsc(Offset a, Offset b) {
  return a >= b ? 1 : -1;
}

/// 降序(从大到小)
int compareOffsetByDesc(Offset a, Offset b) {
  return b >= a ? 1 : -1;
}

/// 计算由点[P]到点[O]组成的线射在[rect]边上的坐标
/// 约定: 点[P]与点[O]均在[rect]内
/// 公式: y = kx + b; x = (y - b) / k
/// k: 斜率 k = (Oy-Py) / (Ox-Px)
/// b: 截距 b = Oy - Ox * k = Py - Px * k
/// 以canvas绘制建立2D坐标系: 左上角为原点, 向右为x轴, 向下为y轴
/// 当abs(k) > 1 线会落在上下边;
/// 当abs(k) < 1 线会落在左右边;
Offset reflectToRectSide(Offset P, Offset O, Rect rect) {
  assert(rect.include(P), 'Point P is not in the rect!');
  // assert(rect.include(O), 'Point O is not in the rect!');
  if (O.dy == P.dy) {
    if (O.dx == P.dx) {
      return Offset(P.dx, P.dy);
    } else if (O.dx > P.dx) {
      return Offset(rect.right, P.dy);
    } else {
      return Offset(rect.left, P.dy);
    }
  } else if (O.dx == P.dx) {
    if (O.dy == P.dy) {
      return Offset(P.dx, P.dy);
    } else if (O.dy > P.dy) {
      return Offset(P.dx, rect.bottom);
    } else {
      return Offset(P.dx, rect.top);
    }
  }
  final k = (O - P).slope;
  final b = O.dy - O.dx * k;
  if (k.abs() > 1) {
    if (O.dy < P.dy) {
      final x = (rect.top - b) / k;
      return Offset(x, rect.top); // top
    } else {
      final x = (rect.bottom - b) / k;
      return Offset(x, rect.bottom);
    }
  } else {
    if (O.dx < P.dx) {
      final y = rect.top * k + b;
      return Offset(rect.top, y); // left
    } else {
      final y = rect.right * k + b;
      return Offset(rect.right, y);
    }
  }
}

const pi0 = 0; //                     0∘|360∘
const pi15 = math.pi * (1 / 12); //   15∘
const pi30 = math.pi * (1 / 6); //    30∘
const pi45 = math.pi * (1 / 4); //    45∘
const pi60 = math.pi * (2 / 6); //    60∘
const pi90 = math.pi * (3 / 6); //    90∘
const pi120 = math.pi * (4 / 6); //   120∘
const pi135 = math.pi * (3 / 4); //   135∘
const pi150 = math.pi * (5 / 6); //   150∘
const pi165 = math.pi * (11 / 12); // 165∘
const pi180 = math.pi; //             180∘

/// 向量旋转[radians]弧度
/// 设当前向量AB为(x, y)旋转角度为𝜃, 根据向量旋转公式:
/// x' = x*cos𝜃 - y*sin𝜃
/// y' = x*sin𝜃 + y*cos𝜃
/// 旋转后的向量为(x', y')
Offset rotateVector(Offset v, double radians) {
  final sin = math.sin(radians);
  final cos = math.cos(radians);
  return Offset(
    v.dx * cos - v.dy * sin,
    v.dx * sin + v.dy * cos,
  );
}

/// 判断点[P]是否在多边形内.
/// 原理: 四边形内的点都在顺时针或逆时针边的同一边，即夹角都小于0或者都大于0，向量积同向。
/// 设: AB为多边形由顶点A到顶点B的一条边, res为AB与AP的叉积, 其结果:
/// res > 0, AP在AB的逆时针方向
/// res = 0, AB和AP共线
/// res < 0, AP在AB的顺时针方向
bool isInsideOfPolygon(Offset P, List<Offset> vertexes) {
  if (vertexes.length <= 2) return false;
  double cross1, cross2;
  bool res1 = true, res2 = true;
  Offset end, start = vertexes.first;
  for (int i = 1; i < vertexes.length; i++) {
    end = vertexes[i];
    cross1 = cross2 = (end - start).cross(P - start);
    res1 = res1 && cross1 >= 0;
    res2 = res2 && cross2 <= 0;
    if (!res1 && !res2) return false;
    start = end;
  }
  return res1 || res2;
}

/// 平行四边行
final class Parallelogram {
  Parallelogram._(this.A, this.B, this.C, this.D);

  /// 以[A]和[B]组成的线为平行四边形底边, 创建与[P]点平行的平行四边行ABCD.
  /// 其中AD两点和BC两点dx相同, 即垂直于2D坐标系.
  factory Parallelogram.fromChannelPoint(Offset A, Offset B, Offset P) {
    final k = (B - A).slope;
    final b = P.dy - P.dx * k;
    return Parallelogram._(
      A,
      B,
      Offset(B.dx, k * B.dx + b),
      Offset(A.dx, k * A.dx + b),
    );
  }

  final Offset A;
  final Offset B;
  final Offset C;
  final Offset D;

  List<Offset> get points => [A, B, C, D];

  /// 判断[point]坐标是否在平行四边行通道内
  /// [deviation]表示允许的最大偏差.
  bool include(Offset point, {double? deviation}) {
    if (deviation != null && deviation > 0) {
      // return isInsideParallelogramByGeometry(
      //   point,
      //   this,
      //   deviation: deviation,
      // );
      return isInsideParallelogramByLineEquation(
        point,
        this,
        deviation: deviation,
      );
    }
    return isInsideOfParallelogramByVector(point, this);
  }

  /// 以AB为底边, 获取平行四边行AB边与CD边的平均分隔线
  List<Offset> get middleLine {
    final k = (B - A).slope;
    final center = (A + B + C + D) / 4;
    final b = center.dy - center.dx * k;
    return [
      Offset(B.dx, k * B.dx + b),
      Offset(A.dx, k * A.dx + b),
    ];
  }

  Rect get bounds {
    return Rect.fromPoints(A, B).expandToInclude(Rect.fromPoints(C, D));
  }
}

/// 判断点[P]是否在平行四边形[pl]内(平面向量法)
bool isInsideOfParallelogramByVector(Offset P, Parallelogram pl) {
  final vAB = pl.B - pl.A;
  final vAD = pl.D - pl.A;
  final vAP = P - pl.A;
  final denominator = vAB.cross(vAD);
  final s = vAP.cross(vAD) / denominator;
  final t = vAB.cross(vAP) / denominator;

  return s >= 0 && s <= 1 && t >= 0 && t <= 1;
}

/// 判断点[P]是否在平行四边形[pl]内(平面解析几何法)
/// 原理: 由点[P]到点O1和点O2拉两条线;
///       O1位AD线上, O1P平行于AB; O2位于AB线上, O2P平行于AD;
///       如果点P在平行四边形内部, 则O1在[A, D]之间, O2在[A, B]之间.
/// AB斜率 = (yb-ya)/(xb-xa) = kAB = kO1P = (yp - y1) / (xp - x1)
/// AD斜率 = (yd-ya)/(xd-xa) = kAD = kO2P = (yp - y2) / (xp - x2)
/// AB截距 = bAB = ya - xa * kAB
/// AD截距 = bAD = ya - xa * kAD
/// O1P截距 = b1 = yp - yx * kAB
/// O2P截距 = b2 = yp - yx * kAD
/// 与AB平行时:
/// x1 = (y1 - b1) / kAB
/// y1 = kAB * x1 + b1
/// x2 = (y2 - b2) / kAD
/// y2 = kAD * x2 + b2
/// 与AD平行时:
/// x1 = (y1 - bAD) / kAD
/// y1 = kAD * x1 + bAD
/// x2 = (y2 - bAB) / kAB
/// y2 = kAB * x2 + bAB
/// 则:
/// x1 = (kAD * x1 + bAD - b1) / kAB
/// x1 * kAB - kAD * x1 = bAD - b1
/// x1 = (bAD - b1) / (kAB - kAD)
/// x2 = (kAB * x2 + bAB - b2) / kAD
/// x2 * kAD - kAB * x2 = bAB - b2
/// x2 = (bAB - b2) / (kAD - kAB)
bool isInsideParallelogramByGeometry(
  Offset P,
  Parallelogram pl, {
  double deviation = precisionError,
}) {
  final vAB = pl.B - pl.A;
  final kAB = vAB.slope;
  final vAD = pl.D - pl.A;
  final kAD = vAD.slope;

  final bAD = pl.A.dy - pl.A.dx * kAD;
  final b1 = P.dy - P.dx * kAB;
  double x1, y1; // 点O1(x1, y1) 在AD线上, 且O1P平行于AB.
  if (vAD.dx == 0) {
    x1 = pl.A.dx;
    y1 = kAB * x1 + b1;
  } else if (vAD.dy == 0) {
    y1 = pl.A.dy;
    x1 = (y1 - b1) / kAB;
  } else if (vAB.dx == 0) {
    x1 = P.dx;
    y1 = kAD * x1 + bAD;
  } else if (vAB.dy == 0) {
    y1 = P.dy;
    x1 = (y1 - bAD) / kAD;
  } else {
    x1 = (bAD - b1) / (kAB - kAD);
    y1 = kAB * x1 + b1;
  }
  final xADLen = vAD.dx.abs() + deviation;
  // 判断x1坐标是否在[A.dx, D.dx]之间, 并且具有一定的偏差[deviation]
  if ((x1 - pl.A.dx).abs() > xADLen || (x1 - pl.D.dx).abs() > xADLen) {
    return false;
  }
  final yADLen = vAD.dy.abs() + deviation;
  // 判断y1坐标是否在[A.dy, D.dy]之间, 并且具有一定的偏差[deviation]
  if ((y1 - pl.A.dy).abs() > yADLen || (y1 - pl.D.dy).abs() > yADLen) {
    return false;
  }

  final bAB = pl.A.dy - pl.A.dx * kAB;
  final b2 = P.dy - P.dx * kAD;
  double x2, y2; // 点O2(x2, y2) 在AB线上, 且O2P平行于AD.
  if (vAB.dx == 0) {
    x2 = pl.A.dx;
    y2 = kAD * x2 + b2;
  } else if (vAB.dy == 0) {
    y2 = pl.A.dy;
    x2 = (y2 - b2) / kAD;
  } else if (vAD.dx == 0) {
    x2 = P.dx;
    y2 = kAB * x2 + bAB;
  } else if (vAD.dy == 0) {
    y2 = P.dy;
    x2 = (y2 - bAB) / kAB;
  } else {
    x2 = (bAB - b2) / (kAD - kAB);
    y2 = kAD * x2 + b2;
  }
  final xABLen = vAB.dx.abs() + deviation;
  // 判断x2坐标是否在[A.dx, B.dx]之间, 并且具有一定的偏差[deviation]
  if ((x2 - pl.A.dx).abs() > xABLen || (x2 - pl.B.dx).abs() > xABLen) {
    return false;
  }
  final yABLen = vAB.dy.abs() + deviation;
  // 判断y2坐标是否在[A.dy, B.dy]之间, 并且具有一定的偏差[deviation]
  if ((y2 - pl.A.dy).abs() > yABLen || (y2 - pl.B.dy).abs() > yABLen) {
    return false;
  }

  return true;
}

/// 判断点[point]是否在平行四边形[pl]内(直线一般方程)
/// 原理: 计算点[point]到两条平行线的垂线距离, 如果超出了平行线间的距离(加上[deviation]偏差), 则判定点[point]不在平行四边形内.
bool isInsideParallelogramByLineEquation(
  Offset point,
  Parallelogram pl, {
  double deviation = precisionError,
}) {
  final lineAB = LineEquation.fromPoints(pl.A, pl.B);
  final lineDC = LineEquation.fromPoints(pl.D, pl.C);
  double sqrtaabb = lineAB.sqrtaabb;
  double dist = (lineAB.C - lineDC.C).abs() / sqrtaabb + deviation;
  if (lineAB.test(point).abs() / sqrtaabb > dist || lineDC.test(point).abs() / sqrtaabb > dist) {
    return false;
  }

  final lineAD = LineEquation.fromPoints(pl.A, pl.D);
  final lineBC = LineEquation.fromPoints(pl.B, pl.C);
  sqrtaabb = lineAD.sqrtaabb;
  dist = (lineAD.C - lineBC.C).abs() / lineAD.sqrtaabb + deviation;
  if (lineAD.test(point).abs() / sqrtaabb > dist || lineBC.test(point).abs() / sqrtaabb > dist) {
    return false;
  }

  return true;
}
