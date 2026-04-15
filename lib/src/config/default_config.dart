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
          const LineConfig(
            type: LineType.solid,
            dashes: [2, 2],
            paint: PaintConfig(
              strokeWidth: 0.5,
            ),
          ),
        ),
      ),
      vertical: GridAxis(
        show: grid?.vertical.show ?? true,
        count: grid?.vertical.count ?? 5,
        line: obtainConfig(
          grid?.vertical.line,
          const LineConfig(
            type: LineType.solid,
            dashes: [2, 2],
            paint: PaintConfig(
              strokeWidth: 0.5,
            ),
          ),
        ),
      ),
      isAllowDragIndicatorHeight: grid?.isAllowDragIndicatorHeight ?? false,
      dragHitTestMinDistance: grid?.dragHitTestMinDistance ?? 10,
      draggingBgOpacity: grid?.draggingBgOpacity ?? 0.1,
      dragBgOpacity: grid?.dragBgOpacity ?? 0,
      dragLine: obtainConfig(
        grid?.dragLine,
        const LineConfig(
          type: LineType.dashed,
          dashes: [3, 5],
          length: 20,
          paint: PaintConfig(
            strokeWidth: 5 * 0.5,
          ),
        ),
      ),
      dragLineOpacity: grid?.dragLineOpacity ?? 0.1,
      // 全局默认的刻度值配置.
      ticksText: obtainConfig(
        grid?.ticksText,
        const TextAreaConfig(
          style: TextStyle(
            fontSize: defaultTextSize,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
          textAlign: TextAlign.end,
          padding: EdgeInsets.symmetric(horizontal: 2),
        ),
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
      mainMinSize: setting?.mainMinSize ?? const Size(120, 80),
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
      const LoadingConfig(
        size: 24,
        strokeWidth: 4,
      ),
    );
  }

  CrossConfig genCrossConfig([CrossConfig? cross]) {
    return CrossConfig(
      enable: cross?.enable ?? true,

      /// 十字线
      crosshair: obtainConfig(
        cross?.crosshair,
        const LineConfig(
          paint: PaintConfig(
            strokeWidth: 0.5,
          ),
          type: LineType.dashed,
          dashes: [3, 3],
        ),
      ),

      /// 十字线坐标点配置
      crosspoint: obtainConfig(
        cross?.crosspoint,
        const PointConfig(
          radius: 2,
          width: 0,
          borderWidth: 3,
        ),
      ),

      /// 十字线实时Tips的样式配置.
      ticksText: obtainConfig(
        cross?.ticksText,
        const TextAreaConfig(
          style: TextStyle(
            fontSize: defaultTextSize,
            fontWeight: FontWeight.normal,
            height: defaultTipsTextHeight,
          ),
          padding: EdgeInsets.all(2),
          border: BorderSide.none,
          borderRadius: BorderRadius.all(
            Radius.circular(2),
          ),
          textAlign: TextAlign.end,
        ),
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
        const TooltipConfig(
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
            overflow: TextOverflow.ellipsis,
            height: defaultMultiTextHeight,
          ),
        ),
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
        const LineConfig(
          paint: PaintConfig(
            strokeWidth: 0.5,
          ),
          type: LineType.dashed,
          dashes: [5, 3],
        ),
      ),

      /// 指针点配置
      crosspoint: obtainConfig(
        draw?.crosspoint,
        const PointConfig(
          radius: 2,
          width: 0,
          borderWidth: 2,
        ),
      ),

      /// 默认绘制线的样式配置
      drawLine: obtainConfig(
        draw?.drawLine,
        const LineConfig(
          paint: PaintConfig(
            strokeWidth: 1,
          ),
          type: LineType.solid,
          dashes: [5, 3],
        ),
      ),

      /// 选择绘制点配置
      drawPoint: obtainConfig(
        draw?.drawPoint,
        const PointConfig(
          radius: 9,
          width: 0,
          borderWidth: 1,
        ),
      ),

      /// 刻度文案配置
      ticksText: obtainConfig(
        draw?.ticksText,
        const TextAreaConfig(
          style: TextStyle(
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
      ),
      spacing: draw?.spacing ?? 1,
      ticksGapBgOpacity: draw?.ticksGapBgOpacity ?? 0.1,
      hitTestMinDistance: draw?.hitTestMinDistance ?? 10,
      magnetMinDistance: draw?.magnetMinDistance ?? 10,
      magnifier: obtainConfig(
        draw?.magnifier,
        const MagnifierConfig(
          enable: true,
          magnificationScale: 2,
          margin: EdgeInsets.all(1),
          size: Size(80, 80),
          decorationOpacity: 1.0,
          shapeSide: BorderSide.none,
        ),
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
      padding: instance?.padding ?? const EdgeInsets.only(top: 5, bottom: 5),
      high: obtainConfig(
        instance?.high,
        const MarkConfig(
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
      ),
      low: obtainConfig(
        instance?.low,
        const MarkConfig(
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
      ),
      last: obtainConfig(
        instance?.last,
        const MarkConfig(
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
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight,
              textBaseline: TextBaseline.alphabetic,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 2,
            ),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      showLatestPoint: instance?.showLatestPoint ?? true,
      latestPoint: obtainConfig(
        instance?.latestPoint,
        const PointConfig(
          radius: 2,
          width: 0,
          borderWidth: 2,
        ),
      ),
      latest: obtainConfig(
        instance?.latest,
        const MarkConfig(
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
            border: BorderSide(width: 0.5),
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ),
      useCandleColorAsLatestBg: instance?.useCandleColorAsLatestBg ?? true,
      showCountDown: instance?.showCountDown ?? true,
      countDown: obtainConfig(
        instance?.countDown,
        const TextAreaConfig(
          style: TextStyle(
            fontSize: defaultTextSize,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
          textAlign: TextAlign.center,
          padding: EdgeInsets.all(2),
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
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
        const TextAreaConfig(
          style: TextStyle(
            fontSize: defaultTextSize,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
          textWidth: 80,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
