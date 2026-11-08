import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/material.dart';

import '../section.dart';

/// 标签缓存与宽度约束: key 不变时 build 不调用; minWidth 稳住宽度, maxWidth 触发省略;
/// 自己排版文本时直接用 [TextLayoutCache]。
class LabelCacheSection extends StatelessWidget {
  const LabelCacheSection({super.key});

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '标签缓存',
    caption:
        '「重绘」只触发 paint, key 未变不重新格式化; 「换值」换 key 才调 build。'
        '左侧价格用 minWidth 稳住宽度, 右侧长文本用 maxWidth 省略; 底部一行由 TextLayoutCache 排版后自行绘制。',
    height: 90,
    create: _LabelCachePainter.new,
    footer: (painter) => Row(
      children: [
        TextButton(onPressed: painter.markNeedsPaint, child: const Text('重绘')),
        TextButton(onPressed: painter.next, child: const Text('换值')),
      ],
    ),
  );
}

class _LabelCachePainter extends SectionPainter {
  late final _price = own(LabelPainter());
  late final _clipped = own(LabelPainter());
  late final _counter = own(LabelPainter());

  /// 底部一行的词各占一个排版槽, 容量覆盖同帧的全部词。
  late final _words = own(TextLayoutCache(capacity: _wordList.length));

  static const _wordList = ['Open', 'High', 'Low', 'Close'];

  double _value = 1234.5;
  int _builds = 0;

  void next() {
    _value += 0.5;
    markNeedsPaint();
  }

  static const _padding = EdgeInsets.symmetric(horizontal: 6, vertical: 3);
  static const _shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3)));

  /// minWidth: 价格位数变化时标签宽度不跳。
  LabelStyle get _priceStyle => byColors(
    #price,
    (c) => LabelStyle(
      text: TextStyle(fontSize: 13, color: c.onPrimary),
      textAlign: TextAlign.end,
      minWidth: 80,
      padding: _padding,
      decoration: ShapeDecoration(color: c.primary, shape: _shape),
    ),
  );

  /// 单行加 ellipsis, 超过 maxWidth 时末尾显示省略号。
  LabelStyle get _clippedStyle => byColors(
    #clipped,
    (c) => LabelStyle(
      text: TextStyle(fontSize: 13, color: c.onPrimary, overflow: TextOverflow.ellipsis),
      maxLines: 1,
      maxWidth: 120,
      padding: _padding,
      decoration: ShapeDecoration(color: c.primary, shape: _shape),
    ),
  );

  LabelStyle get _plainStyle =>
      byColors(#plain, (c) => LabelStyle(text: TextStyle(fontSize: 11, color: c.onSurfaceVariant)));

  @override
  void paint(Canvas canvas, Size size) {
    final value = _value;
    _price.paint(
      canvas,
      value,
      build: () {
        _builds++;
        return value.toStringAsFixed(1);
      },
      style: _priceStyle,
      anchor: const Offset(0, 36),
      align: Alignment.centerLeft,
    );
    _clipped.paint(
      canvas,
      'a long label limited by maxWidth',
      style: _clippedStyle,
      anchor: Offset(size.width, 36),
      align: Alignment.centerRight,
    );
    // 计数在 paint 期才变, 画在画布上才能与本帧一致。
    final builds = _builds;
    _counter.paint(canvas, builds, build: () => 'build 调用 $builds 次', style: _plainStyle, anchor: Offset.zero);

    _words.configure(_plainStyle);
    var x = 0.0;
    for (final word in _wordList) {
      final text = _words.layout(word);
      text.paint(canvas, Offset(x, size.height - text.height));
      x += text.width + 16;
    }
  }
}
