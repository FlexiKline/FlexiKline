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

/// Draw 图层每帧开销基线：`initPoints` 在 `paintDraw` 里占多少。
///
/// 由来：`_drawOverlayObjectList` 每帧对每个 overlay 的每个 point 做一次
/// 「蜡烛坐标 → 屏幕坐标」换算。要不要为它引入脏标记(generation)，取决于它在一帧里的
/// 占比 —— 脏标记的代价是必须穷举所有失效点，漏一个就是「overlay 停在旧位置」这类难查
/// 的 bug，不值得为个位数百分比去付。
///
/// **测量口径与局限**（读数前必读）：
/// - 画布是 `PictureRecorder`，测到的是**录制**开销，不含 GPU 光栅化。真机上 `draw()`
///   那一半会更重，所以这里得到的 `initPoints` 占比是**偏高的上界**。
/// - 被测 overlay 每个只画一条直线（最便宜的真实工具形态）。fib 系列一次画几十条线加
///   文本，`initPoints` 的占比会被进一步摊薄。
/// - 结论方向因此是保守的：如果连这里都不高，真机上更不值得优化。
@Tags(['benchmark'])
library;

import 'dart:ui' show Path, PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Canvas, Offset, Size, SizedBox;
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'DRAW-PAINT-BENCH',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

const _canvasWidth = 400.0;

/// 每轮的帧数：单帧耗时在微秒级，攒够量才有分辨率。
const _frames = 500;

/// 轮数：取各轮**最小值**而非平均。JIT 预热、GC 与系统调度只会让某轮变慢，
/// 最小值最接近真实开销。首版用平均值时出现了「50 个 overlay 比 10 个还快」的读数。
const _rounds = 7;

/// 只画一条直线的 overlay —— 真实工具里最便宜的一种（对标 `TrendLineDrawObject`）。
///
/// 不用 `TestDrawObject`：它的 `draw` 是空实现，会让 `initPoints` 的占比虚高到失去意义。
class _BenchLineDrawObject extends DrawObject<Overlay> {
  _BenchLineDrawObject(super.overlay, super.config);

  /// 实际画出去的次数。用来验证「N 个 overlay 真的都被画了」——
  /// 否则 paintDraw 不随 N 增长时分不清是测量噪声还是有 overlay 被 `continue` 跳过了。
  static int drawCount = 0;

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) return;
    canvas.drawLineByConfig(
      Path()..addPolygon([first, second], false),
      line,
    );
    drawCount++;
  }
}

/// 对标 fib 系列的重量级 overlay：11 条比率线 + 11 段文本。
///
/// 为什么要这一档：可视区裁剪省下的是 `draw()`，`draw()` 越重裁剪越值。用最便宜的
/// 直线量不出裁剪的上限，得拿最贵的形态量。
class _BenchFibLikeDrawObject extends DrawObject<Overlay> {
  _BenchFibLikeDrawObject(super.overlay, super.config);

  static const _rates = [0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0, 1.382, 1.5, 1.618, 2];

  static int drawCount = 0;

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) return;
    final dyLen = first.dy - second.dy;
    for (final rate in _rates) {
      final dy = second.dy + dyLen * rate;
      canvas.drawLineByConfig(
        Path()..addPolygon([Offset(first.dx, dy), Offset(second.dx, dy)], false),
        line,
      );
      canvas.drawTextArea(
        offset: Offset(first.dx, dy),
        text: '$rate(1234.56)',
        textConfig: ticksTextConfig,
      );
    }
    drawCount++;
  }
}

/// 与 [_BenchFibLikeDrawObject] 只差「不画文本」。
///
/// 拿它与 fib-like 相减，得到 11 段文本的实测开销 —— 否则「文本是热点」只是推断。
class _BenchFibLinesOnlyDrawObject extends DrawObject<Overlay> {
  _BenchFibLinesOnlyDrawObject(super.overlay, super.config);

