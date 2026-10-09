import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../config/my_kline_config.dart';
import '../../../config/my_kline_indicator_config.dart';
import 'section.dart';

/// [LabelPainter] 的缓存与宽度约束: key 不变时 build 不调用; minWidth 稳住宽度, maxWidth 触发省略。
class CacheSection extends StatelessWidget {
  const CacheSection(this.configuration, this.indicatorConfig, {super.key});

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '缓存与宽度',
    caption: '「重绘」只触发 paint, key 未变不格式化; 「换值」换 key 才调 build。',
    height: 70,
    create: () => _CachePainter(configuration, indicatorConfig),
    footer: (painter) => Row(
      children: [
        TextButton(onPressed: painter.markNeedsPaint, child: const Text('重绘')),
        TextButton(onPressed: painter.next, child: const Text('换值')),
      ],
    ),
  );
}

class _CachePainter extends SectionPainter {
  _CachePainter(super.configuration, super.indicatorConfig);

  late final _price = own(LabelPainter());
  late final _clipped = own(LabelPainter());
  late final _counter = own(LabelPainter());

  double _value = 1234.5;
  int _builds = 0;

  void next() {
    _value += 0.5;
    markNeedsPaint();
  }

  static const _padding = EdgeInsets.symmetric(horizontal: 6, vertical: 3);
  static const _radius = BorderRadius.all(Radius.circular(3));

  /// minWidth: 价格位数变化时标签宽度不跳。
  static const _priceConfig = TextAreaConfig(
    style: TextStyle(fontSize: 13),
    textAlign: TextAlign.end,
    minWidth: 80,
    padding: _padding,
    borderRadius: _radius,
  );

  /// 默认样式带 TextOverflow.ellipsis, 配 maxWidth 后超宽时末尾显示省略号。
  static const _clippedConfig = TextAreaConfig(
    style: TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis),
    maxLines: 1,
    maxWidth: 120,
    padding: _padding,
    borderRadius: _radius,
  );

  static const _counterConfig = TextAreaConfig(style: TextStyle(fontSize: 11));

  @override
  void paint(Canvas canvas, Size size) {
    final value = _value;
    _price.paint(
      canvas,
      value,
      build: () {
        _builds++;
        return value.toStringAsFixed(1);
      },
      style: _priceConfig.toLabelStyle(textColor: Colors.white, backgroundColor: theme.longColor),
      anchor: Offset(0, size.height / 2),
      align: Alignment.centerLeft,
    );
    _clipped.paint(
      canvas,
      'a long label limited by maxWidth',
      style: _clippedConfig.toLabelStyle(textColor: Colors.white, backgroundColor: theme.longColor),
      anchor: Offset(size.width, size.height / 2),
      align: Alignment.centerRight,
    );
    // 计数在 paint 期才变, 画在画布上才能与本帧一致。
    final builds = _builds;
    _counter.paint(
      canvas,
      builds,
      build: () => 'build 调用 $builds 次',
      style: _counterConfig.toLabelStyle(textColor: theme.ticksTextColor),
      anchor: Offset.zero,
    );
  }
}
