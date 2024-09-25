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

double precisionError = 0.000001;

/// 计算点[P]到由[A]与[B]两点组成线的距离
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
    // 投影AG大于AB长度, 说明超出AB范围, 取BP长试.
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

const pi0 = math.pi * 0; // 0∘ | 360∘
const pi1_4 = math.pi * 0.25; // 45∘
const pi2_4 = math.pi * 0.5; // 90∘
const pi3_4 = math.pi * 0.75; // 135∘
const pi1 = math.pi; // 180∘
const pi_3_4 = math.pi * -0.75; // 225∘
const pi_2_4 = math.pi * -0.5; // 270∘
const pi_1_4 = math.pi * -0.25; // 315∘

/// 计算[A]与[B]两点射在[rect]上的路径.
Path? reflectPathOnRect(Offset A, Offset B, Rect rect) {
  final points = reflectPointsOnRect(A, B, rect);
  if (points.isEmpty) return null;
  return Path()..addPolygon(points, false);
}

/// 判断向量V2长度[v2Len]是否大于向量V1的长度[v1Len]
bool _compareVectorLength(double v1Len, double v2Len) {
  if (v1Len.sign != v2Len.sign) return false;
  if (v1Len == 0 && v2Len == 0) return true;
  if (v1Len.sign > 0) return v2Len > v1Len;
  if (v1Len.sign < 0) return v2Len < v1Len;
  return false;
}

/// 计算[A]与[B]两点射在[rect]上的坐标集合.
/// 公式: y = kx + b; x = (y - b) / k;
/// 斜率: k = (By-Ay) / (Bx-Ax)
/// 截距 b = By - Bx * k = Ay - Ax * k
List<Offset> reflectPointsOnRect(Offset A, Offset B, Rect rect) {
  final vAB = B - A;
  // final direction = vAB.direction;
  final k = vAB.dx == 0 ? 0 : vAB.dy / vAB.dx;
  final b = B.dy - B.dx * k;

  List<Offset> points = [];

  if (rect.include(A)) points.add(A);
  if (rect.include(B)) points.add(B);
  final dxLen = vAB.dx;
  final dyLen = vAB.dy;

  /// 垂线
  if (k == 0) {
    if (A.dx == B.dx && rect.includeDx(A.dx)) {
      // 垂直线
      if (_compareVectorLength(dyLen, 0 - A.dy)) {
        points.add(Offset(A.dx, 0)); // top
      }
      if (_compareVectorLength(dyLen, rect.bottom - A.dy)) {
        points.add(Offset(A.dx, rect.bottom)); // bottom
      }
    } else if (A.dy == B.dy && rect.includeDy(A.dy)) {
      // 水平线
      if (_compareVectorLength(dxLen, 0 - A.dx)) {
        points.add(Offset(0, A.dy)); // left
      }
      if (_compareVectorLength(dxLen, rect.right - A.dx)) {
        points.add(Offset(rect.right, A.dy)); // right
      }
    }
    return points;
  }

  /// top
  double dx = k != 0 ? -b / k : B.dx;
  if (rect.includeDx(dx) && _compareVectorLength(dxLen, dx - A.dx)) {
    points.add(Offset(dx, 0));
  }

  /// bottom
  dx = k != 0 ? dx = (rect.bottom - b) / k : B.dx;
  if (rect.includeDx(dx) && _compareVectorLength(dxLen, dx - A.dx)) {
    points.add(Offset(dx, rect.bottom));
  }

  /// left
  double dy = b;
  if (rect.includeDy(dy) && _compareVectorLength(dyLen, dy - A.dy)) {
    points.add(Offset(0, dy));
  }

  /// right
  dy = rect.right * k + b;
  if (rect.includeDy(dy) && _compareVectorLength(dyLen, dy - A.dy)) {
    points.add(Offset(rect.right, dy));
  }

  return points;
}

/// 计算点[P]与点[O]组成的线射向[rect]边上的坐标
/// 公式 y = kx + b; x = (y - b) / k
/// k: 斜率 k = (Oy-Py) / (Ox-Px)
/// b: 截距 b = Oy - Ox * k = Py - Px * k
/// 以canvas绘制建立2D坐标系: 左上角为原点, 向右为x轴, 向下为y轴
/// 当abs(k) > 1 线会落在上下边;
/// 当abs(k) < 1 线会落在左右边;
Offset reflectPointOnRect(Offset P, Offset O, Rect rect) {
  if (O.dy == P.dy) {
    if (O.dx == P.dx) {
      return Offset(P.dx, P.dy);
    } else if (O.dx > P.dx) {
      return Offset(rect.right, P.dy);
    } else {
      return Offset(0, P.dy);
    }
  } else if (O.dx == P.dx) {
    if (O.dy == P.dy) {
      return Offset(P.dx, P.dy);
    } else if (O.dy > P.dy) {
      return Offset(P.dx, rect.bottom);
    } else {
      return Offset(P.dx, 0);
    }
  }
  final k = (O - P).slope;
  final b = O.dy - O.dx * k;
  if (k.abs() > 1) {
    if (O.dy < P.dy) {
      final x = -b / k;
      return Offset(x, 0); // top
    } else {
      final x = (rect.bottom - b) / k;
      return Offset(x, rect.bottom);
    }
  } else {
    if (O.dx < P.dx) {
      final y = b;
      return Offset(0, y); // left
    } else {
      final y = rect.right * k + b;
      return Offset(rect.right, y);
    }
  }
}
