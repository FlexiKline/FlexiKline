import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../config/my_kline_config.dart';
import '../../../config/my_kline_indicator_config.dart';
import 'demo_image.dart';
import 'section.dart';

/// [ImagePainter]: 摆放同 LabelPainter; 有 decoration 时按形状内轮廓裁切图片。
class ImageSection extends StatelessWidget {
  const ImageSection(this.configuration, this.indicatorConfig, {super.key});

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '图片',
    caption: '依次为: 无装饰不裁切、圆角裁切、气泡裁切(箭头区域不画图片)。',
    height: 90,
    create: () => _ImagePainter(configuration, indicatorConfig),
  );
}

class _ImagePainter extends SectionPainter {
  _ImagePainter(super.configuration, super.indicatorConfig);

  /// 每个 ImagePainter 只缓存一个装饰, 三种形状各用一个。
  late final _painters = [for (final _ in _styles) own(ImagePainter())];
  final _image = checkerImage();

  static const _side = BorderSide(color: Colors.black26);

  static final _styles = [
    const ImageStyle(size: Size(56, 56)),
    ImageStyle(
      size: const Size(56, 56),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(side: _side, borderRadius: BorderRadius.circular(12)),
      ),
    ),
    ImageStyle(
      size: const Size(56, 56),
      fit: BoxFit.cover,
      decoration: ShapeDecoration(
        color: Colors.black12,
        shape: BubbleBorder(side: _side, borderRadius: BorderRadius.circular(16), direction: AxisDirection.down),
      ),
    ),
  ];

  @override
  void dispose() {
    _image.dispose();
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / _styles.length;
    for (final (i, style) in _styles.indexed) {
      final anchor = Offset(step * (i + 0.5), size.height - 10);
      _painters[i].paint(canvas, _image, style: style, anchor: anchor, align: Alignment.bottomCenter);
      paintAnchor(canvas, anchor);
    }
  }
}
