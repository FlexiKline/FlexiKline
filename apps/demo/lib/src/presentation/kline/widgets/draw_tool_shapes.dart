import 'dart:math' as math;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart';
import 'package:flutter/painting.dart';

/// 内置绘图工具对应的图标; 未收录的类型由调用方兜底。
final Map<IDrawType, IconShape> drawToolShapes = {
  trendLine: const TrendLineShape(),
  arrowLine: const ArrowLineShape(),
  extendedTrendLine: const ExtendedTrendLineShape(),
  trendAngle: const TrendAngleShape(),
  rayLine: const RayLineShape(),
  horizontalTrendLine: const HorizontalTrendLineShape(),
  horizontalRayLine: const HorizontalRayLineShape(),
  horizontalLine: const HorizontalLineShape(),
  verticalLine: const VerticalLineShape(),
  crossLine: const CrossLineShape(),
  priceLine: const PriceLineShape(),
  rectangle: const RectangleShape(),
  parallelogram: const ParallelogramShape(),
  parallelChannel: const ParallelChannelShape(),
  fibRetracement: const FibRetracementShape(),
  fibExpansion: const FibExpansionShape(),
  fibFans: const FibFansShape(),
  tripleWaves: const TripleWavesShape(),
  pentaWaves: const PentaWavesShape(),
};

/// 绘图工具图标的公共画法: 在 24 格方形坐标系里描线, 锚点画成空心圆环。
abstract base class DrawToolShape extends IconShape {
  const DrawToolShape();

  @override
  void paint(Canvas canvas, Size size, Color color) => draw(GridPen(canvas, color, size));

  /// 用 [pen] 按格坐标画出图标。
  void draw(GridPen pen);
}

final class TrendLineShape extends DrawToolShape {
  const TrendLineShape();

  @override
  void draw(GridPen pen) {
    final (a, b) = const (Offset(5, 19), Offset(19, 5));
    pen
      ..line(a, b, nodeA: true, nodeB: true)
      ..nodes([a, b]);
  }
}

final class ArrowLineShape extends DrawToolShape {
  const ArrowLineShape();

  @override
  void draw(GridPen pen) {
    final (a, tip) = const (Offset(5, 19), Offset(19.5, 4.5));
    pen
      ..line(a, tip, nodeA: true)
      ..polyline([const Offset(13.5, 4.5), tip, const Offset(19.5, 10.5)])
      ..node(a);
  }
}

final class ExtendedTrendLineShape extends DrawToolShape {
  const ExtendedTrendLineShape();

  @override
  void draw(GridPen pen) {
    final (a, b) = const (Offset(8, 16), Offset(16, 8));
    pen
      ..line(const Offset(2, 22), a, nodeB: true)
      ..line(a, b, nodeA: true, nodeB: true)
      ..line(b, const Offset(22, 2), nodeA: true)
      ..nodes([a, b]);
  }
}

final class TrendAngleShape extends DrawToolShape {
  const TrendAngleShape();

  @override
  void draw(GridPen pen) {
    final (a, b) = const (Offset(5, 19), Offset(18, 6));
    pen
      ..line(a, b, nodeA: true, nodeB: true)
      ..line(a, const Offset(21.5, 19), nodeA: true)
      ..arc(a, 9, -math.pi / 4, math.pi / 4)
      ..nodes([a, b]);
  }
}

final class RayLineShape extends DrawToolShape {
  const RayLineShape();

  @override
  void draw(GridPen pen) {
    final (a, b) = const (Offset(5, 19), Offset(12, 12));
    pen
      ..line(a, b, nodeA: true, nodeB: true)
      ..line(b, const Offset(21.5, 2.5), nodeA: true)
      ..nodes([a, b]);
  }
}

final class HorizontalTrendLineShape extends DrawToolShape {
  const HorizontalTrendLineShape();

  @override
  void draw(GridPen pen) {
    final (a, b) = const (Offset(5, 12), Offset(19, 12));
    pen
      ..line(a, b, nodeA: true, nodeB: true)
      ..nodes([a, b]);
  }
}

final class HorizontalRayLineShape extends DrawToolShape {
  const HorizontalRayLineShape();

  @override
  void draw(GridPen pen) {
    const a = Offset(5, 12);
    pen
      ..line(a, const Offset(21.5, 12), nodeA: true)
      ..node(a);
  }
}

