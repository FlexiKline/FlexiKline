import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../config/my_kline_config.dart';
import '../../../config/my_kline_indicator_config.dart';
import 'section.dart';

/// [PointBuffer]: 同一画笔的点 / 线段攒齐后一次 drawRawPoints, 缓冲跨帧复用。
class BatchSection extends StatelessWidget {
  const BatchSection(this.configuration, this.indicatorConfig, {super.key});

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '批量',
    caption: '柱子是线宽等于柱宽的竖线段(StrokeCap.butt, 否则两端各外延半个线宽); 3 支画笔共 3 次绘制。',
    height: 100,
    create: () => _BatchPainter(configuration, indicatorConfig),
  );
}

class _BatchPainter extends SectionPainter {
  _BatchPainter(super.configuration, super.indicatorConfig);

  /// 一支画笔一个缓冲: 涨柱、跌柱、折线点。
  late final _long = own(PointBuffer());
  late final _short = own(PointBuffer());
  late final _dots = own(PointBuffer());

  static const _count = 40;
  static const _barConfig = PaintConfig(strokeWidth: 5);
  static const _dotConfig = PaintConfig(strokeWidth: 3);

  /// 画笔跨帧复用, 每帧只按主题换色。
  late final _longPaint = _barConfig.paint..strokeCap = StrokeCap.butt;
  late final _shortPaint = _barConfig.paint..strokeCap = StrokeCap.butt;
  late final _dotPaint = _dotConfig.paint..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / _count;
    final base = size.height;
    for (var i = 0; i < _count; i++) {
      final x = step * (i + 0.5);
      final value = math.sin(i / 4);
      final top = base - (value.abs() * 0.6 + 0.1) * size.height;
      (value >= 0 ? _long : _short).addSegment(x, base, x, top);
      _dots.add(x, size.height * (0.3 - math.cos(i / 4) * 0.2));
    }
    _long.flush(canvas, ui.PointMode.lines, _longPaint..color = theme.longColor);
    _short.flush(canvas, ui.PointMode.lines, _shortPaint..color = theme.shortColor);
    _dots.flush(canvas, ui.PointMode.points, _dotPaint..color = theme.lineChartColor);
  }
}
