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

/// 绘制工具的文本标签: 跨帧缓存与锚点对齐。
///
/// 缓存命中以「第二帧画的是同一个 Paragraph 实例」判断; 对齐以文字矩形相对锚点的位置判断,
/// 锚点到文字之间隔着 [TextAreaConfig.padding]。
///
/// 覆盖边界：`draw` 产出的段落实例与位置。
/// **不覆盖**：字形与像素、拖动与命中。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/draw_object_scenario.dart';

void main() {
  final context = FakeDrawContext();

  RecordingCanvas drawFrame(DrawObject object) {
    final canvas = RecordingCanvas();
    object.draw(context, canvas, context.mainRect.size);
    return canvas;
  }

  /// 画两帧, 断言第二帧逐个复用第一帧的段落, 返回第一帧。
  RecordingCanvas expectCachedAcrossFrames(DrawObject object) {
    final first = drawFrame(object);
    final second = drawFrame(object);
    expect(first.paragraphs, isNotEmpty);
    expect(second.paragraphs, hasLength(first.paragraphs.length));
    for (var i = 0; i < first.paragraphs.length; i++) {
      expect(
        identical(first.paragraphs[i].paragraph, second.paragraphs[i].paragraph),
        isTrue,
        reason: '第 $i 个标签值不变, 第二帧应命中缓存',
      );
    }
    return first;
  }

  tearDown(DrawToolsConfig.resetAll);

  group('v2.6.0/labels/cache', () {
    test('斐波那契回撤: 各比率颜色不同仍全部命中', () {
      final object = buildEditingObject(
        FibRetracementDrawObject.new,
        type: fibRetracement,
        offsets: const [Offset(100, 200), Offset(220, 100)],
      );
      final frame = expectCachedAcrossFrames(object);
      expect(frame.paragraphs, hasLength(FibRetracementDrawObject.drawParam.fibRates.length));
    });

    test('斐波那契扩展', () {
      expectCachedAcrossFrames(
        buildEditingObject(
          FibExpansionDrawObject.new,
          type: fibExpansion,
          offsets: const [Offset(100, 200), Offset(160, 100), Offset(220, 150)],
        ),
      );
    });

    test('斐波那契扇形: 横纵两排都命中', () {
      final frame = expectCachedAcrossFrames(
        buildEditingObject(
          FibFansDrawObject.new,
          type: fibFans,
          offsets: const [Offset(100, 200), Offset(220, 100)],
        ),
      );
      expect(frame.paragraphs, hasLength(FibFansDrawObject.drawParam.fibFansParams.length * 2));
    });

    test('价格线', () {
      expectCachedAcrossFrames(
        buildEditingObject(PriceLineDrawObject.new, type: priceLine, offsets: const [Offset(100, 150)]),
      );
    });

    test('趋势角度', () {
      expectCachedAcrossFrames(
        buildEditingObject(
          TrendAngleDrawObject.new,
          type: trendAngle,
          offsets: const [Offset(100, 200), Offset(220, 100)],
        ),
      );
    });
  });

  group('v2.6.0/labels/align', () {
    test('斐波那契回撤: 文字贴在起点左侧, 垂直居中于比率线', () {
      DrawToolsConfig.configure(fibRetracement: const FibonacciDrawParam(fibRates: [0, 1]));
      final padding = FibRetracementDrawObject.drawParam.fibText.padding!;
      final rects = drawFrame(
        buildEditingObject(
          FibRetracementDrawObject.new,
          type: fibRetracement,
          offsets: const [Offset(100, 200), Offset(220, 100)],
        ),
      ).paragraphs.map((e) => e.rect);

      // 比率 0 在 B(dy=100), 比率 1 在 A(dy=200)。
      expect(rects.map((r) => r.right), everyElement(closeTo(100 - padding.right, 0.01)));
      expect(rects.map((r) => r.center.dy), [closeTo(100, 0.01), closeTo(200, 0.01)]);
    });

    for (final (name, a, b, horiAbove, vertLeft) in const [
      ('A 在左下: 横排在 A 下方, 纵排在 A 左侧', Offset(100, 200), Offset(220, 100), false, true),
      ('A 在右上: 横排在 A 上方, 纵排在 A 右侧', Offset(220, 100), Offset(100, 200), true, false),
    ]) {
      test('斐波那契扇形 $name', () {
        DrawToolsConfig.configure(fibFans: const FibFansDrawParam(fibFansParams: [0.5]));
        final padding = FibFansDrawObject.drawParam.fibText.padding!;
        final [hori, vert] = drawFrame(
          buildEditingObject(FibFansDrawObject.new, type: fibFans, offsets: [a, b]),
        ).paragraphs.map((e) => e.rect).toList();

        final mid = Offset.lerp(a, b, 0.5)!;
        expect(hori.center.dx, closeTo(mid.dx, 0.01));
        expect(
          horiAbove ? hori.bottom : hori.top,
          closeTo(horiAbove ? a.dy - padding.bottom : a.dy + padding.top, 0.01),
        );
        expect(vert.center.dy, closeTo(mid.dy, 0.01));
        expect(vertLeft ? vert.right : vert.left, closeTo(vertLeft ? a.dx - padding.right : a.dx + padding.left, 0.01));
      });
    }

    test('价格线: 文字左下角按 priceTextMargin 偏离绘制点', () {
      const point = Offset(100, 150);
      final object = buildEditingObject(PriceLineDrawObject.new, type: priceLine, offsets: const [point]);
      final rect = drawFrame(object).paragraphs.single.rect;
      final margin = PriceLineDrawObject.drawParam.priceTextMargin;
      final padding = object.ticksTextConfig.padding!;

      expect(rect.left, closeTo(point.dx + margin.left + padding.left, 0.01));
      expect(rect.bottom, closeTo(point.dy - margin.bottom - padding.bottom, 0.01));
    });

    test('趋势角度: 文字在基线末端右侧, 垂直居中于基线', () {
      const a = Offset(100, 200);
      final object = buildEditingObject(
        TrendAngleDrawObject.new,
        type: trendAngle,
        offsets: const [a, Offset(220, 100)],
      );
      final rect = drawFrame(object).paragraphs.single.rect;
      final padding = object.ticksTextConfig.padding!;

      expect(rect.left, closeTo(a.dx + TrendAngleDrawObject.drawParam.angleBaseLineMinLen + padding.left, 0.01));
      expect(rect.center.dy, closeTo(a.dy, 0.01));
    });
  });
}
