import 'dart:ui' as ui;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../config/my_kline_config.dart';
import '../../../config/my_kline_indicator_config.dart';
import 'demo_image.dart';
import 'section.dart';

/// 最后价标签(最新蜡烛滚出视区时): 断开的虚线 + 价格 + 箭头。
///
/// 样式取自 [CandleIndicator.offViewPriceMark] 的配置(demo K 线页同一份), 箭头用 [ImageSpan] 代替字符 '▸'。
class LastPriceSection extends StatelessWidget {
  const LastPriceSection(this.configuration, this.indicatorConfig, {super.key});

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '最后价',
    caption: '配置来自 MyKlineIndicatorConfig 的 candle.offViewPriceMark; 虚线在标签处断开, 半透明背景下不透出线。',
    height: 120,
    create: () => _LastPricePainter(configuration, indicatorConfig),
  );
}

/// 一种样式: 名字、配置, 以及按主题与涨跌色解析出的标签样式。
typedef _LastStyle = ({
  String name,
  MarkConfig mark,
  LabelStyle Function(IFlexiKlineTheme theme, Color candle) resolve,
});

class _LastPricePainter extends SectionPainter {
  _LastPricePainter(super.configuration, super.indicatorConfig);

  late final _labels = [for (final _ in _styles) own(LabelPainter())];
  late final _names = own(LabelPainter(capacity: 3));

  /// 箭头与文字同色, 按颜色各生成一张。
  final Map<Color, ui.Image> _arrows = {};

  static const _price = '1234.56';
  static const _nameConfig = TextAreaConfig(style: TextStyle(fontSize: 10));

  late final _mark = indicatorConfig.candle.offViewPriceMark;

  // 每种样式各持一份配置实例: toLabelStyle 按实例单项记忆, 共用实例而颜色不同会每帧重算。
  late final _candle = _mark.copyWith(
    text: _mark.text.copyWith(borderRadius: const BorderRadius.all(Radius.circular(2))),
  );

  /// 默认边框是 BorderStyle.none, 描边要显式给宽度; 颜色留透明, 由 toLabelStyle 的 borderColor 兜底。
  late final _outline = _mark.copyWith(
    text: _mark.text.copyWith(border: const BorderSide(color: Colors.transparent)),
  );

  late final List<_LastStyle> _styles = [
    (
      name: '半透明(同 CandlePaintObject)',
      mark: _mark,
      resolve: (theme, _) =>
          _mark.text.toLabelStyle(textColor: theme.lastPriceColor, backgroundColor: theme.lastPriceBg),
    ),
    (
      name: '蜡烛色背景',
      mark: _candle,
      resolve: (_, candle) => _candle.text.toLabelStyle(textColor: Colors.white, backgroundColor: candle),
    ),
    (
      name: '描边',
      mark: _outline,
      resolve: (theme, _) => _outline.text.toLabelStyle(textColor: theme.textColor, borderColor: theme.markLineColor),
    ),
  ];

  @override
  void dispose() {
    for (final image in _arrows.values) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rowHeight = size.height / _styles.length;
    for (final (i, style) in _styles.indexed) {
      final y = rowHeight * (i + 0.5);
      final labelStyle = style.resolve(theme, theme.longColor);
      final arrow = _arrows.putIfAbsent(labelStyle.text.color!, () => arrowImage(labelStyle.text.color!));
      final label = _labels[i].paint(
        canvas,
        _price,
        build: () => TextSpan(
          children: [
            const TextSpan(text: '$_price '),
            ImageSpan(arrow, const Size(7, 7)),
          ],
        ),
        style: labelStyle,
        anchor: Offset(size.width * 0.7, y),
        align: Alignment.center,
      );

      final gap = style.mark.spacing;
      final line = Path()
        ..moveTo(0, y)
        ..lineTo(label.left - gap, y)
        ..moveTo(label.right + gap, y)
        ..lineTo(size.width, y);
      canvas.drawLineByConfig(line, style.mark.line, themeColor: theme.markLineColor);

      _names.paint(
        canvas,
        style.name,
        style: _nameConfig.toLabelStyle(textColor: theme.ticksTextColor),
        anchor: Offset(0, y - 2),
        align: Alignment.bottomLeft,
      );
    }
  }
}
