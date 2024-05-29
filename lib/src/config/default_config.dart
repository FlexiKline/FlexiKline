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
  /// 默认副图指标最大数量
  int get defaultSubChartMaxCount => constant.defaultSubChartMaxCount;

  /// 默认副图指标刻度数量: 高中低=>top, middle, bottom
  int get defaultSubTickCount => constant.defaultSubTickCount;

  /// 默认时间指标高度
  double get defaultTimeIndicatorHeight {
    return constant.defaultTimeIndicatorHeight * scale;
  }

  /// 默认副图指标高度
  double get defaultSubIndicatorHeight {
    return constant.defaultSubIndicatorHeight * scale;
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

abstract class BaseFlexiKlineConfiguration implements IConfiguration {
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

  GridConfig genGridConfig(IFlexiKlineTheme theme) {
    return GridConfig(
      show: true,
      horizontal: GridAxis(
        show: true,
        width: theme.pixel,
        color: theme.gridLine,
        type: LineType.solid,
        dashes: const [2, 2],
      ),
      vertical: GridAxis(
        show: true,
        width: theme.pixel,
        color: theme.gridLine,
        type: LineType.solid,
        dashes: const [2, 2],
      ),
    );
  }

  SettingConfig genSettingConfig(IFlexiKlineTheme theme) {
    return SettingConfig(
      textColor: theme.textColor,
      longColor: theme.long,
      shortColor: theme.short,
      opacity: 0.5,

      /// 内置LoadingView样式配置
      loading: LoadingConfig(
        size: 24,
        strokeWidth: 4,
        background: theme.tooltipBg,
        valueColor: theme.textColor,
      ),

      /// 主/副图区域大小配置
      // mainRect: Rect.zero,
      mainMinSize: Size.square(20 * theme.scale),
      mainPadding: theme.defaultMainIndicatorPadding,
      mainDrawBelowTipsArea: true,

      /// 主/副图绘制参数
      minPaintBlankRate: 0.5,
      alwaysCalculateScreenOfCandlesIfEnough: false,
      candleMaxWidth: 40 * theme.scale,
      candleWidth: 7 * theme.scale,
      candleSpacing: 1 * theme.scale,
      candleLineWidth: 1 * theme.scale,
      firstCandleInitOffset: 80 * theme.scale,

      /// 全局默认的刻度值配置.
      tickText: TextAreaConfig(
        style: TextStyle(
          fontSize: theme.defaulTextSize,
          color: theme.tickTextColor,
          overflow: TextOverflow.ellipsis,
          height: theme.defaultTextHeight,
        ),
        textAlign: TextAlign.end,
        padding: EdgeInsets.symmetric(horizontal: 2 * theme.scale),
      ),

      /// 副图配置
      // 副区的指标图最大数量
      subChartMaxCount: theme.defaultSubChartMaxCount,
    );
  }

  CrossConfig genCrossConfig(IFlexiKlineTheme theme) {
    return CrossConfig(
      enable: true,
      crosshair: LineConfig(
        width: 0.5 * theme.scale,
        color: theme.crosshair,
        type: LineType.dashed,
        dashes: const [3, 3],
      ),
      point: CrossPointConfig(
        radius: 2 * theme.scale,
        width: 6 * theme.scale,
        color: theme.crosshair,
      ),
      tickText: TextAreaConfig(
        style: TextStyle(
          color: theme.crossTextColor,
          fontSize: theme.defaulTextSize,
          fontWeight: FontWeight.normal,
          height: theme.defaultTextHeight,
        ),
        background: theme.crossTextBg,
        padding: EdgeInsets.all(2 * theme.scale),
        border: BorderSide.none,
        borderRadius: BorderRadius.all(
          Radius.circular(2 * theme.scale),
        ),
      ),
    );
  }

  TooltipConfig genTooltipConfig(IFlexiKlineTheme theme) {
    return TooltipConfig(
      show: true,

      /// tooltip 区域设置
      background: theme.tooltipBg,
      margin: EdgeInsets.only(
        left: 15 * theme.scale,
        right: 65 * theme.scale,
        top: 4 * theme.scale,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 4 * theme.scale,
        vertical: 4 * theme.scale,
      ),
      radius: BorderRadius.all(Radius.circular(4 * theme.scale)),

      /// tooltip 文本设置
      style: TextStyle(
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
      volume: genVolumeIndicator(
        theme,
        paintMode: PaintMode.alone,
        showYAxisTick: false,
        showCrossMark: false,
        showTips: false,
        useTint: true,
      ),
      ma: genMaIndicator(theme),
      ema: genEmaIndicator(theme),
      boll: genBollIndicator(theme),
      time: genTimeIndicator(theme),
      macd: genMacdIndicator(theme),
      kdj: genKdjIndicator(theme),
      mavol: genMavolIndicator(theme),
    );
  }

  CandleIndicator genCandleIndicator(IFlexiKlineTheme theme) {
    return CandleIndicator(
      height: 0,
      padding: theme.defaultMainIndicatorPadding,
      high: MarkConfig(
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
      low: MarkConfig(
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
      last: MarkConfig(
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
      latest: MarkConfig(
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
      useCandleColorAsLatestBg: true,
      showCountDown: true,
      countDown: TextAreaConfig(
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

  VolumeIndicator genVolumeIndicator(
    IFlexiKlineTheme theme, {
    required PaintMode paintMode,
    bool showYAxisTick = false,
    bool showCrossMark = false,
    bool showTips = false,
    bool useTint = true,
    int precision = 2,
  }) {
    return VolumeIndicator(
      height: theme.defaultSubIndicatorHeight,
      padding: theme.defaultSubIndicatorPadding,
      paintMode: paintMode,

      /// 绘制相关参数
      volTips: TipsConfig(
        label: 'Vol: ',
        precision: precision,
        style: TextStyle(
          fontSize: theme.defaulTextSize,
          color: theme.textColor,
          overflow: TextOverflow.ellipsis,
          height: theme.defaultTextHeight,
        ),
      ),
      tipsPadding: theme.defaultTipsPadding,
      tickCount: theme.defaultSubTickCount,
      precision: precision,

      /// 控制参数
      showYAxisTick: showYAxisTick,
      showCrossMark: showCrossMark,
      showTips: showTips,
      useTint: useTint,
    );
  }

  MAIndicator genMaIndicator(IFlexiKlineTheme theme) {
    return MAIndicator(
      height: theme.defaultSubIndicatorHeight,
      padding: theme.defaultSubIndicatorPadding,
      calcParams: [
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
      tipsPadding: theme.defaultTipsPadding,
      lineWidth: theme.defaultIndicatorLineWidth,
    );
  }

  EMAIndicator genEmaIndicator(IFlexiKlineTheme theme) {
    return EMAIndicator(
      height: theme.defaultSubIndicatorHeight,
      padding: theme.defaultSubIndicatorPadding,
      calcParams: [
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
      tipsPadding: theme.defaultTipsPadding,
      lineWidth: theme.defaultIndicatorLineWidth,
    );
  }

  BOLLIndicator genBollIndicator(IFlexiKlineTheme theme) {
    return BOLLIndicator(
      height: theme.defaultSubIndicatorHeight,
      padding: theme.defaultSubIndicatorPadding,

      /// BOLL计算参数
      calcParam: const BOLLParam(n: 20, std: 2),

      /// 绘制相关参数
      mbTips: TipsConfig(
        label: 'BOLL(20): ',
        // precision: 2,
        style: TextStyle(
          fontSize: theme.defaulTextSize,
          color: const Color(0xFF886787),
          overflow: TextOverflow.ellipsis,
          height: theme.defaultTipsTextHeight,
        ),
      ),
      upTips: TipsConfig(
        label: 'UB: ',
        // precision: 2,
        style: TextStyle(
          fontSize: theme.defaulTextSize,
          color: const Color(0xFFF0B527),
          overflow: TextOverflow.ellipsis,
          height: theme.defaultTipsTextHeight,
        ),
      ),
      dnTips: TipsConfig(
        label: 'LB: ',
        // precision: 2,
        style: TextStyle(
          fontSize: theme.defaulTextSize,
          color: const Color(0xFFD85BE0),
          overflow: TextOverflow.ellipsis,
          height: theme.defaultTipsTextHeight,
        ),
      ),
      tipsPadding: theme.defaultTipsPadding,
      lineWidth: theme.defaultIndicatorLineWidth,

      /// 填充配置
      isFillBetweenUpAndDn: true,
      // fillColor:
    );
  }

  TimeIndicator genTimeIndicator(IFlexiKlineTheme theme) {
    return TimeIndicator(
      height: theme.defaultTimeIndicatorHeight,
      padding: EdgeInsets.zero,
      position: DrawPosition.middle,
      // 时间刻度.
      timeTick: TextAreaConfig(
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
    int precision = 2,
  }) {
    return MACDIndicator(
      height: theme.defaultSubIndicatorHeight,
      padding: theme.defaultSubIndicatorPadding,

      /// Macd相关参数
      calcParam: const MACDParam(s: 12, l: 26, m: 9),

      /// 绘制相关参数
      difTips: TipsConfig(
        label: 'DIF: ',
        precision: precision,
        style: TextStyle(
          fontSize: theme.defaulTextSize,
          color: const Color(0xFFDFBF47),
          overflow: TextOverflow.ellipsis,
          height: theme.defaultTextHeight,
        ),
      ),
      deaTips: TipsConfig(
        label: 'DEA: ',
        precision: precision,
        style: TextStyle(
          fontSize: theme.defaulTextSize,
          color: const Color(0xFF795583),
          overflow: TextOverflow.ellipsis,
          height: theme.defaultTextHeight,
        ),
      ),
      macdTips: TipsConfig(
        label: 'MACD: ',
        precision: precision,
        style: TextStyle(
          fontSize: theme.defaulTextSize,
          color: theme.textColor,
          overflow: TextOverflow.ellipsis,
          height: theme.defaultTextHeight,
        ),
      ),
      tipsPadding: theme.defaultTipsPadding,
      tickCount: theme.defaultSubTickCount,
      lineWidth: theme.defaultIndicatorLineWidth,
      precision: precision,
    );
  }

  KDJIndicator genKdjIndicator(
    IFlexiKlineTheme theme, {
    int precision = 2,
  }) {
    return KDJIndicator(
      height: theme.defaultSubIndicatorHeight,
      padding: theme.defaultSubIndicatorPadding,

      /// KDJ计算参数
      calcParam: const KDJParam(n: 9, m1: 3, m2: 3),

      /// 绘制相关参数
      ktips: TipsConfig(
        label: 'K: ',
        precision: precision,
        style: TextStyle(
          fontSize: theme.defaulTextSize,
          color: const Color(0xFF7A5C79),
          overflow: TextOverflow.ellipsis,
          height: theme.defaultTipsTextHeight,
        ),
      ),
      dtips: TipsConfig(
        label: 'D: ',
        precision: precision,
        style: TextStyle(
          fontSize: theme.defaulTextSize,
          color: const Color(0xFFFABD3F),
          overflow: TextOverflow.ellipsis,
          height: theme.defaultTipsTextHeight,
        ),
      ),
      jtips: TipsConfig(
        label: 'D: ',
        precision: precision,
        style: TextStyle(
          fontSize: theme.defaulTextSize,
          color: const Color(0xFFBB72CA),
          overflow: TextOverflow.ellipsis,
          height: theme.defaultTipsTextHeight,
        ),
      ),
      tipsPadding: theme.defaultTipsPadding,
      tickCount: theme.defaultSubTickCount,
      lineWidth: theme.defaultIndicatorLineWidth,
      precision: precision,
    );
  }

  MAVolumeIndicator genMavolIndicator(IFlexiKlineTheme theme) {
    return MAVolumeIndicator(
      volumeIndicator: genVolumeIndicator(
        theme,
        paintMode: PaintMode.combine,
        showCrossMark: true,
        showTips: true,
        showYAxisTick: true,
        useTint: false,
      ),
      volMaIndicator: genVolMaIndicator(theme),
    );
  }

  VolMaIndicator genVolMaIndicator(
    IFlexiKlineTheme theme, {
    int precision = 2,
  }) {
    return VolMaIndicator(
      height: theme.defaultSubIndicatorHeight,
      padding: theme.defaultSubIndicatorPadding,
      calcParams: [
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
      tipsPadding: theme.defaultTipsPadding,
      lineWidth: theme.defaultIndicatorLineWidth,
      precision: precision,
    );
  }
}
