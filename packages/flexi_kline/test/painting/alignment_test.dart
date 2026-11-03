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

void main() {
  const size = Size(40, 20);
  const anchor = Offset(100, 50);

  group('Alignment.place', () {
    const alignments = <String, Alignment>{
      'topLeft': Alignment.topLeft,
      'topCenter': Alignment.topCenter,
      'topRight': Alignment.topRight,
      'centerLeft': Alignment.centerLeft,
      'center': Alignment.center,
      'centerRight': Alignment.centerRight,
      'bottomLeft': Alignment.bottomLeft,
      'bottomCenter': Alignment.bottomCenter,
      'bottomRight': Alignment.bottomRight,
    };
    for (final MapEntry(key: name, value: alignment) in alignments.entries) {
      test('$name 对齐点落在 anchor 上', () {
        final rect = alignment.place(size, anchor);
        expect(rect.size, size);
        expect(rect.topLeft + alignment.alongSize(size), anchor);
      });
    }

    const bounds = Rect.fromLTWH(0, 0, 200, 100);
    final overflows = <String, (Alignment, Offset, Offset)>{
      '超出左边': (Alignment.topLeft, const Offset(-10, 40), const Offset(0, 40)),
      '超出上边': (Alignment.topLeft, const Offset(50, -5), const Offset(50, 0)),
      '超出右边': (Alignment.topRight, const Offset(230, 40), const Offset(160, 40)),
      '超出下边': (Alignment.bottomLeft, const Offset(50, 130), const Offset(50, 80)),
    };
    for (final MapEntry(key: name, value: (alignment, point, topLeft)) in overflows.entries) {
      test('$name 时平移回 bounds 内且尺寸不变', () {
        final rect = alignment.place(size, point, bounds);
        expect(rect.size, size);
        expect(rect.topLeft, topLeft);
        expect(bounds.contains(rect.topLeft) && rect.right <= bounds.right && rect.bottom <= bounds.bottom, isTrue);
      });
    }

    test('在 bounds 内时不平移', () {
      expect(Alignment.center.place(size, anchor, bounds), Alignment.center.place(size, anchor));
    });

    test('bounds 比 size 小时不抛异常, 贴左上', () {
      const small = Rect.fromLTWH(10, 10, 20, 10);
      late Rect rect;
      expect(() => rect = Alignment.bottomRight.place(size, anchor, small), returnsNormally);
      expect(rect.topLeft, small.topLeft);
      expect(rect.size, size);
    });
  });

  group('placeAround', () {
    // 目标是一根蜡烛: x ∈ [96, 104], y ∈ [40, 60]。
    const target = Rect.fromLTRB(96, 40, 104, 60);
    const spacing = 4.0;

    test('四个方向: 锚点为对应边中点外移 spacing, align 指向锚点', () {
      final cases = {
        AxisDirection.up: (const Offset(100, 36), Alignment.bottomCenter),
        AxisDirection.down: (const Offset(100, 64), Alignment.topCenter),
        AxisDirection.left: (const Offset(92, 50), Alignment.centerRight),
        AxisDirection.right: (const Offset(108, 50), Alignment.centerLeft),
      };
      for (final MapEntry(key: side, value: (anchor, align)) in cases.entries) {
        final placed = placeAround(target, size, side: side, spacing: spacing);
        expect(placed.side, side);
        expect(placed.anchor, anchor);
        expect(placed.align, align);
      }
    });

    test('首选侧放不下而对侧放得下时翻转', () {
      // 上方锚点 dy = 36, 气泡高 20, 顶边到 16; bounds.top = 20 时放不下, 下方到 84 放得下。
      const bounds = Rect.fromLTRB(0, 20, 200, 200);
      expect(
        placeAround(target, size, side: AxisDirection.up, spacing: spacing, bounds: bounds).side,
        AxisDirection.down,
      );
      // 横向: 左侧 92 - 40 = 52 < bounds.left 60。
      const narrow = Rect.fromLTRB(60, 0, 300, 100);
      expect(
        placeAround(target, size, side: AxisDirection.left, spacing: spacing, bounds: narrow).side,
        AxisDirection.right,
      );
    });

    test('首选侧放得下时不翻转; 恰好贴边也算放得下', () {
      const bounds = Rect.fromLTRB(0, 16, 200, 200);
      expect(
        placeAround(target, size, side: AxisDirection.up, spacing: spacing, bounds: bounds).side,
        AxisDirection.up,
      );
    });

    test('两侧都放不下时留在首选侧', () {
      const bounds = Rect.fromLTRB(0, 30, 200, 70);
      final placed = placeAround(target, size, side: AxisDirection.up, spacing: spacing, bounds: bounds);
      expect(placed.side, AxisDirection.up);
      expect(placed.anchor, const Offset(100, 36));
    });

    test('flip 为 false 时不翻转', () {
      const bounds = Rect.fromLTRB(0, 20, 200, 200);
      final placed = placeAround(target, size, side: AxisDirection.up, spacing: spacing, flip: false, bounds: bounds);
      expect(placed.side, AxisDirection.up);
    });

    test('无 bounds 时不翻转', () {
      expect(placeAround(target, size, side: AxisDirection.down).side, AxisDirection.down);
    });
  });
}
