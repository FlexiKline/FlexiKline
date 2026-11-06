import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/material.dart';

import '../section.dart';

/// [PointBuffer]: 同一画笔的点 / 线段攒齐后一次 drawRawPoints, 缓冲跨帧复用。
class BatchSection extends StatelessWidget {
  const BatchSection({super.key});

  @override
  Widget build(BuildContext context) => const PaintingSection(
    title: '批量',
    caption: '柱子是线宽等于柱宽的竖线段(StrokeCap.butt, 否则两端各外延半个线宽); 3 支画笔共 3 次绘制。',
    height: 100,
    create: _BatchPainter.new,
  );
}

class _BatchPainter extends SectionPainter {
  /// 一支画笔一个缓冲: 涨柱、跌柱、折线点。
  late final _long = own(PointBuffer());
  late final _short = own(PointBuffer());
  late final _dots = own(PointBuffer());

  static const _count = 40;

  /// 画笔跨帧复用, 每帧只按配色换色。
  final _longPaint = Paint()
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.butt;
  final _shortPaint = Paint()
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.butt;
  final _dotPaint = Paint()
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;

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
    _long.flush(canvas, ui.PointMode.lines, _longPaint..color = colors.primary);
    _short.flush(canvas, ui.PointMode.lines, _shortPaint..color = colors.error);
    _dots.flush(canvas, ui.PointMode.points, _dotPaint..color = colors.tertiary);
  }
}
