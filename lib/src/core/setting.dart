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

  /// Loading配置
  LoadingConfig get loading => settingConfig.loading;

  /// 一个像素的值.
  double get pixel {
    final mediaQuery = MediaQueryData.fromView(ui.window);
    return 1.0 / mediaQuery.devicePixelRatio;
  }

  /// 整个画布区域大小 = 由主图区域 + 副图区域
  Rect get canvasRect => Rect.fromLTRB(
        mainRect.left,
        mainRect.top,
        math.max(mainRect.width, subRect.width),
        mainRect.height + subRect.height,
      );
  double get canvasWidth => canvasRect.width;
  double get canvasHeight => canvasRect.height;

  /// 副图整个区域
  Rect get subRect => Rect.fromLTRB(
        mainRect.left,
        mainRect.bottom,
        mainRect.right,
        mainRect.bottom + subRectHeight,
      );

  /// 副区的指标图最大数量
  int get subChartMaxCount => settingConfig.subChartMaxCount;

  /// 主区域大小
  Rect get mainRect => settingConfig.mainRect;

  /// 主区域最小大小
  Size get mainMinSize => settingConfig.mainMinSize;

  /// 主区域大小设置
  void setMainSize(Size size) {
    if (size >= settingConfig.mainMinSize) {
      settingConfig.mainRect = Rect.fromLTRB(
        0,
        0,
        size.width,
        size.height,
      );
      updateMainIndicatorParam(height: size.height);
      onSizeChange?.call();
    }
  }

  // 主区总宽度
  double get mainRectWidth => mainRect.width;

  /// 主区总高度
  double get mainRectHeight => mainRect.height;

  /// 主区padding
  EdgeInsets get mainPadding => settingConfig.mainPadding;

  Rect get mainChartRect => Rect.fromLTRB(
        mainRect.left + mainPadding.left,
        mainRect.top + mainPadding.top,
        mainRect.right - mainPadding.right,
        mainRect.bottom - mainPadding.bottom,
      );

  /// 主图区域宽.
  double get mainChartWidth => mainChartRect.width;

  /// 主图区域高.
  double get mainChartHeight => mainChartRect.height;

  /// 主图区域宽度的半值.
  double get mainChartWidthHalf => mainChartWidth / 2;

  /// 主图区域左边界值
  double get mainChartLeft => mainChartRect.left;

  /// 主图区域右边界值
  double get mainChartRight => mainChartRect.right;

  /// 主图区域上边界值
  double get mainChartTop => mainChartRect.top;

  /// 主图区域下边界值
  double get mainChartBottom => mainChartRect.bottom;

  /// 主图区域最少留白宽度.
  double get minPaintBlankWidth {
    return mainChartWidth * settingConfig.minPaintBlankRate.clamp(0, 0.9);
  }

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
  int get maxCandleCount => (mainChartWidth / candleActualWidth).ceil();
}
