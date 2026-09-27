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

class ParallelChannelDrawObject extends DrawObject {
  ParallelChannelDrawObject(super.overlay, super.config);

  static ParallelChannelDrawParam get drawParam => DrawToolsConfig.instance.parallelChannel;

  Parallelogram? getParallelChannel() {
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
    final channel = getParallelChannel();
    if (channel == null) return null;
    return channel.bounds;
  }

  @override
  bool hitTest(DrawContext context, Offset position, {bool isMove = false}) {
    assertCheck();
    final channel = getParallelChannel();
    if (channel == null) return false;

    return channel.include(position, deviation: hitTestMinDistance);
  }

  @override
  void drawing(DrawContext context, Canvas canvas, Size size) {
    if (isReady) {
      final channel = getParallelChannel();
      if (channel == null) return;

      _drawParallelChannel(context, canvas, channel);
      _drawThirdPointConnectingLine(canvas, channel);
    }
    drawConnectingLine(context, canvas, size);
  }

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    assertCheck();

    final channel = getParallelChannel();
    if (channel == null) return;

    _drawParallelChannel(context, canvas, channel);
    // 移动只发生在选中对象上, 选中态已覆盖 moving.
    if (context.isSelectedDrawObject(this)) {
      _drawThirdPointConnectingLine(canvas, channel);
    }
  }

  /// 绘制平行通道
  void _drawParallelChannel(
    DrawContext context,
    Canvas canvas,
    Parallelogram channel,
  ) {
    /// 填充通道
    canvas.drawPath(
      Path()..addPolygon(channel.points, true),
      line.linePaint
        ..color =
            line.paint.color?.withAlpha(
              drawParam.parallelBgOpacity.alpha,
            ) ??
            transparent
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

  /// 绘制第三点到平行线CD的连接线.
  ///
  /// 第三点决定CD边的位置, 但自身可落在CD横向范围之外, 此时通道上看不出这个点归谁,
  /// 补一条到就近端点的连接线. 三点共线, 所以连接线与CD同向, 视觉上是CD的延长段.
  void _drawThirdPointConnectingLine(Canvas canvas, Parallelogram channel) {
    final third = allPoints.thirdOrNull?.offset;
    if (third == null) return;

    // C与B同dx, D与A同dx, 谁在左取决于基线AB的方向.
    final (left, right) = channel.C.dx <= channel.D.dx ? (channel.C, channel.D) : (channel.D, channel.C);
    final Offset end;
    if (third.dx < left.dx) {
      end = left;
    } else if (third.dx > right.dx) {
      end = right;
    } else {
      return; // 已落在CD横向范围内, 无需连接线.
    }

    canvas.drawLineByConfig(
      Path()..addPolygon([third, end], false),
      crosshairConfig,
    );
  }
}
