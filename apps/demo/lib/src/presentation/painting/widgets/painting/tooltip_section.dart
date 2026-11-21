import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/material.dart';

import '../section.dart';

/// [TooltipPainter]: 两列卡片, 返回卡片与逐行矩形, 行矩形可直接作点击命中区。
class TooltipSection extends StatelessWidget {
  const TooltipSection({super.key});

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: 'Tooltip',
    caption:
        'label 左对齐、value 右对齐, 单行可单独着色; 点击某行高亮, 命中区来自行矩形。'
        '下方切换 alignment: start / center / end 按最宽一行定宽后整体排布, spaceBetween 两端对齐, '
        'spaceAround 借用为两列定宽; spaceEvenly 不支持, 会降级为 spaceBetween。',
    height: 100,
    create: _TooltipPainter.new,
    onTap: (painter, position) => painter.select(position),
    footer: (painter) => _AlignmentPicker(painter: painter),
  );
}

/// alignment 切换按钮; 只列出绘制时有区别的取值。
class _AlignmentPicker extends StatefulWidget {
  const _AlignmentPicker({required this.painter});

  final _TooltipPainter painter;

  @override
  State<_AlignmentPicker> createState() => _AlignmentPickerState();
}

class _AlignmentPickerState extends State<_AlignmentPicker> {
  late MainAxisAlignment _alignment = widget.painter.alignment;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final alignment in _TooltipPainter.alignmentOptions)
        ChoiceChip(
          label: Text(alignment.name),
          selected: alignment == _alignment,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          onSelected: (_) {
            setState(() => _alignment = alignment);
            widget.painter.setAlignment(alignment);
          },
        ),
    ],
  );
}

class _TooltipPainter extends SectionPainter {
  late final _tooltip = own(TooltipPainter());

  /// 绘制时有区别的取值; spaceEvenly 与 spaceBetween 同效, 不放进来。
  static const alignmentOptions = [
    MainAxisAlignment.start,
    MainAxisAlignment.center,
    MainAxisAlignment.end,
    MainAxisAlignment.spaceBetween,
    MainAxisAlignment.spaceAround,
  ];

  MainAxisAlignment _alignment = MainAxisAlignment.spaceBetween;

  /// 上一帧画出的行矩形, 供点击命中。
  List<Rect> _rows = const [];
  int? _selected;

  MainAxisAlignment get alignment => _alignment;

  void setAlignment(MainAxisAlignment value) {
    if (value == _alignment) return;
    _alignment = value;
    markNeedsPaint();
  }

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
        (label: 'Time', labelStyle: null, value: '2026-10-09', valueStyle: null),
        (label: 'Open', labelStyle: null, value: '1234.50', valueStyle: null),
        (label: 'Close', labelStyle: null, value: '1240.00', valueStyle: up),
        (label: 'Change', labelStyle: null, value: '+0.45%', valueStyle: up),
      ],
      style: TextStyle(fontSize: 11, color: c.onSurface),
      anchor: Offset(size.width / 2, 0),
      align: Alignment.topCenter,
      spacing: 12,
      alignment: _alignment,
      decoration: ShapeDecoration(
        color: c.surfaceContainerHighest,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
    final selected = _selected;
    if (selected != null) {
      canvas.drawRect(card.rows[selected], Paint()..color = c.primary.withValues(alpha: 0.2));
    }
    _rows = card.rows;
  }
}
