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
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'image_span.dart';
import 'paint_resource.dart';

/// 程序绘制的单色小图标, 用作行内 [ImageSpan]; 子类只实现 [draw], 缓存与释放由本类负责。
///
/// 只缓存当前颜色的一张位图, 换色时释放旧图。缓存不看图形参数, 所以参数应为 final; 确需可变时修改后调用 [reset]。
/// 尺寸跟随内容或需对准锚点的外形(气泡、价格标签)用 ShapeBorder, 不用它。
abstract base class ShapeImage implements PaintResource {
  ShapeImage(
    this.size, {
    this.rasterScale = 4,
  }) : assert(!size.isEmpty),
       assert(rasterScale > 0);

  /// 逻辑尺寸, 即 [span] 占位框的大小。
  final Size size;

  /// 位图相对 [size] 的倍率; 默认 4, 覆盖到 4x 屏仍清晰。
  final double rasterScale;

  Color? _color;
  ui.Image? _image;

  /// 在 [size] 的逻辑坐标系内用 [color] 画图形; 画布已按 [rasterScale] 缩放。
  @protected
  void draw(Canvas canvas, Size size, Color color);

  /// [color] 下的位图; 颜色不变时返回同一实例。
  @nonVirtual
  ui.Image of(Color color) {
    final cached = _image;
    if (cached != null && _color == color) return cached;
    cached?.dispose();

    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder)..scale(rasterScale), size, color);
    final picture = recorder.endRecording();
    try {
      _image = picture.toImageSync(
        (size.width * rasterScale).ceil(),
        (size.height * rasterScale).ceil(),
      );
    } finally {
      picture.dispose();
    }
    _color = color;
    return _image!;
  }

  /// 以 [size] 占位的行内图片。
  @nonVirtual
  ImageSpan span(
    Color color, {
    ui.PlaceholderAlignment alignment = ui.PlaceholderAlignment.middle,
  }) => ImageSpan(of(color), size, alignment: alignment);

  @override
  @nonVirtual
  void reset() {
    _image?.dispose();
    _image = null;
    _color = null;
  }

  @override
  @nonVirtual
  void dispose() => reset();

  /// 描边图标用的画笔: 圆头线端、圆角拐点。
  @protected
  @nonVirtual
  Paint strokePaint(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// 凸多边形逐角倒圆, [radius] 为 0 时即原多边形。
  ///
  /// [vertices] 须按屏幕坐标(y 向下)顺时针给出, 圆弧方向依此而定; 半径过大时切点夹到较短邻边的中点, 圆弧随之缩小。
  @protected
  @nonVirtual
  Path roundedPolygon(List<Offset> vertices, double radius) {
    final path = Path();
    if (radius <= 0) return path..addPolygon(vertices, true);

    final count = vertices.length;
    for (var i = 0; i < count; i++) {
      final vertex = vertices[i];
      final toPrev = vertices[(i - 1 + count) % count] - vertex;
      final toNext = vertices[(i + 1) % count] - vertex;
      final unitPrev = toPrev / toPrev.distance;
      final unitNext = toNext / toNext.distance;
      // 切点到顶点的距离 = r / tan(半个顶角)。
      final halfAngle = math.acos(unitPrev.dx * unitNext.dx + unitPrev.dy * unitNext.dy) / 2;
      final distance = math.min(radius / math.tan(halfAngle), math.min(toPrev.distance, toNext.distance) / 2);

      final start = vertex + unitPrev * distance;
      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.arcToPoint(vertex + unitNext * distance, radius: Radius.circular(distance * math.tan(halfAngle)));
    }
    return path..close();
  }
}

/// 实心三角, 尖端朝 [direction](默认向右), 填满 [size]; [radius] 为圆角半径, 默认 0.5 让小箭头不显尖锐。
///
/// [size] 不随方向对调: 朝上或朝下时自行给出横向的盒子。
final class TriangleImage extends ShapeImage {
  TriangleImage(
    super.size, {
    this.direction = AxisDirection.right,
    this.radius = 0.5,
    super.rasterScale,
  }) : assert(radius >= 0);

  final AxisDirection direction;
  final double radius;

  @override
  void draw(Canvas canvas, Size size, Color color) {
    final (w, h) = (size.width, size.height);
    // roundedPolygon 要求顶点顺时针。
    final vertices = switch (direction) {
      AxisDirection.right => [Offset.zero, Offset(w, h / 2), Offset(0, h)],
      AxisDirection.down => [Offset.zero, Offset(w, 0), Offset(w / 2, h)],
      AxisDirection.left => [Offset(w, 0), Offset(w, h), Offset(0, h / 2)],
      AxisDirection.up => [Offset(w / 2, 0), Offset(w, h), Offset(0, h)],
    };
    canvas.drawPath(roundedPolygon(vertices, radius), Paint()..color = color);
  }
}

/// 实心菱形, 四个顶点落在 [size] 各边中点; [radius] 为圆角半径。
final class DiamondImage extends ShapeImage {
  DiamondImage(
    super.size, {
    this.radius = 0.5,
    super.rasterScale,
  }) : assert(radius >= 0);

  final double radius;

  @override
  void draw(Canvas canvas, Size size, Color color) {
    final vertices = [
      Offset(size.width / 2, 0),
      Offset(size.width, size.height / 2),
      Offset(size.width / 2, size.height),
      Offset(0, size.height / 2),
    ];
    canvas.drawPath(roundedPolygon(vertices, radius), Paint()..color = color);
  }
}

