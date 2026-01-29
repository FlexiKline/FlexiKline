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
import 'gradient_config/gradient_config.dart';
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
  EdgeInsets get textPadding => EdgeInsets.all(2 * scale);

  /// 默认指标线图的宽度
  double get indicatorLineWidth {
    return defaultIndicatorLineWidth * scale;
  }

  // 默认文本配置
  double get normalTextSize => setSp(defaultTextSize);
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
    required this.markLineColor,
    required this.lineChartColor,
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
  final Color markLineColor;
  @override
  final Color lineChartColor;

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
  FlexiKlineConfig generateFlexiKlineConfig([FlexiKlineConfig? origin]) {
    return FlexiKlineConfig(
      grid: genGridConfig(origin?.grid),
      setting: genSettingConfig(origin?.setting),
      gesture: genGestureConfig(origin?.gesture),
      cross: genCrossConfig(origin?.cross),
      draw: genDrawConfig(origin?.draw),
      mainIndicator: genMainIndicator(origin?.mainIndicator),
      sub: origin?.sub ?? {},
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
  Map<IIndicatorKey, IndicatorBuilder> get mainIndicatorBuilders => {};

  @override
  Map<IIndicatorKey, IndicatorBuilder> get subIndicatorBuilders => {};

  @override
  Map<IDrawType, DrawObjectBuilder> get drawObjectBuilders => {};

  /// Grid配置
  GridConfig genGridConfig([GridConfig? grid]) {
    return GridConfig(
      show: grid?.show ?? true,
      horizontal: GridAxis(
        show: grid?.horizontal.show ?? true,
        count: grid?.horizontal.count ?? 5,
        line: obtainConfig(
          grid?.horizontal.line,
          LineConfig(
            type: LineType.solid,
            dashes: const [2, 2],
            paint: PaintConfig(
              color: theme.gridLine,
              strokeWidth: theme.pixel,
            ),
          ),
        ).of(
          paintColor: theme.gridLine,
        ),
      ),
      vertical: GridAxis(
        show: grid?.vertical.show ?? true,
        count: grid?.vertical.count ?? 5,
        line: obtainConfig(
          grid?.vertical.line,
          LineConfig(
            type: LineType.solid,
            dashes: const [2, 2],
            paint: PaintConfig(
              color: theme.gridLine,
              strokeWidth: theme.pixel,
            ),
          ),
        ).of(
          paintColor: theme.gridLine,
        ),
      ),
      isAllowDragIndicatorHeight: grid?.isAllowDragIndicatorHeight ?? false,
      dragHitTestMinDistance: grid?.dragHitTestMinDistance ?? 10 * theme.scale,
      draggingBgOpacity: grid?.draggingBgOpacity ?? 0.1,
      dragBgOpacity: grid?.dragBgOpacity ?? 0,
      dragLine: obtainConfig(
        grid?.dragLine,
        LineConfig(
          type: LineType.dashed,
          dashes: const [3, 5],
          length: 20,
          paint: PaintConfig(
            color: theme.markLineColor,
            strokeWidth: theme.pixel * 5,
          ),
        ),
      ).of(
        paintColor: theme.markLineColor,
      ),
      dragLineOpacity: grid?.dragLineOpacity ?? 0.1,
      // 全局默认的刻度值配置.
      ticksText: obtainConfig(
        grid?.ticksText,
        TextAreaConfig(
          style: TextStyle(
            fontSize: theme.normalTextSize,
            color: theme.ticksTextColor,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
          textAlign: TextAlign.end,
          padding: EdgeInsets.symmetric(horizontal: 2 * theme.scale),
        ),
      ).of(
        textColor: theme.ticksTextColor,
        background: null,
        borderColor: null,
      ),
    );
  }

  /// Gesture配置
  GestureConfig genGestureConfig([GestureConfig? gesture]) {
    return GestureConfig(
      supportLongPress: gesture?.supportLongPress ?? true,
      isInertialPan: gesture?.isInertialPan ?? true,
      tolerance: gesture?.tolerance ?? ToleranceConfig(),
      loadMoreWhenNoEnoughDistance: gesture?.loadMoreWhenNoEnoughDistance,
      loadMoreWhenNoEnoughCandles: gesture?.loadMoreWhenNoEnoughCandles ?? 60,
      scalePosition: gesture?.scalePosition ?? ScalePosition.auto,
      scaleSpeed: gesture?.scaleSpeed ?? 10,
      supportKeyboardShortcuts: gesture?.supportKeyboardShortcuts ?? true,
      enableZoom: gesture?.enableZoom ?? false,
      zoomStartMinDistance: gesture?.zoomStartMinDistance ?? 5,
      zoomSpeed: gesture?.zoomSpeed ?? 1,
    );
  }

  SettingConfig genSettingConfig([SettingConfig? setting]) {
    return SettingConfig(
      opacity: setting?.opacity ?? 0.5,

      /// 内置LoadingView样式配置
      loading: genInnerLoadingConfig(setting?.loading),

      /// 主区域最小Size
      mainMinSize: setting?.mainMinSize ?? Size(120 * theme.scale, 80 * theme.scale),
      subMinHeight: setting?.subMinHeight ?? 30 * theme.scale,

      /// 主/副图绘制参数
      minPaintBlankRate: setting?.minPaintBlankRate ?? 0.5,
      alwaysCalculateScreenOfCandlesIfEnough: setting?.alwaysCalculateScreenOfCandlesIfEnough ?? false,
      candleMinWidth: setting?.candleMinWidth ?? 1 * theme.pixel,
      candleMaxWidth: setting?.candleMaxWidth ?? 40 * theme.scale,
      candleWidth: setting?.candleWidth ?? 7 * theme.scale,
      candleSpacingParts: setting?.candleSpacingParts ?? 7,
      candleFixedSpacing: setting?.candleFixedSpacing ?? 1 * theme.scale,
      candleHollowBarBorderWidth: setting?.candleHollowBarBorderWidth ?? 1 * theme.scale,
      candleLineWidth: setting?.candleLineWidth ?? 1 * theme.scale,
      firstCandleInitOffset: setting?.firstCandleInitOffset ?? 80 * theme.scale,

      /// 绘制额外内容是否在允许在主图绘制区域之外
      allowPaintExtraOutsideMainRect: setting?.allowPaintExtraOutsideMainRect ?? true,

      /// 是否展示Y轴刻度.
      showYAxisTick: setting?.showYAxisTick ?? true,
    );
  }

  LoadingConfig genInnerLoadingConfig([LoadingConfig? loading]) {
    return obtainConfig(
      loading,
      LoadingConfig(
        size: 24 * theme.scale,
        strokeWidth: 4 * theme.scale,
        background: theme.tooltipBg,
        valueColor: theme.textColor,
      ),
    ).of(
      valueColor: theme.textColor,
      background: theme.tooltipBg,
    );
  }

  CrossConfig genCrossConfig([CrossConfig? cross]) {
    return CrossConfig(
      enable: cross?.enable ?? true,

      /// 十字线
      crosshair: obtainConfig(
        cross?.crosshair,
        LineConfig(
          paint: PaintConfig(
            color: theme.crossColor,
            strokeWidth: 0.5 * theme.scale,
          ),
          type: LineType.dashed,
          dashes: const [3, 3],
        ),
      ).of(
        paintColor: theme.crossColor,
      ),

      /// 十字线坐标点配置
      crosspoint: obtainConfig(
        cross?.crosspoint,
        PointConfig(
          radius: 2 * theme.scale,
          width: 0 * theme.scale,
          color: theme.crossColor,
          borderWidth: 3 * theme.scale,
          borderColor: theme.crossColor.withAlpha(0.2.alpha),
        ),
      ).of(
        color: theme.crossColor,
        borderColor: theme.crossColor.withAlpha(0.2.alpha),
      ),

      /// 十字线实时Tips的样式配置.
      ticksText: obtainConfig(
        cross?.ticksText,
        TextAreaConfig(
          style: TextStyle(
            color: theme.crossTextColor,
            fontSize: theme.normalTextSize,
            fontWeight: FontWeight.normal,
            height: defaultTipsTextHeight,
          ),
          background: theme.crossTextBg,
          padding: EdgeInsets.all(2 * theme.scale),
          border: BorderSide.none,
          borderRadius: BorderRadius.all(
            Radius.circular(2 * theme.scale),
          ),
          textAlign: TextAlign.end,
        ),
      ).of(
        textColor: theme.crossTextColor,
        background: theme.crossTextBg,
        borderColor: null,
      ),

      /// onCross时, 刻度[ticksText]与绘制边界的间距.
      spacing: cross?.spacing ?? 1 * theme.scale,

      /// onCross时, 当移动到空白区域时, Tips区域是否展示最新的蜡烛的Tips数据.
      showLatestTipsInBlank: cross?.showLatestTipsInBlank ?? true,

      /// onCross时, 当移动到空白区域时, 是否继续按蜡烛宽度移动.
      moveByCandleInBlank: cross?.moveByCandleInBlank ?? false,

      /// tooltip 区域样式设置
      tooltipConfig: obtainConfig(
        cross?.tooltipConfig,
        TooltipConfig(
          show: true,
          // tooltip 区域设置
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
        ),
      ).of(
        textColor: theme.tooltipTextColor,
      ),
    );
  }

  DrawConfig genDrawConfig([DrawConfig? draw]) {
    return DrawConfig(
      enable: draw?.enable ?? false,

      /// 当绘制状态是退出时, 是否允许选择已绘制的Overlay.
      allowSelectWhenExit: draw?.allowSelectWhenExit ?? true,

      /// 绘制指针十字线配置
      crosshair: obtainConfig(
        draw?.crosshair,
        LineConfig(
          paint: PaintConfig(
            strokeWidth: 0.5 * theme.scale,
            color: theme.drawColor,
          ),
          type: LineType.dashed,
          dashes: const [5, 3],
        ),
      ).of(
        paintColor: theme.drawColor,
      ),

      /// 指针点配置
      crosspoint: obtainConfig(
        draw?.crosspoint,
        PointConfig(
          radius: 2 * theme.scale,
          width: 0 * theme.scale,
          color: theme.drawColor,
          borderWidth: 2 * theme.scale,
          borderColor: theme.drawColor.withAlpha(0.5.alpha),
        ),
      ).of(
        color: theme.drawColor,
        borderColor: theme.drawColor.withAlpha(0.5.alpha),
      ),

      /// 默认绘制线的样式配置
      drawLine: obtainConfig(
        draw?.drawLine,
        LineConfig(
          paint: PaintConfig(
            strokeWidth: 1 * theme.scale,
            color: theme.drawColor, // 必须指定
          ),
          type: LineType.solid,
          dashes: [5, 3],
        ),
      ).of(
        paintColor: theme.drawColor,
      ),

      /// 选择绘制点配置
      drawPoint: obtainConfig(
        draw?.drawPoint,
        PointConfig(
          radius: 9 * theme.scale,
          width: 0 * theme.scale,
          color: const Color(0xFFFFFFFF), // 必须指定
          borderWidth: 1 * theme.scale,
          borderColor: theme.drawColor,
        ),
      ).of(
        color: const Color(0xFFFFFFFF),
        borderColor: theme.drawColor,
      ),

      /// 刻度文案配置
      ticksText: obtainConfig(
        draw?.ticksText,
        TextAreaConfig(
          style: TextStyle(
            color: const Color(0xFFFFFFFF), // 必须指定
            fontSize: theme.normalTextSize,
            fontWeight: FontWeight.normal,
            height: defaultTextHeight,
          ),
          padding: EdgeInsets.all(2 * theme.scale),
          border: null, // BorderSide.none,
          borderRadius: BorderRadius.all(
            Radius.circular(2 * theme.scale),
          ),
        ),
      ).of(
        textColor: const Color(0xFFFFFFFF),
        background: null,
        borderColor: null,
      ),
      spacing: draw?.spacing ?? 1 * theme.scale,
      ticksGapBgOpacity: draw?.ticksGapBgOpacity ?? 0.1,
      hitTestMinDistance: draw?.hitTestMinDistance ?? 10 * theme.scale,
      magnetMinDistance: draw?.magnetMinDistance ?? 10 * theme.scale,
      magnifier: obtainConfig(
        draw?.magnifier,
        MagnifierConfig(
          enable: true,
          magnificationScale: 2,
          margin: EdgeInsets.all(1 * theme.scale),
          size: Size(80 * theme.scale, 80 * theme.scale),
          decorationOpacity: 1.0,
          decorationShadows: [
            BoxShadow(
              offset: const Offset(0.1, 0.1),
              blurRadius: 2,
              spreadRadius: 3,
              color: theme.themeColor.withAlpha(0.1.alpha), // 此处不适配Theme
            )
          ],
          shapeSide: BorderSide(
            color: theme.gridLine,
            width: 1 * theme.scale,
          ),
        ),
      ).of(
        sideColor: theme.gridLine,
      ),
    );
  }

  MainPaintObjectIndicator genMainIndicator(
    MainPaintObjectIndicator<PaintObjectIndicator>? mainIndicator,
  );

  CandleIndicator genCandleIndicator(CandleIndicator? instance) {
    return CandleIndicator(
      zIndex: instance?.zIndex ?? -1,
      height: instance?.height ?? theme.mainIndicatorHeight,
      padding: instance?.padding ?? theme.mainIndicatorPadding,
      high: obtainConfig(
        instance?.high,
        MarkConfig(
          spacing: 2 * theme.scale,
          line: LineConfig(
            type: LineType.solid,
            length: 20 * theme.scale,
            paint: PaintConfig(
              color: theme.markLineColor,
              strokeWidth: 0.5 * theme.scale,
            ),
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
      ).of(
        paintColor: theme.markLineColor,
        textColor: theme.textColor,
        background: instance?.high.text.background,
        borderColor: instance?.high.text.border?.color,
      ),
      low: obtainConfig(
        instance?.low,
        MarkConfig(
          spacing: 2 * theme.scale,
          line: LineConfig(
            type: LineType.solid,
            length: 20 * theme.scale,
            paint: PaintConfig(
              color: theme.markLineColor,
              strokeWidth: 0.5 * theme.scale,
            ),
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
      ).of(
        paintColor: theme.markLineColor,
        textColor: theme.textColor,
        background: instance?.low.text.background,
        borderColor: instance?.low.text.border?.color,
      ),
      last: obtainConfig(
        instance?.last,
        MarkConfig(
          show: true,
          spacing: 1 * theme.scale,
          line: LineConfig(
            type: LineType.dashed,
            dashes: [3, 3],
            paint: PaintConfig(
              color: theme.markLineColor, // 如果指定颜色透明度为0 且useCandleColorAsLatestBg为true,则会采用涨跌色
              strokeWidth: 0.5 * theme.scale,
            ),
          ),
          hitTestMargin: 4,
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
            // border: BorderSide(color: theme.transparent),
            borderRadius: BorderRadius.all(Radius.circular(10 * theme.scale)),
          ),
        ),
      ).of(
        paintColor: theme.markLineColor,
        textColor: theme.lastPriceTextColor,
        background: theme.lastPriceTextBg,
        borderColor: instance?.high.text.border?.color,
      ),
      showLatestPoint: instance?.showLatestPoint ?? true,
      latestPoint: obtainConfig(
        instance?.latestPoint,
        PointConfig(
          radius: 2 * theme.scale,
          width: 0 * theme.scale,
          color: theme.lineChartColor,
          borderColor: theme.lineChartColor.withAlpha(0.5.alpha),
          borderWidth: 2 * theme.scale,
        ),
      ).of(
        color: theme.lineChartColor,
        borderColor: theme.lineChartColor.withAlpha(0.5.alpha),
      ),
      latest: obtainConfig(
        instance?.latest,
        MarkConfig(
          show: true,
          spacing: 1 * theme.scale,
          line: LineConfig(
            type: LineType.dashed,
            dashes: [3, 3],
            paint: PaintConfig(
              // color: theme.markLineColor, // 如果指定颜色透明度为0 且useCandleColorAsLatestBg为true,则会采用涨跌色
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
            // minWidth: 45 * theme.scale,
            textAlign: TextAlign.center,
            padding: theme.textPadding,
            background: theme.latestPriceTextBg,
            border: BorderSide(
              color: theme.markLineColor,
              width: 0.5 * theme.scale,
            ),
            borderRadius: BorderRadius.all(Radius.circular(2 * theme.scale)),
          ),
        ),
      ).of(
        // paintColor: theme.markLineColor,
        textColor: theme.textColor,
        background: theme.latestPriceTextBg,
        borderColor: theme.markLineColor,
      ),
      useCandleColorAsLatestBg: instance?.useCandleColorAsLatestBg ?? true,
      showCountDown: instance?.showCountDown ?? true,
      countDown: obtainConfig(
        instance?.countDown,
        TextAreaConfig(
          style: TextStyle(
            fontSize: theme.normalTextSize,
            color: theme.textColor,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
          textAlign: TextAlign.center,
          padding: theme.textPadding,
          background: theme.countDownTextBg,
          border: BorderSide(
            color: theme.markLineColor,
            width: 0.5 * theme.scale,
          ),
          borderRadius: BorderRadius.all(Radius.circular(2 * theme.scale)),
        ),
      ).of(
        textColor: theme.textColor,
        background: theme.countDownTextBg,
        borderColor: theme.markLineColor,
      ),
      chartType: instance?.chartType ?? FlexiChartType.barSolid,
      minWidthLineType: instance?.minWidthLineType,
      timeBarChartTypes: instance?.timeBarChartTypes ?? const {TimeBar.m1: FlexiChartType.lineNormal},
      hideIndicatorsWhenLineChart: instance?.hideIndicatorsWhenLineChart ?? true,
      longColor: instance?.longColor,
      shortColor: instance?.shortColor,
      lineColor: instance?.lineColor,
      lineGradientConfig: instance?.lineGradientConfig ?? GradientPresets.lineChart,
      longGradientConfig: instance?.longGradientConfig ?? GradientPresets.long,
      shortGradientConfig: instance?.shortGradientConfig ?? GradientPresets.short,
    );
  }

  TimeIndicator genTimeIndicator(TimeIndicator? instance) {
    return TimeIndicator(
      height: instance?.height ?? theme.timeIndicatorHeight,
      padding: instance?.padding ?? EdgeInsets.zero,
      position: instance?.position ?? DrawPosition.middle,
      // 时间刻度.
      timeTick: obtainConfig(
        instance?.timeTick,
        TextAreaConfig(
          style: TextStyle(
            fontSize: theme.normalTextSize,
            color: theme.ticksTextColor,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
          textWidth: 80 * theme.scale,
          textAlign: TextAlign.center,
        ),
      ).of(
        textColor: theme.ticksTextColor,
        background: null,
        borderColor: null,
      ),
    );
  }
}
