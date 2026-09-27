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

/// 之前零覆盖的 DrawObject 的绘制产物与命中判据。
///
/// 覆盖：draw 基本产物（画了几条、起止在哪）+ hitTest 几何边界。
/// 不覆盖：手势、颜色视觉呈现。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/draw_object_scenario.dart';

void main() {
  final context = FakeDrawContext();
  final mainRect = context.mainRect; // (0,0)-(400,300)

  tearDown(DrawToolsConfig.resetAll);

  // -----------------------------------------------------------------------
  // ArrowLine
  // -----------------------------------------------------------------------
  group('arrowLine', () {
    test('draw 产出主线 + 两条箭头线', () {
      final object = buildEditingObject(
        ArrowLineDrawObject.new,
        type: arrowLine,
        offsets: const [Offset(100, 200), Offset(200, 100)],
      );
      final canvas = RecordingCanvas();
      object.draw(context, canvas, mainRect.size);

      // 1 条主线 + 2 条箭头 = 3 条 path
      expect(canvas.drawn, hasLength(3));
    });

    test('hitTest 在线段上命中, 线段外不命中', () {
      final object = buildEditingObject(
        ArrowLineDrawObject.new,
        type: arrowLine,
        offsets: const [Offset(100, 200), Offset(200, 100)],
      );
      expect(object.hitTest(context, const Offset(150, 150)), isTrue);
      // 延长线方向上不命中（和 trendLine 一样是线段判据）
      expect(object.hitTest(context, const Offset(250, 50)), isFalse);
    });

    test('箭头端点在可视区外时不画箭头', () {
      // second 在 mainRect 之外
      final object = buildEditingObject(
        ArrowLineDrawObject.new,
        type: arrowLine,
        offsets: const [Offset(100, 200), Offset(500, -100)],
      );
      final canvas = RecordingCanvas();
      object.draw(context, canvas, mainRect.size);

      // 只有主线，没有箭头
      expect(canvas.drawn, hasLength(1));
    });
  });

  // -----------------------------------------------------------------------
  // HorizontalLine
  // -----------------------------------------------------------------------
  group('horizontalLine', () {
    test('draw 画一条横跨 mainRect 的水平线', () {
      final object = buildEditingObject(
        HorizontalLineDrawObject.new,
        type: horizontalLine,
        offsets: const [Offset(150, 100)],
      );
      final canvas = RecordingCanvas();
      object.draw(context, canvas, mainRect.size);

      expect(canvas.drawn, hasLength(1));
      final path = canvas.drawn.single;
      expect(path.start.dy, 100);
      expect(path.end.dy, 100);
      expect(path.start.dx, mainRect.left);
      expect(path.end.dx, mainRect.right);
    });

    test('hitTest 在水平线上命中, 远离不命中', () {
      final object = buildEditingObject(
        HorizontalLineDrawObject.new,
        type: horizontalLine,
        offsets: const [Offset(150, 100)],
      );
      expect(object.hitTest(context, const Offset(200, 100)), isTrue);
      expect(object.hitTest(context, const Offset(200, 200)), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // VerticalLine
  // -----------------------------------------------------------------------
  group('verticalLine', () {
    test('draw 画一条纵跨 mainRect 的垂直线', () {
      final object = buildEditingObject(
        VerticalLineDrawObject.new,
        type: verticalLine,
        offsets: const [Offset(200, 150)],
      );
      final canvas = RecordingCanvas();
      object.draw(context, canvas, mainRect.size);

      expect(canvas.drawn, hasLength(1));
      final path = canvas.drawn.single;
      expect(path.start.dx, 200);
      expect(path.end.dx, 200);
      expect(path.start.dy, mainRect.top);
      expect(path.end.dy, mainRect.bottom);
    });

    test('hitTest 在垂直线上命中, 远离不命中', () {
      final object = buildEditingObject(
        VerticalLineDrawObject.new,
        type: verticalLine,
        offsets: const [Offset(200, 150)],
      );
      expect(object.hitTest(context, const Offset(200, 50)), isTrue);
      expect(object.hitTest(context, const Offset(100, 150)), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // CrossLine
  // -----------------------------------------------------------------------
  group('crossLine', () {
    test('draw 画一横一纵两条线', () {
      final object = buildEditingObject(
        CrossLineDrawObject.new,
        type: crossLine,
        offsets: const [Offset(150, 100)],
      );
      final canvas = RecordingCanvas();
      object.draw(context, canvas, mainRect.size);

      // drawLineByConfig 收到的 path 含两个 sub-path（moveTo+lineTo × 2）
      // RecordingCanvas 按 metric 拆分，应有 2 条
      expect(canvas.drawn, hasLength(2));
    });

    test('hitTest 在横线或纵线上均命中', () {
      final object = buildEditingObject(
        CrossLineDrawObject.new,
        type: crossLine,
        offsets: const [Offset(150, 100)],
      );
      // 水平线上
      expect(object.hitTest(context, const Offset(300, 100)), isTrue);
      // 垂直线上
      expect(object.hitTest(context, const Offset(150, 250)), isTrue);
      // 远离两条线
      expect(object.hitTest(context, const Offset(300, 250)), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // PriceLine
  // -----------------------------------------------------------------------
  group('priceLine', () {
    test('draw 画从锚点到 mainRect 右边界的射线 + 文本', () {
      final object = buildEditingObject(
        PriceLineDrawObject.new,
        type: priceLine,
        offsets: const [Offset(100, 150)],
      );
      final canvas = RecordingCanvas();
      object.draw(context, canvas, mainRect.size);

      // 至少有射线（文本的 drawPath 也可能被记录）
      expect(canvas.drawn, isNotEmpty);
      final linePath = canvas.drawn.first;
      expect(linePath.start, const Offset(100, 150));
      expect(linePath.end.dx, mainRect.right);
      expect(linePath.end.dy, 150);
    });

    test('hitTest 在射线上命中, 锚点左边不命中', () {
      final object = buildEditingObject(
        PriceLineDrawObject.new,
        type: priceLine,
        offsets: const [Offset(100, 150)],
      );
      // 射线右侧
      expect(object.hitTest(context, const Offset(300, 150)), isTrue);
      // 锚点左侧（不在射线上）
      expect(object.hitTest(context, const Offset(50, 150)), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // Rectangle
  // -----------------------------------------------------------------------
  group('rectangle', () {
    test('draw 产出填充 + 边框', () {
      final object = buildEditingObject(
        RectangleDrawObject.new,
        type: rectangle,
        offsets: const [Offset(50, 50), Offset(200, 200)],
      );
      final canvas = RecordingCanvas();
      object.draw(context, canvas, mainRect.size);

      // 至少有填充和边框两组 drawPath
      expect(canvas.drawn, isNotEmpty);
    });

    test('hitTest 矩形内命中, 外不命中', () {
      final object = buildEditingObject(
        RectangleDrawObject.new,
        type: rectangle,
        offsets: const [Offset(50, 50), Offset(200, 200)],
      );
      expect(object.hitTest(context, const Offset(100, 100)), isTrue);
      expect(object.hitTest(context, const Offset(250, 250)), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // ParallelChannel
  // -----------------------------------------------------------------------
  group('parallelChannel', () {
    test('draw 产出填充 + 中线 + 两条边线', () {
      final object = buildEditingObject(
        ParallelChannelDrawObject.new,
        type: parallelChannel,
        offsets: const [Offset(50, 100), Offset(250, 100), Offset(150, 200)],
      );
      final canvas = RecordingCanvas();
      object.draw(context, canvas, mainRect.size);

      // 填充 polygon + 中线 + 基线 AB + 平行线 CD
      expect(canvas.drawn.length, greaterThanOrEqualTo(4));
    });

    test('hitTest 通道内命中, 外不命中', () {
      final object = buildEditingObject(
        ParallelChannelDrawObject.new,
        type: parallelChannel,
        offsets: const [Offset(50, 100), Offset(250, 100), Offset(150, 200)],
      );
      // 通道中间
      expect(object.hitTest(context, const Offset(150, 150)), isTrue);
      // 通道外
      expect(object.hitTest(context, const Offset(150, 50)), isFalse);
    });

    test('选中时第三点在CD横向范围外, 连接线连到就近端点', () {
      // A=(50,100) B=(250,100) → D=(50,200) 在左, C=(250,200) 在右;
      // 第三点 dx=20 在两者左侧, 应连到 D, 而不是横穿通道连到 C.
      final object = buildEditingObject(
        ParallelChannelDrawObject.new,
        type: parallelChannel,
        offsets: const [Offset(50, 100), Offset(250, 100), Offset(20, 200)],
        // 连接线默认虚线, 会被拆成多段 path; 换成实线才能断言端点.
        config: const DrawConfig(enable: true, crosshair: testLine),
      );
      final canvas = RecordingCanvas();
      object.draw(FakeDrawContext(selectedObject: object), canvas, mainRect.size);

      // 连接线最后画, 实线只有一段.
      final connectingLine = canvas.drawn.last;
      expect(connectingLine.start, const Offset(20, 200));
      expect(connectingLine.end, const Offset(50, 200));
    });

    test('未选中时不画第三点连接线', () {
      final object = buildEditingObject(
        ParallelChannelDrawObject.new,
        type: parallelChannel,
        offsets: const [Offset(50, 100), Offset(250, 100), Offset(20, 200)],
        config: const DrawConfig(enable: true, crosshair: testLine),
      );
      final canvas = RecordingCanvas();
      object.draw(context, canvas, mainRect.size);

      expect(canvas.drawn.any((p) => p.start == const Offset(20, 200)), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // Parallelogram
  // -----------------------------------------------------------------------
  group('parallelogram', () {
    test('draw 产出填充 + 四条边', () {
      // A=(50,100), B=(200,100), C=(250,200) → D=A+C-B=(100,200)
      final object = buildEditingObject(
        ParallelogramDrawObject.new,
        type: parallelogram,
        offsets: const [Offset(50, 100), Offset(200, 100), Offset(250, 200)],
      );
      final canvas = RecordingCanvas();
      object.draw(context, canvas, mainRect.size);

      // 填充 polygon + 边框 polygon
      expect(canvas.drawn, isNotEmpty);
    });

    test('hitTest 四边形内命中, 外不命中', () {
      final object = buildEditingObject(
        ParallelogramDrawObject.new,
        type: parallelogram,
        offsets: const [Offset(50, 100), Offset(200, 100), Offset(250, 200)],
      );
      // 内部中心大约在 (162, 150)
      expect(object.hitTest(context, const Offset(162, 150)), isTrue);
      // 明确在外部
      expect(object.hitTest(context, const Offset(10, 10)), isFalse);
    });

    test('第四点 D = A + C - B 构成平行四边形', () {
      final object = buildEditingObject(
        ParallelogramDrawObject.new,
        type: parallelogram,
        offsets: const [Offset(50, 100), Offset(200, 100), Offset(250, 200)],
      );
      final verts = object.getVertices()!;
      expect(verts[0], const Offset(50, 100)); // A
      expect(verts[1], const Offset(200, 100)); // B
      expect(verts[2], const Offset(250, 200)); // C
      expect(verts[3], const Offset(100, 200)); // D = A + C - B
      // 验证 AB ∥ DC
      final ab = verts[1] - verts[0];
      final dc = verts[2] - verts[3];
      expect(ab.dx, dc.dx);
      expect(ab.dy, dc.dy);
    });
  });

  // -----------------------------------------------------------------------
  // TrendAngle
  // -----------------------------------------------------------------------
  group('trendAngle', () {
    test('draw 不抛异常且产出路径', () {
      final object = buildEditingObject(
        TrendAngleDrawObject.new,
        type: trendAngle,
        offsets: const [Offset(100, 200), Offset(300, 100)],
      );
      final canvas = RecordingCanvas();
      expect(
        () => object.draw(context, canvas, mainRect.size),
        returnsNormally,
      );
      expect(canvas.drawn, isNotEmpty);
    });

    test('hitTest 在线段上命中', () {
      final object = buildEditingObject(
        TrendAngleDrawObject.new,
        type: trendAngle,
        offsets: const [Offset(100, 200), Offset(300, 100)],
      );
      expect(object.hitTest(context, const Offset(200, 150)), isTrue);
      expect(object.hitTest(context, const Offset(50, 50)), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // ElliottImpulseWave (tripleWaves / pentaWaves)
  // -----------------------------------------------------------------------
  group('elliottImpulseWave', () {
    test('tripleWaves(4 点) draw 产出 3 条线段', () {
      final object = buildEditingObject(
        ElliottImpulseWaveDrawObject.new,
        type: tripleWaves,
        offsets: const [
          Offset(50, 200),
          Offset(100, 100),
          Offset(150, 180),
          Offset(200, 80),
        ],
      );
      final canvas = RecordingCanvas();
      object.draw(context, canvas, mainRect.size);

      expect(canvas.drawn, hasLength(3));
    });

    test('pentaWaves(6 点) draw 产出 5 条线段', () {
      final object = buildEditingObject(
        ElliottImpulseWaveDrawObject.new,
        type: pentaWaves,
        offsets: const [
          Offset(30, 200),
          Offset(80, 100),
          Offset(120, 160),
          Offset(180, 60),
          Offset(220, 140),
          Offset(300, 40),
        ],
      );
      final canvas = RecordingCanvas();
      object.draw(context, canvas, mainRect.size);

      expect(canvas.drawn, hasLength(5));
    });

    test('hitTest 在线段上命中', () {
      final object = buildEditingObject(
        ElliottImpulseWaveDrawObject.new,
        type: tripleWaves,
        offsets: const [
          Offset(50, 200),
          Offset(100, 100),
          Offset(150, 180),
          Offset(200, 80),
        ],
      );
      // 第一段中点附近
      expect(object.hitTest(context, const Offset(75, 150)), isTrue);
      // 远离所有线段
      expect(object.hitTest(context, const Offset(300, 250)), isFalse);
    });
  });
}
