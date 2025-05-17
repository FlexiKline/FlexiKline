// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart' hide Overlay;

import '../constant.dart';
import '../extension/render/common.dart';
import '../extension/basic_type_ext.dart';
import '../framework/export.dart';
import '../indicators/export.dart';
import 'cross_config/cross_config.dart';
import 'magnifier_config/magnifier_config.dart';
import 'point_config/point_config.dart';
import 'draw_config/draw_config.dart';
import 'flexi_kline_config/flexi_kline_config.dart';
import 'gesture_config/gesture_config.dart';
import 'grid_config/grid_config.dart';
import 'line_config/line_config.dart';
import 'loading_config/loading_config.dart';
import 'mark_config/mark_config.dart';
import 'paint_config/paint_config.dart';
import 'setting_config/setting_config.dart';
import 'text_area_config/text_area_config.dart';
import 'tolerance_config/tolerance_config.dart';
import 'tooltip_config/tooltip_config.dart';

extension IFlexiKlineThemeExt on IFlexiKlineTheme {
  /// 默认时间指标高度
  double get timeIndicatorHeight {
    return defaultTimeIndicatorHeight * scale;
  }

  /// 默认副图指标高度
  double get subIndicatorHeight {
    return defaultSubIndicatorHeight * scale;
  }

  /// 默认主图指标高度
  double get mainIndicatorHeight {
    return defaultMainIndicatorHeight * scale;
  }

  /// 默认主图区域Padding
  EdgeInsets get mainIndicatorPadding => EdgeInsets.only(
        top: 5 * scale, // 顶部留白
        bottom: 5 * scale, // 底部留白, 5: 最低价字体高度的一半, 保证最低价文本不会绘制到边线上.
      );

  /// 默认副指标图Padding
  EdgeInsets get subIndicatorPadding => EdgeInsets.only(top: 12 * scale);

  /// 默认Tips文本区域的Padding: 左边缩进8个单位
  EdgeInsets get tipsPadding => EdgeInsets.only(left: 8 * scale);

  /// 默认文本区域Padding
  EdgeInsets get textPading => EdgeInsets.all(2 * scale);

  /// 默认指标线图的宽度
  double get indicatorLineWidth {
    return defaultIndicatorLineWidth * scale;
  }

  // 默认文本配置
  double get normalTextSize => setSp(defaulTextSize);
}

abstract class BaseFlexiKlineTheme implements IFlexiKlineTheme {
  const BaseFlexiKlineTheme({
    required this.long,
    required this.short,
    required this.dragBg,
    required this.chartBg,
    required this.tooltipBg,
    required this.crossTextBg,
    this.transparent = Colors.transparent,
    required this.latestPriceTextBg,
    required this.lastPriceTextBg,
    required this.countDownTextBg,
    required this.gridLine,
    required this.crossColor,
    required this.drawColor,
    required this.markLine,
    required this.themeColor,
    required this.textColor,
    required this.ticksTextColor,
    required this.lastPriceTextColor,
    required this.crossTextColor,
    required this.tooltipTextColor,
  });

  @override
  final Color long;
  @override
  final Color short;

  /// 背景色
  @override
  final Color dragBg;
  @override
  final Color chartBg;
  @override
  final Color tooltipBg;
  @override
  final Color crossTextBg;
  @override
  final Color transparent;
  @override
  final Color latestPriceTextBg;
  @override
  final Color lastPriceTextBg;
  @override
  final Color countDownTextBg;

  /// 分隔线
  @override
  final Color gridLine;
  @override
  final Color crossColor;
  @override
  final Color drawColor;
  @override
  final Color markLine;

  @override
  final Color themeColor;

  /// 文本颜色配置
  @override
  final Color textColor;
  @override
  final Color ticksTextColor;
  @override
  final Color lastPriceTextColor;
  @override
  final Color crossTextColor;
  @override
  final Color tooltipTextColor;
}

