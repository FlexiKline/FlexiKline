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
import '../config/text_area_config/text_area_config.dart';
import '../data/export.dart';
import '../extension/export.dart';
import '../framework/overlay.dart';

class FibRetracementDrawObject extends DrawObject {
  FibRetracementDrawObject(super.overlay);

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
      'FibRetracement hitTest points.length:${points.length} must be equals 2',
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
      _drawFibRetracement(context, canvas, first, second);
    }
    super.drawing(context, canvas, size);
  }

  @override
  void draw(IDrawContext context, Canvas canvas, Size size) {
    assert(
      points.length == 2,
      'FibRetracement draw points.length:${points.length} must be equals 2',
    );

    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) {
      return;
    }

    _drawFibRetracement(context, canvas, first, second);
  }

  /// 绘制斐波那契回撤
  void _drawFibRetracement(
    IDrawContext context,
    Canvas canvas,
    Offset first,
    Offset second,
  ) {
    final drawParams = context.config.drawParams;
    final precision = context.curKlineData.precision;
    final fibRates = drawParams.fibRetracementRates;
    final fibText = drawParams.fibRateText;
    final fibOpacity = drawParams.fibBgOpacity;
    final fibColors = drawParams.fibColors;
    final colors = fibColors.isNotEmpty ? fibColors : [line.paint.color];
    int i = 0;
    List<Offset> linePoints = [];

    final dxLen = second.dx - first.dx;
    final dyLen = first.dy - second.dy;
    Offset start, end;

    final txtHeightOffset = fibText.areaHeight / 2;
    final txtOffsetDx = dxLen >= 0 ? first.dx : second.dx;

    for (var rate in fibRates) {
      final dy = second.dy + dyLen * rate;
      start = Offset(second.dx, dy);
      end = Offset(second.dx - dxLen, dy);

      final color = colors[i++ % colors.length];
      if (fibOpacity > 0) {
        /// 填充背景
        canvas.drawPath(
          Path()..addPolygon([...linePoints, end, start], true),
          Paint()
            ..color = color.withOpacity(fibOpacity)
            ..style = PaintingStyle.fill,
        );
      }
      linePoints = [start, end];

      /// 画比率线
      canvas.drawLineType(
        line.type,
        Path()..addPolygon(linePoints, false),
        line.linePaint..color = color,
        dashes: line.dashes,
      );

      /// 画比率值
      final value = context.dyToValue(start.dy);
      if (value != null) {
        final text = formatValueTick(value, precision: precision);
        canvas.drawTextArea(
          text: '$rate($text)',
          drawDirection: DrawDirection.rtl,
          offset: Offset(txtOffsetDx, dy - txtHeightOffset),
          textConfig: fibText.copyWith(
            style: fibText.style.copyWith(color: color),
          ),
        );
      }
    }
  }
}
