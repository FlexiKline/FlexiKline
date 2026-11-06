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

// 相等性用例需要非 const 实例。
// ignore_for_file: prefer_const_constructors
import 'dart:math' as math;

import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../recording_canvas.dart';

const _black = Color(0xFF000000);

/// [shape] 在 [size] 内唯一一次绘制调用的位置参数。
List<Object?> _argsOf(IconShape shape, Size size) {
  final canvas = RecordingCanvas();
  shape.paint(canvas, size, _black);
  return canvas.invocations.single.positionalArguments;
}

/// 路径类图形画出的路径。
Path _pathOf(IconShape shape, Size size) => _argsOf(shape, size)[0] as Path;

/// 描边图标(Chevron / Cross)画出的路径与画笔。
(Path, Paint) _strokeOf(IconShape shape, Size size) {
  final args = _argsOf(shape, size);
  return (args[0] as Path, args[1] as Paint);
}

void main() {
  test('CircleShape 以短边为直径居中; strokeWidth 时画成不出界的圆环', () {
    final args = _argsOf(const CircleShape(), const Size(10, 6));
    expect((args[0], args[1], (args[2] as Paint).style), (const Offset(5, 3), 3.0, PaintingStyle.fill));

    final ring = _argsOf(const CircleShape(strokeWidth: 2), const Size(10, 6));
    final paint = ring[2] as Paint;
    expect((ring[0], ring[1], paint.style, paint.strokeWidth), (const Offset(5, 3), 2.0, PaintingStyle.stroke, 2.0));
  });

  group('TriangleShape', () {
    const size = Size(50, 60);

    /// 顶点 (w, h/2) 沿角平分线向内 [depth] 处的点。
    Offset insideTip(double depth) => Offset(size.width - depth, size.height / 2);

    test('radius 为 0 时是填满尺寸的尖角三角', () {
      final path = _pathOf(const TriangleShape(radius: 0), size);
      expect(path.getBounds(), Offset.zero & size);
      expect(path.contains(insideTip(0.5)), isTrue);
    });

    test('圆角切掉尖端, 圆弧向外凸', () {
      const radius = 5.0;
      final path = _pathOf(const TriangleShape(radius: radius), size);

      // 右顶点的半角: 两条边与水平线的夹角。
      final halfAngle = math.atan2(size.height / 2, size.width);
      // 圆角后尖端退到 r / sin(半角) - r。
      final tipDepth = radius / math.sin(halfAngle) - radius;
      expect(path.contains(insideTip(tipDepth - 0.5)), isFalse, reason: '尖端已被圆弧切掉');
      expect(path.contains(insideTip(tipDepth + 0.5)), isTrue, reason: '圆弧外凸; 方向画反会向内凹, 此点落在形状外');
    });

    test('半径过大时夹到邻边一半, 路径仍是凸形、不越界', () {
      final path = _pathOf(const TriangleShape(radius: 1000), size);
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

  group('TriangleShape 方向', () {
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
        final path = _pathOf(TriangleShape(direction: direction, radius: 0), size);
        expect(path.getBounds(), Offset.zero & size);
        expect(path.contains(vertex + inward), isTrue);
        expect(path.contains(tipCorner), isFalse);
        expect(path.contains(baseCorner), isTrue);
      });

      test('${direction.name}: 圆角切掉尖端, 圆弧向外凸', () {
        const radius = 5.0;
        final path = _pathOf(TriangleShape(direction: direction, radius: radius), size);

        // 尖端半角: 横向半宽与纵深的夹角; 圆角后尖端退到 r / sin(半角) - r。
        final vertical = direction == AxisDirection.up || direction == AxisDirection.down;
        final halfAngle = vertical ? math.atan2(size.width / 2, size.height) : math.atan2(size.height / 2, size.width);
        final tipDepth = radius / math.sin(halfAngle) - radius;
        expect(path.contains(vertex + inward * (tipDepth - 0.5)), isFalse, reason: '尖端已被圆弧切掉');
        expect(path.contains(vertex + inward * (tipDepth + 0.5)), isTrue, reason: '顶点顺序反了圆弧会向内凹');
      });
    }
  });

  test('SquareShape 填满盒子, radius 为圆角', () {
    expect(
      _argsOf(const SquareShape(radius: 2), const Size(10, 6))[0],
      RRect.fromLTRBR(0, 0, 10, 6, const Radius.circular(2)),
    );
  });

  test('SquareShape 的 strokeWidth 画成描边方框: 内收半个线宽, 外轮廓保持 radius', () {
    final args = _argsOf(const SquareShape(radius: 3, strokeWidth: 2), const Size(10, 6));
    expect(args[0], RRect.fromLTRBR(1, 1, 9, 5, const Radius.circular(2)));
    expect(((args[1] as Paint).style, (args[1] as Paint).strokeWidth), (PaintingStyle.stroke, 2.0));
  });

  group('DiamondShape', () {
    const size = Size(40, 20);

    test('radius 为 0 时顶点落在各边中点, 四角留空', () {
      final path = _pathOf(const DiamondShape(radius: 0), size);
      expect(path.getBounds(), Offset.zero & size);
      expect(path.contains(const Offset(20, 10)), isTrue);
      expect(path.contains(const Offset(2, 2)), isFalse, reason: '包围盒角落在菱形外');
      expect(path.contains(const Offset(39.5, 10)), isTrue, reason: '右顶点是尖角');
    });

    test('圆角切掉四个顶点, 包围盒随之收缩', () {
      final path = _pathOf(const DiamondShape(radius: 3), size);
      final bounds = path.getBounds();
      expect(bounds.width, lessThan(size.width));
      expect(bounds.height, lessThan(size.height));
      expect(path.contains(const Offset(39.8, 10)), isFalse, reason: '尖端已被圆弧切掉');
      expect(path.contains(const Offset(20, 10)), isTrue);
    });
  });

  group('PlusShape / MinusShape', () {
    const size = Size(30, 30);

    test('PlusShape 默认臂宽为短边 1/3: 臂端与中心在内, 四角在外', () {
      final path = _pathOf(const PlusShape(), size);
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

    test('PlusShape 的 thickness 指定臂宽', () {
      final path = _pathOf(const PlusShape(thickness: 2), size);
      expect(path.contains(const Offset(5, 15.9)), isTrue);
      expect(path.contains(const Offset(5, 16.1)), isFalse);
      expect(path.contains(const Offset(15.9, 5)), isTrue);
      expect(path.contains(const Offset(16.1, 5)), isFalse);
    });

    test('MinusShape 是贯穿宽度的横杠, 竖向居中', () {
      expect(_argsOf(const MinusShape(), size)[0], RRect.fromLTRBR(0, 10, 30, 20, Radius.zero));
    });

    test('MinusShape 的 thickness 指定杠高, radius 为两端圆角且不超过半个杠高', () {
      expect(_argsOf(const MinusShape(thickness: 4), size)[0], RRect.fromLTRBR(0, 13, 30, 17, Radius.zero));
      expect(
        _argsOf(const MinusShape(thickness: 4, radius: 9), size)[0],
        RRect.fromLTRBR(0, 13, 30, 17, const Radius.circular(2)),
      );
    });

    test('PlusShape 的 radius 让臂端变圆: 臂端角落在外, 臂端中点在内', () {
      final path = _pathOf(const PlusShape(thickness: 10, radius: 5), size);
      expect(path.contains(const Offset(0.5, 10.5)), isFalse, reason: '横臂左端的角已被圆角切掉');
      expect(path.contains(const Offset(0.5, 15)), isTrue);
    });
  });

  group('ChevronShape / CrossShape', () {
    const size = Size(30, 20);

    test('描边画笔: 线宽默认短边 1/5, 圆头圆角; thickness 可指定', () {
      final (_, paint) = _strokeOf(const ChevronShape(), size);
      expect(
        (paint.style, paint.strokeWidth, paint.strokeCap, paint.strokeJoin),
        (PaintingStyle.stroke, 4.0, StrokeCap.round, StrokeJoin.round),
      );
      expect(_strokeOf(const CrossShape(thickness: 2), size).$2.strokeWidth, 2);
    });

    test('笔画内缩半个线宽, 不画出盒子', () {
      final inset = (Offset.zero & size).deflate(2);
      expect(_strokeOf(const ChevronShape(), size).$1.getBounds(), inset);
      expect(_strokeOf(const CrossShape(), size).$1.getBounds(), inset);
    });

    test('Chevron 的折点(路径中点)朝向 direction', () {
      Offset apex(AxisDirection direction) {
        final metric = _strokeOf(ChevronShape(direction: direction), size).$1.computeMetrics().single;
        return metric.getTangentForOffset(metric.length / 2)!.position;
      }

      expect(apex(AxisDirection.right), const Offset(28, 10));
      expect(apex(AxisDirection.left), const Offset(2, 10));
      expect(apex(AxisDirection.up), const Offset(15, 2));
      expect(apex(AxisDirection.down), const Offset(15, 18));
    });

    test('Cross 是两条对角线', () {
      final metrics = _strokeOf(const CrossShape(), size).$1.computeMetrics().toList();
      expect(metrics, hasLength(2));
      expect(metrics.map((m) => m.getTangentForOffset(m.length / 2)!.position), [
        const Offset(15, 10),
        const Offset(15, 10),
      ]);
    });
  });

  group('CirclePlusShape', () {
    test('圆环居中, 横竖两臂穿过圆心、贯穿到环上', () {
      final (path, paint) = _strokeOf(const CirclePlusShape(), const Size(40, 30));
      expect((paint.style, paint.strokeWidth), (PaintingStyle.stroke, 3.0), reason: '默认线宽为短边 1/10');
      expect(path.getBounds(), rectMoreOrLessEquals(Rect.fromCircle(center: const Offset(20, 15), radius: 13.5)));

      // 前两条轮廓是横臂与竖臂, 各长一个直径; 最后一条是圆环。
      final arms = path.computeMetrics().take(2).toList();
      expect(arms.map((m) => m.length), [27.0, 27.0]);
      expect(arms.map((m) => m.getTangentForOffset(m.length / 2)!.position), [
        const Offset(20, 15),
        const Offset(20, 15),
      ]);
    });

    test('thickness 指定线宽, 环随之内缩', () {
      final (path, paint) = _strokeOf(const CirclePlusShape(thickness: 6), const Size(30, 30));
      expect(paint.strokeWidth, 6);
      expect(path.getBounds(), rectMoreOrLessEquals(Rect.fromCircle(center: const Offset(15, 15), radius: 12)));
    });

    test('plusRatio 控制臂长占直径的比例', () {
      final (path, _) = _strokeOf(const CirclePlusShape(plusRatio: 0.5), const Size(40, 30));
      expect(path.computeMetrics().take(2).map((m) => m.length), [13.5, 13.5]);
    });

    test('plusThickness 与环宽不同时, 环与加号分两笔各用各的线宽', () {
      final canvas = RecordingCanvas();
      const CirclePlusShape(thickness: 2, plusThickness: 4).paint(canvas, const Size(30, 30), _black);
      expect(canvas.invocations.map((i) => i.memberName), [#drawCircle, #drawPath]);
      expect((canvas.invocations[0].positionalArguments[2] as Paint).strokeWidth, 2);
      expect((canvas.invocations[1].positionalArguments[1] as Paint).strokeWidth, 4);
    });
  });

  test('StarShape 的 points 与 innerRatio: 六角星有 12 个顶点, 内凹顶点按比例收进', () {
    final path = _pathOf(const StarShape(points: 6, innerRatio: 0.5), const Size(40, 40));
    const center = Offset(20, 20);
    // 偶数角上下对称, 不做竖直偏移; 内凹顶点在外半径一半处。
    expect(path.contains(center + Offset.fromDirection(-math.pi / 2 + math.pi / 6, 9.5)), isTrue);
    expect(path.contains(center + Offset.fromDirection(-math.pi / 2 + math.pi / 6, 10.5)), isFalse);
    expect(path.getBounds().top, closeTo(0, 0.01));
    expect(path.getBounds().bottom, closeTo(40, 0.01));
  });

  group('StarShape', () {
    const size = Size(40, 40);
    final path = _pathOf(const StarShape(), size);
    // 圆心与外半径(StarShape 为居中下移半个高差)。
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

  group('BellShape', () {
    const size = Size(50, 50);
    final path = _pathOf(const BellShape(), size);

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

  group('相等性', () {
    // 每行: 名称、const 基准、参数相同的非 const 实例(避免 identical 掩盖相等运算符)、各改一个参数或换类型的实例。
    final cases = <(String, IconShape, IconShape, List<IconShape>)>[
      (
        'TriangleShape',
        const TriangleShape(),
        TriangleShape(direction: AxisDirection.right, radius: 0.5),
        const [TriangleShape(direction: AxisDirection.up), TriangleShape(radius: 1)],
      ),
      ('DiamondShape', const DiamondShape(), DiamondShape(radius: 0.5), const [DiamondShape(radius: 1)]),
      (
        'SquareShape',
        const SquareShape(),
        SquareShape(radius: 0),
        const [SquareShape(radius: 1), SquareShape(strokeWidth: 1)],
      ),
      (
        'PlusShape',
        const PlusShape(thickness: 2),
        PlusShape(thickness: 2),
        const [PlusShape(), PlusShape(thickness: 2, radius: 1), MinusShape(thickness: 2)],
      ),
      (
        'MinusShape',
        const MinusShape(thickness: 2),
        MinusShape(thickness: 2),
        const [MinusShape(), MinusShape(thickness: 2, radius: 1)],
      ),
      (
        'ChevronShape',
        const ChevronShape(thickness: 2),
        ChevronShape(thickness: 2),
        const [ChevronShape(direction: AxisDirection.left, thickness: 2), ChevronShape()],
      ),
      ('CrossShape', const CrossShape(thickness: 2), CrossShape(thickness: 2), const [CrossShape()]),
      (
        'CirclePlusShape',
        const CirclePlusShape(thickness: 2),
        CirclePlusShape(thickness: 2),
        const [
          CirclePlusShape(),
          CirclePlusShape(thickness: 2, plusThickness: 3),
          CirclePlusShape(thickness: 2, plusRatio: 0.5),
          PlusShape(thickness: 2),
        ],
      ),
      ('CircleShape', const CircleShape(), CircleShape(), const [CircleShape(strokeWidth: 1), StarShape()]),
      (
        'StarShape',
        const StarShape(),
        StarShape(points: 5, innerRatio: 0.4),
        const [StarShape(points: 6), StarShape(innerRatio: 0.5), BellShape()],
      ),
      ('BellShape', const BellShape(), BellShape(), const [CircleShape()]),
    ];

    for (final (name, base, equal, others) in cases) {
      test('$name: 参数相同则相等, 任一参数或类型不同则不等', () {
        expect(equal, isNot(same(base)));
        expect(equal, base);
        expect(equal.hashCode, base.hashCode);
        for (final other in others) {
          expect(other, isNot(base), reason: '$other');
        }
      });
    }
  });
}
