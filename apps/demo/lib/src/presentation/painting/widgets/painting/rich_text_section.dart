import 'dart:ui' as ui;

import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/material.dart';

import '../demo_image.dart';
import '../section.dart';

/// 富文本标签: build 返回 InlineSpan; [RawImageSpan] 把已解码的图片排进行内, [ShapeImage.span] 排入代码绘制的图标。
class RichTextSection extends StatelessWidget {
  const RichTextSection({super.key});

  @override
  Widget build(BuildContext context) => const PaintingSection(
    title: '富文本与行内图片',
    caption: '一行多种字重与颜色; 棋盘图是 RawImageSpan 直接排入的 ui.Image, 圆点是 ShapeImage 按颜色缓存的位图。',
    height: 56,
    create: _RichTextPainter.new,
  );
}

class _RichTextPainter extends SectionPainter {
  late final _styled = own(LabelPainter());
  late final _order = own(LabelPainter());
  late final _dot = own(ShapeImage(const CircleShape(), const Size(8, 8)));
  final ui.Image _image = checkerImage();

  LabelStyle get _plainStyle => byColors(#plain, (c) => LabelStyle(text: TextStyle(fontSize: 12, color: c.onSurface)));

  LabelStyle get _orderStyle => byColors(
    #order,
    (c) => LabelStyle(
      text: TextStyle(fontSize: 12, color: c.onPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: ShapeDecoration(
        color: c.primary,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2))),
      ),
    ),
  );

  @override
  void dispose() {
    _image.dispose();
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = colors;
    // 文字颜色取自配色, 以配色作 key: 切换明暗时才重新排版。
    _styled.paint(
      canvas,
      c,
      build: () => TextSpan(
        children: [
          const TextSpan(
            text: 'Bold ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: 'Primary ',
            style: TextStyle(color: c.primary),
          ),
          TextSpan(
            text: 'Error ',
            style: TextStyle(color: c.error),
          ),
          RawImageSpan(_image, const Size(14, 14)),
          const TextSpan(text: ' image inline'),
        ],
      ),
      style: _plainStyle,
      anchor: Offset.zero,
    );

    _order.paint(
      canvas,
      ('buy', 0.5),
      build: () => TextSpan(
        children: [
          _dot.span(c.onPrimary),
          const TextSpan(text: ' Buy 0.5 BTC'),
        ],
      ),
      style: _orderStyle,
      anchor: Offset(0, size.height),
      align: Alignment.bottomLeft,
    );
  }
}
