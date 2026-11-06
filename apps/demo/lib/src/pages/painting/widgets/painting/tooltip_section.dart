import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/material.dart';

import '../section.dart';

/// [TooltipPainter]: 两列卡片, 返回卡片与逐行矩形, 行矩形可直接作点击命中区。
class TooltipSection extends StatelessWidget {
  const TooltipSection({super.key});

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: 'Tooltip',
    caption: 'label 左对齐、value 右对齐, 单行可单独着色; 点击某行高亮, 命中区来自行矩形。',
    height: 100,
    create: _TooltipPainter.new,
    onTap: (painter, position) => painter.select(position),
  );
}

class _TooltipPainter extends SectionPainter {
  late final _tooltip = own(TooltipPainter());

  /// 上一帧画出的行矩形, 供点击命中。
  List<Rect> _rows = const [];
  int? _selected;

  void select(Offset position) {
    final index = _rows.indexWhere((row) => row.inflate(2).contains(position));
    _selected = index < 0 ? null : index;
    markNeedsPaint();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = colors;
    final up = TextStyle(fontSize: 11, color: c.primary);
    final card = _tooltip.paint(
      canvas,
      [
        (label: 'Time', labelStyle: null, value: '2026-10-09 18:00', valueStyle: null),
        (label: 'Open', labelStyle: null, value: '1234.50', valueStyle: null),
        (label: 'Close', labelStyle: null, value: '1240.00', valueStyle: up),
        (label: 'Change', labelStyle: null, value: '+0.45%', valueStyle: up),
      ],
      style: TextStyle(fontSize: 11, color: c.onSurface),
      anchor: Offset(size.width / 2, 0),
      align: Alignment.topCenter,
      spacing: 12,
      backgroundColor: c.surfaceContainerHighest,
      radius: const BorderRadius.all(Radius.circular(4)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
    final selected = _selected;
    if (selected != null) {
      canvas.drawRect(card.rows[selected], Paint()..color = c.primary.withValues(alpha: 0.2));
    }
    _rows = card.rows;
  }
}
