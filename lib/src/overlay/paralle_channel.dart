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

import 'package:flexi_kline/src/utils/export.dart';

import '../core/interface.dart';
import '../extension/export.dart';
import '../framework/overlay.dart';

class ParalleChannelDrawObject extends DrawObject {
  ParalleChannelDrawObject(super.overlay);

  @override
  bool hitTest(IDrawContext context, Offset position, {bool isMove = false}) {
    assert(
      points.length == 3,
      'ParalleChannel hitTest points.length:${points.length} must be equals 3',
    );
    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    final third = points.thirdOrNull?.offset;
    if (first == null || second == null || third == null) {
      return false;
    }

    List<Offset> parallePoints = genParalleChannelPoints(first, second, third);

    return pointIsInsideParalle(
      position,
      parallePoints[0],
      parallePoints[1],
      parallePoints[2],
      parallePoints[3],
    );
  }

  @override
  void draw(IDrawContext context, Canvas canvas, Size size) {
    assert(
      points.length == 3,
      'ParalleChannel draw points.length:${points.length} must be equals 3',
    );

    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    final third = points.thirdOrNull?.offset;
    if (first == null || second == null || third == null) {
      return;
    }

    // 画线
    canvas.drawLineType(
      line.type,
      Path()..addPolygon([first, second], false),
      line.linePaint,
    );

    // 绘制平行通道
    _drawParallChannel(context, canvas, first, second, third);
  }

  void _drawParallChannel(
    IDrawContext context,
    Canvas canvas,
    Offset A,
    Offset B,
    Offset P,
  ) {
    final k = (B - A).slope;
    final b = P.dy - P.dx * k;
    final A1 = Offset(A.dx, k * A.dx + b);
    final B1 = Offset(B.dx, k * B.dx + b);

    canvas.drawPoints(
      PointMode.points,
      [
        A1,
        B1,
      ],
      Paint()
        ..color = const Color(0xFFFF0000)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke,
    );
  }
}
