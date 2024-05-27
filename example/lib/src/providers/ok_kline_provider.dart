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

import 'dart:convert';

import 'package:example/generated/l10n.dart';
import 'package:example/src/router.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config.dart';
import '../theme/export.dart';
import '../utils/cache_util.dart';

Map<TooltipLabel, String> tooltipLables() {
  return {
    TooltipLabel.time: S.current.tooltipTime,
    TooltipLabel.open: S.current.tooltipOpen,
    TooltipLabel.high: S.current.tooltipHigh,
    TooltipLabel.low: S.current.tooltipLow,
    TooltipLabel.close: S.current.tooltipClose,
    TooltipLabel.chg: S.current.tooltipChg,
    TooltipLabel.chgRate: S.current.tooltipChgRate,
    TooltipLabel.range: S.current.tooltipRange,
    TooltipLabel.amount: S.current.tooltipAmount,
    TooltipLabel.turnover: S.current.tooltipTurnover,
  };
}

class OkFlexiKlineConfiguration implements IConfiguration {
  String getFlexKlineConfigKey([FKTheme? theme]) {
    theme ??= globalNavigatorKey.ref.read(themeProvider);
    return 'flexi_kline_config_key_ok-${theme!.brightness.name}';
  }

  @override
  Size get initialMainSize => Size(ScreenUtil().screenWidth, 300.r);

  @override
  FlexiKlineConfig getInitialFlexiKlineConfig() {
    try {
      final key = getFlexKlineConfigKey();
      final String? jsonStr = CacheUtil().get(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final json = jsonDecode(jsonStr);
        if (json is Map<String, dynamic>) {
          return FlexiKlineConfig.fromJson(json);
        }
      }
    } catch (err, stack) {
      defLogger.e('getFlexiKlineConfig error:$err', stackTrace: stack);
    }
    return genFlexiKlineConfigObject(
      globalNavigatorKey.ref.read(themeProvider),
    );
  }

  @override
  void saveFlexiKlineConfig(FlexiKlineConfig config) {
    final jsonSrc = jsonEncode(config);
    CacheUtil().setString(config.key, jsonSrc);
  }

  FlexiKlineConfig genFlexiKlineConfigObject(FKTheme theme) {
    return FlexiKlineConfig(
      key: getFlexKlineConfigKey(theme),
      main: {candleKey},
      sub: {timeKey},
      grid: GridConfig(
        show: true,
        horizontal: GridAxis(
          show: true,
          width: 0.5.r,
          color: theme.dividerLine,
          type: LineType.solid,
          dashes: const [2, 2],
        ),
        vertical: GridAxis(
          show: true,
          width: 0.5.r,
          color: theme.dividerLine,
          type: LineType.solid,
          dashes: const [2, 2],
        ),
      ),
      setting: genSettingConfig(theme),
      cross: CrossConfig(
        enable: true,
        crosshair: LineConfig(
          width: 0.5.r,
          color: theme.t1,
          type: LineType.dashed,
          dashes: const [3, 3],
        ),
        point: CrossPointConfig(
          radius: 2.r,
          width: 6.r,
          color: theme.t1,
        ),
        tickText: TextAreaConfig(
          style: TextStyle(
            color: theme.tlight,
            fontSize: theme.klineTextSize,
            fontWeight: FontWeight.normal,
            height: theme.klineTextHeight,
          ),
          background: theme.lightBg,
          padding: EdgeInsets.all(2.r),
          border: BorderSide.none,
          borderRadius: BorderRadius.all(
            Radius.circular(2.r),
          ),
        ),
      ),
      tooltip: genTooltiipConfig(theme),
      indicators: genIndicatorsConfig(theme),
    );
  }

