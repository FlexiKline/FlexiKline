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

import 'package:flutter/painting.dart';

/// 折线 prev -> [vertex] -> next 在 [vertex] 处以 [radius] 倒圆后的两个切点与圆弧。
///
/// 切点到顶点的距离 = r / tan(半顶角), 夹到两邻边较短者的一半, 圆弧随之缩小; 圆弧方向由转向决定
/// (屏幕坐标 y 向下), 凸角与凹角通用。[radius] 不大于 0、邻边退化或三点共线时返回 null, 调用方直接连到顶点。
({Offset start, Offset end, Radius radius, bool clockwise})? roundCorner(
  Offset prev,
  Offset vertex,
  Offset next,
  double radius,
) {
  if (radius <= 0) return null;
  final toPrev = prev - vertex;
  final toNext = next - vertex;
  // 叉积 (vertex - prev) x toNext, 正为顺时针转向。
  final turn = toPrev.dy * toNext.dx - toPrev.dx * toNext.dy;
  if (toPrev.distance == 0 || toNext.distance == 0 || turn == 0) return null;

  final unitPrev = toPrev / toPrev.distance;
  final unitNext = toNext / toNext.distance;
  final halfAngle = math.acos((unitPrev.dx * unitNext.dx + unitPrev.dy * unitNext.dy).clamp(-1.0, 1.0)) / 2;
  final distance = math.min(radius / math.tan(halfAngle), math.min(toPrev.distance, toNext.distance) / 2);
  return (
    start: vertex + unitPrev * distance,
    end: vertex + unitNext * distance,
    radius: Radius.circular(distance * math.tan(halfAngle)),
    clockwise: turn > 0,
  );
}

extension PathCorner on Path {
  /// 从当前点经 [vertex] 折向 [next], 在 [vertex] 处倒圆; [prev] 是当前点所在边的起点(只用于求角度)。
  ///
  /// 不能倒圆时直接连到 [vertex]。
  void cornerTo(Offset prev, Offset vertex, Offset next, double radius) {
    final corner = roundCorner(prev, vertex, next, radius);
    if (corner == null) {
      lineTo(vertex.dx, vertex.dy);
      return;
    }
    lineTo(corner.start.dx, corner.start.dy);
    arcToPoint(corner.end, radius: corner.radius, clockwise: corner.clockwise);
  }
}
