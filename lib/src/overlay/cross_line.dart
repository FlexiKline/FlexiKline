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

import '../core/interface.dart';
import '../extension/geometry_ext.dart';
import '../extension/render/draw_path.dart';
import '../framework/overlay.dart';

class CrossLineDrawObject extends DrawObject {
  CrossLineDrawObject(super.overlay);

  @override
  bool hitTest(
    IDrawContext context,
    Offset position, {
    bool isMove = false,
  }) {
    final point = points.first;
    if (point == null) return false;
    final offset = point.offset;
    final mainRect = context.mainRect;
    if (mainRect.includeDx(offset.dx) || mainRect.includeDy(offset.dy)) {
      double distance = position.distanceToLine(
        Offset(mainRect.left, offset.dy),
        Offset(mainRect.right, offset.dy),
      );
      final hitTestMinDistance = isMove
          ? context.config.hitTestMinDistance * 10
          : context.config.hitTestMinDistance;
      if (distance <= hitTestMinDistance) {
        return true;
      }
      distance = position.distanceToLine(
        Offset(offset.dx, mainRect.top),
        Offset(offset.dx, mainRect.bottom),
      );
      if (distance <= hitTestMinDistance) {
        return true;
      }
    }
    return false;
  }

  @override
  void draw(IDrawContext context, Canvas canvas, Size size) {
    assert(
      points.length == 1,
      'CrossLine only takes one point, but it has ${points.length}',
    );
    final point = points.first;
    if (point == null) {
      context.logi('draw($type), not found point!');
      return;
    }
    final mainRect = context.mainRect;
    final offset = point.offset;
    if (mainRect.includeDx(offset.dx) || mainRect.includeDy(offset.dy)) {
      canvas.drawLineType(
        line.type,
        Path()
          ..moveTo(mainRect.left, offset.dy)
          ..lineTo(mainRect.right, offset.dy)
          ..moveTo(offset.dx, mainRect.top)
          ..lineTo(offset.dx, mainRect.bottom),
        line.linePaint,
      );
    }
  }
}
