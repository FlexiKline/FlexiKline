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

class ExtendedTrendLineDrawObject extends DrawObject {
  ExtendedTrendLineDrawObject(super.overlay, super.config);

  @override
  bool hitTest(DrawContext context, Offset position, {bool isMove = false}) {
    assertCheck();

    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) {
      return false;
    }

    final distance = position.distanceToLine(first, second);
    return distance <= hitTestMinDistance;
  }

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    assertCheck();

    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) {
      return;
    }

    // 整条直线裁到主区: 两个绘制点只定方向, 画出的是两端都到边界的线段。
    final segment = clipLineToRect(first, second, context.mainRect);
    if (segment.isEmpty) return;

    canvas.drawLineByConfig(
      Path()..addPolygon(segment, false),
      line,
    );
  }
}