final class HorizontalLineShape extends DrawToolShape {
  const HorizontalLineShape();

  @override
  void draw(GridPen pen) {
    const c = Offset(12, 12);
    pen
      ..line(const Offset(2.5, 12), c, nodeB: true)
      ..line(c, const Offset(21.5, 12), nodeA: true)
      ..node(c);
  }
}

final class VerticalLineShape extends DrawToolShape {
  const VerticalLineShape();

  @override
  void draw(GridPen pen) {
    const c = Offset(12, 12);
    pen
      ..line(const Offset(12, 2.5), c, nodeB: true)
      ..line(c, const Offset(12, 21.5), nodeA: true)
      ..node(c);
  }
}

final class CrossLineShape extends DrawToolShape {
  const CrossLineShape();

  @override
  void draw(GridPen pen) {
    const c = Offset(12, 12);
    pen
      ..line(const Offset(2.5, 12), c, nodeB: true)
      ..line(c, const Offset(21.5, 12), nodeA: true)
      ..line(const Offset(12, 2.5), c, nodeB: true)
      ..line(c, const Offset(12, 21.5), nodeA: true)
      ..node(c);
  }
}

/// 价格线: 锚点引出的横线, 右上角标出价格数字。
final class PriceLineShape extends DrawToolShape {
  const PriceLineShape();

  @override
  void draw(GridPen pen) {
    const a = Offset(5, 17);
    pen
      ..digits('123', const Offset(10, 4))
      ..line(a, const Offset(21.5, 17), nodeA: true)
      ..node(a);
  }
}

final class RectangleShape extends DrawToolShape {
  const RectangleShape();

  @override
  void draw(GridPen pen) {
    final (tl, tr, br, bl) = const (Offset(5, 5), Offset(19, 5), Offset(19, 19), Offset(5, 19));
    pen
      ..line(tl, tr, nodeA: true, nodeB: true)
      ..line(tr, br, nodeA: true, nodeB: true)
      ..line(br, bl, nodeA: true, nodeB: true)
      ..line(bl, tl, nodeA: true, nodeB: true)
      ..nodes([tl, tr, br, bl]);
  }
}

final class ParallelogramShape extends DrawToolShape {
  const ParallelogramShape();

  @override
  void draw(GridPen pen) {
    final (a, b, c, d) = const (Offset(5, 19), Offset(5, 10), Offset(19, 5), Offset(19, 14));
    pen
      ..line(a, b, nodeA: true)
      ..line(b, c, nodeB: true)
      ..line(c, d, nodeA: true)
      ..line(d, a, nodeB: true)
      ..nodes([a, c]);
  }
}

final class ParallelChannelShape extends DrawToolShape {
  const ParallelChannelShape();

  @override
  void draw(GridPen pen) {
    final (a, b, c) = const (Offset(5, 10), Offset(19, 4.5), Offset(12, 17));
    pen
      ..line(a, b, nodeA: true, nodeB: true)
      ..line(const Offset(4, 20), c, nodeB: true)
      ..line(c, const Offset(20, 14), nodeA: true)
      ..nodes([a, b, c]);
  }
}

/// 斐波那契回撤: 三条等距横线, 首尾两条各带一个锚点。
final class FibRetracementShape extends DrawToolShape {
  const FibRetracementShape();

  @override
  void draw(GridPen pen) {
    final (a, b) = const (Offset(18.5, 4.5), Offset(5.5, 19.5));
    pen
      ..line(const Offset(2.5, 4.5), a, nodeB: true)
      ..line(const Offset(2.5, 12), const Offset(21.5, 12))
      ..line(b, const Offset(21.5, 19.5), nodeA: true)
      ..nodes([a, b]);
  }
}

final class FibExpansionShape extends DrawToolShape {
  const FibExpansionShape();

  @override
  void draw(GridPen pen) {
    final (a, b, c) = const (Offset(5, 12.5), Offset(11, 4.5), Offset(17, 9.5));
    pen
      ..line(a, b, nodeA: true, nodeB: true)
      ..line(b, c, nodeA: true, nodeB: true)
      ..line(const Offset(10.5, 17), const Offset(21.5, 17))
      ..line(const Offset(2.5, 21.5), const Offset(21.5, 21.5))
      ..nodes([a, b, c]);
  }
}

/// 斐波那契扇形: 坐标轴内自原点发散的射线, 主对角线末端一个锚点。
final class FibFansShape extends DrawToolShape {
  const FibFansShape();