/// 通过[IFlexiKlineTheme]来配置FlexiKline基类.
mixin FlexiKlineThemeConfigurationMixin implements IConfiguration {
  /// 扩展[key]
  String getCacheKey(String key) => '$configKey-$key';

  @override
  FlexiKlineConfig generateFlexiKlineConfig([Map<String, dynamic>? origin]) {
    return FlexiKlineConfig(
      grid: genGridConfig(),
      setting: genSettingConfig(),
      gesture: genGestureConfig(),
      cross: genCrossConfig(),
      draw: genDrawConfig(),
      mainIndicator: genMainIndicator(),
      sub: {},
    );
  }

  @override
  IndicatorBuilder<CandleIndicator> get candleIndicatorBuilder {
    return (json) => genCandleIndicator(
          jsonToInstance(json, CandleIndicator.fromJson),
        );
  }

  @override
  IndicatorBuilder<TimeIndicator> get timeIndicatorBuilder {
    return (json) => genTimeIndicator(
          jsonToInstance(json, TimeIndicator.fromJson),
        );
  }

  @override
  @mustCallSuper
  Map<IIndicatorKey, IndicatorBuilder> get mainIndicatorBuilders => {};

  @override
  @mustCallSuper
  Map<IIndicatorKey, IndicatorBuilder> get subIndicatorBuilders => {};

  @override
  @mustCallSuper
  Map<IDrawType, DrawObjectBuilder> get drawObjectBuilders => {};

  /// Grid配置
  GridConfig genGridConfig() {
    return GridConfig(
      show: true,
      horizontal: GridAxis(
        show: true,
        count: 5,
        line: LineConfig(
          type: LineType.solid,
          dashes: const [2, 2],
          paint: PaintConfig(
            color: theme.gridLine,
            strokeWidth: theme.pixel,
          ),
        ),
      ),
      vertical: GridAxis(
        show: true,
        count: 5,
        line: LineConfig(
          type: LineType.solid,
          dashes: const [2, 2],
          paint: PaintConfig(
            color: theme.gridLine,
            strokeWidth: theme.pixel,
          ),
        ),
      ),
      isAllowDragIndicatorHeight: true,
      dragHitTestMinDistance: 10 * theme.scale,
      dragLine: LineConfig(
        type: LineType.dashed,
        dashes: const [3, 5],
        length: 20,
        paint: PaintConfig(
          color: theme.markLine,
          strokeWidth: theme.pixel * 5,
        ),
      ),
      dragLineOpacity: 0.1,
      // 全局默认的刻度值配置.
      ticksText: TextAreaConfig(
        style: TextStyle(
          fontSize: theme.normalTextSize,
          // color: theme.ticksTextColor,
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
        textAlign: TextAlign.end,
        padding: EdgeInsets.symmetric(horizontal: 2 * theme.scale),
      ),
    );
  }

  /// Gesture配置
  GestureConfig genGestureConfig() {
    return GestureConfig(
      isInertialPan: true,
      tolerance: ToleranceConfig(),
      loadMoreWhenNoEnoughDistance: null,
      loadMoreWhenNoEnoughCandles: 60,
      scalePosition: ScalePosition.auto,
      scaleSpeed: 10,
      zoomSpeed: 1,
    );
  }

  SettingConfig genSettingConfig() {
    return SettingConfig(
      pixel: theme.pixel,
      opacity: 0.5,

      /// 内置LoadingView样式配置
      loading: genInnerLoadingConfig(),

      /// 主区域最小Size
      mainMinSize: Size(120 * theme.scale, 80 * theme.scale),
      subMinHeight: 30 * theme.scale,
      useCandleTicksAsZoomSlideBar: true,

      /// 主/副图绘制参数
      minPaintBlankRate: 0.5,
      alwaysCalculateScreenOfCandlesIfEnough: false,
      candleMaxWidth: 40 * theme.scale,
      candleWidth: 7 * theme.scale,
      candleSpacingParts: 7,
      candleFixedSpacing: 1 * theme.scale,
      candleHollowBarBorderWidth: 1 * theme.scale,
      candleLineWidth: 1 * theme.scale,
      firstCandleInitOffset: 80 * theme.scale,

      /// 副区的指标图最大数量
      subChartMaxCount: defaultSubChartMaxCount,
    );
  }

  LoadingConfig genInnerLoadingConfig() {
    return LoadingConfig(
      size: 24 * theme.scale,
      strokeWidth: 4 * theme.scale,
      background: theme.tooltipBg,
      valueColor: theme.textColor,
    );
  }

  CrossConfig genCrossConfig() {
    return CrossConfig(
      enable: true,
      crosshair: LineConfig(
        paint: PaintConfig(
          // color: theme.crossColor,
          strokeWidth: 0.5 * theme.scale,
        ),
        type: LineType.dashed,
        dashes: const [3, 3],
      ),
      crosspoint: PointConfig(
        radius: 2 * theme.scale,
        width: 0 * theme.scale,
        // color: theme.crossColor,
        borderWidth: 2 * theme.scale,
        borderColor: theme.crossColor.withAlpha(0.5.alpha),
      ),
      ticksText: TextAreaConfig(
        style: TextStyle(
          // color: theme.crossTextColor,
          fontSize: theme.normalTextSize,
          fontWeight: FontWeight.normal,
          height: defaultTextHeight,
        ),
        // background: theme.crossTextBg,
        padding: EdgeInsets.all(2 * theme.scale),
        border: BorderSide.none,
        borderRadius: BorderRadius.all(
          Radius.circular(2 * theme.scale),
        ),
      ),
      spacing: 1 * theme.scale,
      // onCross时, 当移动到空白区域时, Tips区域是否展示最新的蜡烛的Tips数据.
      showLatestTipsInBlank: true,
      tooltipConfig: TooltipConfig(
        show: true,

        /// tooltip 区域设置
        margin: EdgeInsets.only(
          left: 15 * theme.scale,
          right: 65 * theme.scale,
          top: 10 * theme.scale,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 4 * theme.scale,
          vertical: 4 * theme.scale,
        ),
        radius: BorderRadius.all(Radius.circular(4 * theme.scale)),

        /// tooltip 文本设置
        style: TextStyle(
          fontSize: theme.normalTextSize,
          // color: theme.tooltipTextColor,
          overflow: TextOverflow.ellipsis,
          height: defaultMultiTextHeight,
        ),
      ),
    );
  }

  DrawConfig genDrawConfig() {
    return DrawConfig(
      enable: true,
      crosshair: LineConfig(
        paint: PaintConfig(
          strokeWidth: 0.5 * theme.scale,
          // color: theme.drawColor,
        ),
        type: LineType.dashed,
        dashes: const [5, 3],
      ),
      crosspoint: PointConfig(
        radius: 2 * theme.scale,
        width: 0 * theme.scale,
        // color: theme.drawColor,
        borderWidth: 2 * theme.scale,
        borderColor: theme.drawColor.withAlpha(0.5.alpha),
      ),
      drawLine: LineConfig(
        paint: PaintConfig(
          strokeWidth: 1 * theme.scale,
          color: theme.drawColor, // 必须指定
        ),
        type: LineType.solid,
        dashes: [5, 3],
      ),
      // 绘制[drawPoint]和[ticksText]刻度时, 是否始终使用[drawLine]指定的颜色.
      // useDrawLineColor: true,
      drawPoint: PointConfig(
        radius: 9 * theme.scale,
        width: 0 * theme.scale,
        color: const Color(0xFFFFFFFF), // 必须指定
        borderWidth: 1 * theme.scale,
        borderColor: theme.drawColor,
      ),
      ticksText: TextAreaConfig(
        style: TextStyle(
          color: const Color(0xFFFFFFFF), // 必须指定
          fontSize: theme.normalTextSize,
          fontWeight: FontWeight.normal,
          height: defaultTextHeight,
        ),
        // background: theme.drawTextBg, // 已废弃
        padding: EdgeInsets.all(2 * theme.scale),
        border: BorderSide.none,
        borderRadius: BorderRadius.all(
          Radius.circular(2 * theme.scale),
        ),
      ),
      spacing: 1 * theme.scale,
      ticksGapBgOpacity: 0.1,
      hitTestMinDistance: 10 * theme.scale,
      magnetMinDistance: 10 * theme.scale,
      magnifier: MagnifierConfig(
        enable: true,
        magnificationScale: 2,
        margin: EdgeInsets.all(1 * theme.scale),
        size: Size(80 * theme.scale, 80 * theme.scale),
        decorationOpactity: 1.0,
        decorationShadows: [
          BoxShadow(
            offset: const Offset(0.1, 0.1),
            blurRadius: 2,
            spreadRadius: 3,
            color: theme.themeColor.withAlpha(0.1.alpha), // 此处不适配Theme
          )
        ],
        shapeSide: BorderSide(
          // color: theme.gridLine,
          width: 1 * theme.scale,
        ),
      ),
    );
  }

  MainPaintObjectIndicator genMainIndicator();

  CandleIndicator genCandleIndicator(CandleIndicator? instance) {
    return CandleIndicator(
      zIndex: -1,
      height: theme.mainIndicatorHeight,
      padding: theme.mainIndicatorPadding,
      high: MarkConfig(
        spacing: 2 * theme.scale,
        line: LineConfig(
          type: LineType.solid,
          length: 20 * theme.scale,
          paint: PaintConfig(
            // color: theme.markLine,
            strokeWidth: 0.5 * theme.scale,
          ),
        ),
        text: TextAreaConfig(
          style: TextStyle(
            fontSize: theme.normalTextSize,
            // color: theme.textColor,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
        ),
      ),
      low: MarkConfig(
        spacing: 2 * theme.scale,
        line: LineConfig(
          type: LineType.solid,
          length: 20 * theme.scale,
          paint: PaintConfig(
            // color: theme.markLine,
            strokeWidth: 0.5 * theme.scale,
          ),
        ),
        text: TextAreaConfig(
          style: TextStyle(
            fontSize: theme.normalTextSize,
            // color: theme.textColor,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
        ),
      ),
      last: MarkConfig(
        show: true,
        spacing: 1 * theme.scale,
        line: LineConfig(
          type: LineType.dashed,
          dashes: [3, 3],
          paint: PaintConfig(
            // color: theme.markLine,
            strokeWidth: 0.5 * theme.scale,
          ),
        ),
        hitTestMargin: 4,
        text: TextAreaConfig(
          style: TextStyle(
            fontSize: theme.normalTextSize,
            // color: theme.lastPriceTextColor,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
            textBaseline: TextBaseline.alphabetic,
          ),
          // background: theme.lastPriceTextBg,
          padding: EdgeInsets.symmetric(
            horizontal: 4 * theme.scale,
            vertical: 2 * theme.scale,
          ),
          // border: BorderSide(color: theme.transparent),
          borderRadius: BorderRadius.all(Radius.circular(10 * theme.scale)),
        ),
      ),
      latest: MarkConfig(
        show: true,
        spacing: 1 * theme.scale,
        line: LineConfig(
          type: LineType.dashed,
          dashes: [3, 3],
          paint: PaintConfig(
            // color: theme.markLine,
            strokeWidth: 0.5 * theme.scale,
          ),
        ),
        text: TextAreaConfig(
          style: TextStyle(
            fontSize: theme.normalTextSize,
            color: Colors.white,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
          minWidth: 45 * theme.scale,
          textAlign: TextAlign.center,
          padding: theme.textPading,
          borderRadius: BorderRadius.all(Radius.circular(2 * theme.scale)),
        ),
      ),
      useCandleColorAsLatestBg: true,
      showCountDown: true,
      countDown: TextAreaConfig(
        style: TextStyle(
          fontSize: theme.normalTextSize,
          // color: theme.textColor,
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
        textAlign: TextAlign.center,
        // background: theme.countDownTextBg,
        padding: theme.textPading,
        borderRadius: BorderRadius.all(Radius.circular(2 * theme.scale)),
      ),
      longCandleUseHollow: instance?.longCandleUseHollow ?? false,
      shortCandleUseHollow: instance?.shortCandleUseHollow ?? false,
      longColor: instance?.longColor,
      shortColor: instance?.shortColor,
    );
  }

  TimeIndicator genTimeIndicator(TimeIndicator? instance) {
    return TimeIndicator(
      height: theme.timeIndicatorHeight,
      padding: EdgeInsets.zero,
      position: instance?.position ?? DrawPosition.middle,
      // 时间刻度.
      timeTick: TextAreaConfig(
        style: TextStyle(
          fontSize: theme.normalTextSize,
          // color: theme.ticksTextColor,
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
        textWidth: 80 * theme.scale,
        textAlign: TextAlign.center,
      ),
    );
  }
}
