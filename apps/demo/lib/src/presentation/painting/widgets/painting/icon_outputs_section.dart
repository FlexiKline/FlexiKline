import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/material.dart';

import '../section.dart';

/// 底部 Widget 两行共用的图形。
const _shapes = <(String, IconShape)>[
  ('TriangleShape', TriangleShape()),
  ('StarShape', StarShape()),
  ('_HexagonShape', _HexagonShape()),
];

/// 同一个 [IconShape] 的三种用法: 画布标签里的 [ShapeImage]、Widget 中的 [ShapeIcon]、只接受图片的 API 用 [ShapeImageProvider]。
class IconOutputsSection extends StatelessWidget {
  const IconOutputsSection({super.key});

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '图标: 一个图形三处用',
    caption:
        '画布: ShapeImage 按颜色缓存一张位图, 换色释放旧图; 上排放大 6 倍看三角圆角, 其次是行内实际尺寸(5x6)与四个方向, '
        '末行是业务侧继承 IconShape 只实现 paint 的六边形。'
        '底部同一批图形: 第一行 ShapeIcon 矢量绘制, 颜色取自 IconTheme; 第二行 ShapeImageProvider 供 Image 使用。',
    height: 210,
    create: _IconOutputsPainter.new,
    footer: (_) => const _WidgetIcons(),
  );
}

class _WidgetIcons extends StatelessWidget {
  const _WidgetIcons();

  static const _size = 24.0;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        IconTheme(
          data: IconThemeData(size: _size, color: color),
          child: Wrap(
            spacing: 12,
            children: [for (final (name, shape) in _shapes) ShapeIcon(shape, semanticLabel: name)],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            for (final (_, shape) in _shapes) Image(image: ShapeImageProvider(shape, const Size.square(_size), color)),
          ],
        ),
      ],
    );
  }
}

class _IconOutputsPainter extends SectionPainter {
  /// 行内尺寸下的圆角半径; 上排放大 6 倍, 半径同比放大。
  static const _radii = [0.0, 0.5, 1.0];

  late final _large = [for (final r in _radii) own(ShapeImage(TriangleShape(radius: r * 6), const Size(30, 36)))];
  late final _inline = [for (final r in _radii) own(ShapeImage(TriangleShape(radius: r), const Size(5, 6)))];

  static const _directions = [AxisDirection.up, AxisDirection.down, AxisDirection.left, AxisDirection.right];
  late final _arrows = [
    for (final d in _directions)
      own(
        ShapeImage(
          TriangleShape(direction: d),
          axisDirectionToAxis(d) == Axis.vertical ? const Size(6, 5) : const Size(5, 6),
        ),
      ),
  ];
  late final _hexagon = own(ShapeImage(const _HexagonShape(), const Size(8, 8)));

  late final _labels = [for (final _ in _radii) own(LabelPainter())];
  late final _arrowLabels = [for (final _ in _directions) own(LabelPainter())];
  late final _hexagonLabel = own(LabelPainter());
  late final _names = own(LabelPainter(capacity: _radii.length));

  final _imagePaint = Paint()..filterQuality = FilterQuality.medium;

  LabelStyle get _nameStyle =>
      byColors(#name, (c) => LabelStyle(text: TextStyle(fontSize: 10, color: c.onSurfaceVariant)));

  LabelStyle get _labelStyle => byColors(
    #label,
    (c) => LabelStyle(
      text: TextStyle(fontSize: 10, color: c.onPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: ShapeDecoration(
        color: c.primary,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2))),
      ),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final labelStyle = _labelStyle;
    final ink = labelStyle.text.color!;

    final step = size.width / _radii.length;
    for (final (i, radius) in _radii.indexed) {
      final center = Offset(step * (i + 0.5), 30);
      final large = _large[i];
      final image = large.of(colors.onSurface);
      canvas.drawImageRect(
        image,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        Rect.fromCenter(center: center, width: large.size.width, height: large.size.height),
        _imagePaint,
      );
      _names.paint(
        canvas,
        'radius $radius',
        style: _nameStyle,
        anchor: center.translate(0, 22),
        align: Alignment.topCenter,
      );
      _labels[i].paint(
        canvas,
        radius,
        build: () => TextSpan(
          children: [
            const TextSpan(text: '1234.56 '),
            _inline[i].span(ink),
          ],
        ),
        style: labelStyle,
        anchor: Offset(step * (i + 0.5), 100),
        align: Alignment.center,
      );
    }

    final arrowStep = size.width / _directions.length;
    for (final (i, direction) in _directions.indexed) {
      _arrowLabels[i].paint(
        canvas,
        direction,
        build: () => TextSpan(
          children: [
            TextSpan(text: '${direction.name} '),
            _arrows[i].span(ink),
          ],
        ),
        style: labelStyle,
        anchor: Offset(arrowStep * (i + 0.5), 140),
        align: Alignment.center,
      );
    }

    _hexagonLabel.paint(
      canvas,
      'hexagon',
      build: () => TextSpan(
        children: [
          _hexagon.span(ink),
          const TextSpan(text: ' custom IconShape'),
        ],
      ),
      style: labelStyle,
      anchor: Offset(size.width / 2, 185),
      align: Alignment.center,
    );
  }
}

/// 业务侧自定义图形的写法: 继承 [IconShape] 只实现 paint, 可复用 `Path.addRoundedPolygon` 与父类的 strokePaint;
/// 子类须为 final 或 base, 带参数时按参数覆写相等运算符与 hashCode。
final class _HexagonShape extends IconShape {
  const _HexagonShape();

  @override
  void paint(Canvas canvas, Size size, Color color) {
    final (w, h) = (size.width, size.height);
    final vertices = [
      Offset(w / 4, 0),
      Offset(w * 3 / 4, 0),
      Offset(w, h / 2),
      Offset(w * 3 / 4, h),
      Offset(w / 4, h),
      Offset(0, h / 2),
    ];
    canvas.drawPath(Path()..addRoundedPolygon(vertices, 0.5), Paint()..color = color);
  }
}
