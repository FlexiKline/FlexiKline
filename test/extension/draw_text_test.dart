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

import 'package:flexi_kline/src/extension/export.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drawText 多行时以 drawableRect 限制文本宽度', () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const drawableRect = Rect.fromLTWH(0, 0, 80, 100);
    const padding = EdgeInsets.symmetric(horizontal: 4);

    final size = canvas.drawText(
      offset: drawableRect.topLeft,
      text: 'MA7: 64311.59  MA30: 63943.77',
      style: const TextStyle(fontSize: 10, height: 1),
      drawableRect: drawableRect,
      padding: padding,
      maxLines: 2,
    );

    expect(size.width, lessThanOrEqualTo(drawableRect.width));
    expect(size.height, greaterThan(10));
    recorder.endRecording().dispose();
  });

  test('drawText 单行时不因 drawableRect 改变文本宽度', () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const drawableRect = Rect.fromLTWH(0, 0, 80, 100);

    final size = canvas.drawText(
      offset: drawableRect.topLeft,
      text: 'MA7: 64311.59  MA30: 63943.77',
      style: const TextStyle(fontSize: 10, height: 1),
      drawableRect: drawableRect,
      maxLines: 1,
    );

    expect(size.width, greaterThan(drawableRect.width));
    recorder.endRecording().dispose();
  });

  test('drawImageText 多行时以 drawableRect 限制图文总宽度', () {
    final imageRecorder = ui.PictureRecorder();
    Canvas(imageRecorder).drawRect(
      const Rect.fromLTWH(0, 0, 20, 10),
      Paint()..color = const Color(0xFF000000),
    );
    final image = imageRecorder.endRecording().toImageSync(20, 10);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const drawableRect = Rect.fromLTWH(0, 0, 80, 100);

    final bounds = canvas.drawImageText(
      offset: drawableRect.topLeft,
      image: image,
      imgSize: const Size(20, 10),
      text: 'MA7: 64311.59  MA30: 63943.77',
      style: const TextStyle(fontSize: 10, height: 1),
      drawableRect: drawableRect,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      spacing: 4,
      maxLines: 2,
    );

    expect(bounds.width, lessThanOrEqualTo(drawableRect.width));
    expect(bounds.height, greaterThan(10));
    image.dispose();
    recorder.endRecording().dispose();
  });
}
