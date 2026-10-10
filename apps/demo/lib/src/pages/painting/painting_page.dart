import 'package:flutter/material.dart';

import '../../config/my_kline_config.dart';
import '../../config/my_kline_indicator_config.dart';
import 'widgets/batch_section.dart';
import 'widgets/cache_section.dart';
import 'widgets/image_section.dart';
import 'widgets/last_price_section.dart';
import 'widgets/latest_price_section.dart';
import 'widgets/order_mark_section.dart';
import 'widgets/placement_section.dart';
import 'widgets/rich_text_section.dart';
import 'widgets/section.dart';
import 'widgets/shape_image_section.dart';
import 'widgets/shape_section.dart';
import 'widgets/tooltip_section.dart';

/// flexi_kline painting 层的用法示例, 迁移 render 扩展时对照。
///
/// 配置与 demo K 线页同源([MyKlineConfig]、[MyKlineIndicatorConfig]), 画面可与 K 线页互相对照;
/// 每节一个 [SectionPainter]: 像 PaintObject 一样用 own() 持有资源, 创建一次、退出时释放。
class PaintingPage extends StatefulWidget {
  const PaintingPage({super.key});

  @override
  State<PaintingPage> createState() => _PaintingPageState();
}

class _PaintingPageState extends State<PaintingPage> {
  final _configuration = MyKlineConfig();
  final _indicatorConfig = MyKlineIndicatorConfig();

  @override
  void dispose() {
    _indicatorConfig.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (c, i) = (_configuration, _indicatorConfig);
    return Scaffold(
      appBar: AppBar(title: const Text('Painting 示例')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          PlacementSection(c, i),
          CacheSection(c, i),
          RichTextSection(c, i),
          ShapeSection(c, i),
          ImageSection(c, i),
          ShapeImageSection(c, i),
          BatchSection(c, i),
          TooltipSection(c, i),
          LastPriceSection(c, i),
          LatestPriceSection(c, i),
          OrderMarkSection(c, i),
        ],
      ),
    );
  }
}
