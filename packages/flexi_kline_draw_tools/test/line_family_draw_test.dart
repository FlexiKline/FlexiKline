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

/// 线系列工具的绘制产物与命中判据。
///
/// 观察点是 `drawPath` 收到的路径端点与长度，而不是像素。三类线的差别正在于「往哪边
/// 延伸多远」：线段止于两点，射线只向前延伸到边界，延长线两头都到边界。
///
/// 覆盖边界：`draw` / `hitTest` 的几何。
/// **不覆盖**：手势、命中分派、颜色与线型的视觉呈现。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/draw_object_scenario.dart';

void main() {
  final context = FakeDrawContext();
  final mainRect = context.mainRect;

  /// 一条自左下往右上的斜线，两端都在主区内且离边界足够远，
  /// 因此「延伸到边界」与「止于端点」的产物长度必然不同。
  const a = Offset(100, 200);
  const b = Offset(200, 100);

  void drawObject(DrawObject object, RecordingCanvas canvas) {
    object.draw(context, canvas, mainRect.size);
  }

  group('v2.5.0/trendLine/draw', () {
    test('止于两个绘制点', () {
      final object = buildEditingObject(
        TrendLineDrawObject.new,
        type: trendLine,
        offsets: const [a, b],
      );
      final canvas = RecordingCanvas();

      drawObject(object, canvas);

      expect(canvas.drawn, hasLength(1));
      expect(canvas.drawn.single.length, closeTo((b - a).distance, 0.5));
    });

    test('命中判据是线段: 延长线方向上不命中', () {
      final object = buildEditingObject(
        TrendLineDrawObject.new,
        type: trendLine,
        offsets: const [a, b],
      );

      // b 再往前 40px（沿 AB 方向）已在线段之外。
      expect(object.hitTest(context, const Offset(240, 60)), isFalse);
      expect(object.hitTest(context, const Offset(150, 150)), isTrue);
    });
  });

  group('v2.5.0/rayLine/draw', () {
    test('只向 b 的方向延伸到边界', () {
      final object = buildEditingObject(
        RayLineDrawObject.new,
        type: rayLine,
        offsets: const [a, b],
      );
      final canvas = RecordingCanvas();

      drawObject(object, canvas);

      expect(canvas.drawn, hasLength(1));
      final path = canvas.drawn.single;
      expect(path, isStraightSegment());
      // 斜率 -1、从 (100,200) 往右上：先撞 top(y=0) 于 x=300。
      expect(path.start, a, reason: '射线起点必须是第一个绘制点');
      expect(path.end, const Offset(300, 0));
    });

    test('命中判据是射线: 反向不命中, 正向延伸段命中', () {
      final object = buildEditingObject(
        RayLineDrawObject.new,
        type: rayLine,
        offsets: const [a, b],
      );

      expect(object.hitTest(context, const Offset(240, 60)), isTrue, reason: '正向延伸段应命中');
      expect(object.hitTest(context, const Offset(60, 240)), isFalse, reason: '反向不属于射线');
    });
  });

  group('v2.5.0/extendedTrendLine/draw', () {
    test('两头都延伸到边界, 且是一条不折返的线段', () {
      final object = buildEditingObject(
        ExtendedTrendLineDrawObject.new,
        type: extendedTrendLine,
        offsets: const [a, b],
      );
      final canvas = RecordingCanvas();

      drawObject(object, canvas);

      expect(canvas.drawn, hasLength(1));
      final path = canvas.drawn.single;
      expect(
        path,
        isStraightSegment(),
        reason:
            '把正反两段 reflect 结果直接拼成一个 polygon 会来回折返: 同一段被画多次, '
            '虚线的 dash 相位错乱、半透明色叠深。',
      );
      // 斜率 -1 的直线过 (100,200): 两端分别撞 top(y=0,x=300) 与 left(x=0,y=300)。
      final ends = {path.start, path.end};
      expect(ends, {const Offset(300, 0), const Offset(0, 300)});
    });

    test('命中判据是整条直线: 两头延伸段都命中', () {
      final object = buildEditingObject(
        ExtendedTrendLineDrawObject.new,
        type: extendedTrendLine,
        offsets: const [a, b],
      );

      expect(object.hitTest(context, const Offset(240, 60)), isTrue);
      expect(object.hitTest(context, const Offset(60, 240)), isTrue);
      expect(object.hitTest(context, const Offset(60, 60)), isFalse);
    });
  });
}
