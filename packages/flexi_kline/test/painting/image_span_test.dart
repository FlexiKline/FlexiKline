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

import 'dart:ui' as ui;

import 'package:flexi_kline/src/painting/export.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'painting_doubles.dart';

/// ImageSpan 原型: 不经 setPlaceholderDimensions 也能排版, 占位框与 span 先序一一对应。
void main() {
  late ui.Image img1;
  late ui.Image img2;

  setUp(() {
    img1 = solidImage(4, 4);
    img2 = solidImage(8, 8);
  });

  tearDown(() {
    img1.dispose();
    img2.dispose();
  });

  group('ImageSpan 排版', () {
    test('含 ImageSpan 的 TextPainter 能 layout, 占位框数量/顺序/尺寸与 span 先序一致', () {
      final painter = TextPainter(
        text: TextSpan(
          children: [
            const TextSpan(text: 'a'),
            ImageSpan(img1, const Size(10, 12)),
            const TextSpan(text: 'b'),
            ImageSpan(img2, const Size(16, 16)),
          ],
        ),
        textDirection: TextDirection.ltr,
      );
      expect(painter.layout, returnsNormally);

      final boxes = painter.inlinePlaceholderBoxes!;
      expect(boxes, hasLength(2));
      expect(boxes[0].toRect().size, const Size(10, 12));
      expect(boxes[1].toRect().size, const Size(16, 16));
      expect(boxes[0].left, lessThan(boxes[1].left));
      painter.dispose();
    });

    test('经 TextLayoutCache 挂到根 span 下同样能 layout', () {
      final cache = TextLayoutCache()..configure(const LabelStyle(text: TextStyle(fontSize: 10)));
      final painter = cache.layout(
        'img',
        build: () => TextSpan(
          children: [
            ImageSpan(img1, const Size(10, 12)),
            const TextSpan(text: 'x'),
          ],
        ),
      );
      final boxes = painter.inlinePlaceholderBoxes!;
      expect(boxes, hasLength(1));
      expect(boxes.single.toRect().size, const Size(10, 12));
      expect(painter.width, 20);
      cache.dispose();
    });
  });

  group('compareTo', () {
    test('同实例 identical', () {
      final span = ImageSpan(img1, const Size(10, 10));
      expect(span.compareTo(span), RenderComparison.identical);
    });

    test('等字段新实例 identical', () {
      expect(
        ImageSpan(img1, const Size(10, 10)).compareTo(ImageSpan(img1, const Size(10, 10))),
        RenderComparison.identical,
      );
    });

    test('换 size → layout', () {
      expect(
        ImageSpan(img1, const Size(10, 10)).compareTo(ImageSpan(img1, const Size(12, 10))),
        RenderComparison.layout,
      );
    });

    test('换 image → layout', () {
      expect(
        ImageSpan(img1, const Size(10, 10)).compareTo(ImageSpan(img2, const Size(10, 10))),
        RenderComparison.layout,
      );
    });

    test('换 alignment → layout', () {
      expect(
        ImageSpan(
          img1,
          const Size(10, 10),
        ).compareTo(ImageSpan(img1, const Size(10, 10), alignment: ui.PlaceholderAlignment.top)),
        RenderComparison.layout,
      );
    });

    test('与其他类型 span 比较 → layout', () {
      expect(ImageSpan(img1, const Size(10, 10)).compareTo(const TextSpan(text: 'x')), RenderComparison.layout);
    });
  });

  group('== / hashCode', () {
    test('同一图片同字段相等且哈希一致', () {
      final a = ImageSpan(img1, const Size(10, 10));
      final b = ImageSpan(img1, const Size(10, 10));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('按图片身份与尺寸区分', () {
      final a = ImageSpan(img1, const Size(10, 10));
      expect(a == ImageSpan(img2, const Size(10, 10)), isFalse);
      expect(a == ImageSpan(img1, const Size(11, 10)), isFalse);
    });

    test('同像素的不同图片实例不相等', () {
      final other = solidImage(4, 4);
      expect(ImageSpan(img1, const Size(10, 10)) == ImageSpan(other, const Size(10, 10)), isFalse);
      other.dispose();
    });
  });
}
