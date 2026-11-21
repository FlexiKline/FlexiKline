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

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart' show MainAxisAlignment;

import '../foundation/paint_resource.dart';
import '../geometry/placement.dart';
import 'decoration_painter.dart';
import 'label_style.dart';
import 'text_layout_cache.dart';

/// tooltip 的一行; 行样式为 null 时沿用列样式。
typedef TooltipRow = ({String label, TextStyle? labelStyle, String value, TextStyle? valueStyle});

/// 两列 tooltip 卡片: 返回卡片与逐行命中区。
///
/// 定宽与行内排布借用 Flutter 的 [MainAxisAlignment]:
/// - start / end / center: label+spacing+value 整体左对齐 / 右对齐 / 居中, 按最宽一行定宽;
/// - spaceBetween(默认): 按最宽一行定宽, label 贴左缘、value 贴右缘 —— 最宽 label 与最宽
///   value 往往不在同一行, 两端对齐时余量摊进中缝;
/// - spaceAround(借用, 行为已变): 两列定宽, 卡片宽 = 最宽 label + spacing + 最宽 value,
///   两列严格对齐;
/// - spaceEvenly(不支持): 绘制时降级为 spaceBetween。
/// spacing 始终保底为两列间的最小间距。
///
/// 两列各一个 [TextLayoutCache], 列样式只取基础文本样式; 每行自带的样式进 key 与子 span, 切行不清缓存。
/// value 列容量是 label 列的两倍: 在相邻两条数据间来回切换时, 两组值都留在池里。
final class TooltipPainter implements PaintResource {
  TextLayoutCache _labels = TextLayoutCache(capacity: 16);
  TextLayoutCache _values = TextLayoutCache(capacity: 32);
  final DecorationPainter _decoration = DecorationPainter();

  /// 本帧各行的 painter; 跨帧复用列表本身, 不复用内容。
  final List<TextPainter> _labelRows = [];
  final List<TextPainter> _valueRows = [];

  TextStyle? _text;
  LabelStyle? _labelStyle;
  LabelStyle? _valueStyle;

