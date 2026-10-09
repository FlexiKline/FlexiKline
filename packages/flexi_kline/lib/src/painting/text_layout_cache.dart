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

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'label_style.dart';
import 'paint_resource.dart';

/// 一份排版参数下的 TextPainter 池, 按 key 复用排版结果。
///
/// key 契约: 值相等语义, 且在当前 [LabelStyle] 下完全决定文本。可用 String、num、FlexiNum、record;
/// 变长序列直接用 List: 本池按元素比较, 未命中入池时冻结一份副本, 调用方可以复用自己的 List。
/// 可用宽度不进 key, 由 TextPainter.layout 自己判断约束是否变化。
final class TextLayoutCache implements PaintResource {
  TextLayoutCache({this.capacity = 1}) : assert(capacity > 0);

  final int capacity;

  /// 插入序即使用序: 命中时挪到末尾, 满了淘汰首个。
  ///
  /// 值里带上入池时的 key: 命中后用它重新插入, 而不是调用方本次传入的实例, List key 才能一直保持冻结。
  final _entries = LinkedHashMap<Object, ({Object key, TextPainter painter})>(equals: _keyEquals, hashCode: _keyHash);

  LabelStyle? _style;

  /// 同步排版参数; 只有 [LabelStyle.sameLayout] 不成立时才清空。
  ///
  /// 总是记下本次实例: 值相等的新实例换进来后, 调用方持续传它时走 identical 快路径, 不必每帧深比较。
  void configure(LabelStyle style) {
    final old = _style;
    _style = style;
    if (old != null && (identical(old, style) || old.sameLayout(style))) return;
    reset();
  }

  /// [build] 为 null 时 [key] 本身就是文本(String 或 InlineSpan)。
  ///
  /// [minWidth] / [maxWidth] 是本次调用的排版约束, 与 [LabelStyle] 的同名字段取交集, 不进 key。
  TextPainter layout(Object key, {Object Function()? build, double minWidth = 0, double maxWidth = double.infinity}) {
    assert(_style != null, 'configure() must be called before layout()');
    final style = _style!;
    var entry = _entries.remove(key);
    if (entry == null) {
      final content = build?.call() ?? key;
      final painter = _entries.length < capacity ? _create(style) : _entries.remove(_entries.keys.first)!.painter;
      // InlineSpan 统一挂在以 style.text 为样式的根 span 下: 子 span 只写差异(如颜色),
      // ImageSpan 旁边的文字也能继承字号与颜色。
      painter.text = switch (content) {
        final InlineSpan span => TextSpan(style: style.text, children: [span]),
        _ => TextSpan(text: '$content', style: style.text),
      };
      // 冻结 List key: 调用方之后改动原 List 不会破坏已存条目的哈希。
      entry = (key: key is List ? List.unmodifiable(key) : key, painter: painter);
    }
    _entries[entry.key] = entry;

    final painter = entry.painter;
    final max = math.min(style.maxWidth, maxWidth);
    painter.layout(minWidth: math.min(math.max(style.minWidth, minWidth), max), maxWidth: max);
    return painter;
  }

  TextPainter _create(LabelStyle style) => TextPainter(
    textAlign: style.textAlign,
    textDirection: TextDirection.ltr,
    strutStyle: style.strutStyle,
    maxLines: style.maxLines,
    // TextPainter 不认 TextStyle.overflow; RenderParagraph 是把它翻译成 ellipsis 的。
    ellipsis: style.text.overflow == TextOverflow.ellipsis ? '\u2026' : null,
  );

  @override
  void reset() {
    for (final entry in _entries.values) {
      entry.painter.dispose();
    }
    _entries.clear();
  }

  @override
  void dispose() => reset();
}

bool _keyEquals(Object a, Object b) => a is List && b is List ? listEquals(a, b) : a == b;
int _keyHash(Object key) => key is List ? Object.hashAll(key) : key.hashCode;
