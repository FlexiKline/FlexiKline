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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../constant.dart';
import '../extension/render/common.dart';
import '../framework/export.dart';
import '../indicators/export.dart';
import 'boll_param/boll_param.dart';
import 'cross_config/cross_config.dart';
import 'flexi_kline_config/flexi_kline_config.dart';
import 'grid_config/grid_config.dart';
import 'indicators_config/indicators_config.dart';
import 'kdj_param/kdj_param.dart';
import 'line_config/line_config.dart';
import 'loading_config/loading_config.dart';
import 'ma_param/ma_param.dart';
import 'macd_param/macd_param.dart';
import 'mark_config/mark_config.dart';
import 'setting_config/setting_config.dart';
import 'text_area_config/text_area_config.dart';
import 'tips_config/tips_config.dart';
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

  /// 默认副图指标高度
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
  BaseFlexiKlineTheme({
    required this.long,
    required this.short,
    required this.chartBg,
    required this.tooltipBg,
    required this.countDownTextBg,
    required this.crossTextBg,
    this.transparent = Colors.transparent,
    required this.lastPriceTextBg,
    required this.gridLine,
    required this.crosshair,
    required this.priceMarkLine,
    required this.textColor,
    required this.tickTextColor,
    required this.lastPriceTextColor,
    required this.crossTextColor,
    required this.tooltipTextColor,
  });

  BaseFlexiKlineTheme.simple({
    required this.long,
    required this.short,
    required this.chartBg,
    required Color markBg,
    required this.crossTextBg,
    this.transparent = Colors.transparent,
    required this.lastPriceTextBg,
    required Color color,
    required this.gridLine,
    required this.tickTextColor,
    required this.crossTextColor,
  })  : tooltipBg = markBg,
        countDownTextBg = markBg,
        crosshair = color,
        priceMarkLine = color,
        textColor = color,
        lastPriceTextColor = color,
        tooltipTextColor = color;

  @override
  late Color long;
  @override
  late Color short;

  /// 背景色
  @override
  late Color chartBg;
  @override
  late Color tooltipBg;
  @override
  late Color countDownTextBg;
  @override
  late Color crossTextBg;
  @override
  late Color transparent;
  @override
  late Color lastPriceTextBg;

  /// 分隔线
  @override
  late Color gridLine;
  @override
  late Color crosshair;
  @override
  late Color priceMarkLine;

  /// 文本颜色配置
  @override
  late Color textColor;
  @override
  late Color tickTextColor;
  @override
  late Color lastPriceTextColor;
  @override
  late Color crossTextColor;
  @override
  late Color tooltipTextColor;
}

/// 通过[IFlexiKlineTheme]来配置FlexiKline基类.
abstract class BaseFlexiKlineThemeConfiguration implements IConfiguration {
  @override
  FlexiKlineConfig getFlexiKlineConfig([covariant IFlexiKlineTheme? theme]);

  FlexiKlineConfig genFlexiKlineConfig(covariant IFlexiKlineTheme theme) {
    return FlexiKlineConfig(
      key: theme.key,
      grid: genGridConfig(theme),
      setting: genSettingConfig(theme),
      cross: genCrossConfig(theme),
      tooltip: genTooltipConfig(theme),
      indicators: genIndicatorsConfig(theme),
      main: {},
      sub: {},
    );
  }

  GridConfig genGridConfig(
    covariant IFlexiKlineTheme theme, {
    bool show = true,
    GridAxis? horizontal,
    GridAxis? vertical,

    /// 如果配置了[horizontal]与[vertical], 以下无需配置
    bool horizontalShow = true,
    bool verticalShow = true,
    int horizontalCount = 5,
    int verticalCount = 5,
    double? lineWidth,
    Color? lineColor,
    LineType lineType = LineType.solid,
    List<double> lineDashes = const [2, 2],
  }) {
    return GridConfig(
      show: show,
      horizontal: horizontal ??
          GridAxis(
            show: horizontalShow,
            count: horizontalCount,
            width: lineWidth ?? theme.pixel,
            color: lineColor ?? theme.gridLine,
            type: lineType,
            dashes: lineDashes,
          ),
      vertical: vertical ??
          GridAxis(
            show: verticalShow,
            count: verticalCount,
            width: lineWidth ?? theme.pixel,
            color: lineColor ?? theme.gridLine,
            type: lineType,
            dashes: lineDashes,
          ),
    );
  }

