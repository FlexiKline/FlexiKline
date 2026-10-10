import 'dart:math' as math;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../config/my_kline_config.dart';
import '../../../config/my_kline_indicator_config.dart';
import 'section.dart';

/// 历史订单标记: 用 [LabelPainter] + ShapeBorder 画成标签而非图片, 字母保持矢量、跟随主题字体。
///
/// 四种外形 x 四种标记(B 涨色 / S 跌色 / W / L), 每格一个 painter, 跨帧复用排版。
class OrderMarkSection extends StatelessWidget {
  const OrderMarkSection(this.configuration, this.indicatorConfig, {super.key});

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '订单标记',
    caption: '带尖角的形状尖端对准红十字; 圆形 + 尖角是页内实现 AnchoredBorder 的示例(BubbleBorder 的箭头只能长在直边上)。',
    height: 170,
    create: () => _OrderMarkPainter(configuration, indicatorConfig),
  );
}

class _OrderMarkPainter extends SectionPainter {
  _OrderMarkPainter(super.configuration, super.indicatorConfig);

  static const _letters = ['B', 'S', 'W', 'L'];

  /// 圆形容器取正方形(文字最小宽度 = 行高), 矩形左右多留 1 让字母不贴边。
  static const _circlePadding = EdgeInsets.all(3);
  static const _rectPadding = EdgeInsets.symmetric(horizontal: 4, vertical: 3);
  static const _radius = BorderRadius.all(Radius.circular(3));

  /// 四种外形; 矩形 + 尖角的直边(约 18 - 2 x 3)要放得下箭头根宽 6。
  static const _shapes = [
    (
      name: '圆形',
      border: CircleBorder(),
      padding: _circlePadding,
    ),
    (
      name: '圆形 + 尖角',
      border: _PinBorder(),
      padding: _circlePadding,
    ),
    (
      name: '圆角矩形',
      border: RoundedRectangleBorder(borderRadius: _radius),
      padding: _rectPadding,
    ),
    (
      name: '圆角矩形 + 尖角',
      border: BubbleBorder(borderRadius: _radius, arrowSize: Size(6, 4)),
      padding: _rectPadding,
    ),
  ];

  late final _cells = [
    for (final _ in _shapes) [for (final _ in _letters) own(LabelPainter())],
  ];
  late final _names = own(LabelPainter(capacity: _shapes.length));

  static const _text = TextStyle(fontSize: 10, height: 1, color: Colors.white, fontWeight: FontWeight.bold);
  static const _nameConfig = TextAreaConfig(style: TextStyle(fontSize: 10));

  /// 样式按 (外形, 颜色) 缓存一份: 每帧新建 ShapeDecoration 会让 DecorationPainter 重建 BoxPainter。
  final _styles = <(int, Color), LabelStyle>{};

  LabelStyle _style(int shape, Color color) => _styles.putIfAbsent(
    (shape, color),
    () => LabelStyle(
      text: _text,
      textAlign: TextAlign.center,
      minWidth: 10,
      padding: _shapes[shape].padding,
      decoration: ShapeDecoration(color: color, shape: _shapes[shape].border),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    // 主题未定义 W / L 色, 这里写死示意。
    final colors = [theme.longColor, theme.shortColor, Colors.orange, Colors.blueGrey];
    final nameStyle = _nameConfig.toLabelStyle(textColor: theme.ticksTextColor);
    const nameWidth = 96.0;
    final step = (size.width - nameWidth) / _letters.length;
    final rowHeight = size.height / _shapes.length;

    for (final (row, shape) in _shapes.indexed) {
      final centerY = rowHeight * (row + 0.5);
      _names.paint(
        canvas,
        shape.name,
        style: nameStyle,
        anchor: Offset(8, centerY),
        align: Alignment.centerLeft,
      );

      // 带尖角的形状以尖端定位, 尖端放在行中线下方, 标记整体仍大致居中。
      final pointed = shape.border is AnchoredBorder;
      for (final (col, letter) in _letters.indexed) {
        final x = nameWidth + step * (col + 0.5);
        final anchor = Offset(x, pointed ? centerY + 10 : centerY);
        _cells[row][col].paint(
          canvas,
          letter,
          style: _style(row, colors[col]),
          anchor: anchor,
          align: pointed ? Alignment.bottomCenter : Alignment.center,
        );
        if (pointed) paintAnchor(canvas, anchor);
      }
    }
  }
}

/// 圆形 + 向下的尖角(定位针): 两条切线从尖端切到圆上, 路径一次成型。
///
/// 尖端固定在圆心正下方, 不随锚点滑动, 只画填充、不支持描边。
final class _PinBorder extends AnchoredBorder {
  const _PinBorder();

  /// 尖端伸出圆底的长度。
  static const _tip = 4.0;

  @override
  EdgeInsets get outsets => const EdgeInsets.only(bottom: _tip);

  @override
  ShapeBorder anchorTo(Offset anchor) => this;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final center = rect.center;
    final r = rect.shortestSide / 2;
    // 切点与圆心连线同尖端方向的夹角 θ 满足 cos θ = r / (r + _tip)。
    final cos = r / (r + _tip);
    final sin = math.sqrt(1 - cos * cos);
    return Path()
      ..moveTo(center.dx - sin * r, center.dy + cos * r)
      ..arcToPoint(Offset(center.dx + sin * r, center.dy + cos * r), radius: Radius.circular(r), largeArc: true)
      ..lineTo(center.dx, center.dy + r + _tip)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
