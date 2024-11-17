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
import '../extension/export.dart';
import '../framework/draw/overlay.dart';
import '../utils/vector_util.dart';

class ParalleChannelDrawObject extends DrawObject {
  ParalleChannelDrawObject(super.overlay, super.config);

  Parallelogram? getParalleChannel() {
    final points = allPoints;
    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    final third = points.thirdOrNull?.offset;
    if (first == null || second == null || third == null) {
      return null;
    }
    return third.genParalleChannelByLine(first, second);
  }

  @override
  Rect? getTicksMarksBounds() {
    final channel = getParalleChannel();
    if (channel == null) return null;
    return channel.bounds;
  }

  @override
  bool hitTest(IDrawContext context, Offset position, {bool isMove = false}) {
    assert(
      points.length == 3,
      'ParalleChannel hitTest points.length:${points.length} must be equals 3',
    );
    final channel = getParalleChannel();
    if (channel == null) return false;

    return channel.include(position, deviation: hitTestMinDistance);
  }

  @override
  void drawing(IDrawContext context, Canvas canvas, Size size) {
    if (isReady) {
      final channel = getParalleChannel();
      if (channel == null) return;

      _drawParallChannel(context, canvas, channel);
    }
    drawConnectingLine(context, canvas, size);
  }

  @override
  void draw(IDrawContext context, Canvas canvas, Size size) {
    assert(
      points.length == 3,
      'ParalleChannel draw points.length:${points.length} must be equals 3',
    );

    final channel = getParalleChannel();
    if (channel == null) return;

    _drawParallChannel(context, canvas, channel);
  }

  /// 绘制平行通道
  void _drawParallChannel(
    IDrawContext context,
    Canvas canvas,
    Parallelogram channel,
  ) {
    /// 填充通道
    canvas.drawPath(
      Path()..addPolygon(channel.points, true),
      line.linePaint
        ..color = line.paint.color.withOpacity(
          drawParams.paralleBgOpacity,
        )
        ..style = PaintingStyle.fill,
    );

    // 画中线
    canvas.drawLineType(
      LineType.dashed,
      Path()..addPolygon(channel.middleLine, false),
      line.linePaint,
      dashes: line.dashes,
    );

    // 画基线AB
    canvas.drawLineByConfig(
      Path()..addPolygon([channel.A, channel.B], false),
      line,
    );

    /// 画平行线CD
    canvas.drawLineByConfig(
      Path()..addPolygon([channel.C, channel.D], false),
      line,
    );
  }
}
