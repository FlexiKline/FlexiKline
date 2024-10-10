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
import '../framework/export.dart';
import '../indicators/export.dart';
import '../utils/vector_util.dart';
import 'boll_param/boll_param.dart';
import 'cross_config/cross_config.dart';
import 'draw_params/draw_params.dart';
import 'magnifier_config/magnifier_config.dart';
import 'point_config/point_config.dart';
import 'draw_config/draw_config.dart';
import 'flexi_kline_config/flexi_kline_config.dart';
import 'gesture_config/gesture_config.dart';
import 'grid_config/grid_config.dart';
import 'indicators_config/indicators_config.dart';
import 'kdj_param/kdj_param.dart';
import 'line_config/line_config.dart';
import 'loading_config/loading_config.dart';
import 'ma_param/ma_param.dart';
import 'macd_param/macd_param.dart';
import 'mark_config/mark_config.dart';
import 'paint_config/paint_config.dart';
import 'rsi_param/rsi_param.dart';
import 'sar_param/sar_param.dart';
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
    required this.drawTextBg,
    this.transparent = Colors.transparent,
    required this.lastPriceTextBg,
    required this.gridLine,
    required this.crossColor,
    required this.drawColor,
    required this.markLine,
    required this.themeColor,
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
        crossColor = color,
        markLine = color,
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
  late Color drawTextBg;
  @override
  late Color transparent;
  @override
  late Color lastPriceTextBg;

  /// 分隔线
  @override
  late Color gridLine;
  @override
  late Color crossColor;
  @override
  late Color drawColor;
  @override
  late Color markLine;

  @override
  late Color themeColor;

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
mixin FlexiKlineThemeConfigurationMixin implements IConfiguration {
  @override
  Iterable<Overlay> getOverlayListConfig(String instId) => const [];

  @override
  void saveOverlayListConfig(String instId, Iterable<Overlay> list) {}

  @override
  Iterable<SinglePaintObjectIndicator> customMainIndicators() => const [];

  @override
  Iterable<Indicator> customSubIndicators() => const [];

  @override
  FlexiKlineConfig getFlexiKlineConfig([covariant IFlexiKlineTheme? theme]);

  FlexiKlineConfig genFlexiKlineConfig(covariant IFlexiKlineTheme theme) {
    return FlexiKlineConfig(
      key: theme.key,
      grid: genGridConfig(theme),
      setting: genSettingConfig(theme),
      gesture: genGestureConfig(theme),
      cross: genCrossConfig(theme),
      draw: genDrawConfig(theme),
      tooltip: genTooltipConfig(theme),
      indicators: genIndicatorsConfig(theme),
      main: {},
      sub: {},
    );
  }

  GridConfig genGridConfig(covariant IFlexiKlineTheme theme) {
    return GridConfig(
      show: true,
      horizontal: GridAxis(
        show: true,
        count: 5,
        width: theme.pixel,
        color: theme.gridLine,
        type: LineType.solid,
        dashes: const [2, 2],
      ),
      vertical: GridAxis(
        show: true,
        count: 5,
        width: theme.pixel,
        color: theme.gridLine,
        type: LineType.solid,
        dashes: const [2, 2],
      ),
    );
  }

  GestureConfig genGestureConfig(covariant IFlexiKlineTheme theme) {
    return GestureConfig(
      isInertialPan: true,
      tolerance: ToleranceConfig(),
      loadMoreWhenNoEnoughDistance: null,
      loadMoreWhenNoEnoughCandles: 60,
      scalePosition: ScalePosition.auto,
      scaleSpeed: 10,
    );
  }

  SettingConfig genSettingConfig(covariant IFlexiKlineTheme theme) {
    return SettingConfig(
      pixel: theme.pixel,
      textColor: theme.textColor,
      longColor: theme.long,
      shortColor: theme.short,
      opacity: 0.5,

      /// 内置LoadingView样式配置
      loading: genInnerLoadingConfig(theme),

      /// 主/副图区域大小配置
      // mainRect: Rect.zero,
      mainMinSize: Size.square(20 * theme.scale),
      mainPadding: theme.mainIndicatorPadding,
      mainDrawBelowTipsArea: true,

      /// 主/副图绘制参数
      minPaintBlankRate: 0.5,
      alwaysCalculateScreenOfCandlesIfEnough: false,
      candleMaxWidth: 40 * theme.scale,
      candleWidth: 7 * theme.scale,
      candleSpacingParts: 7,
      candleFixedSpacing: 1 * theme.scale,
      candleLineWidth: 1 * theme.scale,
      firstCandleInitOffset: 80 * theme.scale,

      /// 全局默认的刻度值配置.
      tickText: TextAreaConfig(
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
      subChartMaxCount: defaultSubChartMaxCount,
    );
  }

  LoadingConfig genInnerLoadingConfig(covariant IFlexiKlineTheme theme) {
    return LoadingConfig(
      size: 24 * theme.scale,
      strokeWidth: 4 * theme.scale,
      background: theme.tooltipBg,
      valueColor: theme.textColor,
    );
  }

  CrossConfig genCrossConfig(covariant IFlexiKlineTheme theme) {
    return CrossConfig(
      enable: true,
      crosshair: LineConfig(
        width: 0.5 * theme.scale,
        color: theme.crossColor,
        type: LineType.dashed,
        dashes: const [3, 3],
      ),
      crosspoint: PointConfig(
        radius: 2 * theme.scale,
        width: 0 * theme.scale,
        color: theme.crossColor,
        borderWidth: 2 * theme.scale,
        borderColor: theme.crossColor.withOpacity(0.5),
      ),
      tickText: TextAreaConfig(
        style: TextStyle(
          color: theme.crossTextColor,
          fontSize: theme.normalTextSize,
          fontWeight: FontWeight.normal,
          height: defaultTextHeight,
        ),
        background: theme.crossTextBg,
        padding: EdgeInsets.all(2 * theme.scale),
        border: BorderSide.none,
        borderRadius: BorderRadius.all(
          Radius.circular(2 * theme.scale),
        ),
      ),
      spacing: 1 * theme.scale,
      // onCross时, 当移动到空白区域时, Tips区域是否展示最新的蜡烛的Tips数据.
      showLatestTipsInBlank: true,
    );
  }

  DrawConfig genDrawConfig(covariant IFlexiKlineTheme theme) {
    return DrawConfig(
      enable: true,
      crosshair: LineConfig(
        width: 0.5 * theme.scale,
        color: theme.drawColor,
        type: LineType.dashed,
        dashes: const [3, 3],
      ),
      crosspoint: PointConfig(
        radius: 2 * theme.scale,
        width: 0 * theme.scale,
        color: theme.drawColor,
        borderWidth: 2 * theme.scale,
        borderColor: theme.drawColor.withOpacity(0.5),
      ),
      drawLine: LineConfig(
        width: 1 * theme.scale,
        color: theme.drawColor,
        type: LineType.solid,
      ),
      drawPoint: PointConfig(
        radius: 9 * theme.scale,
        width: 0 * theme.scale,
        color: const Color(0xFFFFFFFF),
        borderWidth: 1 * theme.scale,
        borderColor: theme.drawColor,
      ),
      tickText: TextAreaConfig(
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: theme.normalTextSize,
          fontWeight: FontWeight.normal,
          height: defaultTextHeight,
        ),
        background: theme.drawTextBg,
        padding: EdgeInsets.all(2 * theme.scale),
        border: BorderSide.none,
        borderRadius: BorderRadius.all(
          Radius.circular(2 * theme.scale),
        ),
      ),
      spacing: 1 * theme.scale,
      gapBackground: theme.drawColor.withOpacity(0.1),
      hitTestMinDistance: 10 * theme.scale,
      magnifierConfig: MagnifierConfig(
        enable: true,
        times: 2,
        margin: EdgeInsets.all(1 * theme.scale),
        size: Size(80 * theme.scale, 80 * theme.scale),
        boder: BorderSide(
          color: theme.gridLine,
          width: 1 * theme.scale,
        ),
      ),
      drawParams: DrawParams(
        // 箭头(ArrowLine)
        arrowsRadians: pi30,
        arrowsLen: 16 * theme.scale,
        // 价值线(priceLine)
        priceText: TextAreaConfig(
          style: TextStyle(
            // color: const Color(0xFFFFFFFF),
            color: const Color(0xFFFF0000),
            fontSize: theme.normalTextSize,
            fontWeight: FontWeight.normal,
            height: defaultTextHeight,
          ),
          // background: const Color(0xFFFF0000),
          // padding: EdgeInsets.all(1 * theme.scale),
          // border: BorderSide.none,
          // borderRadius: BorderRadius.all(
          //   Radius.circular(2 * theme.scale),
          // ),
        ),
        priceTextMargin: EdgeInsets.only(
          left: 12 * theme.scale,
          bottom: 2 * theme.scale,
        ),
        // 趋势线角度(TrendAngle)
        angleBaseLineMinLen: 80 * theme.scale,
        angleRadSize: Size.square(50 * theme.scale),
        angleText: TextAreaConfig(
          style: TextStyle(
            color: const Color(0xFFFFFFFF),
            fontSize: theme.normalTextSize,
            fontWeight: FontWeight.normal,
            height: defaultTextHeight,
          ),
          background: const Color(0xFFFF0000),
          padding: EdgeInsets.all(1 * theme.scale),
          border: BorderSide.none,
          borderRadius: BorderRadius.all(
            Radius.circular(2 * theme.scale),
          ),
        ),
      ),
    );
  }

  TooltipConfig genTooltipConfig(covariant IFlexiKlineTheme theme) {
    return TooltipConfig(
      show: true,

      /// tooltip 区域设置
      background: theme.tooltipBg,
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
        color: theme.tooltipTextColor,
        overflow: TextOverflow.ellipsis,
        height: defaultMultiTextHeight,
      ),
    );
  }

  IndicatorsConfig genIndicatorsConfig(covariant IFlexiKlineTheme theme) {
    return IndicatorsConfig(
      /// 主区
      candle: genCandleIndicator(theme),
      volume: genMainVolumeIndicator(theme),
      ma: genMaIndicator(theme),
      ema: genEmaIndicator(theme),
      boll: genBollIndicator(theme),
      sar: genSarIndicator(theme),

      /// 副区
      time: genTimeIndicator(theme),
      macd: genMacdIndicator(theme),
      kdj: genKdjIndicator(theme),
      mavol: genMavolIndicator(theme),
      subBoll: genSubBollIndicator(theme),
      subSar: genSubSarIndicator(theme),
      rsi: genSubRsiIndicator(theme),
    );
  }

  CandleIndicator genCandleIndicator(covariant IFlexiKlineTheme theme) {
    return CandleIndicator(
      zIndex: -1,
      height: theme.mainIndicatorHeight,
      padding: theme.mainIndicatorPadding,
      high: MarkConfig(
        spacing: 2 * theme.scale,
        line: LineConfig(
          type: LineType.solid,
          color: theme.markLine,
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
      low: MarkConfig(
        spacing: 2 * theme.scale,
        line: LineConfig(
          type: LineType.solid,
          color: theme.markLine,
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
      last: MarkConfig(
        show: true,
        spacing: 1 * theme.scale,
        line: LineConfig(
          type: LineType.dashed,
          color: theme.markLine,
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
      latest: MarkConfig(
        show: true,
        spacing: 1 * theme.scale,
        line: LineConfig(
          type: LineType.dashed,
          color: theme.markLine,
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

  VolumeIndicator genMainVolumeIndicator(covariant IFlexiKlineTheme theme) {
    return VolumeIndicator(
      key: volumeKey,
      zIndex: -2,
      height: theme.subIndicatorHeight,
      padding: theme.subIndicatorPadding,
      paintMode: PaintMode.alone,

      /// 绘制相关参数
      volTips: TipsConfig(
        label: 'Vol: ',
        precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: theme.textColor,
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
      ),
      tipsPadding: theme.tipsPadding,
      tickCount: defaultSubTickCount,
      precision: 2,

      /// 控制参数
      // showYAxisTick: false,
      // showCrossMark: false,
      // showTips: false,
      // useTint: true,
    );
  }

  MAIndicator genMaIndicator(covariant IFlexiKlineTheme theme) {
    return MAIndicator(
      key: maKey,
      height: theme.mainIndicatorHeight,
      padding: theme.mainIndicatorPadding,
      calcParams: [
        MaParam(
          count: 7,
          tips: TipsConfig(
            label: 'MA7: ',
            // precision: 2,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: Colors.lightBlue,
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
              color: Colors.purple,
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight,
            ),
          ),
        ),
      ],
      tipsPadding: theme.tipsPadding,
      lineWidth: theme.indicatorLineWidth,
    );
  }

  EMAIndicator genEmaIndicator(covariant IFlexiKlineTheme theme) {
    return EMAIndicator(
      key: emaKey,
      height: theme.mainIndicatorHeight,
      padding: theme.mainIndicatorPadding,
      calcParams: [
        MaParam(
          count: 5,
          tips: TipsConfig(
            label: 'EMA5: ',
            // precision: 2,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: Colors.blueGrey,
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
              color: Colors.pink,
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
              color: Colors.deepOrange,
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
              color: Colors.deepPurple,
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight,
            ),
          ),
        ),
      ],
      tipsPadding: theme.tipsPadding,
      lineWidth: theme.indicatorLineWidth,
    );
  }

  BOLLIndicator genBollIndicator(covariant IFlexiKlineTheme theme) {
    return BOLLIndicator(
      key: bollKey,
      height: theme.mainIndicatorHeight,
      padding: theme.mainIndicatorPadding,

      /// BOLL计算参数
      calcParam: const BOLLParam(n: 20, std: 2),

      /// 绘制相关参数
      mbTips: TipsConfig(
        label: 'BOLL(20): ',
        // precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: Colors.orangeAccent,
          overflow: TextOverflow.ellipsis,
          height: defaultTipsTextHeight,
        ),
      ),
      upTips: TipsConfig(
        label: 'UB: ',
        // precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: Colors.orange,
          overflow: TextOverflow.ellipsis,
          height: defaultTipsTextHeight,
        ),
      ),
      dnTips: TipsConfig(
        label: 'LB: ',
        // precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: Colors.orangeAccent,
          overflow: TextOverflow.ellipsis,
          height: defaultTipsTextHeight,
        ),
      ),
      tipsPadding: theme.tipsPadding,
      lineWidth: theme.indicatorLineWidth,

      /// 填充配置
      isFillBetweenUpAndDn: true,
      fillColor: null,
    );
  }

  SARIndicator genSarIndicator(covariant IFlexiKlineTheme theme) {
    return SARIndicator(
      key: sarKey,
      height: theme.mainIndicatorHeight,
      padding: theme.mainIndicatorPadding,
      calcParam: const SARParam(startAf: 0.02, step: 0.02, maxAf: 0.2),
      radius: null, // 2 * theme.scale,
      useCandleColor: true,
      paint: PaintConfig(
        color: const Color(0x00000000),
        strokeWidth: 1 * theme.scale,
        style: PaintingStyle.stroke,
      ),
      tipsPadding: theme.tipsPadding,
      tipsStyle: TextStyle(
        fontSize: theme.normalTextSize,
        color: theme.tickTextColor,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      ),
    );
  }

  TimeIndicator genTimeIndicator(covariant IFlexiKlineTheme theme) {
    return TimeIndicator(
      height: theme.timeIndicatorHeight,
      padding: EdgeInsets.zero,
      position: DrawPosition.middle,
      // 时间刻度.
      timeTick: TextAreaConfig(
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

  MACDIndicator genMacdIndicator(covariant IFlexiKlineTheme theme) {
    return MACDIndicator(
      height: theme.subIndicatorHeight,
      padding: theme.subIndicatorPadding,

      /// Macd相关参数
      calcParam: const MACDParam(s: 12, l: 26, m: 9),

      /// 绘制相关参数
      difTips: TipsConfig(
        label: 'DIF: ',
        precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: const Color(0xFFDFBF47),
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
      ),
      deaTips: TipsConfig(
        label: 'DEA: ',
        precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: const Color(0xFF795583),
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
      ),
      macdTips: TipsConfig(
        label: 'MACD: ',
        precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: theme.textColor,
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
      ),
      tipsPadding: theme.tipsPadding,
      tickCount: defaultSubTickCount,
      lineWidth: theme.indicatorLineWidth,
      precision: 2,
    );
  }

  KDJIndicator genKdjIndicator(covariant IFlexiKlineTheme theme) {
    return KDJIndicator(
      height: theme.subIndicatorHeight,
      padding: theme.subIndicatorPadding,

      /// KDJ计算参数
      calcParam: const KDJParam(n: 9, m1: 3, m2: 3),

      /// 绘制相关参数
      ktips: TipsConfig(
        label: 'K: ',
        precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: const Color(0xFF7A5C79),
          overflow: TextOverflow.ellipsis,
          height: defaultTipsTextHeight,
        ),
      ),
      dtips: TipsConfig(
        label: 'D: ',
        precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: const Color(0xFFFABD3F),
          overflow: TextOverflow.ellipsis,
          height: defaultTipsTextHeight,
        ),
      ),
      jtips: TipsConfig(
        label: 'D: ',
        precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: const Color(0xFFBB72CA),
          overflow: TextOverflow.ellipsis,
          height: defaultTipsTextHeight,
        ),
      ),
      tipsPadding: theme.tipsPadding,
      tickCount: defaultSubTickCount,
      lineWidth: theme.indicatorLineWidth,
      precision: 2,
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
      volumeIndicator: genSubVolumeIndicator(theme),
      volMaIndicator: genSubVolMaIndicator(theme),
    );
  }

  VolumeIndicator genSubVolumeIndicator(covariant IFlexiKlineTheme theme) {
    return VolumeIndicator(
      key: subVolKey, // 区别于主区volumeKey的地方
      zIndex: -2,
      height: theme.subIndicatorHeight,
      padding: theme.subIndicatorPadding,
      paintMode: PaintMode.combine,

      /// 绘制相关参数
      volTips: TipsConfig(
        label: 'Vol: ',
        precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: theme.textColor,
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
      ),
      tipsPadding: theme.tipsPadding,
      tickCount: defaultSubTickCount,
      precision: 2,

      /// 控制参数
      // showYAxisTick: true,
      // showCrossMark: true,
      // showTips: true,
      // useTint: false,
    );
  }

  VolMaIndicator genSubVolMaIndicator(covariant IFlexiKlineTheme theme) {
    return VolMaIndicator(
      key: volMaKey,
      zIndex: 0,
      height: theme.subIndicatorHeight,
      padding: theme.subIndicatorPadding,
      calcParams: [
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
      tipsPadding: theme.tipsPadding,
      lineWidth: theme.indicatorLineWidth,
      precision: 2,
    );
  }

  BOLLIndicator genSubBollIndicator(covariant IFlexiKlineTheme theme) {
    return BOLLIndicator(
      key: subBollKey, // 区别于主区bollKey的地方
      height: theme.subIndicatorHeight,
      padding: theme.subIndicatorPadding,

      /// BOLL计算参数
      calcParam: const BOLLParam(n: 20, std: 2),

      /// 绘制相关参数
      mbTips: TipsConfig(
        label: 'BOLL(20): ',
        // precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: Colors.orangeAccent,
          overflow: TextOverflow.ellipsis,
          height: defaultTipsTextHeight,
        ),
      ),
      upTips: TipsConfig(
        label: 'UB: ',
        // precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: Colors.orangeAccent,
          overflow: TextOverflow.ellipsis,
          height: defaultTipsTextHeight,
        ),
      ),
      dnTips: TipsConfig(
        label: 'LB: ',
        // precision: 2,
        style: TextStyle(
          fontSize: theme.normalTextSize,
          color: Colors.orangeAccent,
          overflow: TextOverflow.ellipsis,
          height: defaultTipsTextHeight,
        ),
      ),
      tipsPadding: theme.tipsPadding,
      lineWidth: theme.indicatorLineWidth,

      /// 填充配置
      isFillBetweenUpAndDn: true,
      fillColor: null,
    );
  }

  SARIndicator genSubSarIndicator(covariant IFlexiKlineTheme theme) {
    return SARIndicator(
      key: subSarKey, // 区别于主区sarKey的地方
      height: theme.subIndicatorHeight,
      padding: theme.subIndicatorPadding,
      calcParam: const SARParam(startAf: 0.02, step: 0.02, maxAf: 0.2),
      radius: null, // 2 * theme.scale,
      useCandleColor: true,
      paint: PaintConfig(
        color: const Color(0x00000000),
        strokeWidth: 1 * theme.scale,
        style: PaintingStyle.stroke,
      ),
      tipsPadding: theme.tipsPadding,
      tipsStyle: TextStyle(
        fontSize: theme.normalTextSize,
        color: theme.tickTextColor,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      ),
    );
  }

  RSIIndicator genSubRsiIndicator(covariant IFlexiKlineTheme theme) {
    return RSIIndicator(
      height: theme.subIndicatorHeight,
      padding: theme.subIndicatorPadding,
      calcParams: [
        RsiParam(
          count: 6,
          tips: TipsConfig(
            label: 'RSI6: ',
            precision: 2,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: Colors.deepOrangeAccent,
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight,
            ),
          ),
        ),
        RsiParam(
          count: 12,
          tips: TipsConfig(
            label: 'RSI12: ',
            precision: 2,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: Colors.blueAccent,
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight,
            ),
          ),
        ),
        RsiParam(
          count: 24,
          tips: TipsConfig(
            label: 'RSI24: ',
            precision: 2,
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: Colors.pinkAccent,
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight,
            ),
          ),
        )
      ],
      tipsPadding: theme.tipsPadding,
      lineWidth: theme.indicatorLineWidth,
    );
  }
}
