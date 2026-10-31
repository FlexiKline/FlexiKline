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

/// 全部已注册绘图类型的统一契约。
///
/// 每个类型按同一组断言检查：`draw` 有产出、`hitTest` 命中与不命中、`Overlay` JSON 往返后
/// 点位与绘制结果一致、点数不足时 `draw` / `drawing` / `hitTest` 不抛。用例表必须与
/// `drawObjectBuilders` 的键一致，新增绘图类型漏填会在这里红。
///
/// 覆盖边界：`draw` / `hitTest` / 序列化的通用契约。
/// **不覆盖**：各类型的几何细节（见 `draw_object_geometry_test.dart` 等）、手势、像素。
library;

import 'dart:convert';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/draw_object_scenario.dart';

/// [offsets] 是 [type] 落满的全部绘制点；[hits] 落在图形上，[misses] 远离图形。
typedef _Case = ({
  IDrawType type,
  List<Offset> offsets,
  List<Offset> hits,
  List<Offset> misses,
});

// 主区 (0,0)-(400,300)，所有点都在其内。
const _cases = <_Case>[
  (
    type: trendLine,
    offsets: [Offset(100, 200), Offset(200, 100)],
    hits: [Offset(100, 200), Offset(150, 150), Offset(200, 100)],
    misses: [Offset(250, 50), Offset(50, 250)],
  ),
  (
    type: arrowLine,
    offsets: [Offset(100, 200), Offset(200, 100)],
    hits: [Offset(100, 200), Offset(150, 150), Offset(200, 100)],
    misses: [Offset(250, 50), Offset(50, 250)],
  ),
  (
    type: extendedTrendLine,
    offsets: [Offset(100, 200), Offset(200, 100)],
    hits: [Offset(100, 200), Offset(150, 150), Offset(250, 50), Offset(50, 250)],
    misses: [Offset(300, 250), Offset(50, 50)],
  ),
  (
    type: trendAngle,
    offsets: [Offset(100, 200), Offset(300, 100)],
    hits: [Offset(100, 200), Offset(200, 150), Offset(300, 100)],
    misses: [Offset(50, 50), Offset(350, 50)],
  ),
  (
    type: rayLine,
    offsets: [Offset(100, 200), Offset(200, 100)],
    hits: [Offset(100, 200), Offset(150, 150), Offset(250, 50)],
    misses: [Offset(50, 250), Offset(300, 250)],
  ),
  (
    type: horizontalTrendLine,
    offsets: [Offset(100, 150), Offset(250, 150)],
    hits: [Offset(100, 150), Offset(175, 150), Offset(250, 150)],
    misses: [Offset(175, 250), Offset(300, 150)],
  ),
  (
    type: horizontalRayLine,
    offsets: [Offset(100, 150), Offset(250, 150)],
    hits: [Offset(100, 150), Offset(175, 150), Offset(350, 150)],
    misses: [Offset(175, 250), Offset(50, 150)],
  ),
  (
    type: horizontalLine,
    offsets: [Offset(150, 100)],
    hits: [Offset(150, 100), Offset(200, 100)],
    misses: [Offset(200, 200)],
  ),
  (
    type: verticalLine,
    offsets: [Offset(200, 150)],
    hits: [Offset(200, 150), Offset(200, 50)],
    misses: [Offset(100, 150)],
  ),
  (
    type: crossLine,
    offsets: [Offset(150, 100)],
    hits: [Offset(150, 100), Offset(300, 100), Offset(150, 250)],
    misses: [Offset(300, 250)],
  ),
  (
    type: priceLine,
    offsets: [Offset(100, 150)],
    hits: [Offset(100, 150), Offset(300, 150)],
    misses: [Offset(50, 150), Offset(300, 250)],
  ),
  (
    type: parallelChannel,
    offsets: [Offset(50, 100), Offset(250, 100), Offset(150, 200)],
    hits: [Offset(50, 100), Offset(250, 100), Offset(150, 200), Offset(150, 150)],
    misses: [Offset(150, 50), Offset(350, 250)],
  ),
  (
    type: parallelogram,
    offsets: [Offset(50, 100), Offset(200, 100), Offset(250, 200)],
    hits: [Offset(50, 100), Offset(200, 100), Offset(250, 200), Offset(162, 150)],
    misses: [Offset(10, 10), Offset(350, 250)],
  ),
  (
    type: rectangle,
    offsets: [Offset(50, 50), Offset(200, 200)],
    hits: [Offset(50, 50), Offset(200, 200), Offset(100, 100)],
    misses: [Offset(250, 250), Offset(10, 10)],
  ),
  (
    type: fibRetracement,
    offsets: [Offset(100, 200), Offset(300, 100)],
    hits: [Offset(100, 200), Offset(300, 100), Offset(200, 150)],
    misses: [Offset(350, 250), Offset(50, 50)],
  ),
  (
    type: fibExpansion,
    offsets: [Offset(100, 200), Offset(200, 100), Offset(300, 150)],
    hits: [Offset(100, 200), Offset(200, 100), Offset(300, 150), Offset(150, 150), Offset(250, 120)],
    misses: [Offset(350, 250), Offset(50, 50)],
  ),
  (
    type: fibFans,
    offsets: [Offset(100, 200), Offset(300, 100)],
    hits: [Offset(100, 200), Offset(300, 100), Offset(200, 150)],
    misses: [Offset(350, 250), Offset(50, 50)],
  ),
  (
    type: tripleWaves,
    offsets: [Offset(50, 200), Offset(100, 100), Offset(150, 180), Offset(200, 80)],
    hits: [Offset(50, 200), Offset(200, 80), Offset(75, 150)],
    misses: [Offset(300, 250), Offset(300, 20)],
  ),
  (
    type: pentaWaves,
    offsets: [
      Offset(30, 200),
      Offset(80, 100),
      Offset(120, 160),
      Offset(180, 60),
      Offset(220, 140),
      Offset(300, 40),
    ],
    hits: [Offset(30, 200), Offset(300, 40), Offset(55, 150)],
    misses: [Offset(350, 250), Offset(150, 250)],
  ),
];

