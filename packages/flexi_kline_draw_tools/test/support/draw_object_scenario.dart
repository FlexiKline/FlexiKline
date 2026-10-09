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

/// 绘制工具单测的公共 arrange / act。
library;

import 'dart:ui' show Paragraph;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

export 'fake_draw_context.dart';

/// 测试统一使用的线样式：实线 + 确定颜色。
///
/// 必须显式给颜色：`drawLineByConfig` 与 `drawLineType` 在颜色无效时直接返回，
/// 断言绘制产物的用例会因此空转。虚线会被拆成多段 path，形状断言随之失效。
const testLine = LineConfig(
  type: LineType.solid,
  paint: PaintConfig(color: Color(0xFF448AFF), strokeWidth: 1),
);

/// 建一个已落满 [offsets] 个绘制点的 [DrawObject]。
///
/// [offsets] 数量须等于 `type.steps`，即对象处于 `Editing`（绘制完成）态。
T buildEditingObject<T extends DrawObject>(
  T Function(Overlay overlay, DrawConfig config) builder, {
  required IDrawType type,
  required List<Offset> offsets,
  DrawConfig config = const DrawConfig(enable: true),
}) {
  assert(
    offsets.length == type.steps,
    '${type.id} 需要 ${type.steps} 个点, 给了 ${offsets.length} 个',
  );
  final object = builder(
    Overlay.fromType(key: 'test', type: type, line: testLine),
    config,
  );
  for (var i = 0; i < offsets.length; i++) {
    object.addPointer(Point.pointer(i, offsets[i]));
  }
  return object;
}

/// 模拟「整体平移」：与 `DrawBinding.onDrawMoveUpdate` 的无指针分支同源。
///
/// 逐点调 [DrawObject.onUpdateDrawPoint] 而不是直接改 offset —— 各工具正是在这个钩子
/// 里做联动修正（如水平线族把 dy 对齐），绕过它就测不到那段逻辑。
void translateObject(DrawObject object, Offset delta) {
  for (final point in object.points) {
    if (point != null && point.offset.isFinite) {
      object.onUpdateDrawPoint(point, point.offset + delta);
    }
  }
}

/// 模拟「拖动单个绘制点」：与 `onDrawMoveUpdate` 的有指针分支同源。
void dragPoint(DrawObject object, int index, Offset to) {
  final point = object.points[index];
  assert(point != null, 'points[$index] 为空, 无法拖动');
  object.setPointer(point);
  object.onUpdateDrawPoint(point!, to);
}

/// 一次 `drawPath` 的产物摘要。
///
/// 只留端点、路径长度与颜色：足以断言「画了几条」「起止在哪」「有没有折返」，
/// 又不必做像素比较。
typedef DrawnPath = ({Offset start, Offset end, double length, Color color});

/// 记录绘制调用的 [Canvas]。
class RecordingCanvas implements Canvas {
  final List<DrawnPath> drawn = [];

  @override
  void drawPath(Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      final start = metric.getTangentForOffset(0)?.position;
      final end = metric.getTangentForOffset(metric.length)?.position;
      if (start == null || end == null) continue;
      drawn.add((start: start, end: end, length: metric.length, color: paint.color));
    }
  }

  /// 文本绘制: 段落实例用来判断缓存是否命中, 矩形用来断言对齐。
  final List<({Paragraph paragraph, Rect rect})> paragraphs = [];

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {
    paragraphs.add((paragraph: paragraph, rect: offset & Size(paragraph.longestLine, paragraph.height)));
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}

/// 路径是否是一条不折返的直线段：总长等于两端点间的直线距离。
///
/// 折返（同一段被来回画过）会让总长大于端点距离，虚线的 dash 相位也随之错乱。
Matcher isStraightSegment({double epsilon = 0.5}) => predicate<DrawnPath>(
  (p) => (p.length - (p.end - p.start).distance).abs() <= epsilon,
  'a straight, non-backtracking segment',
);
