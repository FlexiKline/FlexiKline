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

// ignore_for_file: invalid_use_of_protected_member
import 'dart:math' as math;

import 'package:flexi_kline/src/painting/export.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

/// 记下每次 [draw] 收到的尺寸与颜色。
final class _Probe extends ShapeImage {
  _Probe(super.size, {super.rasterScale});

  final draws = <(Size, Color)>[];

  @override
  void draw(Canvas canvas, Size size, Color color) => draws.add((size, color));
}

/// [TriangleImage] / [DiamondImage] 画出的路径。
Path _pathOf(ShapeImage image) {
  final canvas = RecordingCanvas();
  image.draw(canvas, image.size, const Color(0xFF000000));
  return canvas.invocations.single.positionalArguments[0] as Path;
}

/// [MinusImage] 画出的矩形。
Rect _rectOf(MinusImage image) {
  final canvas = RecordingCanvas();
  image.draw(canvas, image.size, const Color(0xFF000000));
  return canvas.invocations.single.positionalArguments[0] as Rect;
}

/// 描边图标(Chevron / Cross)画出的路径与画笔。
(Path, Paint) _strokeOf(ShapeImage image) {
  final canvas = RecordingCanvas();
  image.draw(canvas, image.size, const Color(0xFF000000));
  final args = canvas.invocations.single.positionalArguments;
  return (args[0] as Path, args[1] as Paint);
}

