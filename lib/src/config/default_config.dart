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

import 'package:flutter/material.dart';

import '../constant.dart' as constant;
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
import 'tooltip_config/tooltip_config.dart';

extension IFlexiKlineThemeExt on IFlexiKlineTheme {
  /// 默认时间指标高度
  double get defaultTimeIndicatorHeight {
    return constant.defaultTimeIndicatorHeight * scale;
  }

  /// 默认副图指标高度
  double get defaultSubIndicatorHeight {
    return constant.defaultSubIndicatorHeight * scale;
  }

  /// 默认副图指标高度
  double get defaultMainIndicatorHeight {
    return constant.defaultMainIndicatorHeight * scale;
  }

  /// 默认主图区域Padding
  EdgeInsets get defaultMainIndicatorPadding => EdgeInsets.only(
        top: 5 * scale, // 顶部留白
        bottom: 5 * scale, // 底部留白, 5: 最低价字体高度的一半, 保证最低价文本不会绘制到边线上.
      );

  /// 默认副指标图Padding
  EdgeInsets get defaultSubIndicatorPadding => EdgeInsets.only(top: 12 * scale);

  /// 默认Tips文本区域的Padding: 左边缩进8个单位
  EdgeInsets get defaultTipsPadding => EdgeInsets.only(left: 8 * scale);

  /// 默认文本区域Padding
  EdgeInsets get defaultTextPading => EdgeInsets.all(2 * scale);

  /// 默认指标线图的宽度
  double get defaultIndicatorLineWidth {
    return constant.defaultIndicatorLineWidth * scale;
  }

  // 默认文本高度
  double get defaultTextHeight => constant.defaultTextHeight;

// 默认文本高度多行模式
  double get defaultMultiTextHeight => constant.defaultMultiTextHeight;

// 默认Tips文本高度
  double get defaultTipsTextHeight => constant.defaultTipsTextHeight;

  // 默认文本配置
  double get defaulTextSize => setSp(constant.defaulTextSize);
}

