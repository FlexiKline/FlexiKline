import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../../config/app_kline_config.dart';
import '../../../../config/app_kline_indicator_config.dart';
import '../section.dart';
import 'kline_section.dart';

/// 指标 tips: 一行多色, 每段的前缀、颜色与精度取自各自的 [TipsConfig]。
class IndicatorTipsSection extends StatelessWidget {
  const IndicatorTipsSection(this.configuration, this.indicatorConfig, {super.key});

  final AppKlineConfig configuration;
  final AppKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '指标 tips',
    caption: 'build 返回多段 TextSpan; key 用数值 List, 逐元素比较, 数值不变时不重新排版。',
    height: 24,
    create: () => _IndicatorTipsPainter(configuration, indicatorConfig),
  );
}

class _IndicatorTipsPainter extends KlineSectionPainter {
  _IndicatorTipsPainter(super.configuration, super.indicatorConfig);

  late final _tips = own(LabelPainter());

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
  }
}