  SettingConfig genSettingConfig(
    covariant IFlexiKlineTheme theme, {
    Color? textColor,
    Color? longColor,
    Color? shortColor,
    double opacity = 0.5,

    /// 内置LoadingView样式配置
    LoadingConfig? loadingConfig,

    /// 主/副图区域大小配置
    Size? mainMinSize,
    EdgeInsets? mainPadding,
    bool mainDrawBelowTipsArea = true,

    /// 主/副图绘制参数
    double minPaintBlankRate = 0.5,
    bool alwaysCalculateScreenOfCandlesIfEnough = false,
    double? candleMaxWidth,
    double? candleWidth,
    double? candleSpacing,
    double? candleLineWidth,
    double? firstCandleInitOffset,

    /// 全局默认的刻度值配置.
    TextAreaConfig? tickText,

    /// 副区的指标图最大数量
    int subChartMaxCount = defaultSubChartMaxCount,

    /// 手势平移限制参数
    ToleranceConfig? panTolerance,
  }) {
    return SettingConfig(
      textColor: textColor ?? theme.textColor,
      longColor: longColor ?? theme.long,
      shortColor: shortColor ?? theme.short,
      opacity: opacity,

      /// 内置LoadingView样式配置
      loading: loadingConfig ?? genInnerLoadingConfig(theme),

      /// 主/副图区域大小配置
      // mainRect: Rect.zero,
      mainMinSize: mainMinSize ?? Size.square(20 * theme.scale),
      mainPadding: mainPadding ?? theme.mainIndicatorPadding,
      mainDrawBelowTipsArea: mainDrawBelowTipsArea,

      /// 主/副图绘制参数
      minPaintBlankRate: minPaintBlankRate,
      alwaysCalculateScreenOfCandlesIfEnough:
          alwaysCalculateScreenOfCandlesIfEnough,
      candleMaxWidth: candleMaxWidth ?? 40 * theme.scale,
      candleWidth: candleWidth ?? 7 * theme.scale,
      candleSpacing: candleSpacing ?? 1 * theme.scale,
      candleLineWidth: candleLineWidth ?? 1 * theme.scale,
      firstCandleInitOffset: firstCandleInitOffset ?? 80 * theme.scale,

      /// 全局默认的刻度值配置.
      tickText: tickText ??
          TextAreaConfig(
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: theme.tickTextColor,
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight,
            ),
            textAlign: TextAlign.end,
            padding: EdgeInsets.symmetric(horizontal: 2 * theme.scale),
          ),

      /// 副区的指标图最大数量
      subChartMaxCount: subChartMaxCount,

      /// 手势平移限制参数
      panTolerance: panTolerance,
    );
  }

  LoadingConfig genInnerLoadingConfig(
    covariant IFlexiKlineTheme theme, {
    double? size,
    double? strokeWidth,
    Color? background,
    Color? valueColor,
  }) {
    return LoadingConfig(
      size: size ?? 24 * theme.scale,
      strokeWidth: strokeWidth ?? 4 * theme.scale,
      background: background ?? theme.tooltipBg,
      valueColor: valueColor ?? theme.textColor,
    );
  }

  CrossConfig genCrossConfig(
    covariant IFlexiKlineTheme theme, {
    bool enable = true,
    LineConfig? crosshair,
    CrossPointConfig? point,
    TextAreaConfig? tickText,
    double? spacing,

    /// onCross时, 当移动到空白区域时, Tips区域是否展示最新的蜡烛的Tips数据.
    bool showLatestTipsInBlank = true,

    /// 如果配置了[tickText], 以下无需配置
    TextStyle? tickTextStyle,
    Color? tickTextBackground,
    EdgeInsets? tickTextPadding,
    BorderSide? tickTextBorder,
    BorderRadius? tickTextRadius,
  }) {
    return CrossConfig(
      enable: enable,
      crosshair: crosshair ??
          LineConfig(
            width: 0.5 * theme.scale,
            color: theme.crosshair,
            type: LineType.dashed,
            dashes: const [3, 3],
          ),
      point: point ??
          CrossPointConfig(
            radius: 2 * theme.scale,
            width: 6 * theme.scale,
            color: theme.crosshair,
          ),
      tickText: tickText ??
          TextAreaConfig(
            style: tickTextStyle ??
                TextStyle(
                  color: theme.crossTextColor,
                  fontSize: theme.normalTextSize,
                  fontWeight: FontWeight.normal,
                  height: defaultTextHeight,
                ),
            background: tickTextBackground ?? theme.crossTextBg,
            padding: tickTextPadding ?? EdgeInsets.all(2 * theme.scale),
            border: tickTextBorder ?? BorderSide.none,
            borderRadius: tickTextRadius ??
                BorderRadius.all(
                  Radius.circular(2 * theme.scale),
                ),
          ),
      spacing: spacing ?? 1 * theme.scale,
      showLatestTipsInBlank: showLatestTipsInBlank,
    );
  }

  TooltipConfig genTooltipConfig(
    covariant IFlexiKlineTheme theme, {
    bool show = true,
    Color? background,
    EdgeInsets? margin,
    EdgeInsets? padding,
    BorderRadius? radius,
    TextStyle? style,
  }) {
    return TooltipConfig(
      show: show,

      /// tooltip 区域设置
      background: background ?? theme.tooltipBg,
      margin: margin ??
          EdgeInsets.only(
            left: 15 * theme.scale,
            right: 65 * theme.scale,
            top: 10 * theme.scale,
          ),
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: 4 * theme.scale,
            vertical: 4 * theme.scale,
          ),
      radius: radius ?? BorderRadius.all(Radius.circular(4 * theme.scale)),

      /// tooltip 文本设置
      style: style ??
          TextStyle(
            fontSize: theme.normalTextSize,
            color: theme.tooltipTextColor,
            overflow: TextOverflow.ellipsis,
            height: defaultMultiTextHeight,
          ),
    );
  }

  IndicatorsConfig genIndicatorsConfig(IFlexiKlineTheme theme) {
    return IndicatorsConfig(
      candle: genCandleIndicator(theme),
      volume: genMainVolumeIndicator(theme),
      ma: genMaIndicator(theme),
      ema: genEmaIndicator(theme),
      boll: genBollIndicator(theme),
      time: genTimeIndicator(theme),
      macd: genMacdIndicator(theme),
      kdj: genKdjIndicator(theme),
      mavol: genMavolIndicator(theme),
    );
  }

  CandleIndicator genCandleIndicator(
    covariant IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    MarkConfig? high,
    MarkConfig? low,
    MarkConfig? last,
    MarkConfig? latest,
    bool useCandleColorAsLatestBg = true,
    bool showCountDown = true,
    TextAreaConfig? countDown,
  }) {
    return CandleIndicator(
      height: height ?? theme.mainIndicatorHeight,
      padding: padding ?? theme.mainIndicatorPadding,
      high: high ??
          MarkConfig(
            spacing: 2 * theme.scale,
            line: LineConfig(
              type: LineType.solid,
              color: theme.priceMarkLine,
              length: 20 * theme.scale,
              width: 0.5 * theme.scale,
            ),
            text: TextAreaConfig(
              style: TextStyle(
                fontSize: theme.normalTextSize,
                color: theme.textColor,
                overflow: TextOverflow.ellipsis,
                height: defaultTextHeight,
              ),
            ),
          ),
      low: low ??
          MarkConfig(
            spacing: 2 * theme.scale,
            line: LineConfig(
              type: LineType.solid,
              color: theme.priceMarkLine,
              length: 20 * theme.scale,
              width: 0.5 * theme.scale,
            ),
            text: TextAreaConfig(
              style: TextStyle(
                fontSize: theme.normalTextSize,
                color: theme.textColor,
                overflow: TextOverflow.ellipsis,
                height: defaultTextHeight,
              ),
            ),
          ),
      last: last ??
          MarkConfig(
            show: true,
            spacing: 100 * theme.scale,
            line: LineConfig(
              type: LineType.dashed,
              color: theme.priceMarkLine,
              width: 0.5 * theme.scale,
              dashes: [3, 3],
            ),
            text: TextAreaConfig(
              style: TextStyle(
                fontSize: theme.normalTextSize,
                color: theme.lastPriceTextColor,
                overflow: TextOverflow.ellipsis,
                height: defaultTextHeight,
                textBaseline: TextBaseline.alphabetic,
              ),
              background: theme.lastPriceTextBg,
              padding: EdgeInsets.symmetric(
                horizontal: 4 * theme.scale,
                vertical: 2 * theme.scale,
              ),
              border: BorderSide(color: theme.transparent),
              borderRadius: BorderRadius.all(Radius.circular(10 * theme.scale)),
            ),
          ),
      latest: latest ??
          MarkConfig(
            show: true,
            spacing: 1 * theme.scale,
            line: LineConfig(
              type: LineType.dashed,
              color: theme.priceMarkLine,
              width: 0.5 * theme.scale,
              dashes: [3, 3],
            ),
            text: TextAreaConfig(
              style: TextStyle(
                fontSize: theme.normalTextSize,
                color: Colors.white,
                overflow: TextOverflow.ellipsis,
                height: defaultTextHeight,
              ),
              minWidth: 45,
              textAlign: TextAlign.center,
              padding: theme.textPading,
              borderRadius: BorderRadius.all(Radius.circular(2 * theme.scale)),
            ),
          ),
      useCandleColorAsLatestBg: useCandleColorAsLatestBg,
      showCountDown: showCountDown,
      countDown: countDown ??
          TextAreaConfig(
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: theme.textColor,
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight,
            ),
            textAlign: TextAlign.center,
            background: theme.countDownTextBg,
            padding: theme.textPading,
            borderRadius: BorderRadius.all(Radius.circular(2 * theme.scale)),
          ),
    );
  }

  VolumeIndicator genMainVolumeIndicator(
    covariant IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    PaintMode paintMode = PaintMode.alone,
    TipsConfig? volTips,
    EdgeInsets? tipsPadding,
    int tickCount = defaultSubTickCount,
    int precision = 2,
  }) {
    return VolumeIndicator(
      height: height ?? theme.subIndicatorHeight,
      padding: padding ?? theme.subIndicatorPadding,
      paintMode: paintMode,

      /// 绘制相关参数
      volTips: volTips ??
          TipsConfig(
            label: 'Vol: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: theme.textColor,
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight,
            ),
          ),
      tipsPadding: tipsPadding ?? theme.tipsPadding,
      tickCount: tickCount,
      precision: precision,

      /// 控制参数
      showYAxisTick: false,
      showCrossMark: false,
      showTips: false,
      useTint: true,
    );
  }

  MAIndicator genMaIndicator(
    covariant IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    List<MaParam>? calcParams,
    EdgeInsets? tipsPadding,
    double? lineWidth,
  }) {
    return MAIndicator(
      height: height ?? theme.mainIndicatorHeight,
      padding: padding ?? theme.mainIndicatorPadding,
      calcParams: calcParams ??
          [
            MaParam(
              count: 7,
              tips: TipsConfig(
                label: 'MA7: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.normalTextSize,
                  color: const Color(0xFF946F9A),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight,
                ),
              ),
            ),
            MaParam(
              count: 30,
              tips: TipsConfig(
                label: 'MA30: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.normalTextSize,
                  color: const Color(0xFFF1BF32),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight,
                ),
              ),
            ),
          ],
      tipsPadding: tipsPadding ?? theme.tipsPadding,
      lineWidth: lineWidth ?? theme.indicatorLineWidth,
    );
  }

  EMAIndicator genEmaIndicator(
    covariant IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    List<MaParam>? calcParams,
    EdgeInsets? tipsPadding,
    double? lineWidth,
  }) {
    return EMAIndicator(
      height: height ?? theme.mainIndicatorHeight,
      padding: padding ?? theme.mainIndicatorPadding,
      calcParams: calcParams ??
          [
            MaParam(
              count: 5,
              tips: TipsConfig(
                label: 'EMA5: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.normalTextSize,
                  color: const Color(0xFF806180),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight,
                ),
              ),
            ),
            MaParam(
              count: 10,
              tips: TipsConfig(
                label: 'EMA10: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.normalTextSize,
                  color: const Color(0xFFEBB736),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight,
                ),
              ),
            ),
            MaParam(
              count: 20,
              tips: TipsConfig(
                label: 'EMA20: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.normalTextSize,
                  color: const Color(0xFFD672D5),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight,
                ),
              ),
            ),
            MaParam(
              count: 60,
              tips: TipsConfig(
                label: 'EMA60: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.normalTextSize,
                  color: const Color.fromARGB(255, 44, 45, 47),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight,
                ),
              ),
            ),
          ],
      tipsPadding: tipsPadding ?? theme.tipsPadding,
      lineWidth: lineWidth ?? theme.indicatorLineWidth,
    );
  }

  BOLLIndicator genBollIndicator(
    covariant IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    BOLLParam? calcParam,
    TipsConfig? mbTips,
    TipsConfig? upTips,
    TipsConfig? dnTips,
    EdgeInsets? tipsPadding,
    int tickCount = defaultSubTickCount,
    double? lineWidth,
    bool isFillBetweenUpAndDn = true,
    Color? fillColor,
  }) {
    return BOLLIndicator(
      height: height ?? theme.mainIndicatorHeight,
      padding: padding ?? theme.mainIndicatorPadding,

      /// BOLL计算参数
      calcParam: calcParam ?? const BOLLParam(n: 20, std: 2),

      /// 绘制相关参数
      mbTips: mbTips ??
          TipsConfig(
            label: 'BOLL(20): ',
            // precision: 2,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: const Color(0xFF886787),
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight,
            ),
          ),
      upTips: upTips ??
          TipsConfig(
            label: 'UB: ',
            // precision: 2,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: const Color(0xFFF0B527),
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight,
            ),
          ),
      dnTips: dnTips ??
          TipsConfig(
            label: 'LB: ',
            // precision: 2,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: const Color(0xFFD85BE0),
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight,
            ),
          ),
      tipsPadding: tipsPadding ?? theme.tipsPadding,
      lineWidth: lineWidth ?? theme.indicatorLineWidth,

      /// 填充配置
      isFillBetweenUpAndDn: isFillBetweenUpAndDn,
      fillColor: fillColor,
    );
  }

  TimeIndicator genTimeIndicator(
    covariant IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    DrawPosition? position,
    TextAreaConfig? tmeiTick,
  }) {
    return TimeIndicator(
      height: height ?? theme.timeIndicatorHeight,
      padding: padding ?? EdgeInsets.zero,
      position: position ?? DrawPosition.middle,
      // 时间刻度.
      timeTick: tmeiTick ??
          TextAreaConfig(
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: theme.tickTextColor,
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight,
            ),
            textWidth: 80 * theme.scale,
            textAlign: TextAlign.center,
          ),
    );
  }

  MACDIndicator genMacdIndicator(
    covariant IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    MACDParam? calcParam,
    TipsConfig? difTips,
    TipsConfig? deaTips,
    TipsConfig? macdTips,
    EdgeInsets? tipsPadding,
    int tickCount = defaultSubTickCount,
    double? lineWidth,
    int precision = 2,
  }) {
    return MACDIndicator(
      height: height ?? theme.subIndicatorHeight,
      padding: padding ?? theme.subIndicatorPadding,

      /// Macd相关参数
      calcParam: calcParam ?? const MACDParam(s: 12, l: 26, m: 9),

      /// 绘制相关参数
      difTips: difTips ??
          TipsConfig(
            label: 'DIF: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: const Color(0xFFDFBF47),
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight,
            ),
          ),
      deaTips: deaTips ??
          TipsConfig(
            label: 'DEA: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: const Color(0xFF795583),
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight,
            ),
          ),
      macdTips: macdTips ??
          TipsConfig(
            label: 'MACD: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: theme.textColor,
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight,
            ),
          ),
      tipsPadding: tipsPadding ?? theme.tipsPadding,
      tickCount: tickCount,
      lineWidth: lineWidth ?? theme.indicatorLineWidth,
      precision: precision,
    );
  }

  KDJIndicator genKdjIndicator(
    covariant IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    KDJParam? calcParam,
    TipsConfig? ktips,
    TipsConfig? dtips,
    TipsConfig? jtips,
    EdgeInsets? tipsPadding,
    int tickCount = defaultSubTickCount,
    double? lineWidth,
    int precision = 2,
  }) {
    return KDJIndicator(
      height: height ?? theme.subIndicatorHeight,
      padding: padding ?? theme.subIndicatorPadding,

      /// KDJ计算参数
      calcParam: calcParam ?? const KDJParam(n: 9, m1: 3, m2: 3),

      /// 绘制相关参数
      ktips: ktips ??
          TipsConfig(
            label: 'K: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: const Color(0xFF7A5C79),
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight,
            ),
          ),
      dtips: dtips ??
          TipsConfig(
            label: 'D: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: const Color(0xFFFABD3F),
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight,
            ),
          ),
      jtips: jtips ??
          TipsConfig(
            label: 'D: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: const Color(0xFFBB72CA),
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight,
            ),
          ),
      tipsPadding: tipsPadding ?? theme.tipsPadding,
      tickCount: tickCount,
      lineWidth: lineWidth ?? theme.indicatorLineWidth,
      precision: precision,
    );
  }

  MAVolumeIndicator genMavolIndicator(
    covariant IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    bool drawBelowTipsArea = false,
  }) {
    return MAVolumeIndicator(
      height: height ?? theme.subIndicatorHeight,
      padding: padding ?? theme.subIndicatorPadding,
      drawBelowTipsArea: drawBelowTipsArea,
      volumeIndicator: genSubVolumeIndicator(
        theme,
        height: height,
        padding: padding,
      ),
      volMaIndicator: genVolMaIndicator(
        theme,
        height: height,
        padding: padding,
      ),
    );
  }

  VolumeIndicator genSubVolumeIndicator(
    covariant IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    PaintMode paintMode = PaintMode.combine,
    TipsConfig? volTips,
    EdgeInsets? tipsPadding,
    int tickCount = defaultSubTickCount,
    int precision = 2,
  }) {
    return VolumeIndicator(
      height: height ?? theme.subIndicatorHeight,
      padding: padding ?? theme.subIndicatorPadding,
      paintMode: paintMode,

      /// 绘制相关参数
      volTips: volTips ??
          TipsConfig(
            label: 'Vol: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: theme.textColor,
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight,
            ),
          ),
      tipsPadding: tipsPadding ?? theme.tipsPadding,
      tickCount: tickCount,
      precision: precision,

      /// 控制参数
      showYAxisTick: true,
      showCrossMark: true,
      showTips: true,
      useTint: false,
    );
  }

  VolMaIndicator genVolMaIndicator(
    covariant IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    List<MaParam>? calcParams,
    EdgeInsets? tipsPadding,
    double? lineWidth,
    int precision = 2,
  }) {
    return VolMaIndicator(
      height: height ?? theme.subIndicatorHeight,
      padding: padding ?? theme.subIndicatorPadding,
      calcParams: calcParams ??
          [
            MaParam(
              count: 5,
              tips: TipsConfig(
                label: 'MA5: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.normalTextSize,
                  color: Colors.orange,
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight,
                ),
              ),
            ),
            MaParam(
              count: 10,
              tips: TipsConfig(
                label: 'MA10: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.normalTextSize,
                  color: Colors.blue,
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight,
                ),
              ),
            ),
          ],
      tipsPadding: tipsPadding ?? theme.tipsPadding,
      lineWidth: lineWidth ?? theme.indicatorLineWidth,
      precision: precision,
    );
  }
}