/// 通过[IFlexiKlineTheme]来配置FlexiKline基类.
abstract class BaseFlexiKlineThemeConfiguration implements IConfiguration {
  FlexiKlineConfig genFlexiKlineConfig(IFlexiKlineTheme theme) {
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
    IFlexiKlineTheme theme, {
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
    IFlexiKlineTheme theme, {
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
    int subChartMaxCount = constant.defaultSubChartMaxCount,
  }) {
    return SettingConfig(
      textColor: textColor ?? theme.textColor,
      longColor: longColor ?? theme.long,
      shortColor: shortColor ?? theme.short,
      opacity: opacity,

      /// 内置LoadingView样式配置
      loading: loadingConfig ??
          LoadingConfig(
            size: 24,
            strokeWidth: 4,
            background: theme.tooltipBg,
            valueColor: theme.textColor,
          ),

      /// 主/副图区域大小配置
      // mainRect: Rect.zero,
      mainMinSize: mainMinSize ?? Size.square(20 * theme.scale),
      mainPadding: mainPadding ?? theme.defaultMainIndicatorPadding,
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
              fontSize: theme.defaulTextSize,
              color: theme.tickTextColor,
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTextHeight,
            ),
            textAlign: TextAlign.end,
            padding: EdgeInsets.symmetric(horizontal: 2 * theme.scale),
          ),

      /// 副区的指标图最大数量
      subChartMaxCount: subChartMaxCount,
    );
  }

  CrossConfig genCrossConfig(
    IFlexiKlineTheme theme, {
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
                  fontSize: theme.defaulTextSize,
                  fontWeight: FontWeight.normal,
                  height: theme.defaultTextHeight,
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
    IFlexiKlineTheme theme, {
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
            top: 4 * theme.scale,
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
            fontSize: theme.defaulTextSize,
            color: theme.tooltipTextColor,
            overflow: TextOverflow.ellipsis,
            height: theme.defaultMultiTextHeight,
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
    IFlexiKlineTheme theme, {
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
      height: height ?? theme.defaultMainIndicatorHeight,
      padding: padding ?? theme.defaultMainIndicatorPadding,
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
                fontSize: theme.defaulTextSize,
                color: theme.textColor,
                overflow: TextOverflow.ellipsis,
                height: theme.defaultTextHeight,
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
                fontSize: theme.defaulTextSize,
                color: theme.textColor,
                overflow: TextOverflow.ellipsis,
                height: theme.defaultTextHeight,
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
                fontSize: theme.defaulTextSize,
                color: theme.lastPriceTextColor,
                overflow: TextOverflow.ellipsis,
                height: theme.defaultTextHeight,
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
                fontSize: theme.defaulTextSize,
                color: Colors.white,
                overflow: TextOverflow.ellipsis,
                height: theme.defaultTextHeight,
              ),
              minWidth: 45,
              textAlign: TextAlign.center,
              padding: theme.defaultTextPading,
              borderRadius: BorderRadius.all(Radius.circular(2 * theme.scale)),
            ),
          ),
      useCandleColorAsLatestBg: useCandleColorAsLatestBg,
      showCountDown: showCountDown,
      countDown: countDown ??
          TextAreaConfig(
            style: TextStyle(
              fontSize: theme.defaulTextSize,
              color: theme.textColor,
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTextHeight,
            ),
            textAlign: TextAlign.center,
            background: theme.countDownTextBg,
            padding: theme.defaultTextPading,
            borderRadius: BorderRadius.all(Radius.circular(2 * theme.scale)),
          ),
    );
  }

  VolumeIndicator genMainVolumeIndicator(
    IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    PaintMode paintMode = PaintMode.alone,
    TipsConfig? volTips,
    EdgeInsets? tipsPadding,
    int tickCount = constant.defaultSubTickCount,
    int precision = 2,
  }) {
    return VolumeIndicator(
      height: height ?? theme.defaultSubIndicatorHeight,
      padding: padding ?? theme.defaultSubIndicatorPadding,
      paintMode: paintMode,

      /// 绘制相关参数
      volTips: volTips ??
          TipsConfig(
            label: 'Vol: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.defaulTextSize,
              color: theme.textColor,
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTextHeight,
            ),
          ),
      tipsPadding: tipsPadding ?? theme.defaultTipsPadding,
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
    IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    List<MaParam>? calcParams,
    EdgeInsets? tipsPadding,
    double? lineWidth,
  }) {
    return MAIndicator(
      height: height ?? theme.defaultMainIndicatorHeight,
      padding: padding ?? theme.defaultMainIndicatorPadding,
      calcParams: calcParams ??
          [
            MaParam(
              count: 7,
              tips: TipsConfig(
                label: 'MA7: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.defaulTextSize,
                  color: const Color(0xFF946F9A),
                  overflow: TextOverflow.ellipsis,
                  height: theme.defaultTipsTextHeight,
                ),
              ),
            ),
            MaParam(
              count: 30,
              tips: TipsConfig(
                label: 'MA30: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.defaulTextSize,
                  color: const Color(0xFFF1BF32),
                  overflow: TextOverflow.ellipsis,
                  height: theme.defaultTipsTextHeight,
                ),
              ),
            ),
          ],
      tipsPadding: tipsPadding ?? theme.defaultTipsPadding,
      lineWidth: lineWidth ?? theme.defaultIndicatorLineWidth,
    );
  }

  EMAIndicator genEmaIndicator(
    IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    List<MaParam>? calcParams,
    EdgeInsets? tipsPadding,
    double? lineWidth,
  }) {
    return EMAIndicator(
      height: height ?? theme.defaultMainIndicatorHeight,
      padding: padding ?? theme.defaultMainIndicatorPadding,
      calcParams: calcParams ??
          [
            MaParam(
              count: 5,
              tips: TipsConfig(
                label: 'EMA5: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.defaulTextSize,
                  color: const Color(0xFF806180),
                  overflow: TextOverflow.ellipsis,
                  height: theme.defaultTipsTextHeight,
                ),
              ),
            ),
            MaParam(
              count: 10,
              tips: TipsConfig(
                label: 'EMA10: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.defaulTextSize,
                  color: const Color(0xFFEBB736),
                  overflow: TextOverflow.ellipsis,
                  height: theme.defaultTipsTextHeight,
                ),
              ),
            ),
            MaParam(
              count: 20,
              tips: TipsConfig(
                label: 'EMA20: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.defaulTextSize,
                  color: const Color(0xFFD672D5),
                  overflow: TextOverflow.ellipsis,
                  height: theme.defaultTipsTextHeight,
                ),
              ),
            ),
            MaParam(
              count: 60,
              tips: TipsConfig(
                label: 'EMA60: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.defaulTextSize,
                  color: const Color.fromARGB(255, 44, 45, 47),
                  overflow: TextOverflow.ellipsis,
                  height: theme.defaultTipsTextHeight,
                ),
              ),
            ),
          ],
      tipsPadding: tipsPadding ?? theme.defaultTipsPadding,
      lineWidth: lineWidth ?? theme.defaultIndicatorLineWidth,
    );
  }

  BOLLIndicator genBollIndicator(
    IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    BOLLParam? calcParam,
    TipsConfig? mbTips,
    TipsConfig? upTips,
    TipsConfig? dnTips,
    EdgeInsets? tipsPadding,
    int tickCount = constant.defaultSubTickCount,
    double? lineWidth,
    bool isFillBetweenUpAndDn = true,
    Color? fillColor,
  }) {
    return BOLLIndicator(
      height: height ?? theme.defaultMainIndicatorHeight,
      padding: padding ?? theme.defaultMainIndicatorPadding,

      /// BOLL计算参数
      calcParam: calcParam ?? const BOLLParam(n: 20, std: 2),

      /// 绘制相关参数
      mbTips: mbTips ??
          TipsConfig(
            label: 'BOLL(20): ',
            // precision: 2,
            style: TextStyle(
              fontSize: theme.defaulTextSize,
              color: const Color(0xFF886787),
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTipsTextHeight,
            ),
          ),
      upTips: upTips ??
          TipsConfig(
            label: 'UB: ',
            // precision: 2,
            style: TextStyle(
              fontSize: theme.defaulTextSize,
              color: const Color(0xFFF0B527),
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTipsTextHeight,
            ),
          ),
      dnTips: dnTips ??
          TipsConfig(
            label: 'LB: ',
            // precision: 2,
            style: TextStyle(
              fontSize: theme.defaulTextSize,
              color: const Color(0xFFD85BE0),
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTipsTextHeight,
            ),
          ),
      tipsPadding: tipsPadding ?? theme.defaultTipsPadding,
      lineWidth: lineWidth ?? theme.defaultIndicatorLineWidth,

      /// 填充配置
      isFillBetweenUpAndDn: isFillBetweenUpAndDn,
      fillColor: fillColor,
    );
  }

  TimeIndicator genTimeIndicator(
    IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    DrawPosition? position,
    TextAreaConfig? tmeiTick,
  }) {
    return TimeIndicator(
      height: height ?? theme.defaultTimeIndicatorHeight,
      padding: padding ?? EdgeInsets.zero,
      position: position ?? DrawPosition.middle,
      // 时间刻度.
      timeTick: tmeiTick ??
          TextAreaConfig(
            style: TextStyle(
              fontSize: theme.defaulTextSize,
              color: theme.tickTextColor,
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTextHeight,
            ),
            textWidth: 80 * theme.scale,
            textAlign: TextAlign.center,
          ),
    );
  }

  MACDIndicator genMacdIndicator(
    IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    MACDParam? calcParam,
    TipsConfig? difTips,
    TipsConfig? deaTips,
    TipsConfig? macdTips,
    EdgeInsets? tipsPadding,
    int tickCount = constant.defaultSubTickCount,
    double? lineWidth,
    int precision = 2,
  }) {
    return MACDIndicator(
      height: height ?? theme.defaultSubIndicatorHeight,
      padding: padding ?? theme.defaultSubIndicatorPadding,

      /// Macd相关参数
      calcParam: calcParam ?? const MACDParam(s: 12, l: 26, m: 9),

      /// 绘制相关参数
      difTips: difTips ??
          TipsConfig(
            label: 'DIF: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.defaulTextSize,
              color: const Color(0xFFDFBF47),
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTextHeight,
            ),
          ),
      deaTips: deaTips ??
          TipsConfig(
            label: 'DEA: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.defaulTextSize,
              color: const Color(0xFF795583),
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTextHeight,
            ),
          ),
      macdTips: macdTips ??
          TipsConfig(
            label: 'MACD: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.defaulTextSize,
              color: theme.textColor,
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTextHeight,
            ),
          ),
      tipsPadding: tipsPadding ?? theme.defaultTipsPadding,
      tickCount: tickCount,
      lineWidth: lineWidth ?? theme.defaultIndicatorLineWidth,
      precision: precision,
    );
  }

  KDJIndicator genKdjIndicator(
    IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    KDJParam? calcParam,
    TipsConfig? ktips,
    TipsConfig? dtips,
    TipsConfig? jtips,
    EdgeInsets? tipsPadding,
    int tickCount = constant.defaultSubTickCount,
    double? lineWidth,
    int precision = 2,
  }) {
    return KDJIndicator(
      height: height ?? theme.defaultSubIndicatorHeight,
      padding: padding ?? theme.defaultSubIndicatorPadding,

      /// KDJ计算参数
      calcParam: calcParam ?? const KDJParam(n: 9, m1: 3, m2: 3),

      /// 绘制相关参数
      ktips: ktips ??
          TipsConfig(
            label: 'K: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.defaulTextSize,
              color: const Color(0xFF7A5C79),
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTipsTextHeight,
            ),
          ),
      dtips: dtips ??
          TipsConfig(
            label: 'D: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.defaulTextSize,
              color: const Color(0xFFFABD3F),
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTipsTextHeight,
            ),
          ),
      jtips: jtips ??
          TipsConfig(
            label: 'D: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.defaulTextSize,
              color: const Color(0xFFBB72CA),
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTipsTextHeight,
            ),
          ),
      tipsPadding: tipsPadding ?? theme.defaultTipsPadding,
      tickCount: tickCount,
      lineWidth: lineWidth ?? theme.defaultIndicatorLineWidth,
      precision: precision,
    );
  }

  MAVolumeIndicator genMavolIndicator(
    IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    bool drawBelowTipsArea = false,
  }) {
    return MAVolumeIndicator(
      height: height ?? theme.defaultSubIndicatorHeight,
      padding: padding ?? theme.defaultSubIndicatorPadding,
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
    IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    PaintMode paintMode = PaintMode.combine,
    TipsConfig? volTips,
    EdgeInsets? tipsPadding,
    int tickCount = constant.defaultSubTickCount,
    int precision = 2,
  }) {
    return VolumeIndicator(
      height: height ?? theme.defaultSubIndicatorHeight,
      padding: padding ?? theme.defaultSubIndicatorPadding,
      paintMode: paintMode,

      /// 绘制相关参数
      volTips: volTips ??
          TipsConfig(
            label: 'Vol: ',
            precision: precision,
            style: TextStyle(
              fontSize: theme.defaulTextSize,
              color: theme.textColor,
              overflow: TextOverflow.ellipsis,
              height: theme.defaultTextHeight,
            ),
          ),
      tipsPadding: tipsPadding ?? theme.defaultTipsPadding,
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
    IFlexiKlineTheme theme, {
    double? height,
    EdgeInsets? padding,
    List<MaParam>? calcParams,
    EdgeInsets? tipsPadding,
    double? lineWidth,
    int precision = 2,
  }) {
    return VolMaIndicator(
      height: height ?? theme.defaultSubIndicatorHeight,
      padding: padding ?? theme.defaultSubIndicatorPadding,
      calcParams: calcParams ??
          [
            MaParam(
              count: 5,
              tips: TipsConfig(
                label: 'MA5: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.defaulTextSize,
                  color: Colors.orange,
                  overflow: TextOverflow.ellipsis,
                  height: theme.defaultTipsTextHeight,
                ),
              ),
            ),
            MaParam(
              count: 10,
              tips: TipsConfig(
                label: 'MA10: ',
                // precision: 2,
                style: TextStyle(
                  fontSize: theme.defaulTextSize,
                  color: Colors.blue,
                  overflow: TextOverflow.ellipsis,
                  height: theme.defaultTipsTextHeight,
                ),
              ),
            ),
          ],
      tipsPadding: tipsPadding ?? theme.defaultTipsPadding,
      lineWidth: lineWidth ?? theme.defaultIndicatorLineWidth,
      precision: precision,
    );
  }
}
