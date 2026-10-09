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
