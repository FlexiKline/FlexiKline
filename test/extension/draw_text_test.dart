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

import '../support/support.dart';

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

  group('边界矫正', () {
    const style = TextStyle(fontSize: 10, height: 1);
    const opaque = Color(0xFF000000);

    /// 传了背景色时容器区域以一次 `drawPath` 落到画布上, 其包围盒即容器实际位置。
    Rect containerOf(RecordingCanvas canvas) {
      expect(canvas.pathBounds, hasLength(1));
      return canvas.pathBounds.single;
    }

    ui.Image squareImage() {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 20, 10),
        Paint()..color = opaque,
      );
      return recorder.endRecording().toImageSync(20, 10);
    }

    test('drawText center 传 drawableRect 时仍以 offset 为水平中心', () {
      final canvas = RecordingCanvas();

      final size = canvas.drawText(
        offset: const Offset(200, 50),
        text: 'ABC',
        style: style,
        drawDirection: DrawDirection.center,
        drawableRect: const Rect.fromLTWH(0, 0, 400, 200),
        backgroundColor: opaque,
        maxLines: 1,
      );

      final container = containerOf(canvas);
      expect(container.center.dx, closeTo(200, 0.01));
      expect(container.width, closeTo(size.width, 0.01));
    });

    test('drawText center 的落点与是否传 drawableRect 无关', () {
      final withRect = RecordingCanvas();
      withRect.drawText(
        offset: const Offset(200, 50),
        text: 'ABC',
        style: style,
        drawDirection: DrawDirection.center,
        drawableRect: const Rect.fromLTWH(0, 0, 400, 200),
        backgroundColor: opaque,
        maxLines: 1,
      );

      final withoutRect = RecordingCanvas();
      withoutRect.drawText(
        offset: const Offset(200, 50),
        text: 'ABC',
        style: style,
        drawDirection: DrawDirection.center,
        backgroundColor: opaque,
        maxLines: 1,
      );

      expect(containerOf(withRect), containerOf(withoutRect));
    });

    test('drawText 容器底边不超出 drawableRect 且高度不被压缩', () {
      const drawableRect = Rect.fromLTWH(0, 0, 400, 100);
      final canvas = RecordingCanvas();

      final size = canvas.drawText(
        offset: const Offset(10, 95),
        text: 'ABC',
        style: style,
        drawableRect: drawableRect,
        backgroundColor: opaque,
        maxLines: 1,
      );

      final container = containerOf(canvas);
      expect(container.bottom, lessThanOrEqualTo(drawableRect.bottom + 0.01));
      expect(container.height, closeTo(size.height, 0.01));
    });

    test('drawText 在 drawableRect 装不下容器时贴左上角且不抛异常', () {
      // 夹取的上界此时小于下界, 若改用 clamp 会抛 ArgumentError。
      const drawableRect = Rect.fromLTWH(20, 30, 5, 5);
      final canvas = RecordingCanvas();

      expect(
        () => canvas.drawText(
          offset: const Offset(22, 33),
          text: 'ABC',
          style: style,
          drawableRect: drawableRect,
          backgroundColor: opaque,
          maxLines: 1,
        ),
        returnsNormally,
      );
      expect(containerOf(canvas).topLeft, drawableRect.topLeft);
    });

    test('drawImageText center 传 drawableRect 时仍以 offset 为水平中心', () {
      final image = squareImage();
      final canvas = RecordingCanvas();

      final bounds = canvas.drawImageText(
        offset: const Offset(200, 50),
        image: image,
        imgSize: const Size(20, 10),
        text: 'ABC',
        style: style,
        drawDirection: DrawDirection.center,
        drawableRect: const Rect.fromLTWH(0, 0, 400, 200),
        spacing: 4,
        maxLines: 1,
      );

      expect(bounds.center.dx, closeTo(200, 0.01));
      image.dispose();
    });

    test('drawImageText 容器底边不超出 drawableRect', () {
      const drawableRect = Rect.fromLTWH(0, 0, 400, 100);
      final image = squareImage();
      final canvas = RecordingCanvas();

      final bounds = canvas.drawImageText(
        offset: const Offset(10, 95),
        image: image,
        imgSize: const Size(20, 10),
        text: 'ABC',
        style: style,
        drawableRect: drawableRect,
        maxLines: 1,
      );

      expect(bounds.bottom, lessThanOrEqualTo(drawableRect.bottom + 0.01));
      image.dispose();
    });

    test('drawImageText 图片尺寸为空时不占位, 文本紧贴容器左边且不计入 spacing', () {
      final image = squareImage();
      final canvas = RecordingCanvas();

      // 高度为 0 的 imgSize 视为不绘制图片: 既不应推开文本, 也不应产生图文间距。
      final bounds = canvas.drawImageText(
        offset: Offset.zero,
        image: image,
        imgSize: const Size(20, 0),
        text: 'ABC',
        style: style,
        spacing: 8,
        backgroundColor: opaque,
        maxLines: 1,
      );

      expect(canvas.paragraphOffsets, hasLength(1));
      expect(canvas.paragraphOffsets.single.dx, closeTo(bounds.left, 0.01));
      expect(bounds.width, closeTo(canvas.pathBounds.single.width, 0.01));
      image.dispose();
    });

    test('drawImageText 图片宽度为空时不参与垂直分布', () {
      final image = squareImage();
      final canvas = RecordingCanvas();

      // 宽度为 0 视为不绘制, 但其 40 的高度一旦参与垂直分布就会超出可用高度并触发断言。
      expect(
        () => canvas.drawImageText(
          offset: Offset.zero,
          image: image,
          imgSize: const Size(0, 40),
          text: 'ABC',
          style: style,
          maxLines: 1,
        ),
        returnsNormally,
      );
      image.dispose();
    });

    test('drawImageView center 与底边约束同时生效', () {
      const drawableRect = Rect.fromLTWH(0, 0, 400, 100);
      final image = squareImage();
      final canvas = RecordingCanvas();

      final bounds = canvas.drawImageView(
        offset: const Offset(200, 95),
        image: image,
        imgSize: const Size(20, 10),
        drawDirection: DrawDirection.center,
        drawableRect: drawableRect,
        backgroundColor: opaque,
      );

      expect(bounds.center.dx, closeTo(200, 0.01));
      expect(bounds.bottom, lessThanOrEqualTo(drawableRect.bottom + 0.01));
      image.dispose();
    });
  });
}
