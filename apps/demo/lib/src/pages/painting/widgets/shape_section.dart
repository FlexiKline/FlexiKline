import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../config/my_kline_config.dart';
import '../../../config/my_kline_indicator_config.dart';
import 'section.dart';

/// 标签形状: 配置能表达的圆角、边框、渐变、阴影走 TextAreaConfig; 气泡与自定义形状直接给 [LabelStyle]。
class ShapeSection extends StatelessWidget {
  const ShapeSection(this.configuration, this.indicatorConfig, {super.key});

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '形状',
    caption: '边框画在 body 内侧; AnchoredBorder 的外延(箭头)参与摆放与夹取, 尖端对准 anchor。',
    height: 150,
    create: () => _ShapePainter(configuration, indicatorConfig),
  );
}

class _ShapePainter extends SectionPainter {
  _ShapePainter(super.configuration, super.indicatorConfig);

  late final _bubbles = own(LabelPainter(capacity: 4));
  late final _rounded = own(LabelPainter());
  late final _tag = own(LabelPainter());
  late final _gradient = own(LabelPainter());

  static const _text = TextStyle(fontSize: 12, color: Colors.white);
  static const _padding = EdgeInsets.symmetric(horizontal: 6, vertical: 3);

  static const _bubbleAligns = {
    AxisDirection.down: Alignment.bottomCenter,
    AxisDirection.up: Alignment.topCenter,
    AxisDirection.right: Alignment.centerRight,
    AxisDirection.left: Alignment.centerLeft,
  };

  /// TextAreaConfig 只能表达圆角矩形, 气泡形状直接构造 LabelStyle; 建一次复用, 免得每帧深比较。
  static final _bubbleStyles = {
    for (final direction in _bubbleAligns.keys)
      direction: LabelStyle(
        text: _text,
        padding: _padding,
        decoration: ShapeDecoration(
          color: Colors.blueGrey,
          shape: BubbleBorder(
            side: const BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(4),
            direction: direction,
          ),
        ),
      ),
  };

  static const _tagStyle = LabelStyle(
    text: _text,
    padding: _padding,
    decoration: ShapeDecoration(color: Colors.teal, shape: _PriceTagBorder()),
  );

  /// 默认边框是 BorderStyle.none, 描边要显式给宽度; 颜色由 toLabelStyle 的 borderColor 兜底。
  static const _roundedConfig = TextAreaConfig(
    style: TextStyle(fontSize: 12),
    padding: _padding,
    border: BorderSide(color: Colors.transparent, width: 2),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  static const _gradientConfig = TextAreaConfig(
    style: _text,
    padding: _padding,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    gradient: GradientConfig(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.indigo, Colors.pink],
    ),
    shadows: [BoxShadow(color: Colors.black38, blurRadius: 6, spreadRadius: 1, offset: Offset(0, 2))],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 4;
    for (final (i, MapEntry(key: direction, value: align)) in _bubbleAligns.entries.indexed) {
      final anchor = Offset(step * (i + 0.5), 40);
      _bubbles.paint(canvas, direction.name, style: _bubbleStyles[direction]!, anchor: anchor, align: align);
      paintAnchor(canvas, anchor);
    }

    final y = size.height - 30;
    _rounded.paint(
      canvas,
      'rounded',
      style: _roundedConfig.toLabelStyle(textColor: theme.textColor, borderColor: theme.markLineColor),
      anchor: Offset(step * 0.5, y),
      align: Alignment.center,
    );

    final tagAnchor = Offset(step * 1.5, y);
    _tag.paint(canvas, '1234.5', style: _tagStyle, anchor: tagAnchor, align: Alignment.centerLeft);
    paintAnchor(canvas, tagAnchor);

    _gradient.paint(
      canvas,
      'gradient + shadow',
      style: _gradientConfig.toLabelStyle(),
      anchor: Offset(step * 3, y),
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