  @override
  void draw(GridPen pen) {
    final (o, end) = const (Offset(4, 20), Offset(17.5, 6.5));
    pen
      ..polyline([const Offset(4, 3), o, const Offset(21, 20)])
      ..line(o, end, nodeB: true)
      ..line(o, const Offset(21, 13))
      ..line(o, const Offset(11, 3.5))
      ..node(end);
  }
}

/// 三浪: 三段折线, 左上标起点 1, 右下标终点 3。
final class TripleWavesShape extends DrawToolShape {
  const TripleWavesShape();

  @override
  void draw(GridPen pen) => pen
    ..digits('1', const Offset(2.5, 2.5))
    ..digits('3', const Offset(18, 16))
    ..polyline(const [Offset(5.5, 19.5), Offset(10, 9), Offset(14, 15.5), Offset(19, 5)]);
}

/// 五浪: 五段折线, 左上标起点 1, 右下标终点 5。
final class PentaWavesShape extends DrawToolShape {
  const PentaWavesShape();

  @override
  void draw(GridPen pen) => pen
    ..digits('1', const Offset(2.5, 2.5))
    ..digits('5', const Offset(18, 16))
    ..polyline(const [
      Offset(5, 19.5),
      Offset(8, 11),
      Offset(10.5, 15.5),
      Offset(13.5, 6),
      Offset(16, 11.5),
      Offset(21, 3),
    ]);
}

/// 马蹄形磁铁, 开口朝下, 两极与磁身之间有分隔线; [strong] 时两极下方加闪电, 磁身位置不变。
final class MagnetShape extends IconShape {
  const MagnetShape({this.strong = false});

  final bool strong;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final pen = GridPen(canvas, color, size);
    // 磁身外弧半径 8、内弧半径 3.5, 圆心 (12, 10.5), 两脚到 y=17, 在 y=14 分出两极。
    pen
      ..path(
        Path()
          ..moveTo(4, 17)
          ..lineTo(4, 10.5)
          ..arcTo(Rect.fromCircle(center: const Offset(12, 10.5), radius: 8), math.pi, math.pi, false)
          ..lineTo(20, 17)
          ..lineTo(15.5, 17)
          ..lineTo(15.5, 10.5)
          ..arcTo(Rect.fromCircle(center: const Offset(12, 10.5), radius: 3.5), 0, -math.pi, false)
          ..lineTo(8.5, 17)
          ..close(),
      )
      ..line(const Offset(4, 14), const Offset(8.5, 14))
      ..line(const Offset(15.5, 14), const Offset(20, 14));
    if (strong) {
      pen
        ..polyline(const [Offset(7, 19), Offset(5.5, 21), Offset(7, 21), Offset(5.5, 23)])
        ..polyline(const [Offset(18.5, 19), Offset(17, 21), Offset(18.5, 21), Offset(17, 23)]);
    }
  }

  @override
  bool operator ==(Object other) => other is MagnetShape && other.strong == strong;

  @override
  int get hashCode => Object.hash(MagnetShape, strong);
}

/// 线宽示意: 一根粗 [width] 格的横线。
final class LineWeightShape extends IconShape {
  const LineWeightShape(this.width) : assert(width > 0);

  final double width;

  @override
  void paint(Canvas canvas, Size size, Color color) =>
      GridPen(canvas, color, size, stroke: width).line(const Offset(3, 12), const Offset(21, 12));

  @override
  bool operator ==(Object other) => other is LineWeightShape && other.width == width;

  @override
  int get hashCode => Object.hash(LineWeightShape, width);
}

/// 线型示意: 实线、虚线或点线。
final class LineTypeShape extends IconShape {
  const LineTypeShape(this.type);

  final LineType type;

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final pen = GridPen(canvas, color, size);
    switch (type) {
      case LineType.solid:
        pen.line(const Offset(3, 12), const Offset(21, 12));
      case LineType.dashed:
        for (final x in const [3.0, 10.0, 17.0]) {
          pen.line(Offset(x, 12), Offset(x + 4, 12));
        }
      case LineType.dotted:
        for (final x in const [4.0, 8.0, 12.0, 16.0, 20.0]) {
          pen.dot(Offset(x, 12), 1.25);
        }
    }
  }

  @override
  bool operator ==(Object other) => other is LineTypeShape && other.type == type;

  @override
  int get hashCode => Object.hash(LineTypeShape, type);
}

