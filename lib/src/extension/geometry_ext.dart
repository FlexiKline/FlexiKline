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

import 'package:flutter/material.dart';

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

  bool inclueDx(double dx) {
    return dx >= left && dx <= right;
  }

  bool inclueDy(double dy) {
    return dy >= top && dy <= bottom;
  }

  Offset get origin => Offset(left, top);

  Rect shiftYAxis(double height) {
    return Rect.fromLTRB(left, math.min(top + height, bottom), right, bottom);
  }
}

extension OffsetExt on Offset {
  Offset clamp(Rect rect) {
    return Offset(
      dx.clamp(rect.left, rect.right),
      dy.clamp(rect.top, rect.bottom),
    );
  }
}

extension SizeExt on Size {
  bool get nonzero => width > 0 || height > 0;
}
