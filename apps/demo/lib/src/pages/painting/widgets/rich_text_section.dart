import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../config/my_kline_config.dart';
import '../../../config/my_kline_indicator_config.dart';
import 'demo_image.dart';
import 'section.dart';

/// 富文本标签: build 返回 InlineSpan; 指标 tips 每段的颜色取自各自的 [TipsConfig]。
class RichTextSection extends StatelessWidget {
  const RichTextSection(this.configuration, this.indicatorConfig, {super.key});

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '富文本',
    caption: '一行多色(指标 tips): key 用 List, 逐元素比较; ImageSpan 把图片排进文字行内。',
    height: 60,
    create: () => _RichTextPainter(configuration, indicatorConfig),
  );
}

class _RichTextPainter extends SectionPainter {
  _RichTextPainter(super.configuration, super.indicatorConfig);

  late final _tips = own(LabelPainter());
  late final _order = own(LabelPainter());
  final _dot = dotImage(Colors.white);

  static const _tipsConfig = [
    TipsConfig(
      label: 'MA7: ',
      style: TextStyle(fontSize: defaultTextSize, color: Colors.orange),
    ),
    TipsConfig(
      label: 'MA30: ',
      style: TextStyle(fontSize: defaultTextSize, color: Colors.purple),
    ),
    TipsConfig(
      label: 'MA60: ',
      style: TextStyle(fontSize: defaultTextSize, color: Colors.blue),
    ),
  ];

  static const _orderConfig = TextAreaConfig(
    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    borderRadius: BorderRadius.all(Radius.circular(2)),
  );

  @override
  void dispose() {
    _dot.dispose();
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    const values = [101.25, 98.6, 95.12];
    _tips.paint(
      canvas,
      values,
      build: () => TextSpan(
        children: [
          for (final (i, tips) in _tipsConfig.indexed)
            TextSpan(text: '${tips.label}${values[i].toStringAsFixed(tips.getP(2))}  ', style: tips.style),
        ],
      ),
      style: const TextAreaConfig().toLabelStyle(textColor: theme.textColor),
      anchor: Offset.zero,
    );

    _order.paint(
      canvas,
      ('buy', 0.5),
      build: () => TextSpan(
        children: [
          ImageSpan(_dot, const Size(8, 8)),
          const TextSpan(text: ' Buy 0.5 BTC'),
        ],
      ),
      style: _orderConfig.toLabelStyle(textColor: Colors.white, backgroundColor: theme.longColor),
      anchor: Offset(0, size.height),
      align: Alignment.bottomLeft,
    );
  }
}
