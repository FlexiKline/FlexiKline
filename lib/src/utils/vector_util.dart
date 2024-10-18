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

import '../extension/geometry_ext.dart';

const double precisionError = 0.000001;

/// 计算点[P]到由[A]与[B]两点组成延长线的距离
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
double distancePointToLine(Offset P, Offset A, Offset B) {
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

  bool pointInside(Offset point) {
    return isInsideOfParallelogram(point, this);
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
bool isInsideOfParallelogram(Offset P, Parallelogram pl) {
  final vAB = pl.B - pl.A;
  final vAD = pl.D - pl.A;
  final vAP = P - pl.A;
  final denominator = vAB.cross(vAD);
  final s = vAP.cross(vAD) / denominator;
  final t = vAB.cross(vAP) / denominator;

  return s >= 0 && s <= 1 && t >= 0 && t <= 1;
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
    cross1 = cross2 = (end - start).cross((P - start));
    res1 = res1 && cross1 >= 0;
    res2 = res2 && cross2 <= 0;
    if (!res1 && !res2) return false;
    start = end;
  }
  return res1 || res2;
}

/// 判断点[P]是否在平行四边形[pl]内(平面解析几何法)
/// 由点P按AB斜率(等于DC/CD的斜率)计算点P的截距, 然后再比较AD
bool isInsideParallelogramByGeometry(Offset P, Parallelogram pl) {
  double k = (pl.B - pl.A).slope; // vAB与vDC的斜率相等
  double b1 = pl.A.dy - pl.A.dx * k;
  double b2 = pl.D.dy - pl.D.dx * k;
  double bp = P.dy - P.dx * k;
  if ((bp - b1).sign == (bp - b2).sign) {
    return false;
  }

  k = (pl.D - pl.A).slope; // vAD与vBC的斜率相等
  b1 = pl.A.dy - pl.A.dx * k;
  b2 = pl.C.dy - pl.C.dx * k;
  bp = P.dy - P.dx * k;
  if ((bp - b1).sign == (bp - b2).sign) {
    return false;
  }

  return true;
}
