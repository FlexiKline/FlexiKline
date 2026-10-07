import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart';
import 'package:flutter/material.dart';

import 'my_kline_storage.dart';
import 'my_kline_theme.dart';

/// FlexiKline 框架配置：组合框架 mixin、绘制工具 builder 与内存存储。
class MyKlineConfig with MyKlineStorageMixin, FlexiKlineConfigurationMixin, DrawObjectBuildersConfigMixin {
  MyKlineConfig();

  @override
  IFlexiKlineTheme get theme => myKlineTheme;

  @override
  String cacheKey(String key) => 'my_kline_config_v1-$key';

  @override
  CrossConfig genCrossConfig([CrossConfig? cross]) {
    cross = super.genCrossConfig(cross);
    return cross.copyWith(
      moveByCandleInBlank: true,
      crosspoint: cross.crosspoint.copyWith(borderWidth: null, borderColor: null),
      tooltipConfig: cross.tooltipConfig.copyWith(
        radius: BorderRadius.circular(8),
        hitTestMargin: 10,
      ),
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
  MainPaintObjectIndicator genMainIndicator(
    MainPaintObjectIndicator<Indicator>? mainIndicator,
  ) {
    return MainPaintObjectIndicator(
      size: mainIndicator?.size ?? const Size(375, 300),
      padding: mainIndicator?.padding ?? defaultMainIndicatorPadding,
      drawBelowTipsArea: mainIndicator?.drawBelowTipsArea ?? true,
      children: mainIndicator?.children,
    );
  }
}
