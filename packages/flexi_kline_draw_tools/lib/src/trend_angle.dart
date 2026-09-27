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

import 'dart:math' as math;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';

import 'draw_param.dart';
import 'draw_tools_config.dart';

class TrendAngleDrawObject extends DrawObject {
  TrendAngleDrawObject(super.overlay, super.config);

  /// 趋势角度绘制参数。通过 [DrawToolsConfig.configure] 定制。
  static TrendAngleDrawParam get drawParam => DrawToolsConfig.instance.trendAngle;

  @override
  bool hitTest(DrawContext context, Offset position, {bool isMove = false}) {
    assertCheck();

    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) {
      return false;
    }

    final distance = position.distanceToLineSegment(first, second);
    return distance <= hitTestMinDistance;
  }

  @override
  void drawing(DrawContext context, Canvas canvas, Size size) {
    drawConnectingLine(context, canvas, size);
    final first = points.firstOrNull?.offset;
    final second = (points.secondOrNull ?? pointer)?.offset;
    if (first != null && second != null) {
      // 当指针2超出, 以指针1为中心和以弧度大小的矩形区域开始绘制.
      final incircleRect = Rect.fromCenter(
        center: first,
        width: drawParam.angleRadSize.width,
        height: drawParam.angleRadSize.height,
      );
      if (!incircleRect.contains(second)) {
        _drawAngleLineAndRadVal(context, canvas, first, second);
      }
      // 当趋势线长度 > 弧度半径时, 开始绘制
      // if ((second - first).length > drawParams.angleRadSize.longestSide) {
      //   _drawAngleLineAndRadVal(context, canvas, first, second);
      // }
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

    // 画TrendLine
    canvas.drawLineByConfig(
      Path()..addPolygon([first, second], false),
      line,
    );

    // 画基线与弧度
    _drawAngleLineAndRadVal(context, canvas, first, second);
  }

  /// 绘制以[A]的x轴水平方向的基线, 和与向量AB线的弧线与弧度值
  void _drawAngleLineAndRadVal(
    DrawContext context,
    Canvas canvas,
    Offset A,
    Offset B,
  ) {
    final vAB = B - A;
    final H = Offset(
      A.dx + math.max(drawParam.angleBaseLineMinLen, vAB.length),
      A.dy,
    );
    final vAH = H - A;

    // 画基线
    canvas.drawLineType(
      LineType.dashed, // 用虚线
      Path()..addPolygon([A, H], false),
      line.linePaint,
      dashes: line.dashes,
    );

    // 弧度
    final radians = vAH.angleToSigned(vAB);

    // 画弧线
    canvas.drawLineType(
      LineType.dashed, // 用虚线
      Path()..addArc(
        Rect.fromCenter(
          center: A,
          width: drawParam.angleRadSize.width,
          height: drawParam.angleRadSize.height,
        ),
        0,
        radians,
      ),
      line.linePaint,
      dashes: line.dashes,
    );

    // 画弧度值
    final radText = drawParam.angleText ?? ticksTextConfig;
    final radVal = (radians * -180 / math.pi).toStringAsFixed(2);
    canvas.drawTextArea(
      offset: Offset(
        A.dx + drawParam.angleBaseLineMinLen,
        A.dy - radText.areaHeight / 2,
      ),
      text: '$radVal°',
      textConfig: radText,
    );
  }
}
