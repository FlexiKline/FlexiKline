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

import 'package:flutter/painting.dart';

import '../geometry/path_corner.dart';
import 'icon_shape.dart';

/// 实心三角, 尖端朝 [direction](默认向右), 填满给定尺寸; [radius] 为圆角半径, 默认 0.5 让小箭头不显尖锐。
///
/// 尺寸不随方向对调: 朝上或朝下时自行给出横向的盒子。
final class TriangleShape extends IconShape {
  const TriangleShape({this.direction = AxisDirection.right, this.radius = 0.5}) : assert(radius >= 0);

  final AxisDirection direction;
  final double radius;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final (w, h) = (size.width, size.height);
    final vertices = switch (direction) {
      AxisDirection.right => [Offset.zero, Offset(w, h / 2), Offset(0, h)],
      AxisDirection.down => [Offset.zero, Offset(w, 0), Offset(w / 2, h)],
      AxisDirection.left => [Offset(w, 0), Offset(w, h), Offset(0, h / 2)],
      AxisDirection.up => [Offset(w / 2, 0), Offset(w, h), Offset(0, h)],
    };
    canvas.drawPath(Path()..addRoundedPolygon(vertices, radius), Paint()..color = color);
  }

  @override
  bool operator ==(Object other) => other is TriangleShape && other.direction == direction && other.radius == radius;

  @override
  int get hashCode => Object.hash(TriangleShape, direction, radius);
}

/// 实心菱形, 四个顶点落在各边中点; [radius] 为圆角半径。
final class DiamondShape extends IconShape {
  const DiamondShape({this.radius = 0.5}) : assert(radius >= 0);

  final double radius;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final vertices = [
      Offset(size.width / 2, 0),
      Offset(size.width, size.height / 2),
      Offset(size.width / 2, size.height),
      Offset(0, size.height / 2),
    ];
    canvas.drawPath(Path()..addRoundedPolygon(vertices, radius), Paint()..color = color);
  }

  @override
  bool operator ==(Object other) => other is DiamondShape && other.radius == radius;

  @override
  int get hashCode => Object.hash(DiamondShape, radius);
}

/// 实心圆点, 直径取短边并居中。
final class CircleShape extends IconShape {
  const CircleShape();

  @override
  void paint(Canvas canvas, Size size, Color color) =>
      canvas.drawCircle(size.center(Offset.zero), size.shortestSide / 2, Paint()..color = color);
}

/// 实心矩形色块, 填满给定尺寸; [radius] 为圆角半径, 默认 0。常用于图例。
final class SquareShape extends IconShape {
  const SquareShape({this.radius = 0}) : assert(radius >= 0);

  final double radius;

  @override
  void paint(Canvas canvas, Size size, Color color) =>
      canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)), Paint()..color = color);

  @override
  bool operator ==(Object other) => other is SquareShape && other.radius == radius;

  @override
  int get hashCode => Object.hash(SquareShape, radius);
}

/// 加号, 两臂贯穿给定尺寸; [thickness] 为臂宽, 默认取短边的 1/3。
final class PlusShape extends IconShape {
  const PlusShape({this.thickness}) : assert(thickness == null || thickness > 0);

  final double? thickness;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final (w, h) = (size.width, size.height);
    final t = thickness ?? size.shortestSide / 3;
    // 单条路径填充: 半透明色下交叉处不会叠色。
    final path = Path()
      ..addRect(Rect.fromLTRB(0, (h - t) / 2, w, (h + t) / 2))
      ..addRect(Rect.fromLTRB((w - t) / 2, 0, (w + t) / 2, h));
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool operator ==(Object other) => other is PlusShape && other.thickness == thickness;

  @override
  int get hashCode => Object.hash(PlusShape, thickness);
}

/// 减号, 贯穿宽度的横杠; [thickness] 为杠高, 默认取短边的 1/3。
final class MinusShape extends IconShape {
  const MinusShape({this.thickness}) : assert(thickness == null || thickness > 0);

  final double? thickness;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final (w, h) = (size.width, size.height);
    final t = thickness ?? size.shortestSide / 3;
    canvas.drawRect(Rect.fromLTRB(0, (h - t) / 2, w, (h + t) / 2), Paint()..color = color);
  }

  @override
  bool operator ==(Object other) => other is MinusShape && other.thickness == thickness;

  @override
  int get hashCode => Object.hash(MinusShape, thickness);
}

