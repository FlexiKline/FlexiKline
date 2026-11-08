import 'package:flutter/material.dart';

import '../../config/app_kline_config.dart';
import '../../config/app_kline_indicator_config.dart';
import '../../widgets/theme_toggle_button.dart';
import 'widgets/kline/crosshair_section.dart';
import 'widgets/kline/date_bubble_section.dart';
import 'widgets/kline/indicator_tips_section.dart';
import 'widgets/kline/last_price_section.dart';
import 'widgets/kline/latest_price_section.dart';
import 'widgets/kline/order_mark_section.dart';
import 'widgets/painting/batch_section.dart';
import 'widgets/painting/border_section.dart';
import 'widgets/painting/icon_outputs_section.dart';
import 'widgets/painting/icon_shapes_section.dart';
import 'widgets/painting/image_section.dart';
import 'widgets/painting/label_cache_section.dart';
import 'widgets/painting/placement_section.dart';
import 'widgets/painting/rich_text_section.dart';
import 'widgets/painting/tooltip_section.dart';
import 'widgets/painting/widget_border_section.dart';

/// 绘制示例, 分两个标签页: flexi_painting 的能力, 以及这些能力在 K 线绘制中的用法。
///
/// 「flexi_painting」页只依赖 flexi_painting, 按库的分层排列, 每项能力一节;
/// 「K 线场景」页的样式取自 demo K 线页同一份配置([AppKlineConfig]、[AppKlineIndicatorConfig]), 每节对应一个图表元素。
/// 新增示例: 在对应目录加一个 section 文件, 并登记到下面的列表。
class PaintingPage extends StatefulWidget {
  const PaintingPage({super.key});

  @override
  State<PaintingPage> createState() => _PaintingPageState();
}

class _PaintingPageState extends State<PaintingPage> {
  final _configuration = AppKlineConfig();
  final _indicatorConfig = AppKlineIndicatorConfig();

  @override
  void dispose() {
    _indicatorConfig.dispose();
    super.dispose();
  }

  static const _paintingSections = [
    PlacementSection(),
    LabelCacheSection(),
    RichTextSection(),
    BorderSection(),
    WidgetBorderSection(),
    ImageSection(),
    BatchSection(),
    TooltipSection(),
    IconShapesSection(),
    IconOutputsSection(),
  ];

  @override
  Widget build(BuildContext context) {
    final (c, i) = (_configuration, _indicatorConfig);
    final klineSections = [
      CrosshairSection(c, i),
      IndicatorTipsSection(c, i),
      DateBubbleSection(c, i),
      LastPriceSection(c, i),
      LatestPriceSection(c, i),
      OrderMarkSection(c, i),
    ];
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painting 示例'),
          actions: const [ThemeToggleButton()],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'flexi_painting'),
              Tab(text: 'K 线场景'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(padding: const EdgeInsets.all(12), children: _paintingSections),
            ListView(padding: const EdgeInsets.all(12), children: klineSections),
          ],
        ),
      ),
    );
  }
}
