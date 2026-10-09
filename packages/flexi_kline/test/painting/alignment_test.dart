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
}
