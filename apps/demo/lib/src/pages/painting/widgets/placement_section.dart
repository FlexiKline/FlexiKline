import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../config/my_kline_config.dart';
import '../../../config/my_kline_indicator_config.dart';
import 'section.dart';

/// [LabelPainter] 的摆放: anchor + align 决定位置, bounds 把标签夹回可见区。
class PlacementSection extends StatelessWidget {
  const PlacementSection(this.configuration, this.indicatorConfig, {super.key});

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '摆放',
    caption: '配置来自 cross.ticksText; align 指标签哪个点对准 anchor(红十字); 右下角标签越过 bounds 后被夹回。',
    height: 200,
    create: () => _PlacementPainter(configuration, indicatorConfig),
  );
}

class _PlacementPainter extends SectionPainter {
  _PlacementPainter(super.configuration, super.indicatorConfig);

  /// 同一帧画 9 + 1 个标签, 容量不能小于同屏数量, 否则后画的会挤掉先画的。
  late final _labels = own(LabelPainter(capacity: 10));

  static const _alignments = {
    'topLeft': Alignment.topLeft,
    'topCenter': Alignment.topCenter,
    'topRight': Alignment.topRight,
    'centerLeft': Alignment.centerLeft,
    'center': Alignment.center,
    'centerRight': Alignment.centerRight,
    'bottomLeft': Alignment.bottomLeft,
    'bottomCenter': Alignment.bottomCenter,
    'bottomRight': Alignment.bottomRight,
  };

  @override
  void paint(Canvas canvas, Size size) {
    // 与 cross 刻度同一配置、同一主题兜底, 见 PaintYAxisTicksOnCrossMixin。
    final style = flexiKlineConfig.cross.ticksText.toLabelStyle(
      textColor: theme.crossTextColor,
      backgroundColor: theme.crossTextBg,
    );
    final cell = Size(size.width / 3, (size.height - 40) / 3);
    for (final (i, MapEntry(key: name, value: align)) in _alignments.entries.indexed) {
      final anchor = Offset(cell.width * (i % 3 + 0.5), cell.height * (i ~/ 3 + 0.5));
      // key 本身就是文本, 省掉 build。
      _labels.paint(canvas, name, style: style, anchor: anchor, align: align);
      paintAnchor(canvas, anchor);
    }

    final edge = Offset(size.width - 4, size.height - 10);
    _labels.paint(
      canvas,
      'clamped into bounds',
      style: style,
      anchor: edge,
      align: Alignment.topLeft,
      bounds: Offset.zero & size,
    );
    paintAnchor(canvas, edge);
  }
}
