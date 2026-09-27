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

/// 斐波那契族的取色回退。
///
/// `fibColors` / `fibFansColors` 置空是文档明说支持的配置（「如果为空使用指针画笔颜色」），
/// 而取色写成 `colors[i % colors.length]` —— 调色板与线色同时缺失时会除零。线色缺失不是
/// 假想: `Overlay` 可由业务直接构造，也可来自旧版本的持久化数据。
///
/// 覆盖边界：取色回退与循环取模。
/// **不覆盖**：比率线的位置计算、文本排版。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/draw_object_scenario.dart';

void main() {
  final context = FakeDrawContext();

  /// 颜色未设置的线样式：`PaintConfig.color` 为 null 走主题，此处刻意不给。
  const colorlessLine = LineConfig(
    type: LineType.solid,
    paint: PaintConfig(strokeWidth: 1),
  );

  /// 建一个线色为空的对象，绕开 `Overlay.fromType` + `ensure()` 的正常填色路径。
  T buildColorless<T extends DrawObject>(
    T Function(Overlay, DrawConfig) builder, {
    required IDrawType type,
    required List<Offset> offsets,
  }) {
    final object = builder(
      Overlay.fromType(key: 'test', type: type, line: colorlessLine),
      const DrawConfig(enable: true),
    );
    for (var i = 0; i < offsets.length; i++) {
      object.addPointer(Point.pointer(i, offsets[i]));
    }
    return object;
  }

  tearDown(() {
    // 所有绘制参数统一复位，避免用例之间串扰。
    DrawToolsConfig.resetAll();
  });

  group('v2.5.0/fibonacci/palette', () {
    test('调色板与线色同时为空时不抛异常', () {
      DrawToolsConfig.configure(fibRetracement: const FibonacciDrawParam(fibColors: []));
      final object = buildColorless(
        FibRetracementDrawObject.new,
        type: fibRetracement,
        offsets: const [Offset(100, 200), Offset(220, 100)],
      );

      expect(
        () => object.draw(context, RecordingCanvas(), context.mainRect.size),
        returnsNormally,
        reason:
            'colors 为空时 `colors[i % colors.length]` 会除零；'
            '取色必须有兜底，而不是把「配置成空」变成崩溃。',
      );
    });

    test('扇形的调色板与线色同时为空时不抛异常', () {
      DrawToolsConfig.configure(fibFans: const FibFansDrawParam(fibFansColors: []));
      final object = buildColorless(
        FibFansDrawObject.new,
        type: fibFans,
        offsets: const [Offset(100, 200), Offset(220, 100)],
      );

      expect(
        () => object.draw(context, RecordingCanvas(), context.mainRect.size),
        returnsNormally,
      );
    });

    test('调色板为空但线色可用时按线色画', () {
      DrawToolsConfig.configure(
        fibRetracement: const FibonacciDrawParam(fibColors: [], fibBgOpacity: 0),
      );
      final object = buildEditingObject(
        FibRetracementDrawObject.new,
        type: fibRetracement,
        offsets: const [Offset(100, 200), Offset(220, 100)],
      );
      final canvas = RecordingCanvas();

      object.draw(context, canvas, context.mainRect.size);

      expect(canvas.drawn, isNotEmpty);
      expect(
        canvas.drawn.map((e) => e.color.toARGB32()).toSet(),
        {testLine.paint.color!.toARGB32()},
        reason: '文档承诺「fibColors 为空时使用指针画笔颜色」。',
      );
    });

    test('调色板短于比率数时循环取用', () {
      const palette = [Color(0xFFFF0000), Color(0xFF00FF00)];
      DrawToolsConfig.configure(
        fibRetracement: const FibonacciDrawParam(
          fibRates: [0, 0.5, 1],
          fibColors: palette,
          fibBgOpacity: 0,
        ),
      );
      final object = buildEditingObject(
        FibRetracementDrawObject.new,
        type: fibRetracement,
        offsets: const [Offset(100, 200), Offset(220, 100)],
      );
      final canvas = RecordingCanvas();

      object.draw(context, canvas, context.mainRect.size);

      expect(
        canvas.drawn.map((e) => e.color.toARGB32()).toSet(),
        {
          // 连接虚线用线色，比率线用调色板；3 个比率 2 个颜色应循环取用。
          testLine.paint.color!.toARGB32(),
          ...palette.map((e) => e.toARGB32()),
        },
      );
    });
  });
}
