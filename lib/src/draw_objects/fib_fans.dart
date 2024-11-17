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
import '../config/text_area_config/text_area_config.dart';
import '../extension/export.dart';
import '../framework/draw/overlay.dart';
import '../utils/export.dart';

class FibFansDrawObject extends DrawObject {
  FibFansDrawObject(super.overlay, super.config);

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
      'FibFans hitTest points.length:${points.length} must be equals 2',
    );
    final rectangle = getRectangleRect();
    if (rectangle == null) return false;

    return rectangle.include(position);
  }

  @override
  void drawing(IDrawContext context, Canvas canvas, Size size) {
    if (isReady) {
      final points = allPoints;
      final first = points.firstOrNull?.offset;
      final second = points.secondOrNull?.offset;
      if (first == null || second == null) {
        return;
      }
      _drawFibFans(context, canvas, first, second);
    }
    drawConnectingLine(context, canvas, size);
  }

  @override
  void draw(IDrawContext context, Canvas canvas, Size size) {
    assert(
      points.length == 2,
      'FibFans draw points.length:${points.length} must be equals 2',
    );

    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) {
      return;
    }

    _drawFibFans(context, canvas, first, second);
  }

  /// 绘制斐波那契扇形
  void _drawFibFans(
    IDrawContext context,
    Canvas canvas,
    Offset A,
    Offset B,
  ) {
    final mainRect = context.mainRect;
    final fibFansParams = drawParams.fibFansParams;
    final fibText = drawParams.fibText;
    final fibTextColor =
        fibText.style.color != null && fibText.style.color!.alpha != 0
            ? fibText.style.color
            : null;
    final fibGridColor = drawParams.fibFansGridColor;
    final isDrawGrid = fibGridColor != null && fibGridColor.alpha != 0;
    final fibColors = drawParams.fibFansColors;
    final colors = fibColors.isNotEmpty ? fibColors : [line.paint.color];
    int i = 0;

    final dxLen = B.dx - A.dx;
    final dyLen = B.dy - A.dy;
    Offset fans1, fans2, hori, vert;
    double dx, dy;

    final areaHeight = fibText.areaHeight;
    final txtHalft = areaHeight / 2;
    final txtHeight = dyLen >= 0 ? areaHeight : 0;
    final vertTxtDirection = dxLen >= 0 ? DrawDirection.rtl : DrawDirection.ltr;

    for (var rate in fibFansParams) {
      dx = A.dx + dxLen * rate;
      dy = A.dy + dyLen * rate;
      hori = Offset(dx, A.dy);
      vert = Offset(A.dx, dy);
      fans1 = Offset(B.dx, dy);
      fans2 = Offset(dx, B.dy);

      if (isDrawGrid) {
        /// 画扇形网格线
        canvas.drawLineType(
          line.type,
          Path()..addPolygon([vert, fans1], false),
          line.linePaint..color = fibGridColor,
          dashes: line.dashes,
        );
        canvas.drawLineType(
          line.type,
          Path()..addPolygon([hori, fans2], false),
          line.linePaint..color = fibGridColor,
          dashes: line.dashes,
        );
      }

      final color = colors[i++ % colors.length];

      /// 画扇形线
      final fnas1Points = reflectPointsOnRect(A, fans1, mainRect);
      canvas.drawLineType(
        line.type,
        Path()..addPolygon(fnas1Points, false),
        line.linePaint..color = color,
        dashes: line.dashes,
      );
      final fnas2Points = reflectPointsOnRect(A, fans2, mainRect);
      canvas.drawLineType(
        line.type,
        Path()..addPolygon(fnas2Points, false),
        line.linePaint..color = color,
        dashes: line.dashes,
      );

      /// 画扇形参数值
      canvas.drawTextArea(
        text: cutInvalidZero(rate),
        drawDirection: DrawDirection.center,
        offset: Offset(dx, A.dy - txtHeight),
        textConfig: fibText.copyWith(
          style: fibText.style.copyWith(color: fibTextColor ?? color),
        ),
      );
      canvas.drawTextArea(
        text: cutInvalidZero(rate),
        drawDirection: vertTxtDirection,
        offset: Offset(A.dx, dy - txtHalft),
        textConfig: fibText.copyWith(
          style: fibText.style.copyWith(color: fibTextColor ?? color),
        ),
      );
    }
  }
}
