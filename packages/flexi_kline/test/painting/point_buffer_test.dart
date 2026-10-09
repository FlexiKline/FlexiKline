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

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flexi_kline/src/painting/export.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  late PointBuffer buffer;
  late RecordingCanvas canvas;
  final paint = Paint()..strokeWidth = 2;

  /// 全部 drawRawPoints 调用的 (mode, points, paint)。
  List<(ui.PointMode, Float32List, Paint)> rawPoints() => [
    for (final i in canvas.invocations.where((i) => i.memberName == #drawRawPoints))
      (
        i.positionalArguments[0] as ui.PointMode,
        i.positionalArguments[1] as Float32List,
        i.positionalArguments[2] as Paint,
      ),
  ];

  setUp(() {
    buffer = PointBuffer();
    canvas = RecordingCanvas();
  });

  tearDown(() => buffer.dispose());

  test('初始为空, flush 不画', () {
    expect(buffer.isEmpty, isTrue);
    buffer.flush(canvas, ui.PointMode.points, paint);
    expect(canvas.countOf(#drawRawPoints), 0);
  });

  test('超过 256 个 float 时扩容且数据保持', () {
    for (var i = 0; i < 200; i++) {
      buffer.add(i.toDouble(), i + 0.5);
    }
    buffer.flush(canvas, ui.PointMode.points, paint);

    final (_, points, _) = rawPoints().single;
    expect(points.length, 400);
    expect(points.sublist(0, 4), [0, 0.5, 1, 1.5]);
    expect(points.sublist(396), [198, 198.5, 199, 199.5]);
    // 扩容边界(第 128 个点, float 下标 256)前后连续。
    expect(points.sublist(254, 258), [127, 127.5, 128, 128.5]);
  });

  test('flush 以传入的 mode 与 paint 调一次 drawRawPoints, 之后清空', () {
    buffer
      ..addSegment(0, 1, 2, 3)
      ..addSegment(4, 5, 6, 7);
    expect(buffer.isEmpty, isFalse);
    buffer.flush(canvas, ui.PointMode.lines, paint);

    final (mode, points, used) = rawPoints().single;
    expect(mode, ui.PointMode.lines);
    expect(points, [0, 1, 2, 3, 4, 5, 6, 7]);
    expect(used, same(paint));
    expect(buffer.isEmpty, isTrue);

    buffer.flush(canvas, ui.PointMode.lines, paint);
    expect(canvas.countOf(#drawRawPoints), 1);
  });

  test('addSegment 写入 4 个 float', () {
    buffer.addSegment(1, 2, 3, 4);
    buffer.flush(canvas, ui.PointMode.lines, paint);
    expect(rawPoints().single.$2, [1, 2, 3, 4]);
  });

  test('reset 后为空', () {
    buffer.add(1, 2);
    buffer.reset();
    expect(buffer.isEmpty, isTrue);
    buffer.flush(canvas, ui.PointMode.points, paint);
    expect(canvas.countOf(#drawRawPoints), 0);
  });

  test('dispose 后再 add 重新分配并正常画出', () {
    buffer.add(1, 2);
    buffer.dispose();
    expect(buffer.isEmpty, isTrue);

    buffer.add(3, 4);
    buffer.flush(canvas, ui.PointMode.points, paint);
    expect(rawPoints().single.$2, [3, 4]);
  });
}
