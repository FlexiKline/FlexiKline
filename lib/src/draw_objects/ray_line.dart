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
import '../utils/vector_util.dart';

class RayLineDrawObject extends DrawObject {
  RayLineDrawObject(super.overlay);

  @override
  bool hitTest(IDrawContext context, Offset position, {bool isMove = false}) {
    assert(
      points.length == 2,
      'RayLine hitTest points.length:${points.length} must be equals 2',
    );
    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) {
      return false;
    }

    final distance = position.distanceToRayLine(first, second);
    return distance <= context.config.hitTestMinDistance;
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

    final mainRect = context.mainRect;
    final list = reflectPointsOnRect(first, second, mainRect);

    canvas.drawLineByConfig(
      Path()..addPolygon(list, false),
      line,
    );
  }
}
