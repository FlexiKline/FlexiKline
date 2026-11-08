import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/material.dart';

import '../section.dart';

/// 摆放: [LabelPainter] 的 anchor + align 与 bounds 夹回、paintAround 按空间翻到对侧, 以及 [AlignmentPlace.place] 直接摆放自绘图形。
class PlacementSection extends StatelessWidget {
  const PlacementSection({super.key});

  @override
  Widget build(BuildContext context) => const PaintingSection(
    title: '摆放',
    caption:
        '上: align 指标签哪个点对准 anchor(红十字); 右下角标签越过 bounds 后被夹回。'
        '下: paintAround 首选上方, 贴顶的灰块上方放不下, 翻到下方; 右侧圆点用 Alignment.place 摆放, 不经过 LabelPainter。',
    height: 260,
    create: _PlacementPainter.new,
  );
}

class _PlacementPainter extends SectionPainter {
  /// 同一帧画 9 + 1 个标签, 容量不能小于同屏数量, 否则后画的会挤掉先画的。
  late final _labels = own(LabelPainter(capacity: 10));
  late final _around = [for (var i = 0; i < 2; i++) own(LabelPainter())];

  static const _gridHeight = 170.0;

  static const _alignments = {
    'topLeft': Alignment.topLeft,
    'topCenter': Alignment.topCenter,
    'topRight': Alignment.topRight,
    'centerLeft': Alignment.centerLeft,
    'center': Alignment.center,
    'centerRight': Alignment.centerRight,
    'bottomLeft': Alignment.bottomLeft,
    'bottomCenter': Alignment.bottomCenter,
    'bottomRight': Alignment.bottomRight,
  };

  LabelStyle get _style => byColors(
    #label,
    (c) => LabelStyle(
      text: TextStyle(fontSize: 11, color: c.onPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: ShapeDecoration(
        color: c.primary,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2))),
      ),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final style = _style;
    final grid = Rect.fromLTWH(0, 0, size.width, _gridHeight);
    final cell = Size(size.width / 3, (_gridHeight - 30) / 3);
    for (final (i, MapEntry(key: name, value: align)) in _alignments.entries.indexed) {
      final anchor = Offset(cell.width * (i % 3 + 0.5), cell.height * (i ~/ 3 + 0.5));
      // key 本身就是文本, 省掉 build。
      _labels.paint(canvas, name, style: style, anchor: anchor, align: align);
      paintAnchor(canvas, anchor);
    }
    final edge = Offset(size.width - 4, _gridHeight - 10);
    _labels.paint(canvas, 'clamped into bounds', style: style, anchor: edge, align: Alignment.topLeft, bounds: grid);
    paintAnchor(canvas, edge);

    final lower = Rect.fromLTRB(0, _gridHeight + 10, size.width, size.height);
    final targetPaint = Paint()..color = colors.outline;
    final targets = [
      (name: 'flipped', rect: Rect.fromLTWH(size.width * 0.1, lower.top + 2, 48, 14)),
      (name: 'preferred', rect: Rect.fromLTWH(size.width * 0.4, lower.top + 44, 48, 14)),
    ];
    canvas.drawRect(
      lower,
      Paint()
        ..color = colors.outlineVariant
        ..style = PaintingStyle.stroke,
    );
    for (final (i, target) in targets.indexed) {
      canvas.drawRect(target.rect, targetPaint);
      _around[i].paintAround(
        canvas,
        target.name,
        styleOf: (_) => style,
        target: target.rect,
        side: AxisDirection.up,
        spacing: 4,
        bounds: lower,
      );
    }

    final dotAnchor = Offset(size.width * 0.85, lower.center.dy);
    final dot = Alignment.bottomRight.place(const Size(14, 14), dotAnchor, lower);
    canvas.drawOval(dot, Paint()..color = colors.tertiary);
    paintAnchor(canvas, dotAnchor);
  }
}
