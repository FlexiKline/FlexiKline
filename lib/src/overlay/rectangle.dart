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
import '../framework/overlay.dart';

class RectangleDrawObject extends DrawObject {
  RectangleDrawObject(super.overlay);

  Rect? getRectangleRect() {
    final points = allPoints;
    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) {
      return null;
    }
    return Rect.fromPoints(first, second);
  }

  @override
  bool hitTest(IDrawContext context, Offset position, {bool isMove = false}) {
    assert(
      points.length == 2,
      'Rectangle hitTest points.length:${points.length} must be equals 2',
    );
    final rectangle = getRectangleRect();
    if (rectangle == null) return false;

    return rectangle.include(position);
  }

  @override
  void drawing(IDrawContext context, Canvas canvas, Size size) {
    super.drawing(context, canvas, size);
    if (isReady) {
      final rectangle = getRectangleRect();
      if (rectangle == null) return;

      _drawParallChannel(context, canvas, rectangle);
    }
  }

  @override
  void draw(IDrawContext context, Canvas canvas, Size size) {
    assert(
      points.length == 2,
      'Rectangle draw points.length:${points.length} must be equals 2',
    );

    final rectangle = getRectangleRect();
    if (rectangle == null) return;

    _drawParallChannel(context, canvas, rectangle);
  }

  /// 绘制平行通道
  void _drawParallChannel(
    IDrawContext context,
    Canvas canvas,
    Rect rect,
  ) {
    /// 画填充背景
    canvas.drawPath(
      Path()..addRect(rect),
      line.linePaint
        ..color = line.paint.color.withOpacity(
          context.config.drawParams.paralleBgOpacity,
        )
        ..style = PaintingStyle.fill,
    );

    /// 画矩形四条边线
    canvas.drawLineType(
      line.type,
      Path()..addRect(rect),
      line.linePaint,
    );
  }
}
