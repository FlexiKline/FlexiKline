import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_kline_storage.dart';
import 'app_kline_theme.dart';

/// FlexiKline 框架配置：组合框架 mixin、绘制工具 builder 与内存存储。
class AppKlineConfig with AppKlineStorageMixin, FlexiKlineConfigurationMixin, DrawObjectBuildersConfigMixin {
  AppKlineConfig();

  @override
  IFlexiKlineTheme get theme => appKlineTheme;

  @override
  String cacheKey(String key) => 'my_kline_config_v1-$key';

  @override
  CrossConfig genCrossConfig([CrossConfig? cross]) {
    cross = super.genCrossConfig(cross);
    return cross.copyWith(
      moveByCandleInBlank: true,
      crosspoint: cross.crosspoint.copyWith(borderWidth: null, borderColor: null),
      tooltipConfig: styleTooltip(cross.tooltipConfig.copyWith(hitTestMargin: 10)),
    );
  }

  /// 十字线 Tooltip 的卡片样式, 按当前明暗模式取色; 切换主题后须重新套用。
  ///
  /// 画布内没有背景模糊: 面色取半透明的 surfaceContainerHighest 叠在图表底色上的实色, 避免透出蜡烛;
  /// 再加上沿亮、两侧淡的高光描边与投影, 呈现浮起的玻璃面板。
  static TooltipConfig styleTooltip(TooltipConfig config) {
    final theme = appKlineTheme;
    final scheme = AppTheme.schemeOf(theme.brightness);
    final edge = scheme.outlineVariant;
    return config.copyWith(
      backgroundColor: Color.alphaBlend(
        scheme.surfaceContainerHighest.withValues(alpha: 0.58),
        theme.chartBg.withValues(alpha: 0.68),
      ),
      border: BorderSide(color: edge, width: 0.5),
      borderRadius: BorderRadius.circular(8),
      // 高光用不随主题变的白光。
      borderGradient: GradientConfig(
        colors: [
          edge.withValues(alpha: 0.85),
          edge.withValues(alpha: 0),
          edge.withValues(alpha: 0),
          edge.withValues(alpha: 0.65),
        ],
        stops: const [0, 0.35, 0.65, 1],
      ),
      shadows: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: theme.brightness == Brightness.dark ? 0.5 : 0.12),
          offset: const Offset(0, 4),
          blurRadius: 16,
        ),
      ],
    );
  }

  @override
  GridConfig genGridConfig([GridConfig? grid]) {
    return super.genGridConfig(grid).copyWith(isAllowDragIndicatorHeight: true);
  }

  @override
  DrawConfig genDrawConfig([DrawConfig? draw]) {
    draw = super.genDrawConfig(draw);
    return draw.copyWith(
      enable: true,
      crosspoint: draw.crosspoint.copyWith(borderWidth: null, borderColor: null),
    );
  }

  @override
  GestureConfig genGestureConfig([GestureConfig? gesture]) {
    return super.genGestureConfig(gesture).copyWith(enableZoom: true);
  }

  @override
  SettingConfig genSettingConfig([SettingConfig? setting]) {
    final config = super.genSettingConfig(setting);
    return config.copyWith(
      candleFixedSpacing: null,
      candleSpacingParts: 7,
      minPaintBlankRate: 0.9,
    );
  }

  @override
  MainPaintObjectIndicator genMainIndicator([MainPaintObjectIndicator<Indicator>? mainIndicator]) {
    return MainPaintObjectIndicator(
      size: mainIndicator?.size ?? const Size(375, 300),
      padding: mainIndicator?.padding ?? defaultMainIndicatorPadding,
      drawBelowTipsArea: mainIndicator?.drawBelowTipsArea ?? true,
      children: mainIndicator?.children,
    );
  }
}
