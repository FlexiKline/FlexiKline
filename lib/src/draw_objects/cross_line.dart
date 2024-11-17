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

import 'dart:ui';

import '../core/core.dart';
import '../extension/geometry_ext.dart';
import '../extension/render/draw_path.dart';
import '../framework/draw/overlay.dart';

class CrossLineDrawObject extends DrawObject {
  CrossLineDrawObject(super.overlay, super.config);

  @override
  bool hitTest(IDrawContext context, Offset position, {bool isMove = false}) {
    assert(
      points.length == 1,
      'CrossLine only takes one point, but it has ${points.length}',
    );
    final first = points.firstOrNull?.offset;
    if (first == null) return false;

    final mainRect = context.mainRect;
    if (mainRect.includeDx(first.dx) || mainRect.includeDy(first.dy)) {
      final deviation = isMove ? hitTestMinDistance * 10 : hitTestMinDistance;

      double distance = position.distanceToLine(
        Offset(mainRect.left, first.dy),
        Offset(mainRect.right, first.dy),
      );
      if (distance <= deviation) return true;

      distance = position.distanceToLine(
        Offset(first.dx, mainRect.top),
        Offset(first.dx, mainRect.bottom),
      );
      if (distance <= deviation) return true;
    }
    return false;
  }

  @override
  void draw(IDrawContext context, Canvas canvas, Size size) {
    assert(
      points.length == 1,
      'CrossLine only takes one point, but it has ${points.length}',
    );
    final first = points.firstOrNull?.offset;
    if (first == null) return;

    final mainRect = context.mainRect;
    if (mainRect.includeDx(first.dx) || mainRect.includeDy(first.dy)) {
      canvas.drawLineByConfig(
        Path()
          ..moveTo(mainRect.left, first.dy)
          ..lineTo(mainRect.right, first.dy)
          ..moveTo(first.dx, mainRect.top)
          ..lineTo(first.dx, mainRect.bottom),
        line,
      );
    }
  }
}
