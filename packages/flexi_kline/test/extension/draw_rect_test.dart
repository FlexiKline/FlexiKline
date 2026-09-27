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

import 'package:flexi_kline/src/extension/export.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  const opaque = Color(0xFF000000);
  const size = Size(40, 10);

  Rect areaOf(RecordingCanvas canvas) {
    expect(canvas.pathBounds, hasLength(1));
    return canvas.pathBounds.single;
  }

  test('drawRectBackground rtl 在不传 drawableSize 时同样向左展开', () {
    final canvas = RecordingCanvas();

    final origin = canvas.drawRectBackground(
      offset: const Offset(100, 20),
      size: size,
      drawDirection: DrawDirection.rtl,
      backgroundColor: opaque,
    );

    expect(origin.dx, closeTo(60, 0.01));
    expect(areaOf(canvas).right, closeTo(100, 0.01));
  });

  test('drawRectBackground center 以 offset 为水平中心', () {
    final canvas = RecordingCanvas();

    canvas.drawRectBackground(
      offset: const Offset(100, 20),
      size: size,
      drawDirection: DrawDirection.center,
      drawableSize: const Size(400, 200),
      backgroundColor: opaque,
    );

    expect(areaOf(canvas).center.dx, closeTo(100, 0.01));
  });

  test('drawRectBackground center 的落点与是否传 drawableSize 无关', () {
    final withSize = RecordingCanvas();
    withSize.drawRectBackground(
      offset: const Offset(100, 20),
      size: size,
      drawDirection: DrawDirection.center,
      drawableSize: const Size(400, 200),
      backgroundColor: opaque,
    );

    final withoutSize = RecordingCanvas();
    withoutSize.drawRectBackground(
      offset: const Offset(100, 20),
      size: size,
      drawDirection: DrawDirection.center,
      backgroundColor: opaque,
    );

    expect(areaOf(withSize), areaOf(withoutSize));
  });

  test('drawRectBackground ltr 行为不变: 原点即 offset, 且被 drawableSize 夹回', () {
    final canvas = RecordingCanvas();

    final origin = canvas.drawRectBackground(
      offset: const Offset(380, 195),
      size: size,
      drawableSize: const Size(400, 200),
      backgroundColor: opaque,
    );

    expect(origin, const Offset(360, 190));
    expect(areaOf(canvas), const Rect.fromLTWH(360, 190, 40, 10));
  });
}
