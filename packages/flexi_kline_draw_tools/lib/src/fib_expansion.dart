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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';

import 'draw_param.dart';
import 'draw_tools_config.dart';

class FibExpansionDrawObject extends DrawObject {
  FibExpansionDrawObject(super.overlay, super.config);

  /// 斐波那契扩展绘制参数。通过 [DrawToolsConfig.configure] 定制。
  static FibonacciDrawParam get drawParam => DrawToolsConfig.instance.fibExpansion;

  @override
  bool hitTest(DrawContext context, Offset position, {bool isMove = false}) {
    assertCheck();

    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) return false;
    if (position.distanceToLineSegment(first, second) <= hitTestMinDistance) {
      return true;
    }

    final third = points.thirdOrNull?.offset;
    if (third == null) return false;
    return Rect.fromPoints(second, third).include(position);
  }

  @override
  void drawing(DrawContext context, Canvas canvas, Size size) {
    if (isReady) {
      final points = allPoints;
      final first = points.firstOrNull?.offset;
      final second = points.secondOrNull?.offset;
      final third = points.thirdOrNull?.offset;
      if (first == null || second == null || third == null) {
        return;
      }
      _drawFibonacciLevel(context, canvas, second, third, second.dy - first.dy);
    }
    drawConnectingLine(context, canvas, size);
  }

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    assertCheck();

    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    final third = points.thirdOrNull?.offset;
    if (first == null || second == null || third == null) {
      return;
    }

    _drawFibConnectingLine(canvas, [first, second, third]);
    _drawFibonacciLevel(context, canvas, second, third, second.dy - first.dy);
  }

  void _drawFibConnectingLine(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;
    canvas.drawLineType(
      LineType.dashed,
      Path()..addPolygon(points, false),
      line.linePaint,
      dashes: line.dashes,
    );
  }

  /// 绘制斐波那契水平线。
  void _drawFibonacciLevel(
    DrawContext context,
    Canvas canvas,
    Offset A,
    Offset B,
    double? dyLen,
  ) {
    final precision = context.klineData.precision;
    final fibRates = drawParam.fibRates;
    final fibText = drawParam.fibText;
    final fibTextColor = fibText.style.color != null && fibText.style.color!.a != 0 ? fibText.style.color : null;
    final fibBgOpacity = drawParam.fibBgOpacity;
    final fibColors = drawParam.fibColors;
    final colors = fibColors.isNotEmpty ? fibColors : [line.paint.color ?? context.theme.drawToolColor];
    int i = 0;
    List<Offset> linePoints = [];

    final dxLen = B.dx - A.dx;
    dyLen ??= A.dy - B.dy;
    Offset start, end;

    final txtHeightOffset = fibText.areaHeight / 2;
    final txtOffsetDx = dxLen >= 0 ? A.dx : B.dx;

    for (final rate in fibRates) {
      final dy = B.dy + dyLen * rate;
      start = Offset(B.dx, dy);
      end = Offset(B.dx - dxLen, dy);

      final color = colors[i++ % colors.length];
      if (fibBgOpacity > 0) {
        /// 填充背景
        canvas.drawPath(
          Path()..addPolygon([...linePoints, end, start], true),
          Paint()
            ..color = color.withAlpha(fibBgOpacity.alpha)
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
        final text = formatValueTicksText(value, precision: precision);
        canvas.drawTextArea(
          text: '$rate($text)',
          drawDirection: DrawDirection.rtl,
          offset: Offset(txtOffsetDx, dy - txtHeightOffset),
          textConfig: fibText.copyWith(
            style: fibText.style.copyWith(color: fibTextColor ?? color),
          ),
        );
      }
    }
  }
}
