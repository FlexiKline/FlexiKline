import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../../config/my_kline_config.dart';
import '../../../../config/my_kline_indicator_config.dart';
import '../section.dart';
import 'kline_section.dart';

/// 日期气泡(蜡烛日期标记): [BubbleConfig] 描述外观、所在侧与间距, 内容由使用方给出(这里是图标 + 日期)。
class DateBubbleSection extends StatelessWidget {
  const DateBubbleSection(this.configuration, this.indicatorConfig, {super.key});

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '日期气泡',
    caption:
        'BubbleConfig 转成 LabelStyle 后由 paintAround 摆放: 渐变背景与阴影、两端浅中间亮的渐变边框、圆角箭头, 围绕灰块四向摆放。'
        '胶囊形的左右两边没有直边放箭头, 左右两侧改用小圆角。',
    height: 170,
    create: () => _DateBubblePainter(configuration, indicatorConfig),
  );
}

class _DateBubblePainter extends KlineSectionPainter {
  _DateBubblePainter(super.configuration, super.indicatorConfig);

  /// 每个方向一个 painter: 各自持有排版与装饰缓存。
  late final _labels = {for (final side in AxisDirection.values) side: own(LabelPainter())};
  late final _icon = own(ShapeImage(const StarShape(), const Size(12, 12)));

  /// 上下: 胶囊形, 箭头在上下直边上; 边框从两端到中点渐变, mirror 镜像出右半段: 两端浅、中间亮。
  /// 背景渐变用 clamp, 让 body 之外的箭头取两端色, 默认的 decal 会让它透明。
  static const _vertical = BubbleConfig(
    text: TextAreaConfig(
      style: TextStyle(fontSize: 12, height: 1.2, color: Colors.white),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      borderRadius: BorderRadius.all(Radius.circular(16)),
      gradient: GradientConfig(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        tileMode: TileMode.clamp,
        colors: [Colors.indigo, Colors.pink],
      ),
      shadows: [BoxShadow(color: Colors.black38, blurRadius: 6, spreadRadius: 1, offset: Offset(0, 2))],
      border: BorderSide(color: Colors.white),
      borderGradient: GradientConfig(
        begin: Alignment.centerLeft,
        end: Alignment.center,
        tileMode: TileMode.mirror,
        startAlpha: 0.15,
        endAlpha: 1,
      ),
    ),
    arrowSize: Size(12, 6),
    arrowRadius: 2,
  );

  /// 左右: 圆角要给箭头留出竖直直边(气泡高约 24, 圆角 6 留下约 12)。
  static final _horizontal = _vertical.copyWith(
    text: _vertical.text.copyWith(borderRadius: const BorderRadius.all(Radius.circular(6))),
    arrowSize: const Size(10, 6),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final target = Rect.fromCenter(center: size.center(Offset.zero), width: 8, height: 40);
    canvas.drawRect(target, Paint()..color = Colors.grey);
    for (final side in AxisDirection.values) {
      final bubble = side == AxisDirection.up || side == AxisDirection.down ? _vertical : _horizontal;
      _labels[side]!.paintAround(
        canvas,
        side,
        build: () => TextSpan(
          children: [
            _icon.span(_vertical.text.style.color!),
            const TextSpan(text: ' 11-03 17:20'),
          ],
        ),
        styleOf: bubble.toLabelStyle,
        target: target,
        side: side,
        spacing: bubble.spacing,
        flip: bubble.flip,
        bounds: bounds,
      );
    }
  }
}
