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

import 'draw_param.dart';
import 'draw_tools_config.dart';

class RectangleDrawObject extends DrawObject {
  RectangleDrawObject(super.overlay, super.config);

  static RectangleDrawParam get drawParam => DrawToolsConfig.instance.rectangle;

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
  bool hitTest(DrawContext context, Offset position, {bool isMove = false}) {
    assertCheck();

    final rectangle = getRectangleRect();
    if (rectangle == null) return false;

    return rectangle.include(position);
  }

  @override
  void drawing(DrawContext context, Canvas canvas, Size size) {
    if (isReady) {
      final rectangle = getRectangleRect();
      if (rectangle == null) return;

      _drawRectangle(context, canvas, rectangle);
    }
    drawConnectingLine(context, canvas, size);
  }

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    assertCheck();

    final rectangle = getRectangleRect();
    if (rectangle == null) return;

    _drawRectangle(context, canvas, rectangle);
  }

  /// 绘制平行四边形
  void _drawRectangle(
    DrawContext context,
    Canvas canvas,
    Rect rect,
  ) {
    /// 画填充背景
    canvas.drawPath(
      Path()..addRect(rect),
      line.linePaint
        ..color =
            line.paint.color?.withAlpha(
              drawParam.rectangleBgOpacity.alpha,
            ) ??
            transparent
        ..style = PaintingStyle.fill,
    );

    /// 画矩形四条边线
    canvas.drawLineByConfig(
      Path()..addRect(rect),
      line,
    );
  }
}
