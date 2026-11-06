import 'package:flexi_kline/flexi_kline.dart';

import '../../../../config/my_kline_config.dart';
import '../../../../config/my_kline_indicator_config.dart';
import '../../../../theme/my_app_theme.dart';
import '../section.dart';

/// K 线场景的示例画笔: 样式取自 demo K 线页同一份配置, 颜色取 K 线主题, 切换明暗时重绘。
abstract class KlineSectionPainter extends SectionPainter {
  KlineSectionPainter(this.configuration, this.indicatorConfig) : super(repaint: myAppThemeMode);

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;

  /// 同框架 controller: 取一次后持有。
  late final FlexiKlineConfig flexiKlineConfig = configuration.getFlexiKlineConfig();

  /// 随明暗模式变化, 每帧现取。
  IFlexiKlineTheme get theme => configuration.theme;
}