/// 24 格坐标系下的描线笔: 入参都是格坐标, 按给定尺寸换算成像素。
///
/// 图形收拢到中心 20 格内, 与 Material 图标四周留 2 格的安全区一致; 线宽与锚点半径不随之缩小,
/// 保证与同尺寸的 Material 图标笔画一样粗。
final class GridPen {
  GridPen(this.canvas, Color color, Size size, {double stroke = GridPen.stroke})
    : u = size.shortestSide / 24,
      _origin = size.center(Offset.zero),
      paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * size.shortestSide / 24
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  /// 线宽, 单位为格。
  static const stroke = 2.0;

  /// 锚点圆环半径, 单位为格。
  static const nodeRadius = 2.5;

  /// 安全区与整格的比例。
  static const _fit = 20 / 24;

  final Canvas canvas;
  final Paint paint;

  /// 一格对应的像素。
  final double u;
  final Offset _origin;

  /// 格坐标到像素坐标。
  Offset _map(Offset p) => _origin + (p - const Offset(12, 12)) * (u * _fit);

  /// 空心圆环锚点。
  void node(Offset center) => canvas.drawCircle(_map(center), nodeRadius * u, paint);

  void nodes(Iterable<Offset> centers) => centers.forEach(node);

  /// 实心圆点, 半径 [radius] 格。
  void dot(Offset center, double radius) => canvas.drawCircle(_map(center), radius * u, Paint()..color = paint.color);

  /// [a] 到 [b] 的线段; 端点是锚点([nodeA]、[nodeB])时在圆环外收笔。
  void line(Offset a, Offset b, {bool nodeA = false, bool nodeB = false}) {
    final (from, to) = (_map(a), _map(b));
    final shift = (to - from) / (to - from).distance * (nodeRadius * u);
    canvas.drawLine(nodeA ? from + shift : from, nodeB ? to - shift : to, paint);
  }

  void polyline(List<Offset> points) =>
      canvas.drawPath(Path()..addPolygon([for (final p in points) _map(p)], false), paint);

  void arc(Offset center, double radius, double start, double sweep) =>
      canvas.drawArc(Rect.fromCircle(center: _map(center), radius: radius * u * _fit), start, sweep, false, paint);

  /// 按格坐标描 [path]。
  void path(Path path) {
    final scale = u * _fit;
    final offset = _map(Offset.zero);
    canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..scale(scale)
      ..drawPath(path, Paint.from(paint)..strokeWidth = paint.strokeWidth / scale)
      ..restore();
  }

  /// 在 [topLeft] 起写 [text] 中的数字(只收录 1、2、3、5), 字高 [height] 格, 宽为高的 0.6。
  void digits(String text, Offset topLeft, {double height = 5.5}) {
    final width = height * 0.6;
    final glyph = Paint.from(paint)..strokeWidth = paint.strokeWidth * 0.8;
    for (final (i, char) in text.split('').indexed) {
      final origin = topLeft + Offset(i * width * 1.25, 0);
      final points = [for (final p in _glyphs[char]!) _map(origin + Offset(p.dx * width, p.dy * height))];
      canvas.drawPath(Path()..addPolygon(points, false), glyph);
    }
  }

  /// 数字笔画, 坐标是在 1x1 字框内的比例。
  static const _glyphs = {
    '1': [Offset(0.1, 0.25), Offset(0.55, 0), Offset(0.55, 1)],
    '2': [
      Offset(0, 0.22),
      Offset(0.25, 0),
      Offset(0.75, 0),
      Offset(1, 0.22),
      Offset(1, 0.38),
      Offset(0, 1),
      Offset(1, 1),
    ],
    '3': [
      Offset(0.05, 0),
      Offset(1, 0),
      Offset(0.45, 0.42),
      Offset(0.8, 0.48),
      Offset(1, 0.7),
      Offset(0.8, 1),
      Offset(0.2, 1),
      Offset(0, 0.85),
    ],
    '5': [
      Offset(0.95, 0),
      Offset(0.1, 0),
      Offset(0.02, 0.45),
      Offset(0.6, 0.4),
      Offset(1, 0.62),
      Offset(0.85, 0.95),
      Offset(0.3, 1),
      Offset(0, 0.85),
    ],
  };
}
