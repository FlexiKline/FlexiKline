import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../config/my_kline_config.dart';
import '../../../config/my_kline_indicator_config.dart';
import 'section.dart';

/// [TooltipPainter]: 两列卡片, 返回卡片与逐行矩形, 行矩形可直接作点击命中区。
class TooltipSection extends StatelessWidget {
  const TooltipSection(this.configuration, this.indicatorConfig, {super.key});

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: 'Tooltip',
    caption: '配置来自 cross.tooltipConfig; label 左对齐、value 右对齐; 点击某行高亮, 命中区来自行矩形。',
    height: 100,
    create: () => _TooltipPainter(configuration, indicatorConfig),
    onTap: (painter, position) => painter.select(position),
  );
}

class _TooltipPainter extends SectionPainter {
  _TooltipPainter(super.configuration, super.indicatorConfig);

  late final _tooltip = own(TooltipPainter());

  late final _config = flexiKlineConfig.cross.tooltipConfig;

  /// 上一帧画出的行矩形, 供点击命中。
  List<Rect> _rows = const [];
  int? _selected;

  void select(Offset position) {
    final index = _rows.indexWhere((row) => row.inflate(_config.hitTestMargin).contains(position));
    _selected = index < 0 ? null : index;
    markNeedsPaint();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final up = _config.style.ensure(theme.longColor);
    final card = _tooltip.paint(
      canvas,
      [
        (label: 'Time', labelStyle: null, value: '2026-10-09 18:00', valueStyle: null),
        (label: 'Open', labelStyle: null, value: '1234.50', valueStyle: null),
        (label: 'Close', labelStyle: null, value: '1240.00', valueStyle: up),
        (label: 'Change', labelStyle: null, value: '+0.45%', valueStyle: up),
      ],
      style: _config.style.ensure(theme.tooltipTextColor),
      anchor: Offset(size.width / 2, 0),
      align: Alignment.topCenter,
      spacing: _config.spacing,
      backgroundColor: theme.tooltipBg,
      radius: _config.radius,
      padding: _config.padding,
    );
    final selected = _selected;
    if (selected != null) {
      canvas.drawRect(card.rows[selected], Paint()..color = theme.crosshairColor.withValues(alpha: 0.2));
    }
    _rows = card.rows;
  }
}
