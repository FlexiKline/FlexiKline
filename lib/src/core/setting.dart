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

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../model/export.dart';
import 'binding_base.dart';
import 'interface.dart';

mixin SettingBinding on KlineBindingBase implements ISetting, IConfig {
  @override
  void init() {
    _settingConfig = SettingConfig.fromJson(settingConfigData);
    logd('init setting');
    super.init();
  }

  @override
  void initState() {
    super.initState();
    logd("initState setting");
  }

  @override
  void dispose() {
    super.dispose();
    logd("dispose setting");
  }

  @override
  void storeState() {
    super.storeState();
    logd("storeState setting");
    storeSettingData(settingConfig);
  }

  @override
  void loadConfig(Map<String, dynamic> configData) {
    logd("loadConfig setting");
    _settingConfig = SettingConfig.fromJson(configData);
    super.loadConfig(configData);
  }

  late SettingConfig _settingConfig;

  @override
  SettingConfig get settingConfig => _settingConfig;

  VoidCallback? onSizeChange;
  ValueChanged<bool>? onLoading;

  Color get longColor => settingConfig.longColor;
  Color get shortColor => settingConfig.shortColor;
  Color get longTintColor => settingConfig.longTintColor;
  Color get shortTintColor => settingConfig.shortTintColor;

  /// Loading配置
  double get loadingProgressSize => settingConfig.loadingProgressSize;
  double get loadingProgressStrokeWidth =>
      settingConfig.loadingProgressStrokeWidth;
  Color get loadingProgressBackgroundColor =>
      settingConfig.loadingProgressBackgroundColor;
  Color get loadingProgressValueColor =>
      settingConfig.loadingProgressValueColor;

  /// 一个像素的值.
  double get pixel {
    final mediaQuery = MediaQueryData.fromView(ui.window);
    return 1.0 / mediaQuery.devicePixelRatio;
  }

  /// 整个画布区域大小 = 由主图区域 + 副图区域
  Rect get canvasRect => Rect.fromLTRB(
        mainRect.left,
        mainRect.top,
        math.max(mainRectSize.width, subRectSize.width),
        mainRectSize.height + subRectSize.height,
      );
  double get canvasWidth => canvasRect.width;
  double get canvasHeight => canvasRect.height;

  /// 主图区域大小
  // Rect _mainRect = Rect.zero;
  Rect get mainRect => settingConfig.mainRect;
  Size get mainRectSize => Size(mainRect.width, mainRect.height);
  void setMainSize(Size size) {
    settingConfig.mainRect = Rect.fromLTRB(
      0,
      0,
      size.width,
      size.height,
    );
    updateMainIndicatorParam(height: size.height);
    onSizeChange?.call();
  }

  /// 主图总宽度
  double get mainRectWidth => mainRect.width;

  /// 主图总高度
  double get mainRectHeight => mainRect.height;

  /// 主图区域的tips高度
  // double get mainTipsHeight => settingConfig.mainTipsHeight;

  /// 主图上下padding
  EdgeInsets get mainPadding => settingConfig.mainPadding;

  Rect get mainDrawRect => Rect.fromLTRB(
        mainRect.left + mainPadding.left,
        mainRect.top + mainPadding.top,
        mainRect.right - mainPadding.right,
        mainRect.bottom - mainPadding.bottom,
      );

  /// X轴主绘制区域真实宽.
  double get mainDrawWidth => mainRectWidth - mainPadding.horizontal;

  /// Y轴主绘制区域真实高.
  double get mainDrawHeight => mainRectHeight - mainPadding.vertical;

  /// X轴上主绘制区域宽度的半值.
  double get mainDrawWidthHalf => mainDrawWidth / 2;

  /// X轴主绘制区域的左边界值
  double get mainDrawLeft => mainPadding.left;

  /// X轴主绘制区域右边界值
  double get mainDrawRight => mainRectWidth - mainPadding.right;

  /// Y轴主绘制区域上边界值
  double get mainDrawTop => mainPadding.top;

  /// Y轴主绘制区域下边界值
  double get mainDrawBottom => mainRectHeight - mainPadding.bottom;

  bool checkOffsetInMainRect(Offset offset) {
    return mainRect.contains(offset);
  }

  double clampDxInMain(double dx) => dx.clamp(mainDrawLeft, mainDrawRight);
  double clampDyInMain(double dy) => dy.clamp(mainDrawTop, mainDrawBottom);

  /// 绘制区域最少留白宽度.
  double get minPaintBlankWidth =>
      mainDrawWidth * settingConfig.minPaintBlankRate.clamp(0, 0.9);

  // Gesture Pan
  // 平移结束后, candle惯性平移, 持续的最长时间.
  @Deprecated('待优化')
  int panMaxDurationWhenPanEnd = 1000;
  // 平移结束后, candle惯性平移, 此时每一帧移动的最大偏移量. 值越大, 移动的会越远.
  double panMaxOffsetPreFrameWhenPanEnd = 30.0;

  /// 最大蜡烛宽度[1, 50]
  // double _candleMaxWidth = 40.0;
  double get candleMaxWidth => settingConfig.candleMaxWidth;
  set candleMaxWidth(double width) {
    settingConfig.candleMaxWidth = width.clamp(1.0, 50.0);
  }

  /// 单根蜡烛宽度
  // double _candleWidth = 8.0;
  double get candleWidth => settingConfig.candleWidth;
  set candleWidth(double width) {
    // 限制蜡烛宽度范围[1, candleMaxWidth]
    settingConfig.candleWidth = width.clamp(1.0, candleMaxWidth);
  }

  /// 蜡烛间距
  double get candleSpacing => settingConfig.candleSpacing;

  /// 单根蜡烛所占据实际宽度
  double get candleActualWidth => candleWidth + candleSpacing;

  /// 单根蜡烛的一半
  double get candleWidthHalf => candleActualWidth / 2;

  /// 绘制区域宽度内, 可绘制的蜡烛数
  int get maxCandleCount => (mainDrawWidth / candleActualWidth).ceil();

  // Candle 第一根Candle相对于mainRect右边的偏移
  double get firstCandleInitOffset => settingConfig.firstCandleInitOffset;

  /// 时间格式化函数
  // String Function(DateTime dateTime)? dateTimeFormat;
  // String formatDateTime(DateTime dateTime) {
  //   if (dateTimeFormat != null) {
  //     return dateTimeFormat!.call(dateTime);
  //   }
  //   return formatyyMMddHHMMss(dateTime);
  // }

  /// 定制展示Candle Card info.
  List<TooltipInfo> Function(CandleModel model)? customCandleCardInfo;

  ///////////////////////////////////////////
  /// 以下是副图的绘制配置 /////////////////////
  //////////////////////////////////////////
  /// 副图整个区域
  Rect get subRect => Rect.fromLTRB(
        mainRect.left,
        mainRect.bottom,
        mainRect.right,
        mainRect.bottom + subRectHeight,
      );

  /// 副图整个区域大小
  Size get subRectSize => Size(subRect.width, subRect.height);

  /// 副区的指标图最大数量
  int get subChartMaxCount => settingConfig.subChartMaxCount;
}
