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

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/export.dart';
import '../constant.dart';
import '../framework/export.dart';
import 'binding_base.dart';
import 'interface.dart';

class FlexiKlineSizeNotifier extends ValueNotifier<Rect> {
  FlexiKlineSizeNotifier(super.value);

  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}

mixin SettingBinding on KlineBindingBase implements ISetting, IChart, ICross {
  @override
  void initState() {
    super.initState();
    logd("initState setting");
    initFlexiKlineState();
  }

  @override
  void dispose() {
    super.dispose();
    logd("dispose setting");
    sizeChangeListener.dispose();
    mainIndicator.dispose();
    for (var indicator in subRectIndicators) {
      indicator.dispose();
    }
    subRectIndicators.clear();
  }

  /// KlineData整个图表区域大小变化监听器
  final sizeChangeListener = FlexiKlineSizeNotifier(defaultCanvasRectMinRect);
  void invokeSizeChanged() {
    if (_landCanvasRect != null) {
      final changed = updateMainIndicatorParam(height: mainRect.height);
      if (!changed) markRepaintChart();
      sizeChangeListener.value = canvasRect;
      sizeChangeListener.notifyListeners();
    }
    if (sizeChangeListener.value != canvasRect) {
      final changed = updateMainIndicatorParam(height: mainRect.height);
      if (!changed) markRepaintChart();
      sizeChangeListener.value = canvasRect;
    }
    markRepaintCross();
  }

  Rect? _landCanvasRect;

  /// 整个画布区域大小 = 由主图区域 + 副图区域
  @override
  Rect get canvasRect {
    if (_landCanvasRect != null) {
      return _landCanvasRect!;
    }
    return Rect.fromLTRB(
      mainRect.left,
      mainRect.top,
      math.max(mainRect.width, subRect.width),
      mainRect.height + subRectHeight,
    );
  }

  double get canvasWidth => canvasRect.width;
  double get canvasHeight => canvasRect.height;

  /// 副图整个区域
  @override
  Rect get subRect {
    if (_landCanvasRect != null) {
      return Rect.fromLTRB(
        _landCanvasRect!.left,
        _landCanvasRect!.bottom - subRectHeight,
        _landCanvasRect!.right,
        _landCanvasRect!.bottom,
      );
    }
    return Rect.fromLTRB(
      mainRect.left,
      mainRect.bottom,
      mainRect.right,
      mainRect.bottom + subRectHeight,
    );
  }

  /// 主区域大小
  @override
  Rect get mainRect {
    if (_landCanvasRect != null) {
      return Rect.fromLTRB(
        _landCanvasRect!.left,
        _landCanvasRect!.top,
        _landCanvasRect!.right,
        _landCanvasRect!.bottom - subRectHeight,
      );
    }
    return settingConfig.mainRect;
  }

  /// 主区域最小宽高
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
      invokeSizeChanged();
    }
  }

  /// 设置横屏的Kline的大小
  /// [size] 当前Kline主区+副区的大小.
  /// 注: 设置是临时的, 并不会更新到配置中.
  void setLandCanvasSize(Size size) {
    if (size >= settingConfig.mainMinSize) {
      _landCanvasRect = Rect.fromLTRB(
        0,
        0,
        size.width,
        size.height,
      );
      invokeSizeChanged();
    }
  }

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

  /// 主图区域最少留白宽度比例.
  double get minPaintBlankWidth {
    return mainChartWidth * settingConfig.minPaintBlankRate.clamp(0, 0.9);
  }

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

  /// 蜡烛间距  // TODO: 待优化
  double get candleSpacing => settingConfig.candleSpacing;

  /// 单根蜡烛所占据实际宽度
  double get candleActualWidth => candleWidth + candleSpacing;

  /// 单根蜡烛的一半
  double get candleWidthHalf => candleActualWidth / 2;

  /// 绘制区域宽度内, 可绘制的蜡烛数
  int get maxCandleCount => (mainChartWidth / candleActualWidth).ceil();

  Set<ValueKey> get supportMainIndicatorKeys {
    return indicatorsConfig.mainIndicators.keys.toSet()..remove(candleKey);
  }

  Set<ValueKey> get supportSubIndicatorKeys {
    return indicatorsConfig.subIndicators.keys.toSet()..remove(timeKey);
  }

  Set<ValueKey> get mainIndicatorKeys {
    return mainIndicator.children.map((e) => e.key).toSet();
  }

  Set<ValueKey> get subIndicatorKeys {
    return subRectIndicators.map((e) => e.key).toSet();
  }

  @protected
  @override
  MultiPaintObjectIndicator get mainIndicator {
    return _flexiKlineConfig.mainIndicator;
  }

  Queue<Indicator> get subIndicators {
    return _flexiKlineConfig.subIndicators;
  }

  @protected
  @override
  List<Indicator> get subRectIndicators {
    if (indicatorsConfig.time.position == DrawPosition.bottom) {
      return [...subIndicators, indicatorsConfig.time];
    } else {
      return [indicatorsConfig.time, ...subIndicators];
    }
  }

  /// 更新主区指标的布局参数
  @protected
  @override
  bool updateMainIndicatorParam({
    double? height,
    EdgeInsets? padding,
  }) {
    bool changed = mainIndicator.updateLayout(
      height: height,
      padding: padding,
      // reset: true,
    );
    if (changed) {
      markRepaintChart(reset: true);
    }
    return changed;
  }

  @override
  double calculateIndicatorTop(int slot) {
    double top = 0;
    final list = subRectIndicators;
    if (slot >= 0 && slot < list.length) {
      for (int i = 0; i < slot; i++) {
        top += list[i].height;
      }
    }
    return top;
  }

  @protected
  @override
  double get subRectHeight {
    double totalHeight = 0.0;
    for (final indicator in subRectIndicators) {
      totalHeight += indicator.height;
    }
    return totalHeight;
  }

  @protected
  @override
  void ensurePaintObjectInstance() {
    mainIndicator.ensurePaintObject(this);
    for (var indicator in subRectIndicators) {
      indicator.ensurePaintObject(this);
    }
  }

  /// 在主图中添加指标
  void addIndicatorInMain(ValueKey<dynamic> key) {
    if (indicatorsConfig.mainIndicators.containsKey(key)) {
      mainIndicator.appendIndicator(
        indicatorsConfig.mainIndicators[key]!,
        this,
      );
      markRepaintChart(reset: true);
      markRepaintCross();
    }
  }

  /// 删除主图中[key]指定的指标
  void delIndicatorInMain(ValueKey<dynamic> key) {
    mainIndicator.deleteIndicator(key);
    markRepaintChart(reset: true);
    markRepaintCross();
  }

  /// 在副图中添加指标
  void addIndicatorInSub(ValueKey<dynamic> key) {
    if (indicatorsConfig.subIndicators.containsKey(key)) {
      if (subIndicators.length >= settingConfig.subChartMaxCount) {
        final deleted = subIndicators.removeFirst();
        deleted.dispose();
      }
      subIndicators.addLast(indicatorsConfig.subIndicators[key]!);
      invokeSizeChanged();
    }
  }

  /// 删除副图[key]指定的指标
  void delIndicatorInSub(ValueKey key) {
    bool hasRemove = false;
    subIndicators.removeWhere((indicator) {
      if (indicator.key == key) {
        indicator.dispose();
        hasRemove = true;
        return true;
      }
      return false;
    });
    if (hasRemove) invokeSizeChanged();
  }

  FlexiKlineConfig? __flexiKlineConfig;
  FlexiKlineConfig get _flexiKlineConfig {
    if (__flexiKlineConfig == null) {
      final config = configuration.getFlexiKlineConfig();
      _flexiKlineConfig = config;
    }
    return __flexiKlineConfig!;
  }

  set _flexiKlineConfig(config) {
    __flexiKlineConfig = config.clone();
    __flexiKlineConfig!.init();
  }

  @override
  void initFlexiKlineState() {
    /// 修正mainRect大小
    if (mainRect.isEmpty) {
      settingConfig.setMainRect(configuration.initialMainSize);
    }
    settingConfig.checkAndFixMinSize();

    /// 最终渲染前, 如果用户更改了配置, 此处做下更新.

    updateMainIndicatorParam(
      height: mainRect.height,
      padding: mainPadding,
    );

    /// TODO: 此处考虑对其他参数的修正
  }

  /// 保存当前配置到本地
  @override
  void saveFlexiKlineConfig() {
    configuration.saveFlexiKlineConfig(_flexiKlineConfig);
  }

  /// 更新[config]
  @override
  void updateFlexiKlineConfig(FlexiKlineConfig config) {
    if (config.key != _flexiKlineConfig.key) {
      /// 保存当前配置
      saveFlexiKlineConfig();

      /// 使用当前配置更新config
      config.update(_flexiKlineConfig);

      /// 释放当前配置所有指标
      _flexiKlineConfig.dispose();

      /// 更新当前配置为[config]
      _flexiKlineConfig = config;

      /// 初始化状态
      initFlexiKlineState();

      /// 保存当前配置
      saveFlexiKlineConfig();
    }
  }

  /// 保存当前FlexiKline配置到本地
  void storeFlexiKlineConfig() {
    configuration.saveFlexiKlineConfig(_flexiKlineConfig);
  }

  /// IndicatorsConfig
  @override
  IndicatorsConfig get indicatorsConfig => _flexiKlineConfig.indicators;

  /// SettingConfig
  @override
  SettingConfig get settingConfig => _flexiKlineConfig.setting;

  /// SettingConfig
  @override
  GestureConfig get gestureConfig => _flexiKlineConfig.gesture;

  /// GridConfig
  @override
  GridConfig get gridConfig => _flexiKlineConfig.grid;

  /// CrossConfig
  @override
  CrossConfig get crossConfig => _flexiKlineConfig.cross;

  /// TooltipConfig
  @override
  TooltipConfig get tooltipConfig => _flexiKlineConfig.tooltip;
}
