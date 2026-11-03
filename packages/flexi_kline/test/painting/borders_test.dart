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
import 'dart:ui' show PictureRecorder;

import 'package:flexi_kline/src/painting/export.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

/// 沿路径每 0.25 逻辑像素取一个点, 用于逐点检查轮廓。
List<Offset> _samples(Path path) => [
  for (final metric in path.computeMetrics())
    for (var d = 0.0; d <= metric.length; d += 0.25) metric.getTangentForOffset(d)!.position,
];

void main() {
  const arrowSize = Size(10, 6);
  const half = 5.0;
  const h = 6.0;
  const radius = 4.0;
  // 不放在原点: 锚点相对 body 左上角, 绝对坐标 = body.topLeft + arrow。
  const body = Rect.fromLTWH(20, 10, 100, 40);

  BubbleBorder bubble(AxisDirection direction, [Offset? arrow]) => BubbleBorder(
    borderRadius: const BorderRadius.all(Radius.circular(radius)),
    direction: direction,
    arrowSize: arrowSize,
    arrow: arrow,
  );

  group('outsets', () {
    test('四个方向只在对应边外延 arrowSize.height', () {
      expect(bubble(AxisDirection.up).outsets, const EdgeInsets.only(top: h));
      expect(bubble(AxisDirection.down).outsets, const EdgeInsets.only(bottom: h));
      expect(bubble(AxisDirection.left).outsets, const EdgeInsets.only(left: h));
      expect(bubble(AxisDirection.right).outsets, const EdgeInsets.only(right: h));
    });
  });

  group('anchorTo', () {
    test('只改 arrow, 保留其余字段', () {
      const origin = BubbleBorder(
        side: BorderSide(width: 2, color: Color(0xFF00FF00)),
        borderRadius: BorderRadius.all(Radius.circular(6)),
        direction: AxisDirection.left,
        arrowSize: Size(8, 4),
      );
      const anchor = Offset(3, 7);
      final anchored = origin.anchorTo(anchor);
      expect(anchored.arrow, anchor);
      expect(anchored.side, origin.side);
      expect(anchored.borderRadius, origin.borderRadius);
      expect(anchored.direction, origin.direction);
      expect(anchored.arrowSize, origin.arrowSize);
    });
  });

  group('getOuterPath: down', () {
    test('尖端对准相对 body 左上角的 arrow', () {
      const arrow = Offset(30, 40 + h);
      final tip = body.topLeft + arrow; // (50, 56)
      final path = bubble(AxisDirection.down).anchorTo(arrow).getOuterPath(body);
      expect(path.getBounds().bottom, body.bottom + h);
      expect(path.getBounds().top, body.top);
      expect(path.contains(tip - const Offset(0, 0.5)), isTrue);
      expect(path.contains(Offset(tip.dx - half - 2, tip.dy - 0.5)), isFalse);
      expect(path.contains(Offset(tip.dx + half + 2, tip.dy - 0.5)), isFalse);
      expect(path.contains(body.center), isTrue);
    });

    test('rect 平移时尖端跟着平移同样距离(阴影以 rect.shift 调 getOuterPath)', () {
      const shift = Offset(7, 3);
      final border = bubble(AxisDirection.down).anchorTo(const Offset(30, 40 + h));
      final path = border.getOuterPath(body);
      final shifted = border.getOuterPath(body.shift(shift));
      expect(shifted.getBounds(), path.getBounds().shift(shift));
      final tip = body.topLeft + const Offset(30, 40 + h - 0.5);
      expect(shifted.contains(tip + shift), isTrue);
      expect(shifted.contains(tip), isFalse);
    });

    test('arrow 远在左侧时尖端夹到左圆角之外 + 半个根宽', () {
      const arrow = Offset(-50, 40 + h);
      final path = bubble(AxisDirection.down).anchorTo(arrow).getOuterPath(body);
      final clamped = body.left + radius + half;
      expect(path.contains(Offset(clamped, body.bottom + h - 0.5)), isTrue);
      expect(path.contains(body.topLeft + arrow - const Offset(0, 0.5)), isFalse);
      // 尖端不越过左圆角进入角区。
      expect(path.contains(Offset(body.left + 1, body.bottom + 1)), isFalse);
    });

    test('arrow 远在右侧时尖端夹到右圆角之外 + 半个根宽', () {
      const arrow = Offset(300, 40 + h);
      final path = bubble(AxisDirection.down).anchorTo(arrow).getOuterPath(body);
      final clamped = body.right - radius - half;
      expect(path.contains(Offset(clamped, body.bottom + h - 0.5)), isTrue);
      expect(path.contains(body.topLeft + arrow - const Offset(0, 0.5)), isFalse);
    });

    test('arrow 为 null 时对准边中点', () {
      final path = bubble(AxisDirection.down).getOuterPath(body);
      expect(path.contains(Offset(body.center.dx, body.bottom + h - 0.5)), isTrue);
    });
  });

  group('getOuterPath: 其余方向', () {
    test('up 向上伸出', () {
      const arrow = Offset(60, -h);
      final path = bubble(AxisDirection.up).anchorTo(arrow).getOuterPath(body);
      expect(path.getBounds().top, body.top - h);
      expect(path.getBounds().bottom, body.bottom);
      expect(path.contains(body.topLeft + arrow + const Offset(0, 0.5)), isTrue);
    });

    test('left 向左伸出', () {
      const arrow = Offset(-h, 20);
      final path = bubble(AxisDirection.left).anchorTo(arrow).getOuterPath(body);
      expect(path.getBounds().left, body.left - h);
      expect(path.getBounds().right, body.right);
      expect(path.contains(body.topLeft + arrow + const Offset(0.5, 0)), isTrue);
    });

    test('right 向右伸出, 夹到下圆角之外', () {
      const arrow = Offset(100 + h, 200);
      final path = bubble(AxisDirection.right).anchorTo(arrow).getOuterPath(body);
      expect(path.getBounds().right, body.right + h);
      expect(path.getBounds().left, body.left);
      expect(path.contains(Offset(body.right + h - 0.5, body.bottom - radius - half)), isTrue);
    });
  });

  group('直边放不下根宽', () {
    // 每条边的直边 = 边长 12 - 两侧圆角 8 = 4, 小于根宽 10; 直边横跨 x ∈ [24, 28]、y ∈ [14, 18]。
    const narrow = Rect.fromLTWH(20, 10, 12, 12);
    const eps = 1e-3;

    for (final direction in AxisDirection.values) {
      test('$direction: 根宽收缩到直边长度、中心取直边中点, 路径不越过圆角端点', () {
        // arrow 远在角外: 收缩后中心固定在直边中点, 不再夹取。
        final path = bubble(direction, const Offset(-100, -100)).getOuterPath(narrow);
        final (lo, hi, tip) = switch (direction) {
          AxisDirection.up => (24.0, 28.0, Offset(narrow.center.dx, narrow.top - h + 0.5)),
          AxisDirection.down => (24.0, 28.0, Offset(narrow.center.dx, narrow.bottom + h - 0.5)),
          AxisDirection.left => (14.0, 18.0, Offset(narrow.left - h + 0.5, narrow.center.dy)),
          AxisDirection.right => (14.0, 18.0, Offset(narrow.right + h - 0.5, narrow.center.dy)),
        };
        expect(path.contains(tip), isTrue);

        // 逐点检查: 伸出 body 的部分(即箭头)沿边的坐标都落在直边之内。
        final vertical = direction == AxisDirection.up || direction == AxisDirection.down;
        final along = [
          for (final p in _samples(path))
            if (switch (direction) {
              AxisDirection.up => p.dy < narrow.top - eps,
              AxisDirection.down => p.dy > narrow.bottom + eps,
              AxisDirection.left => p.dx < narrow.left - eps,
              AxisDirection.right => p.dx > narrow.right + eps,
            })
              vertical ? p.dx : p.dy,
        ];
        expect(along, isNotEmpty);
        for (final value in along) {
          expect(value, inInclusiveRange(lo - eps, hi + eps));
        }
      });
    }

    for (final direction in AxisDirection.values) {
      test('$direction: 直边长度为 0 时不画箭头, 路径即圆角矩形, outsets 保留', () {
        // 边长 8 = 两侧圆角 8。
        const square = Rect.fromLTWH(20, 10, 8, 8);
        final border = bubble(direction, const Offset(4, 4));
        final path = border.getOuterPath(square);
        expect(path.getBounds(), square);
        expect(path.contains(square.center), isTrue);
        // 四个角在圆弧之外。
        for (final corner in [square.topLeft, square.topRight, square.bottomRight, square.bottomLeft]) {
          expect(path.contains(corner + (square.center - corner) * 0.05), isFalse);
        }
        expect(border.outsets, isNot(EdgeInsets.zero));
      });
    }
  });

  group('圆角超过半边', () {
    test('像 RRect 一样等比缩小: 胶囊形左右两端只有圆弧, 没有竖直线段', () {
      // body 高 40, 圆角 30: 上下相邻圆角之和 60 > 40, 缩到 20, 即胶囊形。
      const border = BubbleBorder(borderRadius: BorderRadius.all(Radius.circular(30)), arrowSize: arrowSize);
      const r = 20.0;
      final left = Offset(body.left + r, body.center.dy);
      final right = Offset(body.right - r, body.center.dy);
      for (final p in _samples(border.getOuterPath(body))) {
        // 两端各是半径 20 的半圆: 采样点到圆心的距离等于半径。
        if (p.dx < left.dx) expect((p - left).distance, closeTo(r, 0.1), reason: '$p');
        if (p.dx > right.dx) expect((p - right).distance, closeTo(r, 0.1), reason: '$p');
      }
      // 箭头仍在下边的直边上。
      expect(border.getOuterPath(body).contains(Offset(body.center.dx, body.bottom + h - 0.5)), isTrue);
    });
  });

  group('arrowRadius', () {
    const r = 2.0;
    BubbleBorder rounded(AxisDirection direction, [Offset? arrow]) => BubbleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(radius)),
      direction: direction,
      arrowSize: arrowSize,
      arrowRadius: r,
      arrow: arrow,
    );
    // 根部切线长 r * tan(atan2(h, half) / 2)。
    final root = r * math.tan(math.atan2(h, half) / 2);

    test('尖端倒圆: 几何尖端附近不在路径内, 尖端内缩不超过 r', () {
      const arrow = Offset(50, 40 + h);
      final tip = body.topLeft + arrow;
      final sharp = bubble(AxisDirection.down).anchorTo(arrow).getOuterPath(body);
      final path = rounded(AxisDirection.down).anchorTo(arrow).getOuterPath(body);
      expect(sharp.contains(tip - const Offset(0, 0.5)), isTrue);
      expect(path.contains(tip - const Offset(0, 0.5)), isFalse);
      // getBounds 含圆弧控制点(即几何尖端), 取轮廓采样的最低点。
      final lowest = _samples(path).map((p) => p.dy).reduce(math.max);
      expect(lowest, inExclusiveRange(tip.dy - r, tip.dy - 0.5));
      expect(path.contains(tip - const Offset(0, 2)), isTrue);
    });

    test('根部倒圆: 腰与底边的凹角被圆弧填平', () {
      const arrow = Offset(50, 40 + h);
      final rootPoint = Offset(body.left + arrow.dx + half, body.bottom);
      final sharp = bubble(AxisDirection.down).anchorTo(arrow).getOuterPath(body);
      final path = rounded(AxisDirection.down).anchorTo(arrow).getOuterPath(body);
      const probe = Offset(0.2, 0.05);
      expect(sharp.contains(rootPoint + probe), isFalse);
      expect(path.contains(rootPoint + probe), isTrue);
    });

    test('四个方向的尖端都倒圆', () {
      for (final direction in AxisDirection.values) {
        final path = rounded(direction).getOuterPath(body);
        final tip = switch (direction) {
          AxisDirection.up => Offset(body.center.dx, body.top - h + 0.5),
          AxisDirection.down => Offset(body.center.dx, body.bottom + h - 0.5),
          AxisDirection.left => Offset(body.left - h + 0.5, body.center.dy),
          AxisDirection.right => Offset(body.right + h - 0.5, body.center.dy),
        };
        expect(path.contains(tip), isFalse, reason: '$direction');
        expect(path.contains(body.center), isTrue, reason: '$direction');
      }
    });

    test('arrow 远在左侧时中心多让出根部切线长, 箭头不越过左圆角端点', () {
      final path = rounded(AxisDirection.down, const Offset(-50, 40 + h)).getOuterPath(body);
      final below = [
        for (final p in _samples(path))
          if (p.dy > body.bottom + 1e-3) p,
      ];
      final lowest = below.reduce((a, b) => a.dy >= b.dy ? a : b);
      expect(lowest.dx, closeTo(body.left + radius + half + root, 0.3));
      for (final p in below) {
        expect(p.dx, greaterThanOrEqualTo(body.left + radius - 1e-3));
      }
    });

    test('anchorTo、scale 与 == 带上 arrowRadius', () {
      final border = rounded(AxisDirection.down);
      expect(border.anchorTo(const Offset(1, 1)).arrowRadius, r);
      expect(border.scale(2).arrowRadius, 2 * r);
      expect(border == bubble(AxisDirection.down), isFalse);
    });
  });

  group('描边', () {
    const side = BorderSide(width: 2, color: Color(0xFFFF0000));
    const border = BubbleBorder(side: side, borderRadius: BorderRadius.all(Radius.circular(radius)));

    test('dimensions 为 inside 描边宽度', () {
      expect(border.dimensions, const EdgeInsets.all(2));
      expect(const BubbleBorder().dimensions, EdgeInsets.zero);
    });

    test('getInnerPath 按描边宽度内缩', () {
      final inner = border.getInnerPath(body).getBounds();
      expect(inner.left, body.left + 2);
      expect(inner.top, body.top + 2);
      expect(inner.right, body.right - 2);
    });

    test('paint 只画一次路径, 中心线内缩半个线宽', () {
      final canvas = RecordingCanvas();
      border.paint(canvas, body);
      expect(canvas.countOf(#drawPath), 1);
      final bounds = canvas.pathBounds.single;
      expect(bounds.left, body.left + 1);
      expect(bounds.top, body.top + 1);
      final paint = canvas.invocations.single.positionalArguments[1] as Paint;
      expect(paint.style, PaintingStyle.stroke);
      expect(paint.strokeWidth, 2);
      expect(paint.color, side.color);
    });

    test('无边框时 paint 不画', () {
      final canvas = RecordingCanvas();
      bubble(AxisDirection.down).paint(canvas, body);
      expect(canvas.invocations, isEmpty);
    });
  });

  group('BubbleBorder.gradient', () {
    const side = BorderSide(width: 2, color: Color(0x80FF0000));
    // decal: shader 区域之外透明, 区域若只取 body 则箭头画不出来。
    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF00FF00), Color(0xFF00FF00)],
      tileMode: TileMode.decal,
    );
    const border = BubbleBorder(
      side: side,
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      arrowSize: arrowSize,
      gradient: gradient,
    );

    test('描边画笔挂 shader, 画笔色不透明以免 alpha 叠乘', () {
      final canvas = RecordingCanvas();
      border.paint(canvas, body);
      expect(canvas.countOf(#drawPath), 1);
      final paint = canvas.invocations.single.positionalArguments[1] as Paint;
      expect(paint.shader, isNotNull);
      expect(paint.color.a, 1);
      expect(paint.strokeWidth, 2);
    });

    test('着色区域含箭头: 栅格化后箭头处有像素', () async {
      final recorder = PictureRecorder();
      border.paint(Canvas(recorder), body);
      final image = recorder.endRecording().toImageSync(140, 70);
      addTearDown(image.dispose);
      final bytes = (await image.toByteData())!;
      var painted = 0;
      for (var y = (body.bottom + 1).ceil(); y < 70; y++) {
        for (var x = 0; x < 140; x++) {
          if (bytes.getUint8((y * 140 + x) * 4 + 3) > 0) painted++;
        }
      }
      expect(painted, greaterThan(0));
    });

    test('anchorTo、scale 与 == 带上 gradient', () {
      expect(border.anchorTo(const Offset(1, 1)).gradient, gradient);
      expect(border.scale(2).gradient, gradient);
      expect(
        border == const BubbleBorder(side: side, borderRadius: BorderRadius.all(Radius.circular(radius))),
        isFalse,
      );
    });
  });

  group('GradientRoundedRectangleBorder', () {
    const gradient = LinearGradient(colors: [Color(0xFF00FF00), Color(0xFF0000FF)]);
    const side = BorderSide(width: 2, color: Color(0xFFFF0000));
    const border = GradientRoundedRectangleBorder(
      side: side,
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      gradient: gradient,
    );

    test('按 strokeAlign 填充内外轮廓之间, 画笔挂 shader', () {
      final canvas = RecordingCanvas();
      border.paint(canvas, body);
      final args = canvas.invocations.single.positionalArguments;
      expect(canvas.invocations.single.memberName, #drawDRRect);
      expect((args[0] as RRect).outerRect, body);
      expect((args[1] as RRect).outerRect, body.deflate(2));
      expect((args[2] as Paint).shader, isNotNull);
    });

    test('线宽 0 画细线; 无边框时不画', () {
      final hairline = RecordingCanvas();
      border.copyWith(side: const BorderSide(width: 0)).paint(hairline, body);
      expect(hairline.rrectBounds, [body]);
      expect((hairline.invocations.single.positionalArguments[1] as Paint).shader, isNotNull);

      final none = RecordingCanvas();
      border.copyWith(side: BorderSide.none).paint(none, body);
      expect(none.invocations, isEmpty);
    });

    test('copyWith 与 scale 保留 gradient, 仍是 RoundedRectangleBorder', () {
      final copied = border.copyWith(borderRadius: BorderRadius.zero);
      expect(copied.gradient, gradient);
      expect(copied.side, side);
      expect(
        border.scale(2),
        const GradientRoundedRectangleBorder(
          side: BorderSide(width: 4, color: Color(0xFFFF0000)),
          borderRadius: BorderRadius.all(Radius.circular(radius * 2)),
          gradient: gradient,
        ),
      );
      expect(border, isA<RoundedRectangleBorder>());
    });

    test('== 区分渐变, 与同参的 RoundedRectangleBorder 不等', () {
      expect(border, border.copyWith());
      expect(border.hashCode, border.copyWith().hashCode);
      expect(
        border == border.copyWith(gradient: const LinearGradient(colors: [Color(0xFF000000), Color(0xFFFFFFFF)])),
        isFalse,
      );
      expect(
        border == const RoundedRectangleBorder(side: side, borderRadius: BorderRadius.all(Radius.circular(radius))),
        isFalse,
      );
    });
  });

  group('scale / == / hashCode', () {
    test('scale(2) 放大边框、圆角、箭头与相对锚点, 保留方向', () {
      const origin = BubbleBorder(
        side: BorderSide(width: 1),
        borderRadius: BorderRadius.all(Radius.circular(3)),
        direction: AxisDirection.up,
        arrowSize: Size(10, 6),
        arrow: Offset(1, 2),
      );
      expect(
        origin.scale(2),
        const BubbleBorder(
          side: BorderSide(width: 2),
          borderRadius: BorderRadius.all(Radius.circular(6)),
          direction: AxisDirection.up,
          arrowSize: Size(20, 12),
          arrow: Offset(2, 4),
        ),
      );
    });

    test('等值实例相等且哈希一致, 任一字段不同则不等', () {
      final a = bubble(AxisDirection.down, const Offset(1, 1));
      final b = bubble(AxisDirection.down, const Offset(1, 1));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == bubble(AxisDirection.up, const Offset(1, 1)), isFalse);
      expect(a == bubble(AxisDirection.down, const Offset(2, 1)), isFalse);
      expect(a == a.scale(2), isFalse);
    });
  });
}
