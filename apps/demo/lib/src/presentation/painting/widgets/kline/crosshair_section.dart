import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../../config/app_kline_config.dart';
import '../../../../config/app_kline_indicator_config.dart';
import '../section.dart';
import 'kline_section.dart';

/// 十字线: 线条、两轴刻度标签与 tooltip 卡片, 样式全部取自 [CrossConfig]。
class CrosshairSection extends StatelessWidget {
  const CrosshairSection(this.configuration, this.indicatorConfig, {super.key});

  final AppKlineConfig configuration;
  final AppKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '十字线',
    caption:
        '线条取 cross.crosshair, 刻度标签取 cross.ticksText 并夹在画布内, 卡片取 cross.tooltipConfig 并放在十字线对侧。'
        '点击空白处移动十字线, 点中卡片某行则高亮, 命中区来自行矩形。',
    height: 170,
    create: () => _CrosshairPainter(configuration, indicatorConfig),
    onTap: (painter, position) => painter.tap(position),
  );
}

class _CrosshairPainter extends KlineSectionPainter {
  _CrosshairPainter(super.configuration, super.indicatorConfig);

  late final _cross = flexiKlineConfig.cross;

  /// 按主题套用的 Tooltip 样式; 主题不变时复用同一实例, 卡片装饰走记忆。
  TooltipConfig? _tooltipConfig;
  IFlexiKlineTheme? _tooltipTheme;
  TooltipConfig get tooltipConfig {
    if (!identical(theme, _tooltipTheme)) {
      _tooltipTheme = theme;
      _tooltipConfig = AppKlineConfig.styleTooltip(_cross.tooltipConfig);
    }
    return _tooltipConfig!;
  }

  late final _ticks = own(LabelPainter(capacity: 2));
  late final _tooltip = own(TooltipPainter());

  Offset? _point;

  /// 上一帧画出的行矩形, 供点击命中。
  List<Rect> _rows = const [];
  int? _selected;

  void tap(Offset position) {
    final index = _rows.indexWhere((row) => row.inflate(_cross.tooltipConfig.hitTestMargin).contains(position));
    if (index >= 0) {
      _selected = index;
    } else {
      _point = position;
      _selected = null;
    }
    markNeedsPaint();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final point = _point ?? Offset(size.width * 0.7, size.height * 0.55);
    canvas.drawLineByConfig(
      Path()
        ..moveTo(0, point.dy)
        ..lineTo(size.width, point.dy)
        ..moveTo(point.dx, 0)
        ..lineTo(point.dx, size.height),
      _cross.crosshair,
      themeColor: theme.crosshairColor,
    );

    // 与 cross 刻度同一配置、同一主题兜底, 见 PaintGridTicksMixin.paintYAxisTicksOnCross。
    final tickStyle = _cross.ticksText.toLabelStyle(
      textColor: theme.crossTextColor,
      backgroundColor: theme.crossTextBg,
    );
    final price = 1300 - point.dy / size.height * 100;
    _ticks.paint(
      canvas,
      ('y', price),
      build: () => price.toStringAsFixed(2),
      style: tickStyle,
      anchor: Offset(size.width, point.dy),
      align: Alignment.centerRight,
      bounds: bounds,
    );
    final minute = (point.dx / size.width * 60).floor();
    _ticks.paint(
      canvas,
      ('x', minute),
      build: () => '10-09 18:${minute.toString().padLeft(2, '0')}',
      style: tickStyle,
      anchor: Offset(point.dx, size.height),
      align: Alignment.bottomCenter,
      bounds: bounds,
    );

    final config = tooltipConfig;
    final up = config.style.ensure(theme.longColor);
    final onLeft = point.dx > size.width / 2;
    final card = _tooltip.paint(
      canvas,
      [
        (label: 'Time', labelStyle: null, value: '2026-10-09 18:00', valueStyle: null),
        (label: 'Open', labelStyle: null, value: '1234.50', valueStyle: null),
        (label: 'Close', labelStyle: null, value: '1240.00', valueStyle: up),
        (label: 'Change', labelStyle: null, value: '+0.45%', valueStyle: up),
      ],
      style: config.style.ensure(theme.tooltipTextColor),
      anchor: onLeft ? const Offset(4, 4) : Offset(size.width - 4, 4),
      align: onLeft ? Alignment.topLeft : Alignment.topRight,
      spacing: config.spacing,
      decoration: config.toDecoration(backgroundColor: theme.tooltipBg),
      padding: config.padding,
    );
    final selected = _selected;
    if (selected != null) {
      canvas.drawRect(card.rows[selected], Paint()..color = theme.crosshairColor.withValues(alpha: 0.2));
    }
    _rows = card.rows;
  }
}