/// 折线箭头 `›`, 尖端朝 [direction](默认向右); [thickness] 为线宽, 默认取短边的 1/5。
///
/// 折线内缩半个线宽, 笔画不会画出给定尺寸。
final class ChevronShape extends IconShape {
  const ChevronShape({this.direction = AxisDirection.right, this.thickness})
    : assert(thickness == null || thickness > 0);

  final AxisDirection direction;
  final double? thickness;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final t = thickness ?? size.shortestSide / 5;
    final r = (Offset.zero & size).deflate(t / 2);
    final points = switch (direction) {
      AxisDirection.right => [r.topLeft, r.centerRight, r.bottomLeft],
      AxisDirection.down => [r.topLeft, r.bottomCenter, r.topRight],
      AxisDirection.left => [r.topRight, r.centerLeft, r.bottomRight],
      AxisDirection.up => [r.bottomLeft, r.topCenter, r.bottomRight],
    };
    canvas.drawPath(Path()..addPolygon(points, false), strokePaint(color, t));
  }

  @override
  bool operator ==(Object other) =>
      other is ChevronShape && other.direction == direction && other.thickness == thickness;

  @override
  int get hashCode => Object.hash(ChevronShape, direction, thickness);
}

/// 叉号, 两条对角线; [thickness] 为线宽, 默认取短边的 1/5, 笔画不会画出给定尺寸。
final class CrossShape extends IconShape {
  const CrossShape({this.thickness}) : assert(thickness == null || thickness > 0);

  final double? thickness;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final t = thickness ?? size.shortestSide / 5;
    final r = (Offset.zero & size).deflate(t / 2);
    final path = Path()
      ..moveTo(r.left, r.top)
      ..lineTo(r.right, r.bottom)
      ..moveTo(r.right, r.top)
      ..lineTo(r.left, r.bottom);
    canvas.drawPath(path, strokePaint(color, t));
  }

  @override
  bool operator ==(Object other) => other is CrossShape && other.thickness == thickness;

  @override
  int get hashCode => Object.hash(CrossShape, thickness);
}

/// 实心五角星, 外接圆直径取短边, 在盒内居中。
final class StarShape extends IconShape {
  const StarShape();

  /// 内顶点半径与外顶点半径之比。
  static const _innerRatio = 0.4;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final outer = size.shortestSide / 2;
    // 星高 (1 + cos36°) x 外半径, 比直径矮: 圆心下移半个差值以垂直居中。
    final center = Offset(size.width / 2, size.height / 2 + outer * (1 - math.cos(math.pi / 5)) / 2);
    final vertices = [
      for (var i = 0; i < 10; i++)
        center + Offset.fromDirection(i * math.pi / 5 - math.pi / 2, i.isEven ? outer : outer * _innerRatio),
    ];
    canvas.drawPath(Path()..addPolygon(vertices, true), Paint()..color = color);
  }
}

/// 铃铛(钟身 + 顶钮 + 铃舌), 按尺寸比例绘制; 细节较多, 宜 12 以上使用。
final class BellShape extends IconShape {
  const BellShape();

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final (w, h) = (size.width, size.height);
    // 钟身从左下沿经圆顶到右下沿, 底沿为直线。
    final path = Path()
      ..moveTo(0.12 * w, 0.78 * h)
      ..cubicTo(0.24 * w, 0.66 * h, 0.24 * w, 0.50 * h, 0.26 * w, 0.38 * h)
      ..cubicTo(0.28 * w, 0.22 * h, 0.40 * w, 0.14 * h, 0.50 * w, 0.14 * h)
      ..cubicTo(0.60 * w, 0.14 * h, 0.72 * w, 0.22 * h, 0.74 * w, 0.38 * h)
      ..cubicTo(0.76 * w, 0.50 * h, 0.76 * w, 0.66 * h, 0.88 * w, 0.78 * h)
      ..close()
      ..addOval(Rect.fromLTRB(0.45 * w, 0.03 * h, 0.55 * w, 0.13 * h))
      ..addOval(Rect.fromLTRB(0.4 * w, 0.81 * h, 0.6 * w, 0.99 * h));
    canvas.drawPath(path, Paint()..color = color);
  }
}
