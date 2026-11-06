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

/// 圆点, 直径取短边并居中; 给出 [strokeWidth] 时画成圆环, 环不超出给定尺寸。
final class CircleShape extends IconShape {
  const CircleShape({this.strokeWidth}) : assert(strokeWidth == null || strokeWidth > 0);

  /// 圆环线宽; null 时为实心圆。
  final double? strokeWidth;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final center = size.center(Offset.zero);
    final w = strokeWidth;
    if (w == null) {
      canvas.drawCircle(center, size.shortestSide / 2, Paint()..color = color);
    } else {
      canvas.drawCircle(center, (size.shortestSide - w) / 2, _outline(color, w));
    }
  }

  @override
  bool operator ==(Object other) => other is CircleShape && other.strokeWidth == strokeWidth;

  @override
  int get hashCode => Object.hash(CircleShape, strokeWidth);
}

/// 矩形色块, 填满给定尺寸, 常用于图例; [radius] 为圆角半径, 给出 [strokeWidth] 时画成描边方框。
final class SquareShape extends IconShape {
  const SquareShape({this.radius = 0, this.strokeWidth})
    : assert(radius >= 0),
      assert(strokeWidth == null || strokeWidth > 0);

  final double radius;

  /// 描边线宽; null 时为实心。描边沿内侧收进半个线宽, 外轮廓仍是 [radius] 的圆角。
  final double? strokeWidth;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final w = strokeWidth;
    if (w == null) {
      canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)), Paint()..color = color);
    } else {
      final rect = (Offset.zero & size).deflate(w / 2);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(math.max(0, radius - w / 2))), _outline(color, w));
    }
  }

  @override
  bool operator ==(Object other) => other is SquareShape && other.radius == radius && other.strokeWidth == strokeWidth;

  @override
  int get hashCode => Object.hash(SquareShape, radius, strokeWidth);
}

/// 加号, 两臂贯穿给定尺寸; [thickness] 为臂宽, 默认取短边的 1/3; [radius] 为臂端圆角, 不超过半个臂宽。
final class PlusShape extends IconShape {
  const PlusShape({this.thickness, this.radius = 0}) : assert(thickness == null || thickness > 0), assert(radius >= 0);

  final double? thickness;
  final double radius;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final (w, h) = (size.width, size.height);
    final t = thickness ?? size.shortestSide / 3;
    final r = Radius.circular(math.min(radius, t / 2));
    // 单条路径填充: 半透明色下交叉处不会叠色。
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(0, (h - t) / 2, w, (h + t) / 2), r))
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB((w - t) / 2, 0, (w + t) / 2, h), r));
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool operator ==(Object other) => other is PlusShape && other.thickness == thickness && other.radius == radius;

  @override
  int get hashCode => Object.hash(PlusShape, thickness, radius);
}

/// 减号, 贯穿宽度的横杠; [thickness] 为杠高, 默认取短边的 1/3; [radius] 为两端圆角, 不超过半个杠高。
final class MinusShape extends IconShape {
  const MinusShape({this.thickness, this.radius = 0}) : assert(thickness == null || thickness > 0), assert(radius >= 0);

  final double? thickness;
  final double radius;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final (w, h) = (size.width, size.height);
    final t = thickness ?? size.shortestSide / 3;
    final rect = Rect.fromLTRB(0, (h - t) / 2, w, (h + t) / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(math.min(radius, t / 2))), Paint()..color = color);
  }

  @override
  bool operator ==(Object other) => other is MinusShape && other.thickness == thickness && other.radius == radius;

  @override
  int get hashCode => Object.hash(MinusShape, thickness, radius);
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

/// 圆圈加号 ⊕: 圆环居中, 横竖两臂穿过圆心; 笔画不会画出给定尺寸。
final class CirclePlusShape extends IconShape {
  const CirclePlusShape({this.thickness, this.plusThickness, this.plusRatio = 1})
    : assert(thickness == null || thickness > 0),
      assert(plusThickness == null || plusThickness > 0),
      assert(plusRatio > 0 && plusRatio <= 1);

  /// 圆环线宽, 默认取短边的 1/10。
  final double? thickness;

  /// 加号线宽, 默认同圆环线宽。
  final double? plusThickness;

  /// 加号臂长占圆环直径(按环线中心计)的比例; 1 时两臂碰到环上。
  final double plusRatio;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final t = thickness ?? size.shortestSide / 10;
    final c = size.center(Offset.zero);
    final r = (size.shortestSide - t) / 2;
    final arm = r * plusRatio;
    final plus = Path()
      ..moveTo(c.dx - arm, c.dy)
      ..lineTo(c.dx + arm, c.dy)
      ..moveTo(c.dx, c.dy - arm)
      ..lineTo(c.dx, c.dy + arm);
    final plusWidth = plusThickness ?? t;
    if (plusWidth == t) {
      // 线宽相同时合成一条路径描边: 半透明色下臂与环相接处不会叠色。
      canvas.drawPath(Path.from(plus)..addOval(Rect.fromCircle(center: c, radius: r)), strokePaint(color, t));
    } else {
      canvas
        ..drawCircle(c, r, strokePaint(color, t))
        ..drawPath(plus, strokePaint(color, plusWidth));
    }
  }

  @override
  bool operator ==(Object other) =>
      other is CirclePlusShape &&
      other.thickness == thickness &&
      other.plusThickness == plusThickness &&
      other.plusRatio == plusRatio;

  @override
  int get hashCode => Object.hash(CirclePlusShape, thickness, plusThickness, plusRatio);
}

/// 实心星形, 外接圆直径取短边, 在盒内居中; [points] 为角数, [innerRatio] 为内凹顶点与外顶点的半径比。
final class StarShape extends IconShape {
  const StarShape({this.points = 5, this.innerRatio = 0.4})
    : assert(points >= 3),
      assert(innerRatio > 0 && innerRatio < 1);

  final int points;
  final double innerRatio;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final outer = size.shortestSide / 2;
    final step = math.pi / points;
    // 奇数角时星高为 (1 + cos(π/n)) 倍外半径, 比直径矮: 圆心下移半个差值以垂直居中。
    final dy = points.isOdd ? outer * (1 - math.cos(step)) / 2 : 0.0;
    final center = Offset(size.width / 2, size.height / 2 + dy);
    final vertices = [
      for (var i = 0; i < points * 2; i++)
        center + Offset.fromDirection(i * step - math.pi / 2, i.isEven ? outer : outer * innerRatio),
    ];
    canvas.drawPath(Path()..addPolygon(vertices, true), Paint()..color = color);
  }

  @override
  bool operator ==(Object other) => other is StarShape && other.points == points && other.innerRatio == innerRatio;

  @override
  int get hashCode => Object.hash(StarShape, points, innerRatio);
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

/// 描边画笔, 默认的尖角拐点: 方框描边的外角跟随圆角参数, 不被圆角拐点磨圆。
Paint _outline(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width;
