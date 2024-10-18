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
import '../framework/draw/overlay.dart';

class HorizontalLineDrawObject extends DrawObject {
  HorizontalLineDrawObject(super.overlay, super.config);

  @override
  bool hitTest(IDrawContext context, Offset position, {bool isMove = false}) {
    assert(
      points.length == 1,
      'HorizontalLine only takes one point, but it has ${points.length}',
    );
    final first = points.firstOrNull?.offset;
    if (first == null) return false;

    final dy = first.dy;
    final mainRect = context.mainRect;
    if (!mainRect.includeDy(dy)) return false;

    final distance = position.distanceToLine(
      Offset(mainRect.left, dy),
      Offset(mainRect.right, dy),
    );
    return distance <= hitTestMinDistance;
  }

  @override
  void draw(IDrawContext context, Canvas canvas, Size size) {
    assert(
      points.length == 1,
      'HorizontalLine only takes one point, but it has ${points.length}',
    );
    final first = points.firstOrNull?.offset;
    if (first == null) return;

    final mainRect = context.mainRect;
    final dy = first.dy;
    if (!mainRect.includeDy(dy)) {
      context.logi('draw($type), but dy:$dy not in mainRect.');
      return;
    }

    canvas.drawLineByConfig(
      Path()
        ..addPolygon(
          [Offset(mainRect.left, dy), Offset(mainRect.right, dy)],
          false,
        ),
      line,
    );
  }
}