void main() {
  const red = Color(0xFFFF0000);
  const blue = Color(0xFF0000FF);

  group('ShapeImage 缓存', () {
    test('同色复用同一张图, 只画一次', () {
      final image = _Probe(const Size(5, 6));
      addTearDown(image.dispose);

      final first = image.of(red);
      expect(image.of(red), same(first));
      expect(image.draws, [(const Size(5, 6), red)], reason: 'draw 收到逻辑尺寸');
    });

    test('位图尺寸 = 逻辑尺寸 x rasterScale, 向上取整', () {
      final image = _Probe(const Size(5, 6.1), rasterScale: 3);
      addTearDown(image.dispose);

      final bitmap = image.of(red);
      expect((bitmap.width, bitmap.height), (15, 19));
    });

    test('换色重建并释放旧图', () {
      final image = _Probe(const Size(5, 6));
      addTearDown(image.dispose);

      final first = image.of(red);
      final second = image.of(blue);
      expect(second, isNot(same(first)));
      expect(first.debugDisposed, isTrue);
      expect(second.debugDisposed, isFalse);
    });

    test('reset 释放后可继续使用, dispose 释放', () {
      final image = _Probe(const Size(5, 6));
      final first = image.of(red);
      image.reset();
      expect(first.debugDisposed, isTrue);

      final second = image.of(red);
      expect(second, isNot(same(first)), reason: 'reset 后同色也重画');
      image.dispose();
      expect(second.debugDisposed, isTrue);
    });

    test('span 以逻辑尺寸占位, 图片即当前颜色的缓存', () {
      final image = _Probe(const Size(5, 6));
      addTearDown(image.dispose);

      final span = image.span(red);
      expect(span.size, const Size(5, 6));
      expect(span.image, same(image.of(red)));
    });
  });

  test('CircleImage 以短边为直径居中', () {
    final canvas = RecordingCanvas();
    final image = CircleImage(const Size(10, 6));
    addTearDown(image.dispose);
    image.draw(canvas, image.size, red);

    final args = canvas.invocations.single.positionalArguments;
    expect((args[0], args[1]), (const Offset(5, 3), 3.0));
  });

  group('TriangleImage', () {
    const size = Size(50, 60);

    /// 顶点 (w, h/2) 沿角平分线向内 [depth] 处的点。
    Offset insideTip(double depth) => Offset(size.width - depth, size.height / 2);

    test('radius 为 0 时是填满尺寸的尖角三角', () {
      final path = _pathOf(TriangleImage(size, radius: 0));
      expect(path.getBounds(), Offset.zero & size);
      expect(path.contains(insideTip(0.5)), isTrue);
    });

    test('圆角切掉尖端, 圆弧向外凸', () {
      const radius = 5.0;
      final path = _pathOf(TriangleImage(size, radius: radius));

      // 右顶点的半角: 两条边与水平线的夹角。
      final halfAngle = math.atan2(size.height / 2, size.width);
      // 圆角后尖端退到 r / sin(半角) - r。
      final tipDepth = radius / math.sin(halfAngle) - radius;
      expect(path.contains(insideTip(tipDepth - 0.5)), isFalse, reason: '尖端已被圆弧切掉');
      expect(path.contains(insideTip(tipDepth + 0.5)), isTrue, reason: '圆弧外凸; 方向画反会向内凹, 此点落在形状外');
    });

    test('半径过大时夹到邻边一半, 路径仍是凸形、不越界', () {
      final path = _pathOf(TriangleImage(size, radius: 1000));
      final bounds = path.getBounds();
      expect((Offset.zero & size).inflate(0.01).contains(bounds.topLeft), isTrue);
      expect((Offset.zero & size).inflate(0.01).contains(bounds.bottomRight), isTrue);
      expect(path.contains(Offset(size.width / 3, size.height / 2)), isTrue, reason: '质心仍在形状内');

      // 切点夹到邻边中点后, 圆弧半径随之缩小到仍与两边相切; 半径不缩小会把尖端削得更深。
      final halfAngle = math.atan2(size.height / 2, size.width);
      final r = math.sqrt(size.width * size.width + size.height * size.height / 4) / 2 * math.tan(halfAngle);
      final tipDepth = r / math.sin(halfAngle) - r;
      expect(path.contains(insideTip(tipDepth + 0.5)), isTrue);
      expect(path.contains(insideTip(tipDepth - 0.5)), isFalse);
    });
  });

  group('TriangleImage 方向', () {
    const size = Size(50, 60);
    // 每个方向: 尖端顶点、朝底边的单位向量、尖端一侧的盒角(应在外)、底边一侧的盒角(应在内)。
    const cases = [
      (AxisDirection.right, Offset(50, 30), Offset(-1, 0), Offset(49.5, 0.5), Offset(0.5, 0.5)),
      (AxisDirection.left, Offset(0, 30), Offset(1, 0), Offset(0.5, 0.5), Offset(49.5, 0.5)),
      (AxisDirection.up, Offset(25, 0), Offset(0, 1), Offset(0.5, 0.5), Offset(0.5, 59.5)),
      (AxisDirection.down, Offset(25, 60), Offset(0, -1), Offset(0.5, 59.5), Offset(0.5, 0.5)),
    ];

    for (final (direction, vertex, inward, tipCorner, baseCorner) in cases) {
      test('${direction.name}: 尖端朝向正确, 填满盒子', () {
        final path = _pathOf(TriangleImage(size, direction: direction, radius: 0));
        expect(path.getBounds(), Offset.zero & size);
        expect(path.contains(vertex + inward), isTrue);
        expect(path.contains(tipCorner), isFalse);
        expect(path.contains(baseCorner), isTrue);
      });

      test('${direction.name}: 圆角切掉尖端, 圆弧向外凸', () {
        const radius = 5.0;
        final path = _pathOf(TriangleImage(size, direction: direction, radius: radius));

        // 尖端半角: 横向半宽与纵深的夹角; 圆角后尖端退到 r / sin(半角) - r。
        final vertical = direction == AxisDirection.up || direction == AxisDirection.down;
        final halfAngle = vertical ? math.atan2(size.width / 2, size.height) : math.atan2(size.height / 2, size.width);
        final tipDepth = radius / math.sin(halfAngle) - radius;
        expect(path.contains(vertex + inward * (tipDepth - 0.5)), isFalse, reason: '尖端已被圆弧切掉');
        expect(path.contains(vertex + inward * (tipDepth + 0.5)), isTrue, reason: '顶点顺序反了圆弧会向内凹');
      });
    }
  });

  test('SquareImage 填满盒子, radius 为圆角', () {
    final canvas = RecordingCanvas();
    SquareImage(const Size(10, 6), radius: 2).draw(canvas, const Size(10, 6), red);
    expect(
      canvas.invocations.single.positionalArguments[0],
      RRect.fromLTRBR(0, 0, 10, 6, const Radius.circular(2)),
    );
  });

  group('roundedPolygon', () {
    test('子类可直接复用: radius 为 0 是原多边形, 否则切掉每个顶点', () {
      final image = _Probe(const Size(1, 1));
      addTearDown(image.dispose);
      const square = [Offset.zero, Offset(10, 0), Offset(10, 10), Offset(0, 10)];

      expect(image.roundedPolygon(square, 0).getBounds(), const Rect.fromLTRB(0, 0, 10, 10));
      final rounded = image.roundedPolygon(square, 2);
      expect(rounded.contains(const Offset(0.3, 0.3)), isFalse, reason: '直角被半径 2 的圆弧切掉');
      expect(rounded.contains(const Offset(1, 5)), isTrue);
    });
  });

  group('DiamondImage', () {
    const size = Size(40, 20);

    test('radius 为 0 时顶点落在各边中点, 四角留空', () {
      final path = _pathOf(DiamondImage(size, radius: 0));
      expect(path.getBounds(), Offset.zero & size);
      expect(path.contains(const Offset(20, 10)), isTrue);
      expect(path.contains(const Offset(2, 2)), isFalse, reason: '包围盒角落在菱形外');
      expect(path.contains(const Offset(39.5, 10)), isTrue, reason: '右顶点是尖角');
    });

    test('圆角切掉四个顶点, 包围盒随之收缩', () {
      final path = _pathOf(DiamondImage(size, radius: 3));
      final bounds = path.getBounds();
      expect(bounds.width, lessThan(size.width));
      expect(bounds.height, lessThan(size.height));
      expect(path.contains(const Offset(39.8, 10)), isFalse, reason: '尖端已被圆弧切掉');
      expect(path.contains(const Offset(20, 10)), isTrue);
    });
  });

  group('PlusImage / MinusImage', () {
    const size = Size(30, 30);

    test('PlusImage 默认臂宽为短边 1/3: 臂端与中心在内, 四角在外', () {
      final path = _pathOf(PlusImage(size));
      expect(path.getBounds(), Offset.zero & size);
      for (final point in const [
        Offset(15, 15),
        Offset(0.5, 15),
        Offset(29.5, 15),
        Offset(15, 0.5),
        Offset(15, 29.5),
      ]) {
        expect(path.contains(point), isTrue, reason: '$point');
      }
      expect(path.contains(const Offset(5, 10.5)), isTrue);
      expect(path.contains(const Offset(5, 9.5)), isFalse, reason: '臂宽 10: 横臂 y 在 [10, 20]');
    });

    test('PlusImage 的 thickness 指定臂宽', () {
      final path = _pathOf(PlusImage(size, thickness: 2));
      expect(path.contains(const Offset(5, 15.9)), isTrue);
      expect(path.contains(const Offset(5, 16.1)), isFalse);
      expect(path.contains(const Offset(15.9, 5)), isTrue);
      expect(path.contains(const Offset(16.1, 5)), isFalse);
    });

    test('MinusImage 是贯穿宽度的横杠, 竖向居中', () {
      expect(_rectOf(MinusImage(size)), const Rect.fromLTRB(0, 10, 30, 20));
    });

    test('MinusImage 的 thickness 指定杠高', () {
      expect(_rectOf(MinusImage(size, thickness: 4)), const Rect.fromLTRB(0, 13, 30, 17));
    });
  });

  group('ChevronImage / CrossImage', () {
    const size = Size(30, 20);

    test('描边画笔: 线宽默认短边 1/5, 圆头圆角; thickness 可指定', () {
      final (_, paint) = _strokeOf(ChevronImage(size));
      expect(
        (paint.style, paint.strokeWidth, paint.strokeCap, paint.strokeJoin),
        (
          PaintingStyle.stroke,
          4.0,
          StrokeCap.round,
          StrokeJoin.round,
        ),
      );
      expect(_strokeOf(CrossImage(size, thickness: 2)).$2.strokeWidth, 2);
    });

    test('笔画内缩半个线宽, 不画出盒子', () {
      final inset = (Offset.zero & size).deflate(2);
      expect(_strokeOf(ChevronImage(size)).$1.getBounds(), inset);
      expect(_strokeOf(CrossImage(size)).$1.getBounds(), inset);
    });

    test('Chevron 的折点(路径中点)朝向 direction', () {
      Offset apex(AxisDirection direction) {
        final metric = _strokeOf(ChevronImage(size, direction: direction)).$1.computeMetrics().single;
        return metric.getTangentForOffset(metric.length / 2)!.position;
      }

      expect(apex(AxisDirection.right), const Offset(28, 10));
      expect(apex(AxisDirection.left), const Offset(2, 10));
      expect(apex(AxisDirection.up), const Offset(15, 2));
      expect(apex(AxisDirection.down), const Offset(15, 18));
    });

    test('Cross 是两条对角线', () {
      final metrics = _strokeOf(CrossImage(size)).$1.computeMetrics().toList();
      expect(metrics, hasLength(2));
      expect(metrics.map((m) => m.getTangentForOffset(m.length / 2)!.position), [
        const Offset(15, 10),
        const Offset(15, 10),
      ]);
    });
  });

  group('StarImage', () {
    const size = Size(40, 40);
    final path = _pathOf(StarImage(size));
    // 圆心与外半径(StarImage 为居中下移半个高差)。
    final center = Offset(20, 20 + 20 * (1 - math.cos(math.pi / 5)) / 2);

    Offset at(double angle, double distance) => center + Offset.fromDirection(angle, distance);

    test('五个外顶点在内、相邻两臂之间的凹口在外', () {
      for (var i = 0; i < 5; i++) {
        final tip = i * 2 * math.pi / 5 - math.pi / 2;
        expect(path.contains(at(tip, 18)), isTrue, reason: '臂 $i');
        expect(path.contains(at(tip + math.pi / 5, 12)), isFalse, reason: '凹口 $i');
      }
      expect(path.contains(center), isTrue);
    });

    test('整体不超出盒子且垂直居中', () {
      final bounds = path.getBounds();
      expect(
        const Rect.fromLTWH(0, 0, 40, 40).inflate(0.01).expandToInclude(bounds),
        const Rect.fromLTWH(0, 0, 40, 40).inflate(0.01),
      );
      expect((bounds.top + bounds.bottom) / 2, closeTo(20, 0.01));
    });
  });

  group('BellImage', () {
    const size = Size(50, 50);
    final path = _pathOf(BellImage(size));

    test('钟身、顶钮与铃舌在内, 盒角与底沿两侧在外', () {
      for (final point in const [Offset(25, 25), Offset(25, 4), Offset(25, 45), Offset(12, 36), Offset(38, 36)]) {
        expect(path.contains(point), isTrue, reason: '$point');
      }
      for (final point in const [Offset(1, 1), Offset(1, 39), Offset(49, 39), Offset(25, 40)]) {
        expect(path.contains(point), isFalse, reason: '$point');
      }
    });

    test('整体不超出盒子', () {
      expect(const Rect.fromLTWH(0, 0, 50, 50).expandToInclude(path.getBounds()), const Rect.fromLTWH(0, 0, 50, 50));
    });
  });
}
