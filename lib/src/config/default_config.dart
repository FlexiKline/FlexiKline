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
import '../extension/basic_type_ext.dart';
import '../extension/render/types.dart';
import '../framework/export.dart';
import '../indicators/export.dart';
import 'cross_config/cross_config.dart';
import 'draw_config/draw_config.dart';
import 'flexi_kline_config/flexi_kline_config.dart';
import 'gesture_config/gesture_config.dart';
import 'gradient_config/gradient_config.dart';
import 'grid_config/grid_config.dart';
import 'line_config/line_config.dart';
import 'loading_config/loading_config.dart';
import 'magnifier_config/magnifier_config.dart';
import 'mark_config/mark_config.dart';
import 'paint_config/paint_config.dart';
import 'point_config/point_config.dart';
import 'setting_config/setting_config.dart';
import 'text_area_config/text_area_config.dart';
import 'tolerance_config/tolerance_config.dart';
import 'tooltip_config/tooltip_config.dart';

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
              strokeWidth: 0.5,
            ),
          ),
        ).of(
          paintColor: theme.gridLineColor,
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
              strokeWidth: 0.5,
            ),
          ),
        ).of(
          paintColor: theme.gridLineColor,
        ),
      ),
      isAllowDragIndicatorHeight: grid?.isAllowDragIndicatorHeight ?? false,
      dragHitTestMinDistance: grid?.dragHitTestMinDistance ?? 10,
      draggingBgOpacity: grid?.draggingBgOpacity ?? 0.1,
      dragBgOpacity: grid?.dragBgOpacity ?? 0,
      dragLine: obtainConfig(
        grid?.dragLine,
        LineConfig(
          type: LineType.dashed,
          dashes: const [3, 5],
          length: 20,
          paint: PaintConfig(
            strokeWidth: 5 * 0.5,
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
            fontSize: defaultTextSize,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
          textAlign: TextAlign.end,
          padding: EdgeInsets.symmetric(horizontal: 2),
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
      enableLongPress: gesture?.enableLongPress ?? true,
      enableInertialPan: gesture?.enableInertialPan ?? true,
      tolerance: gesture?.tolerance ?? ToleranceConfig(),
      loadMoreWhenNoEnoughDistance: gesture?.loadMoreWhenNoEnoughDistance,
      loadMoreWhenNoEnoughCandles: gesture?.loadMoreWhenNoEnoughCandles ?? 60,
      enableScale: gesture?.enableScale ?? true,
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
      mainMinSize: setting?.mainMinSize ?? Size(120, 80),
      subMinHeight: setting?.subMinHeight ?? 30,

      /// 主/副图绘制参数
      minPaintBlankRate: setting?.minPaintBlankRate ?? 0.5,
      alwaysCalculateScreenOfCandlesIfEnough: setting?.alwaysCalculateScreenOfCandlesIfEnough ?? false,
      candleMinWidth: setting?.candleMinWidth ?? 0.5,
      candleMaxWidth: setting?.candleMaxWidth ?? 40,
      candleWidth: setting?.candleWidth ?? 7,
      candleSpacingParts: setting?.candleSpacingParts ?? 7,
      candleFixedSpacing: setting?.candleFixedSpacing ?? 1,
      candleHollowBarBorderWidth: setting?.candleHollowBarBorderWidth ?? 1,
      candleLineWidth: setting?.candleLineWidth ?? 1,
      firstCandleInitOffset: setting?.firstCandleInitOffset ?? 80,

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
        size: 24,
        strokeWidth: 4,
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
            strokeWidth: 0.5,
          ),
          type: LineType.dashed,
          dashes: const [3, 3],
        ),
      ).of(
        paintColor: theme.crosshairColor,
      ),

      /// 十字线坐标点配置
      crosspoint: obtainConfig(
        cross?.crosspoint,
        PointConfig(
          radius: 2,
          width: 0,
          color: theme.crosshairColor,
          borderWidth: 3,
          borderColor: theme.crosshairColor.withAlpha(0.2.alpha),
        ),
      ).of(
        color: theme.crosshairColor,
        borderColor: theme.crosshairColor.withAlpha(0.2.alpha),
      ),

      /// 十字线实时Tips的样式配置.
      ticksText: obtainConfig(
        cross?.ticksText,
        TextAreaConfig(
          style: TextStyle(
            color: theme.crossTextColor,
            fontSize: defaultTextSize,
            fontWeight: FontWeight.normal,
            height: defaultTipsTextHeight,
          ),
          background: theme.crossTextBg,
          padding: EdgeInsets.all(2),
          border: BorderSide.none,
          borderRadius: BorderRadius.all(
            Radius.circular(2),
          ),
          textAlign: TextAlign.end,
        ),
      ).of(
        textColor: theme.crossTextColor,
        background: theme.crossTextBg,
        borderColor: null,
      ),

      /// onCross时, 刻度[ticksText]与绘制边界的间距.
      spacing: cross?.spacing ?? 1,

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
            left: 15,
            right: 65,
            top: 10,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          radius: BorderRadius.all(Radius.circular(4)),

          /// tooltip 文本设置
          style: TextStyle(
            fontSize: defaultTextSize,
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
            strokeWidth: 0.5,
          ),
          type: LineType.dashed,
          dashes: const [5, 3],
        ),
      ).of(
        paintColor: theme.drawToolColor,
      ),

      /// 指针点配置
      crosspoint: obtainConfig(
        draw?.crosspoint,
        PointConfig(
          radius: 2,
          width: 0,
          color: theme.drawToolColor,
          borderWidth: 2,
          borderColor: theme.drawToolColor.withAlpha(0.5.alpha),
        ),
      ).of(
        color: theme.drawToolColor,
        borderColor: theme.drawToolColor.withAlpha(0.5.alpha),
      ),

      /// 默认绘制线的样式配置
      drawLine: obtainConfig(
        draw?.drawLine,
        LineConfig(
          paint: PaintConfig(
            strokeWidth: 1,
          ),
          type: LineType.solid,
          dashes: [5, 3],
        ),
      ).of(
        paintColor: theme.drawToolColor,
      ),

      /// 选择绘制点配置
      drawPoint: obtainConfig(
        draw?.drawPoint,
        PointConfig(
          radius: 9,
          width: 0,
          color: const Color(0xFFFFFFFF), // 必须指定
          borderWidth: 1,
          borderColor: theme.drawToolColor,
        ),
      ).of(
        color: const Color(0xFFFFFFFF),
        borderColor: theme.drawToolColor,
      ),

      /// 刻度文案配置
      ticksText: obtainConfig(
        draw?.ticksText,
        TextAreaConfig(
          style: TextStyle(
            color: const Color(0xFFFFFFFF), // 必须指定
            fontSize: defaultTextSize,
            fontWeight: FontWeight.normal,
            height: defaultTextHeight,
          ),
          padding: EdgeInsets.all(2),
          border: null,
          borderRadius: BorderRadius.all(
            Radius.circular(2),
          ),
        ),
      ).of(
        textColor: const Color(0xFFFFFFFF),
        background: null,
        borderColor: null,
      ),
      spacing: draw?.spacing ?? 1,
      ticksGapBgOpacity: draw?.ticksGapBgOpacity ?? 0.1,
      hitTestMinDistance: draw?.hitTestMinDistance ?? 10,
      magnetMinDistance: draw?.magnetMinDistance ?? 10,
      magnifier: obtainConfig(
        draw?.magnifier,
        MagnifierConfig(
          enable: true,
          magnificationScale: 2,
          margin: EdgeInsets.all(1),
          size: Size(80, 80),
          decorationOpacity: 1.0,
          decorationShadows: [
            BoxShadow(
              offset: const Offset(0.1, 0.1),
              blurRadius: 2,
              spreadRadius: 3,
              color: theme.gridLineColor.withAlpha(0.1.alpha), // 用 gridLineColor 替代已移除的 themeColor
            )
          ],
          shapeSide: BorderSide(
            color: theme.gridLineColor,
            width: 1,
          ),
        ),
      ).of(
        sideColor: theme.gridLineColor,
      ),
    );
  }

  MainPaintObjectIndicator genMainIndicator(
    MainPaintObjectIndicator<Indicator>? mainIndicator,
  );

  CandleIndicator genCandleIndicator(CandleIndicator? instance) {
    return CandleIndicator(
      zIndex: instance?.zIndex ?? -1,
      height: instance?.height ?? defaultMainIndicatorHeight,
      padding: instance?.padding ?? EdgeInsets.only(top: 5, bottom: 5),
      high: obtainConfig(
        instance?.high,
        MarkConfig(
          spacing: 2,
          line: LineConfig(
            type: LineType.solid,
            length: 20,
            paint: PaintConfig(
              strokeWidth: 0.5,
            ),
          ),
          text: TextAreaConfig(
            style: TextStyle(
              fontSize: defaultTextSize,
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
          spacing: 2,
          line: LineConfig(
            type: LineType.solid,
            length: 20,
            paint: PaintConfig(
              strokeWidth: 0.5,
            ),
          ),
          text: TextAreaConfig(
            style: TextStyle(
              fontSize: defaultTextSize,
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
          spacing: 1,
          line: LineConfig(
            type: LineType.dashed,
            dashes: [3, 3],
            paint: PaintConfig(
              strokeWidth: 0.5,
            ),
          ),
          hitTestMargin: 4,
          text: TextAreaConfig(
            style: TextStyle(
              fontSize: defaultTextSize,
              color: theme.lastPriceColor,
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight,
              textBaseline: TextBaseline.alphabetic,
            ),
            background: theme.lastPriceBg,
            padding: EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 2,
            ),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ).of(
        paintColor: theme.markLineColor,
        textColor: theme.lastPriceColor,
        background: theme.lastPriceBg,
        borderColor: instance?.high.text.border?.color,
      ),
      showLatestPoint: instance?.showLatestPoint ?? true,
      latestPoint: obtainConfig(
        instance?.latestPoint,
        PointConfig(
          radius: 2,
          width: 0,
          color: theme.lineChartColor,
          borderColor: theme.lineChartColor.withAlpha(0.5.alpha),
          borderWidth: 2,
        ),
      ).of(
        color: theme.lineChartColor,
        borderColor: theme.lineChartColor.withAlpha(0.5.alpha),
      ),
      latest: obtainConfig(
        instance?.latest,
        MarkConfig(
          show: true,
          spacing: 1,
          line: LineConfig(
            type: LineType.dashed,
            dashes: [3, 3],
            paint: PaintConfig(
              strokeWidth: 0.5,
            ),
          ),
          text: TextAreaConfig(
            style: TextStyle(
              fontSize: defaultTextSize,
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight,
            ),
            textAlign: TextAlign.center,
            padding: EdgeInsets.all(2),
            background: theme.latestPriceBg,
            border: BorderSide(
              color: theme.markLineColor,
              width: 0.5,
            ),
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ).of(
        textColor: theme.textColor,
        background: theme.latestPriceBg,
        borderColor: theme.markLineColor,
      ),
      useCandleColorAsLatestBg: instance?.useCandleColorAsLatestBg ?? true,
      showCountDown: instance?.showCountDown ?? true,
      countDown: obtainConfig(
        instance?.countDown,
        TextAreaConfig(
          style: TextStyle(
            fontSize: defaultTextSize,
            color: theme.textColor,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
          textAlign: TextAlign.center,
          padding: EdgeInsets.all(2),
          background: theme.countDownBg,
          border: BorderSide(
            color: theme.markLineColor,
            width: 0.5,
          ),
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ).of(
        textColor: theme.textColor,
        background: theme.countDownBg,
        borderColor: theme.markLineColor,
      ),
      chartType: instance?.chartType ?? FlexiChartType.barSolid,
      minWidthLineType: instance?.minWidthLineType,
      intervalChartTypes: instance?.intervalChartTypes ?? {interval1m: FlexiChartType.lineNormal},
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
      height: instance?.height ?? defaultTimeIndicatorHeight,
      padding: instance?.padding ?? EdgeInsets.zero,
      position: instance?.position ?? DrawPosition.middle,
      // 时间刻度.
      timeTick: obtainConfig(
        instance?.timeTick,
        TextAreaConfig(
          style: TextStyle(
            fontSize: defaultTextSize,
            color: theme.ticksTextColor,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
          textWidth: 80,
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
