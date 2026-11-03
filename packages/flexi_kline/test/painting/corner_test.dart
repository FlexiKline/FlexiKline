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

import 'package:flexi_kline/src/painting/corner.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('roundCorner', () {
    // 向右再向下: 屏幕坐标下顺时针转向。
    const prev = Offset(0, 0);
    const vertex = Offset(10, 0);
    const next = Offset(10, 10);

    test('直角: 切点距顶点 r, 圆弧半径 r, 顺时针', () {
      final corner = roundCorner(prev, vertex, next, 2)!;
      expect(corner.start, const Offset(8, 0));
      expect(corner.end.dx, closeTo(10, 1e-9));
      expect(corner.end.dy, closeTo(2, 1e-9));
      expect(corner.radius.x, closeTo(2, 1e-9));
      expect(corner.clockwise, isTrue);
    });

    test('反向折线转向相反, 圆弧逆时针', () {
      final corner = roundCorner(next, vertex, prev, 2)!;
      expect(corner.clockwise, isFalse);
      expect(corner.start.dy, closeTo(2, 1e-9));
      expect(corner.end, const Offset(8, 0));
    });

    test('半径过大时切点夹到较短邻边的一半, 圆弧随之缩小', () {
      final corner = roundCorner(prev, vertex, const Offset(10, 4), 100)!;
      expect(corner.start, const Offset(8, 0));
      expect(corner.end.dy, closeTo(2, 1e-9));
      expect(corner.radius.x, closeTo(2, 1e-9));
    });

    test('半径为 0、邻边退化或三点共线时返回 null', () {
      expect(roundCorner(prev, vertex, next, 0), isNull);
      expect(roundCorner(vertex, vertex, next, 2), isNull);
      expect(roundCorner(prev, vertex, vertex, 2), isNull);
      expect(roundCorner(prev, vertex, const Offset(20, 0), 2), isNull);
    });
  });

  test('cornerTo 不能倒圆时直接连到顶点', () {
    final path = Path()
      ..moveTo(0, 0)
      ..cornerTo(Offset.zero, const Offset(10, 0), const Offset(10, 10), 0)
      ..lineTo(10, 10)
      ..close();
    // 尖角保留: 顶点附近仍在路径内。
    expect(path.contains(const Offset(9.9, 0.1)), isTrue);
  });
}