  /// 画卡片, 返回卡片矩形(含 padding)与各行矩形(横向撑满卡片)。
  ///
  /// [spacing] 与 [alignment] 的行内排布语义见类文档。
  /// [minContentWidth] / [maxContentWidth] 指内容区宽度, 不含 [padding]; 超出 [maxContentWidth] 时压缩 value 列。
  /// [decoration] 是卡片的背景与边框, 跨帧传同一实例时复用其 BoxPainter; 为 null 时不画。
  ({Rect bounds, List<Rect> rows}) paint(
    Canvas canvas,
    List<TooltipRow> infos, {
    required TextStyle style,
    required Offset anchor,
    Alignment align = Alignment.topLeft,
    Rect? bounds,
    double spacing = 0,
    MainAxisAlignment alignment = MainAxisAlignment.spaceBetween,
    double? minContentWidth,
    double maxContentWidth = double.infinity,
    ShapeDecoration? decoration,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    if (infos.isEmpty) return (bounds: Rect.zero, rows: const <Rect>[]);
    _configure(style, infos.length);

    final labels = _labelRows..clear();
    final values = _valueRows..clear();
    final gap = math.max(0.0, spacing);
    double widest = 0;
    double labelWidth = 0;
    double valueWidth = 0;
    for (final info in infos) {
      final label = _labels.layout((info.label, info.labelStyle), build: () => _span(info.label, info.labelStyle));
      final value = _values.layout((info.value, info.valueStyle), build: () => _span(info.value, info.valueStyle));
      labels.add(label);
      values.add(value);
      widest = math.max(widest, label.width + gap + value.width);
      labelWidth = math.max(labelWidth, label.width);
      valueWidth = math.max(valueWidth, value.width);
    }

    // 定宽: spaceAround 借用为两列定宽(最宽 label + gap + 最宽 value); 其余按最宽一行。
    final byColumns = alignment == MainAxisAlignment.spaceAround;
    var contentWidth = math.max(byColumns ? labelWidth + gap + valueWidth : widest, minContentWidth ?? 0);
    if (maxContentWidth.isFinite && contentWidth > maxContentWidth && maxContentWidth > labelWidth + gap) {
      contentWidth = maxContentWidth;
      // 压缩 value 列: byColumns 按列最大宽一刀切; 否则逐行扣除各自 label 与 gap 的剩余空间。
      for (var i = 0; i < infos.length; i++) {
        final valueMaxWidth = byColumns ? maxContentWidth - labelWidth - gap : maxContentWidth - labels[i].width - gap;
        if (values[i].width <= valueMaxWidth) continue;
        final info = infos[i];
        values[i] = _values.layout((info.value, info.valueStyle), maxWidth: valueMaxWidth);
      }
    }

    double contentHeight = 0;
    for (var i = 0; i < infos.length; i++) {
      contentHeight += math.max(labels[i].height, values[i].height);
    }
    final card = align.place(Size(contentWidth + padding.horizontal, contentHeight + padding.vertical), anchor, bounds);

    _decoration.paint(canvas, decoration, card, anchor);

    final rows = <Rect>[];
    var top = card.top + padding.top;
    final left = card.left + padding.left;
    final width = card.width - padding.horizontal;
    for (var i = 0; i < infos.length; i++) {
      final label = labels[i];
      final value = values[i];
      final height = math.max(label.height, value.height);
      // 行内垂直居中; 水平按 alignment 分配余量, gap 始终保底在中缝。
      final (labelDx, valueDx) = _rowOffsets(alignment, gap, width - label.width - value.width, label.width);
      label.paint(canvas, Offset(left + labelDx, top + (height - label.height) / 2));
      value.paint(canvas, Offset(left + valueDx, top + (height - value.height) / 2));
      rows.add(Rect.fromLTRB(card.left, top, card.right, top + height));
      top += height;
    }
    return (bounds: card, rows: rows);
  }

  /// 行内 label / value 的横轴偏移: [free] 是内容区扣除两列后的余量(不小于 [gap]),
  /// 扣除保底 [gap] 后的剩余余量按 [alignment] 分配。
  ///
  /// spaceAround 借用为两列定宽、spaceEvenly 不支持, 两者绘制时都按 spaceBetween 两端对齐。
  static (double, double) _rowOffsets(MainAxisAlignment alignment, double gap, double free, double labelWidth) {
    final rest = math.max(0.0, free - gap);
    final after = labelWidth + gap; // start 基准: value 紧跟 label。
    return switch (alignment) {
      MainAxisAlignment.start => (0.0, after),
      MainAxisAlignment.end => (rest, rest + after),
      MainAxisAlignment.center => (rest / 2, rest / 2 + after),
      // spaceBetween 及借用/降级的 spaceAround / spaceEvenly: 两端对齐。
      _ => (0.0, rest + after),
    };
  }

  /// 同步列样式, 并保证容量不小于行数: 否则同一帧后面的行会淘汰前面行仍要绘制的 painter。
  void _configure(TextStyle style, int rows) {
    if (style != _text) {
      _text = style;
      _labelStyle = LabelStyle(text: style);
      _valueStyle = LabelStyle(text: style, textAlign: TextAlign.end);
    }
    if (rows > _labels.capacity) {
      _labels.dispose();
      _labels = TextLayoutCache(capacity: rows);
    }
    if (rows * 2 > _values.capacity) {
      _values.dispose();
      _values = TextLayoutCache(capacity: rows * 2);
    }
    _labels.configure(_labelStyle!);
    _values.configure(_valueStyle!);
  }

  /// 行样式为 null 时直接用文本, 由列样式的根 span 决定外观。
  static Object _span(String text, TextStyle? style) => style == null ? text : TextSpan(text: text, style: style);

  void _clearRows() {
    _labelRows.clear();
    _valueRows.clear();
  }

  @override
  void reset() {
    _clearRows();
    _labels.reset();
    _values.reset();
    _decoration.reset();
  }

  @override
  void dispose() {
    _clearRows();
    _labels.dispose();
    _values.dispose();
    _decoration.dispose();
  }
}
