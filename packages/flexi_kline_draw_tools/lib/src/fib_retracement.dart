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

/// 斐波那契回撤绘图对象（2 点）。
class FibRetracementDrawObject extends DrawObject {
  FibRetracementDrawObject(super.overlay, super.config);

  /// 斐波那契扩展绘制参数。通过 [DrawToolsConfig.configure] 定制。
  static FibonacciDrawParam get drawParam => DrawToolsConfig.instance.fibRetracement;

  /// 默认 11 个比率, 留余量给自定义比率。
  late final _labels = own(LabelPainter(capacity: 16));
  final _fill = Paint()..style = PaintingStyle.fill;

  @override
  bool hitTest(DrawContext context, Offset position, {bool isMove = false}) {
    assertCheck();
    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) return false;

    return Rect.fromPoints(first, second).include(position);
  }

  @override
  void drawing(DrawContext context, Canvas canvas, Size size) {
    if (isReady) {
      final first = allPoints.firstOrNull?.offset;
      final second = allPoints.secondOrNull?.offset;
      if (first == null || second == null) return;
      _drawFibonacciLevel(context, canvas, first, second);
    }
    drawConnectingLine(context, canvas, size);
  }

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    assertCheck();

    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) return;

    _drawFibConnectingLine(canvas, [first, second]);
    _drawFibonacciLevel(context, canvas, first, second);
  }

  void _drawFibConnectingLine(Canvas canvas, List<Offset> pts) {
    if (pts.length < 2) return;
    canvas.drawLineType(
      LineType.dashed,
      Path()..addPolygon(pts, false),
      line.linePaint,
      dashes: line.dashes,
    );
  }

  /// 绘制斐波那契回撤水平线（A→B 区间）。
  void _drawFibonacciLevel(
    DrawContext context,
    Canvas canvas,
    Offset A,
    Offset B,
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
    final dyLen = A.dy - B.dy;
    Offset start, end;

    // 各比率颜色不同: 颜色进 key 与 span, 样式共用一份, 否则每画一个比率就清一次缓存。
    final style = fibText.toLabelStyle();
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
          _fill..color = color.withAlpha(fibBgOpacity.alpha),
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
        final textColor = fibTextColor ?? color;
        _labels.paint(
          canvas,
          (rate, value, precision, textColor),
          build: () => TextSpan(
            text: '$rate(${formatValueTicksText(value, precision: precision)})',
            style: TextStyle(color: textColor),
          ),
          style: style,
          anchor: Offset(txtOffsetDx, dy),
          align: Alignment.centerRight,
        );
      }
    }
  }
}