/// 实心圆点, 直径取 [size] 的短边并居中。
final class CircleImage extends ShapeImage {
  CircleImage(super.size, {super.rasterScale});

  @override
  void draw(Canvas canvas, Size size, Color color) => canvas.drawCircle(
    size.center(Offset.zero),
    size.shortestSide / 2,
    Paint()..color = color,
  );
}

/// 实心矩形色块, 填满 [size]; [radius] 为圆角半径, 默认 0。常用于指标图例。
final class SquareImage extends ShapeImage {
  SquareImage(
    super.size, {
    this.radius = 0,
    super.rasterScale,
  }) : assert(radius >= 0);

  final double radius;

  @override
  void draw(Canvas canvas, Size size, Color color) => canvas.drawRRect(
    RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
    Paint()..color = color,
  );
}

/// 加号, 两臂贯穿 [size]; [thickness] 为臂宽, 默认取短边的 1/3。
final class PlusImage extends ShapeImage {
  PlusImage(
    super.size, {
    this.thickness,
    super.rasterScale,
  }) : assert(thickness == null || thickness > 0);

  final double? thickness;

  @override
  void draw(Canvas canvas, Size size, Color color) {
    final (w, h) = (size.width, size.height);
    final t = thickness ?? size.shortestSide / 3;
    // 单条路径填充: 半透明色下交叉处不会叠色。
    final path = Path()
      ..addRect(
        Rect.fromLTRB(0, (h - t) / 2, w, (h + t) / 2),
      )
      ..addRect(
        Rect.fromLTRB((w - t) / 2, 0, (w + t) / 2, h),
      );
    canvas.drawPath(path, Paint()..color = color);
  }
}

/// 减号, 贯穿 [size] 宽度的横杠; [thickness] 为杠高, 默认取短边的 1/3。
final class MinusImage extends ShapeImage {
  MinusImage(
    super.size, {
    this.thickness,
    super.rasterScale,
  }) : assert(thickness == null || thickness > 0);

  final double? thickness;

  @override
  void draw(Canvas canvas, Size size, Color color) {
    final (w, h) = (size.width, size.height);
    final t = thickness ?? size.shortestSide / 3;
    canvas.drawRect(
      Rect.fromLTRB(0, (h - t) / 2, w, (h + t) / 2),
      Paint()..color = color,
    );
  }
}

/// 折线箭头 `›`, 尖端朝 [direction](默认向右); [thickness] 为线宽, 默认取短边的 1/5。
///
/// 折线内缩半个线宽, 笔画不会画出 [size]。
final class ChevronImage extends ShapeImage {
  ChevronImage(
    super.size, {
    this.direction = AxisDirection.right,
    this.thickness,
    super.rasterScale,
  }) : assert(thickness == null || thickness > 0);

  final AxisDirection direction;
  final double? thickness;

  @override
  void draw(Canvas canvas, Size size, Color color) {
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
}

/// 叉号, 两条对角线; [thickness] 为线宽, 默认取短边的 1/5, 笔画不会画出 [size]。
final class CrossImage extends ShapeImage {
  CrossImage(
    super.size, {
    this.thickness,
    super.rasterScale,
  }) : assert(thickness == null || thickness > 0);

  final double? thickness;

  @override
  void draw(Canvas canvas, Size size, Color color) {
    final t = thickness ?? size.shortestSide / 5;
    final r = (Offset.zero & size).deflate(t / 2);
    final path = Path()
      ..moveTo(r.left, r.top)
      ..lineTo(r.right, r.bottom)
      ..moveTo(r.right, r.top)
      ..lineTo(r.left, r.bottom);
    canvas.drawPath(path, strokePaint(color, t));
  }
}

/// 实心五角星, 外接圆直径取 [size] 的短边, 在盒内居中。
final class StarImage extends ShapeImage {
  StarImage(super.size, {super.rasterScale});

  /// 内顶点半径与外顶点半径之比。
  static const _innerRatio = 0.4;

  @override
  void draw(Canvas canvas, Size size, Color color) {
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

/// 铃铛(钟身 + 顶钮 + 铃舌), 按 [size] 比例绘制; 细节较多, 宜 12 以上使用。
final class BellImage extends ShapeImage {
  BellImage(super.size, {super.rasterScale});

  @override
  void draw(Canvas canvas, Size size, Color color) {
    final (w, h) = (size.width, size.height);
    // 钟身从左下沿经圆顶到右下沿, 底沿为直线。
    final path = Path()
      ..moveTo(0.12 * w, 0.78 * h)
      ..cubicTo(0.24 * w, 0.66 * h, 0.24 * w, 0.50 * h, 0.26 * w, 0.38 * h)
      ..cubicTo(0.28 * w, 0.22 * h, 0.40 * w, 0.14 * h, 0.50 * w, 0.14 * h)
      ..cubicTo(0.60 * w, 0.14 * h, 0.72 * w, 0.22 * h, 0.74 * w, 0.38 * h)
      ..cubicTo(0.76 * w, 0.50 * h, 0.76 * w, 0.66 * h, 0.88 * w, 0.78 * h)
      ..close()
      ..addOval(
        Rect.fromLTRB(0.45 * w, 0.03 * h, 0.55 * w, 0.13 * h),
      )
      ..addOval(
        Rect.fromLTRB(0.4 * w, 0.81 * h, 0.6 * w, 0.99 * h),
      );
    canvas.drawPath(path, Paint()..color = color);
  }
}