void main() {
  final context = FakeDrawContext();
  final size = context.mainRect.size;
  const config = DrawConfig(enable: true);

  tearDown(DrawToolsConfig.resetAll);

  DrawObject buildObject(Overlay overlay) => drawObjectBuilders[overlay.type]!(overlay, config)!;

  /// 落满 [c.offsets] 的对象，处于绘制完成态。
  DrawObject editing(_Case c) => buildEditingObject(
    (overlay, config) => drawObjectBuilders[c.type]!(overlay, config)!,
    type: c.type,
    offsets: c.offsets,
  );

  /// 只落前 [count] 个点的对象，处于绘制中途。
  DrawObject partial(_Case c, int count) {
    final object = buildObject(Overlay.fromType(key: 'partial', type: c.type, line: testLine));
    for (var i = 0; i < count; i++) {
      object.addPointer(Point.pointer(i, c.offsets[i]));
    }
    return object;
  }

  List<DrawnPath> drawOf(DrawObject object) {
    final canvas = RecordingCanvas();
    object.draw(context, canvas, size);
    return canvas.drawn;
  }

  group('registry', () {
    test('用例表与注册表的类型一一对应', () {
      expect(_cases.map((c) => c.type).toSet(), drawObjectBuilders.keys.toSet());
      expect(_cases.map((c) => c.type.id).toSet(), hasLength(_cases.length));
    });

    test('每个类型的点数与用例一致, 且都归属具体分组', () {
      for (final c in _cases) {
        expect(c.offsets, hasLength(c.type.steps), reason: c.type.id);
        expect(c.type.groupId, isNot(drawGroupUnknown), reason: c.type.id);
      }
    });

    test('注册的 builder 构造出的对象带着对应的类型', () {
      for (final c in _cases) {
        expect(editing(c).type, c.type, reason: c.type.id);
      }
    });
  });

  for (final c in _cases) {
    group(c.type.id, () {
      test('draw 有产出且不抛', () {
        final object = editing(c);
        late List<DrawnPath> drawn;
        expect(() => drawn = drawOf(object), returnsNormally);
        expect(drawn, isNotEmpty);
      });

      test('hitTest 图形上命中, 远离处不命中', () {
        final object = editing(c);
        for (final p in c.hits) {
          expect(object.hitTest(context, p), isTrue, reason: 'hit $p');
        }
        for (final p in c.misses) {
          expect(object.hitTest(context, p), isFalse, reason: 'miss $p');
        }
      });

      test('Overlay JSON 往返后点位、参数与绘制结果不变', () {
        final overlay = Overlay(
          id: 7,
          key: 'round-trip',
          type: c.type,
          zIndex: 3,
          lock: true,
          line: testLine,
          points: [
            for (var i = 0; i < c.offsets.length; i++)
              Point(
                index: i,
                ts: context.dxToTimestamp(c.offsets[i].dx)!,
                value: context.dyToValue(c.offsets[i].dy)!,
              ),
          ],
        );
        final original = buildObject(overlay);
        final restored = buildObject(
          Overlay.fromJson(jsonDecode(jsonEncode(overlay.toJson())) as Map<String, dynamic>),
        );

        expect(restored.id, original.id);
        expect(restored.key, original.key);
        expect(restored.type, original.type);
        expect(restored.zIndex, 3);
        expect(restored.lock, isTrue);
        expect(restored.line.toJson(), original.line.toJson());
        expect(restored.points.map((p) => (p!.index, p.ts, p.value.toDouble())), [
          for (final p in original.points) (p!.index, p.ts, p.value.toDouble()),
        ]);

        // 偏移不入 JSON, 由时间戳与价格重新换算回原位。
        expect(original.initPoints(context), isTrue);
        expect(restored.initPoints(context), isTrue);
        expect(restored.points.map((p) => p!.offset), c.offsets);
        expect(drawOf(restored), drawOf(original));
      });

      test('点数不足时 draw / drawing / hitTest 不抛', () {
        for (var count = 0; count < c.type.steps; count++) {
          final object = partial(c, count);
          final canvas = RecordingCanvas();
          expect(() => object.draw(context, canvas, size), returnsNormally, reason: 'draw $count');
          expect(() => object.drawing(context, canvas, size), returnsNormally, reason: 'drawing $count');
          // 图形尚未成形, 只验证远离处不抛且不命中。
          for (final p in c.misses) {
            expect(object.hitTest(context, p), isFalse, reason: 'hitTest $count $p');
          }
        }
      });
    });
  }

  group('DrawToolsConfig', () {
    test('configure 只覆盖传入的参数, resetAll 还原默认', () {
      final config = DrawToolsConfig.instance;
      const defaults = RectangleDrawParam();
      expect(config.rectangle.rectangleBgOpacity, defaults.rectangleBgOpacity);

      DrawToolsConfig.configure(rectangle: const RectangleDrawParam(rectangleBgOpacity: 0.5));
      expect(config.rectangle.rectangleBgOpacity, 0.5);
      expect(config.arrowLine.arrowsLen, const ArrowLineDrawParam().arrowsLen);

      DrawToolsConfig.resetAll();
      expect(config.rectangle.rectangleBgOpacity, defaults.rectangleBgOpacity);
    });

    test('配置的参数作用到绘制产物', () {
      final rectangleCase = _cases.firstWhere((c) => c.type == rectangle);
      DrawToolsConfig.configure(rectangle: const RectangleDrawParam(rectangleBgOpacity: 0.5));

      // 第一笔是背景填充，其透明度来自配置。
      final fill = drawOf(editing(rectangleCase)).first;
      expect(fill.color.a, closeTo(0.5, 0.01));
    });
  });
}
