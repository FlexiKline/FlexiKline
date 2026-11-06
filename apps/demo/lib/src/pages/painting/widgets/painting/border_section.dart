import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/material.dart';

import '../section.dart';

/// 画布上的异形边框: 标签的 decoration 换成不同 ShapeBorder; [AnchoredBorder] 的外延(箭头、尖角)参与摆放与夹取。
class BorderSection extends StatelessWidget {
  const BorderSection({super.key});

  @override
  Widget build(BuildContext context) => const PaintingSection(
    title: '边框(画布)',
    caption:
        '上: BubbleBorder 四个方向, 箭头尖端对准红十字。'
        '下: 描边圆角矩形、页内实现 AnchoredBorder 的价格标签、渐变填充加阴影、GradientRoundedRectangleBorder 渐变描边; 边框画在 body 内侧。',
    height: 150,
    create: _BorderPainter.new,
  );
}

class _BorderPainter extends SectionPainter {
  late final _bubbles = own(LabelPainter(capacity: 4));
  late final _rounded = own(LabelPainter());
  late final _tag = own(LabelPainter());
  late final _gradient = own(LabelPainter());
  late final _gradientBorder = own(LabelPainter());

  static const _padding = EdgeInsets.symmetric(horizontal: 6, vertical: 3);
  static const _radius = BorderRadius.all(Radius.circular(4));
  static const _gradientColors = [Colors.indigo, Colors.pink];

  static const _bubbleAligns = {
    AxisDirection.down: Alignment.bottomCenter,
    AxisDirection.up: Alignment.topCenter,
    AxisDirection.right: Alignment.centerRight,
    AxisDirection.left: Alignment.centerLeft,
  };

  TextStyle _text(ColorScheme c) => TextStyle(fontSize: 12, color: c.onPrimary);

  LabelStyle _bubble(AxisDirection direction) => byColors(
    direction,
    (c) => LabelStyle(
      text: _text(c),
      padding: _padding,
      decoration: ShapeDecoration(
        color: c.primary,
        shape: BubbleBorder(
          side: BorderSide(color: c.onPrimary),
          borderRadius: _radius,
          direction: direction,
        ),
      ),
    ),
  );

  LabelStyle get _roundedStyle => byColors(
    #rounded,
    (c) => LabelStyle(
      text: TextStyle(fontSize: 12, color: c.onSurface),
      padding: _padding,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: c.outline, width: 2),
          borderRadius: _radius,
        ),
      ),
    ),
  );

  LabelStyle get _tagStyle => byColors(
    #tag,
    (c) => LabelStyle(
      text: _text(c),
      padding: _padding,
      decoration: ShapeDecoration(color: c.tertiary, shape: const _PriceTagBorder()),
    ),
  );

  /// 渐变与阴影不随配色变化, 建一次复用。
  static const _gradientStyle = LabelStyle(
    text: TextStyle(fontSize: 12, color: Colors.white),
    padding: _padding,
    decoration: ShapeDecoration(
      gradient: LinearGradient(colors: _gradientColors),
      shadows: [BoxShadow(color: Colors.black38, blurRadius: 6, spreadRadius: 1, offset: Offset(0, 2))],
      shape: RoundedRectangleBorder(borderRadius: _radius),
    ),
  );

  LabelStyle get _gradientBorderStyle => byColors(
    #gradientBorder,
    (c) => LabelStyle(
      text: TextStyle(fontSize: 12, color: c.onSurface),
      padding: _padding,
      decoration: const ShapeDecoration(
        shape: GradientRoundedRectangleBorder(
          side: BorderSide(width: 2),
          borderRadius: _radius,
          gradient: LinearGradient(colors: _gradientColors),
        ),
      ),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 4;
    for (final (i, MapEntry(key: direction, value: align)) in _bubbleAligns.entries.indexed) {
      final anchor = Offset(step * (i + 0.5), 40);
      _bubbles.paint(canvas, direction.name, style: _bubble(direction), anchor: anchor, align: align);
      paintAnchor(canvas, anchor);
    }

    final y = size.height - 30;
    _rounded.paint(canvas, 'rounded', style: _roundedStyle, anchor: Offset(step * 0.5, y), align: Alignment.center);

    final tagAnchor = Offset(step * 1.5 - 20, y);
    _tag.paint(canvas, '1234.5', style: _tagStyle, anchor: tagAnchor, align: Alignment.centerLeft);
    paintAnchor(canvas, tagAnchor);

    _gradient.paint(canvas, 'gradient', style: _gradientStyle, anchor: Offset(step * 2.5, y), align: Alignment.center);
    _gradientBorder.paint(
      canvas,
      'border',
      style: _gradientBorderStyle,
      anchor: Offset(step * 3.5, y),
      align: Alignment.center,
    );
  }
}

/// 左侧带尖角的价格标签: 尖角是 body 之外的外延, 由 [outsets] 报给摆放逻辑。
///
/// 路径必须相对 rect 计算, 阴影平移 rect 时尖角才会跟着走。
class _PriceTagBorder extends AnchoredBorder {
  const _PriceTagBorder({this.tip = 6, this.anchorY});

  final double tip;

  /// 尖端相对 body 顶边的纵向位置; null 时居中。
  final double? anchorY;

  @override
  EdgeInsets get outsets => EdgeInsets.only(left: tip);

  @override
  _PriceTagBorder anchorTo(Offset anchor) => _PriceTagBorder(tip: tip, anchorY: anchor.dy);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    // body 被夹取平移后锚点可能落在边外, 尖端夹回 body 的纵向范围内。
    final y = rect.top + (anchorY ?? rect.height / 2).clamp(0, rect.height);
    return Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left - tip, y)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => _PriceTagBorder(tip: tip * t, anchorY: anchorY == null ? null : anchorY! * t);
}
