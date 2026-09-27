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

import 'package:flexi_kline/flexi_kline.dart';

class HorizontalRayLineDrawObject extends DrawObject {
  HorizontalRayLineDrawObject(super.overlay, super.config);

  @override
  bool hitTest(DrawContext context, Offset position, {bool isMove = false}) {
    assertCheck();

    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) {
      return false;
    }

    final distance = position.distanceToRayLine(first, second);
    return distance <= hitTestMinDistance;
  }

  /// 保持两点共 dy，规则同 [HorizontalTrendLineDrawObject.onUpdateDrawPoint]。
  @override
  void onUpdateDrawPoint(Point point, Offset offset) {
    final first = points.firstOrNull;
    if (first == null || point.index == first.index) {
      super.onUpdateDrawPoint(point, offset);
      for (final other in points) {
        if (other == null || other.index == point.index) continue;
        super.onUpdateDrawPoint(other, Offset(other.offset.dx, offset.dy));
      }
    } else {
      super.onUpdateDrawPoint(point, Offset(offset.dx, first.offset.dy));
    }
  }

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    assertCheck();

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
