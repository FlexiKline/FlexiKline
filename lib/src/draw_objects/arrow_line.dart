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
import '../extension/export.dart';
import '../framework/draw/overlay.dart';

class ArrowLineDrawObject extends DrawObject {
  ArrowLineDrawObject(super.overlay, super.config);

  @override
  bool hitTest(IDrawContext context, Offset position, {bool isMove = false}) {
    assert(
      points.length == 2,
      'ArrowLine hitTest points.length:${points.length} must be equals 2',
    );
    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) {
      return false;
    }

    final distance = position.distanceToRayLine(first, second);
    return distance <= hitTestMinDistance;
  }

  @override
  void draw(IDrawContext context, Canvas canvas, Size size) {
    assert(
      points.length == 2,
      'RayLine draw points.length:${points.length} must be equals 2',
    );

    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) {
      return;
    }

    // 画线
    canvas.drawLineByConfig(
      Path()..addPolygon([first, second], false),
      line,
    );

    // 画箭头
    final drawRect = context.mainRect;
    if (drawRect.contains(second)) {
      final vector = (first - second).normalized() * drawParams.arrowsLen;
      final arrow1 = vector.rotate(drawParams.arrowsRadians) + second;
      final arrow2 = vector.rotate(-drawParams.arrowsRadians) + second;

      canvas.drawLineByConfig(
        Path()..addPolygon([second, arrow1], false),
        line,
      );
      canvas.drawLineByConfig(
        Path()..addPolygon([second, arrow2], false),
        line,
      );
    }
  }
}
