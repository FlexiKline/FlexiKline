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

import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记下每次 [paint] 收到的尺寸与颜色。
final class _Probe extends IconShape {
  _Probe();

  final paints = <(Size, Color)>[];

  @override
  void paint(Canvas canvas, Size size, Color color) => paints.add((size, color));
}

void main() {
  const red = Color(0xFFFF0000);
  const blue = Color(0xFF0000FF);

  test('同色复用同一张图, 只画一次', () {
    final shape = _Probe();
    final image = ShapeImage(shape, const Size(5, 6));
    addTearDown(image.dispose);

    final first = image.of(red);
    expect(image.of(red), same(first));
    expect(shape.paints, [(const Size(5, 6), red)], reason: 'paint 收到逻辑尺寸');
  });

  test('位图尺寸 = 逻辑尺寸 x rasterScale, 向上取整', () {
    final image = ShapeImage(_Probe(), const Size(5, 6.1), rasterScale: 3);
    addTearDown(image.dispose);

    final bitmap = image.of(red);
    expect((bitmap.width, bitmap.height), (15, 19));
  });

  test('换色重建并释放旧图', () {
    final image = ShapeImage(_Probe(), const Size(5, 6));
    addTearDown(image.dispose);

    final first = image.of(red);
    final second = image.of(blue);
    expect(second, isNot(same(first)));
    expect(first.debugDisposed, isTrue);
    expect(second.debugDisposed, isFalse);
  });

  test('reset 释放后可继续使用, dispose 释放', () {
    final image = ShapeImage(_Probe(), const Size(5, 6));
    final first = image.of(red);
    image.reset();
    expect(first.debugDisposed, isTrue);

    final second = image.of(red);
    expect(second, isNot(same(first)), reason: 'reset 后同色也重画');
    image.dispose();
    expect(second.debugDisposed, isTrue);
  });

  test('span 以逻辑尺寸占位, 图片即当前颜色的缓存', () {
    final image = ShapeImage(_Probe(), const Size(5, 6));
    addTearDown(image.dispose);

    final span = image.span(red);
    expect(span.size, const Size(5, 6));
    expect(span.image, same(image.of(red)));
  });
}
