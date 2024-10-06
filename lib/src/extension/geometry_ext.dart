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

import '../utils/vector_util.dart';

extension RectExt on Rect {
  /// Whether the point specified by the given offset (which is assumed to be
  /// relative to the origin) lies between the left and right and the top and
  /// bottom edges of this rectangle.
  ///
  /// Rectangles include their top, left, bottom and right edges.
  bool include(Offset offset) {
    return offset.dx >= left &&
        offset.dx <= right &&
        offset.dy >= top &&
        offset.dy <= bottom;
  }

  bool includeDx(double dx) {
    return dx >= left && dx <= right;
  }

  bool includeDy(double dy) {
    return dy >= top && dy <= bottom;
  }

  Offset get origin => Offset(left, top);

  Rect shiftYAxis(double height) {
    return Rect.fromLTRB(left, math.min(top + height, bottom), right, bottom);
  }

  Rect clampRect(Rect rect) {
    return Rect.fromLTRB(
      left.clamp(rect.left, rect.right),
      top.clamp(rect.top, rect.bottom),
      right.clamp(rect.left, rect.right),
      bottom.clamp(rect.top, rect.bottom),
    );
  }
}

extension OffsetExt on Offset {
  Offset clamp(Rect rect) {
    return Offset(
      dx.clamp(rect.left, rect.right),
      dy.clamp(rect.top, rect.bottom),
    );
  }

  double get length => distance;

  /// Normalize this.
  Offset normalized() {
    final l = distance;
    if (l == 0.0) {
      return Offset.zero;
    }
    final d = 1.0 / l;
    return this * d;
  }

  /// Distance from this to [arg]
  double distanceTo(Offset arg) => (this - arg).distance;

  /// Returns the angle between this vector and [other] in radians.
  double angleTo(Offset other) {
    if (dy == other.dy && dx == other.dx) {
      return 0.0;
    }

    final d = dot(other) / (distance * other.distance);

    return math.acos(d.clamp(-1.0, 1.0));
  }

  /// Returns the signed angle between this and [other] in radians.
  double angleToSigned(Offset other) {
    if (dy == other.dy && dx == other.dx) {
      return 0.0;
    }

    final s = cross(other);
    final c = dot(other);

    return math.atan2(s, c);
  }

  /// 点乘 Inner product.
  double dot(Offset other) {
    return dy * other.dy + dx * other.dx;
  }

  /// 叉乘 Cross product.
  double cross(Offset other) {
    return dx * other.dy - dy * other.dx;
  }

  /// 当前坐标P到由[A]与[B]两点组成线的距离
  double distanceToLine(Offset A, Offset B) {
    return distancePointToLine(this, A, B);
  }

  /// 当前坐标P到由[A]与[B]两点组成延长线的距离
  double distanceToExtendedLine(Offset A, Offset B) {
    return distancePointToExtendedLine(this, A, B);
  }

  /// 将当前坐标到[other]组成的线映射向[rect]边上的坐标
  Offset reflectRectSide(Offset other, Rect rect) {
    return reflectToRectSide(this, other, rect);
  }

  /// 斜率
  double get slope {
    if (dx == 0) return 0;
    return dy / dx;
  }
}

extension SizeExt on Size {
  bool get nonzero => width > 0 || height > 0;
}