  SettingConfig genSettingConfig(FKTheme theme) {
    return SettingConfig(
      textColor: theme.t1,
      longColor: theme.long,
      shortColor: theme.short,
      opacity: 0.5,

      /// 内置LoadingView样式配置
      loading: LoadingConfig(
        size: 24,
        strokeWidth: 4,
        background: theme.markBg,
        valueColor: theme.t1,
      ),

      /// 主/副图区域大小配置
      // mainRect: Rect.zero,
      // mainMinSize: defaultMainRectMinSize,
      mainPadding: defaultMainIndicatorPadding,

      /// 主/副图绘制参数
      minPaintBlankRate: 0.5,
      alwaysCalculateScreenOfCandlesIfEnough: false,
      candleMaxWidth: 40.0.r,
      candleWidth: 7.0.r,
      candleSpacing: 1.0.r,
      candleLineWidth: 1.0.r,
      firstCandleInitOffset: 80.r,

      /// 全局默认的刻度值配置.
      tickText: TextAreaConfig(
        style: TextStyle(
          fontSize: theme.klineTextSize,
          color: theme.t2,
          overflow: TextOverflow.ellipsis,
          height: theme.klineTextHeight,
        ),
        textAlign: TextAlign.end,
        padding: EdgeInsets.symmetric(horizontal: 2.r),
      ),

      /// 副图配置
      // 副区的指标图最大数量
      subChartMaxCount: defaultSubChartMaxCount,
    );
  }

  TooltipConfig genTooltiipConfig(FKTheme theme) {
    return TooltipConfig(
      show: true,

      /// tooltip 区域设置
      background: theme.cardBg,
      margin: EdgeInsets.only(
        left: 15.r,
        right: 65.r,
        top: 4.r,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 4.r,
        vertical: 4.r,
      ),
      radius: BorderRadius.all(Radius.circular(4.r)),

      /// tooltip 文本设置
      style: TextStyle(
        fontSize: theme.klineTextSize,
        color: theme.t2,
        overflow: TextOverflow.ellipsis,
        height: defaultMultiTextHeight,
      ),
    );
  }

  IndicatorsConfig genIndicatorsConfig(FKTheme theme) {
    return IndicatorsConfig(
      candle: genCandleIndicator(theme),
      volume: genVolumeIndicator(theme, paintMode: PaintMode.alone),
      ma: genMaIndicator(theme),
      time: genTimeIndicator(theme),
      macd: genMacdIndicator(theme),
      mavol: genMavolIndicator(theme),
    );
  }

  CandleIndicator genCandleIndicator(FKTheme theme) {
    return CandleIndicator(
      height: 0,
      padding: defaultMainIndicatorPadding,
      high: MarkConfig(
        spacing: 2,
        line: LineConfig(
          type: LineType.solid,
          color: theme.t1,
          length: 20.r,
          width: 0.5.r,
        ),
        text: TextAreaConfig(
          style: TextStyle(
            fontSize: theme.klineTextSize,
            color: theme.t1,
            overflow: TextOverflow.ellipsis,
            height: theme.klineTextHeight,
          ),
        ),
      ),
      low: MarkConfig(
        spacing: 2.r,
        line: LineConfig(
          type: LineType.solid,
          color: theme.t1,
          length: 20.r,
          width: 0.5.r,
        ),
        text: TextAreaConfig(
          style: TextStyle(
            fontSize: theme.klineTextSize,
            color: theme.t1,
            overflow: TextOverflow.ellipsis,
            height: theme.klineTextHeight,
          ),
        ),
      ),
      last: MarkConfig(
        show: true,
        spacing: 100.r,
        line: LineConfig(
          type: LineType.dashed,
          color: theme.t3,
          width: 0.5.r,
          dashes: [3, 3],
        ),
        text: TextAreaConfig(
          style: TextStyle(
            fontSize: theme.klineTextSize,
            color: theme.tlight,
            overflow: TextOverflow.ellipsis,
            height: theme.klineTextHeight,
            textBaseline: TextBaseline.alphabetic,
          ),
          background: theme.translucentBg,
          padding: EdgeInsets.symmetric(horizontal: 4.r, vertical: 2.r),
          border: BorderSide(color: theme.transparent),
          borderRadius: BorderRadius.all(Radius.circular(10.r)),
        ),
      ),
      latest: MarkConfig(
        show: true,
        spacing: 1.r,
        line: LineConfig(
          type: LineType.dashed,
          color: theme.t3,
          width: 0.5.r,
          dashes: [3, 3],
        ),
        text: TextAreaConfig(
          style: TextStyle(
            fontSize: theme.klineTextSize,
            color: Colors.white,
            overflow: TextOverflow.ellipsis,
            height: theme.klineTextHeight,
          ),
          minWidth: 45,
          textAlign: TextAlign.center,
          padding: defaultTextPading,
          borderRadius: BorderRadius.all(Radius.circular(2.r)),
        ),
      ),
      useCandleColorAsLatestBg: true,
      showCountDown: true,
      countDown: TextAreaConfig(
        style: TextStyle(
          fontSize: theme.klineTextSize,
          color: theme.t1,
          overflow: TextOverflow.ellipsis,
          height: theme.klineTextHeight,
        ),
        textAlign: TextAlign.center,
        background: theme.disable,
        padding: defaultTextPading,
        borderRadius: BorderRadius.all(Radius.circular(2.r)),
      ),
    );
  }

