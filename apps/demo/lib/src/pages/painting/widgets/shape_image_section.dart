import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../config/my_kline_config.dart';
import '../../../config/my_kline_indicator_config.dart';
import 'section.dart';

/// 程序绘制的小图标: [TriangleImage] 的圆角对比、内置图形一览, 以及业务侧继承 [ShapeImage] 的自定义图形。
class ShapeImageSection extends StatelessWidget {
  const ShapeImageSection(this.configuration, this.indicatorConfig, {super.key});

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: 'ShapeImage',
    caption:
        '按颜色缓存一张位图, 换色释放旧图。上排放大 6 倍看三角圆角; 其次是行内实际尺寸(5x6, 最后价箭头用默认 radius 0.5)与四个方向;'
        '最下面两排是其余内置图形, 以及业务侧继承 ShapeImage 只实现 draw 的自定义图形。',
    height: 270,
    create: () => _ShapeImagePainter(configuration, indicatorConfig),
  );
}

class _ShapeImagePainter extends SectionPainter {
  _ShapeImagePainter(super.configuration, super.indicatorConfig);

  /// 行内尺寸下的圆角半径; 上排放大 6 倍, 半径同比放大。
  static const _radii = [0.0, 0.5, 1.0];

  late final _large = [for (final r in _radii) own(TriangleImage(const Size(30, 36), radius: r * 6))];
  late final _inline = [for (final r in _radii) own(TriangleImage(const Size(5, 6), radius: r))];

  static const _directions = [AxisDirection.up, AxisDirection.down, AxisDirection.left, AxisDirection.right];
  late final _arrows = [
    for (final d in _directions)
      own(TriangleImage(axisDirectionToAxis(d) == Axis.vertical ? const Size(6, 5) : const Size(5, 6), direction: d)),
  ];
  late final _arrowLabels = [for (final _ in _directions) own(LabelPainter())];

  static const _iconSize = Size(8, 8);
  late final _icons = [
    ('CircleImage', own(CircleImage(_iconSize))),
    ('DiamondImage', own(DiamondImage(_iconSize))),
    ('PlusImage', own(PlusImage(_iconSize))),
    ('MinusImage', own(MinusImage(_iconSize))),
    ('ChevronImage', own(ChevronImage(_iconSize))),
    ('CrossImage', own(CrossImage(_iconSize))),
    ('StarImage', own(StarImage(_iconSize))),
    ('BellImage', own(BellImage(_iconSize))),
    ('SquareImage', own(SquareImage(_iconSize, radius: 1.5))),
    ('_HexagonImage', own(_HexagonImage(_iconSize))),
  ];

  late final _labels = [for (final _ in _radii) own(LabelPainter())];
  late final _iconLabels = [for (final _ in _icons) own(LabelPainter())];
  late final _names = own(LabelPainter(capacity: _radii.length + _icons.length));

  static const _labelConfig = TextAreaConfig(
    style: TextStyle(fontSize: 10),
    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    borderRadius: BorderRadius.all(Radius.circular(2)),
  );
  static const _nameConfig = TextAreaConfig(style: TextStyle(fontSize: 10));

  final _imagePaint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final nameStyle = _nameConfig.toLabelStyle(textColor: theme.ticksTextColor);
    final labelStyle = _labelConfig.toLabelStyle(textColor: theme.lastPriceColor, backgroundColor: theme.lastPriceBg);

    final step = size.width / _radii.length;
    for (final (i, radius) in _radii.indexed) {
      final center = Offset(step * (i + 0.5), 30);
      final large = _large[i];
      final image = large.of(theme.textColor);
      canvas.drawImageRect(
        image,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        Rect.fromCenter(center: center, width: large.size.width, height: large.size.height),
        _imagePaint,
      );
      _names.paint(
        canvas,
        'radius $radius',
        style: nameStyle,
        anchor: center.translate(0, 22),
        align: Alignment.topCenter,
      );

      _labels[i].paint(
        canvas,
        radius,
        build: () => TextSpan(
          children: [
            const TextSpan(text: '1234.56 '),
            _inline[i].span(labelStyle.text.color!),
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
            _arrows[i].span(labelStyle.text.color!),
          ],
        ),
        style: labelStyle,
        anchor: Offset(arrowStep * (i + 0.5), 140),
        align: Alignment.center,
      );
    }

    // 每行 5 个, 名字在图标下方。
    const columns = 5;
    final iconStep = size.width / columns;
    for (final (i, (name, image)) in _icons.indexed) {
      final anchor = Offset(iconStep * (i % columns + 0.5), 185.0 + i ~/ columns * 48);
      _iconLabels[i].paint(
        canvas,
        name,
        build: () => TextSpan(
          children: [
            image.span(theme.longColor),
            const TextSpan(text: ' Buy'),
          ],
        ),
        style: labelStyle,
        anchor: anchor,
        align: Alignment.center,
      );
      _names.paint(
        canvas,
        name,
        style: nameStyle,
        anchor: anchor.translate(0, 14),
        align: Alignment.topCenter,
      );
    }
  }
}

/// 业务侧自定义图形的写法: 继承 [ShapeImage] 只实现 draw, 可复用父类的 roundedPolygon / strokePaint;
/// 子类须为 final 或 base。
final class _HexagonImage extends ShapeImage {
  _HexagonImage(super.size);

  @override
  void draw(Canvas canvas, Size size, Color color) {
    final (w, h) = (size.width, size.height);
    final vertices = [
      Offset(w / 4, 0),
      Offset(w * 3 / 4, 0),
      Offset(w, h / 2),
      Offset(w * 3 / 4, h),
      Offset(w / 4, h),
      Offset(0, h / 2),
    ];
    canvas.drawPath(roundedPolygon(vertices, 0.5), Paint()..color = color);
  }
}