  static int drawCount = 0;

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) return;
    final dyLen = first.dy - second.dy;
    for (final rate in _BenchFibLikeDrawObject._rates) {
      final dy = second.dy + dyLen * rate;
      canvas.drawLineByConfig(
        Path()..addPolygon([Offset(first.dx, dy), Offset(second.dx, dy)], false),
        line,
      );
    }
    drawCount++;
  }
}

void main() {
  /// 造 [count] 个身份不同的绘制类型。
  ///
  /// 必须各不相同：`Overlay.id` 取创建时刻的毫秒时间戳，`==` 由 id + key + type 构成，
  /// 同一毫秒内连着建同类型的两个会撞号，后者在 `SortableHashSet` 里顶掉前者。
  List<IDrawType> benchTypes(int count) {
    return List.generate(count, (i) => FlexiDrawType('bench_line_$i', 2, groupId: 'bench'));
  }

  Future<FlexiKlineController> mountChart(
    WidgetTester tester,
    List<IDrawType> types, {
    required DrawObjectBuilder builder,
  }) async {
    final config = FakeFlexiKlineConfiguration(enableStorage: true, enableDraw: true);
    final controller = FlexiKlineController(configuration: config);
    for (final type in types) {
      controller.registerDrawObjectBuilder(type, builder);
    }
    final scenario = ControllerScenario(controller: controller);
    await scenario.initWithData(
      _spec,
      genFlatCandleList(),
      canvasWidth: _canvasWidth,
      candle: TestCandleIndicator(visibleMinMaxFromData: true),
    );
    addTearDown(scenario.dispose);
    controller.flushPendingKlineData();
    controller.paintChart(Canvas(PictureRecorder()), controller.canvasRect.size);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    return controller;
  }

  /// 铺 [types].length 条线，纵向均分主区，两端都落在可见蜡烛范围内。
  ///
  /// 返回落成的对象列表：controller 不对外暴露对象树，绘制完成那一刻的
  /// `drawState.object` 就是刚入列表的那个，顺手收集起来。
  List<DrawObject> fillOverlays(FlexiKlineController controller, List<IDrawType> types) {
    final mainRect = controller.mainRect;
    final step = mainRect.height / (types.length + 1);
    final objects = <DrawObject>[];
    for (int i = 0; i < types.length; i++) {
      final dy = mainRect.top + step * (i + 1);
      controller.startDraw(types[i], isInitPointer: false);
      controller.onDrawConfirm(Offset(mainRect.right - 160, dy));
      controller.onDrawUpdate(Offset(mainRect.right - 40, dy));
      controller.onDrawConfirm(Offset(mainRect.right - 40, dy));
      final object = controller.drawState.object;
      if (object != null) objects.add(object);
      // 停在 Editing 会让下一条画不了(同类型再 startDraw 是收起语义), 退回 Prepared。
      controller.prepareDraw(force: true);
    }
    return objects;
  }

  /// 跑 [_rounds] 轮 [body]，返回最快一轮的微秒数。
  int bestMicros(void Function() body) {
    var best = -1;
    for (int r = 0; r < _rounds; r++) {
      final sw = Stopwatch()..start();
      body();
      sw.stop();
      final micros = sw.elapsedMicroseconds;
      if (best < 0 || micros < best) best = micros;
    }
    return best;
  }

  /// 量一档：[count] 个由 [builder] 造出的 overlay，打印 paintDraw / initPoints 及换算两半。
  ///
  /// [drawCountOf] / [resetDrawCount] 用来校验「N 个 overlay 真的都画了」。
  Future<void> measure(
    WidgetTester tester, {
    required String label,
    required int count,
    required DrawObjectBuilder builder,
    required int Function() drawCountOf,
    required void Function() resetDrawCount,
  }) async {
    {
      final types = benchTypes(count);
      final controller = await mountChart(tester, types, builder: builder);
      final objects = fillOverlays(controller, types);

      expect(objects, hasLength(count), reason: '前置：$count 个 overlay 都要落成');
      expect(controller.hasDrawOverlay, isTrue);

      final canvasSize = controller.canvasRect.size;
      final points = objects.expand((o) => o.points).whereType<Point>().toList();

      void paintBody() {
        for (int i = 0; i < _frames; i++) {
          controller.paintDraw(Canvas(PictureRecorder()), canvasSize);
        }
      }

      void initBody() {
        for (int i = 0; i < _frames; i++) {
          for (final object in objects) {
            object.initPoints(controller);
          }
        }
      }

      // 拆开换算的两半：想知道该不该做「同帧共享换算参数」那类低风险优化。
      void valueBody() {
        for (int i = 0; i < _frames; i++) {
          for (final point in points) {
            controller.valueToDy(point.value);
          }
        }
      }

      void tsBody() {
        for (int i = 0; i < _frames; i++) {
          for (final point in points) {
            controller.timestampToDx(point.ts);
          }
        }
      }

      // 四个 body 全部预热后再计时：只热其中一个会让后测的那个背上 JIT 成本。
      for (final body in [paintBody, initBody, valueBody, tsBody]) {
        body();
      }

      // 校验 N 个 overlay 真的都画了：paintDraw 不随 N 增长时，要能排除
      // 「有 overlay 被 initPoints 失败或 moving 跳过」这个可能。
      resetDrawCount();
      controller.paintDraw(Canvas(PictureRecorder()), canvasSize);
      final drawnPerFrame = drawCountOf();

      final paintMicros = bestMicros(paintBody);
      final initMicros = bestMicros(initBody);
      final valueMicros = bestMicros(valueBody);
      final tsMicros = bestMicros(tsBody);

      final share = initMicros / paintMicros * 100;
      debugPrint(
        'draw_paint_bench[$label / $count overlays / ${points.length} points]: '
        'drawn/frame $drawnPerFrame, '
        'paintDraw ${(paintMicros / _frames).toStringAsFixed(2)}us/frame, '
        'initPoints ${(initMicros / _frames).toStringAsFixed(2)}us/frame '
        '(${share.toStringAsFixed(1)}% of paintDraw), '
        'valueToDy ${(valueMicros / _frames).toStringAsFixed(2)}us/frame, '
        'timestampToDx ${(tsMicros / _frames).toStringAsFixed(2)}us/frame',
      );

      expect(drawnPerFrame, count, reason: '每帧应画出全部 $count 个 overlay');
    }
  }

  // 轻量档：每个 overlay 一条直线，对标 trendLine —— initPoints 占比的上界。
  for (final count in const [10, 50, 200]) {
    testWidgets('draw 图层每帧开销 / line × $count', (tester) async {
      await measure(
        tester,
        label: 'line',
        count: count,
        builder: _BenchLineDrawObject.new,
        drawCountOf: () => _BenchLineDrawObject.drawCount,
        resetDrawCount: () => _BenchLineDrawObject.drawCount = 0,
      );
    });
  }

  // 重量档：每个 overlay 11 线 + 11 文本，对标 fib 系列 —— 用来估可视区裁剪的上限收益。
  for (final count in const [10, 20]) {
    testWidgets('draw 图层每帧开销 / fib-like × $count', (tester) async {
      await measure(
        tester,
        label: 'fib-like',
        count: count,
        builder: _BenchFibLikeDrawObject.new,
        drawCountOf: () => _BenchFibLikeDrawObject.drawCount,
        resetDrawCount: () => _BenchFibLikeDrawObject.drawCount = 0,
      );
    });
  }

  // 对照档：同样 11 线但不画文本。与 fib-like 相减 = 文本的实测开销。
  for (final count in const [10, 20]) {
    testWidgets('draw 图层每帧开销 / fib-lines-only × $count', (tester) async {
      await measure(
        tester,
        label: 'fib-lines-only',
        count: count,
        builder: _BenchFibLinesOnlyDrawObject.new,
        drawCountOf: () => _BenchFibLinesOnlyDrawObject.drawCount,
        resetDrawCount: () => _BenchFibLinesOnlyDrawObject.drawCount = 0,
      );
    });
  }
}