  TimeIndicator genTimeIndicator(FKTheme theme) {
    return TimeIndicator(
      height: defaultTimeIndicatorHeight,
      padding: EdgeInsets.zero,
      position: DrawPosition.middle,
      // 时间刻度.
      timeTick: TextAreaConfig(
        style: TextStyle(
          fontSize: theme.klineTextSize,
          color: theme.t2,
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
        textWidth: 80.r,
        textAlign: TextAlign.center,
      ),
    );
  }

  VolumeIndicator genVolumeIndicator(
    FKTheme theme, {
    required PaintMode paintMode,
    bool showYAxisTick = false,
    bool showCrossMark = false,
    bool showTips = false,
    bool useTint = true,
  }) {
    return VolumeIndicator(
      height: defaultSubIndicatorHeight,
      padding: defaultSubIndicatorPadding,
      paintMode: paintMode,

      /// 绘制相关参数
      volTips: TipsConfig(
        label: 'Vol: ',
        precision: 2,
        style: TextStyle(
          fontSize: theme.klineTextSize,
          color: theme.t1,
          overflow: TextOverflow.ellipsis,
          height: theme.klineTextHeight,
        ),
      ),
      tipsPadding: defaultTipsPadding,
      tickCount: defaultSubTickCount,
      precision: 2,

      /// 控制参数
      showYAxisTick: showYAxisTick,
      showCrossMark: showCrossMark,
      showTips: showTips,
      useTint: useTint,
    );
  }

  MAIndicator genMaIndicator(FKTheme theme) {
    return MAIndicator(
      height: 0,
    );
  }

  MACDIndicator genMacdIndicator(FKTheme theme) {
    return MACDIndicator(
      height: defaultSubIndicatorHeight,
      padding: defaultSubIndicatorPadding,

      /// Macd相关参数
      calcParam: const MACDParam(s: 12, l: 26, m: 9),

      /// 绘制相关参数
      difTips: TipsConfig(
        label: 'DIF: ',
        precision: 2,
        style: TextStyle(
          fontSize: theme.klineTextSize,
          color: const Color(0xFFDFBF47),
          overflow: TextOverflow.ellipsis,
          height: theme.klineTextHeight,
        ),
      ),
      deaTips: TipsConfig(
        label: 'DEA: ',
        precision: 2,
        style: TextStyle(
          fontSize: theme.klineTextSize,
          color: const Color(0xFF795583),
          overflow: TextOverflow.ellipsis,
          height: theme.klineTextHeight,
        ),
      ),
      macdTips: TipsConfig(
        label: 'MACD: ',
        precision: 2,
        style: TextStyle(
          fontSize: theme.klineTextSize,
          color: theme.t1,
          overflow: TextOverflow.ellipsis,
          height: theme.klineTextHeight,
        ),
      ),
      tipsPadding: defaultTipsPadding,
      tickCount: defaultSubTickCount,
      lineWidth: defaultIndicatorLineWidth,
      precision: 2,
    );
  }

  MAVolumeIndicator genMavolIndicator(FKTheme theme) {
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

  VolMaIndicator genVolMaIndicator(FKTheme theme) {
    return VolMaIndicator();
  }
}
