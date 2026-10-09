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

import 'alignment.dart';
import 'decoration_painter.dart';
import 'label_style.dart';
import 'paint_resource.dart';
import 'text_layout_cache.dart';

/// tooltip 的一行; 行样式为 null 时沿用列样式。
typedef TooltipRow = ({String label, TextStyle? labelStyle, String value, TextStyle? valueStyle});

/// 两列 tooltip 卡片: label 左对齐、value 右对齐, 返回卡片与逐行命中区。
///
/// 两列各一个 [TextLayoutCache], 列样式只取基础文本样式; 每行自带的样式进 key 与子 span, 切行不清缓存。
/// value 列容量是 label 列的两倍: 十字线在相邻蜡烛间来回时两组值都留在池里。
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

  Color? _background;
  BorderRadius? _radius;
  ShapeDecoration? _shape;

  /// 画卡片, 返回卡片矩形(含 padding)与各行矩形(横向撑满卡片)。
  ///
  /// [minContentWidth] / [maxContentWidth] 指内容区宽度, 不含 [padding]; 超出 [maxContentWidth] 时只压缩 value 列。
  ({Rect bounds, List<Rect> rows}) paint(
    Canvas canvas,
    List<TooltipRow> infos, {
    required TextStyle style,
    required Offset anchor,
    Alignment align = Alignment.topLeft,
    Rect? bounds,
    double spacing = 0,
    double? minContentWidth,
    double maxContentWidth = double.infinity,
    Color? backgroundColor,
    BorderRadius radius = BorderRadius.zero,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    if (infos.isEmpty) return (bounds: Rect.zero, rows: const <Rect>[]);
    _configure(style, infos.length);

    final labels = _labelRows..clear();
    final values = _valueRows..clear();
    double labelWidth = 0;
    double valueWidth = 0;
    for (final info in infos) {
      final label = _labels.layout((info.label, info.labelStyle), build: () => _span(info.label, info.labelStyle));
      final value = _values.layout((info.value, info.valueStyle), build: () => _span(info.value, info.valueStyle));
      labels.add(label);
      values.add(value);
      labelWidth = math.max(labelWidth, label.width);
      valueWidth = math.max(valueWidth, value.width);
    }

    final gap = math.max(0.0, spacing);
    var contentWidth = math.max(labelWidth + gap + valueWidth, minContentWidth ?? 0);
    if (maxContentWidth.isFinite && contentWidth > maxContentWidth && maxContentWidth > labelWidth + gap) {
      contentWidth = maxContentWidth;
      final valueMaxWidth = maxContentWidth - labelWidth - gap;
      for (var i = 0; i < infos.length; i++) {
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

    if (backgroundColor != _background || radius != _radius) {
      _background = backgroundColor;
      _radius = radius;
      _shape = backgroundColor == null || backgroundColor.a == 0
          ? null
          : ShapeDecoration(
              color: backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: radius),
            );
    }
    _decoration.paint(canvas, _shape, card, anchor);

    final rows = <Rect>[];
    var top = card.top + padding.top;
    for (var i = 0; i < infos.length; i++) {
      final label = labels[i];
      final value = values[i];
      final height = math.max(label.height, value.height);
      // 行内垂直居中。
      label.paint(canvas, Offset(card.left + padding.left, top + (height - label.height) / 2));
      value.paint(canvas, Offset(card.right - padding.right - value.width, top + (height - value.height) / 2));
      rows.add(Rect.fromLTRB(card.left, top, card.right, top + height));
      top += height;
    }
    return (bounds: card, rows: rows);
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
