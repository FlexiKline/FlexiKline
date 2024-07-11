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

import 'package:flutter/material.dart';

import '../config/export.dart';
import '../constant.dart';
import '../extension/collections_ext.dart';
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

/// 负责FlexiKline的各种设置与配置的获取.
mixin SettingBinding on KlineBindingBase
    implements ISetting, IChart, ICross, IGrid {
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
    final oldCanvasRect = sizeChangeListener.value;

    if (_fixedCanvasRect != null) {
      final changed = updateMainIndicatorParam(height: mainRect.height);
      if (changed || oldCanvasRect != _fixedCanvasRect) {
        markRepaintChart(reset: true);

        sizeChangeListener.value = canvasRect;
        sizeChangeListener.notifyListeners();
      }
    } else {
      if (oldCanvasRect != canvasRect) {
        final changed = updateMainIndicatorParam(height: mainRect.height);
        if (changed || oldCanvasRect.width != mainRect.width) {
          markRepaintChart(reset: true);
        }
        sizeChangeListener.value = canvasRect;
      }
    }

    markRepaintCross();
  }

  Rect? _fixedCanvasRect;

  /// 整个画布区域大小 = 由主图区域 + 副图区域
  @override
  Rect get canvasRect {
    if (_fixedCanvasRect != null) {
      return _fixedCanvasRect!;
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
    if (_fixedCanvasRect != null) {
      return Rect.fromLTRB(
        _fixedCanvasRect!.left,
        _fixedCanvasRect!.bottom - subRectHeight,
        _fixedCanvasRect!.right,
        _fixedCanvasRect!.bottom,
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
    if (_fixedCanvasRect != null) {
      return Rect.fromLTRB(
        _fixedCanvasRect!.left,
        _fixedCanvasRect!.top,
        _fixedCanvasRect!.right,
        _fixedCanvasRect!.bottom - subRectHeight,
      );
    }
    return settingConfig.mainRect;
  }

  /// 主区域最小宽高
  Size get mainMinSize => settingConfig.mainMinSize;

  /// 主区域大小设置
  void setMainSize(Size size) {
    settingConfig.setMainRect(size);
    invokeSizeChanged();
  }

  /// 适配[FlexiKlineWidget]所在布局的变化
  ///
  /// 注: 目前仅考虑适配宽度的变化.
  ///   这将会导致无法手动调整[FlexiKlineWidget]的宽度.
  void adaptLayoutChange(Size size) {
    if (size.width != mainRect.width) {
      setMainSize(Size(size.width, mainRect.height));
    }
  }

  void exitFixedSize() {
    if (_fixedCanvasRect != null) {
      _fixedCanvasRect = null;
      invokeSizeChanged();
    }
  }

  /// 设置Kline固定大小(主要在全屏或横屏场景中使用此API)
  /// 当设置[_fixedCanvasRect]后, 主区高度=[_fixedCanvasRect]的总高度 - [subRectHeight]副区所有指标高度
  /// [size] 当前Kline主区+副区的大小.
  /// 注: 设置是临时的, 并不会更新到配置中.
  void setFixedSize(Size size) {
    if (size >= settingConfig.mainMinSize) {
      _fixedCanvasRect = Rect.fromLTRB(
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
  double get candleMaxWidth => settingConfig.candleMaxWidth;
  // set candleMaxWidth(double width) {
  //   settingConfig.candleMaxWidth = width.clamp(1.0, 50.0);
  // }

  /// 单根蜡烛宽度, 限制范围1[pixel] ~ [candleMaxWidth] 之间
  double get candleWidth => settingConfig.candleWidth;
  set candleWidth(double width) {
    settingConfig.candleWidth = width.clamp(
      settingConfig.pixel,
      candleMaxWidth,
    );
  }

  /// 单根蜡烛所占据实际宽度
  double get candleActualWidth => candleWidth + settingConfig.candleSpacing;

  /// 单根蜡烛的一半
  double get candleWidthHalf => candleActualWidth / 2;

  /// 绘制区域宽度内, 可绘制的蜡烛数
  int get maxCandleCount => (mainChartWidth / candleActualWidth).ceil();

  Map<ValueKey, SinglePaintObjectIndicator> get supportMainIndicators {
    return {...indicatorsConfig.mainIndicators, ..._customMainIndicators};
  }

  Map<ValueKey, Indicator> get supportSubIndicators {
    return {...indicatorsConfig.subIndicators, ..._customSubIndicators};
  }

  Set<ValueKey> get supportMainIndicatorKeys {
    return supportMainIndicators.keys.toSet()..remove(candleKey);
  }

  Set<ValueKey> get supportSubIndicatorKeys {
    return supportSubIndicators.keys.toSet()..remove(timeKey);
  }

  Set<ValueKey> get mainIndicatorKeys {
    return mainIndicator.children.map((e) => e.key).toSet();
  }

  Set<ValueKey> get subIndicatorKeys {
    return subRectIndicators.map((e) => e.key).toSet();
  }

  @override
  MultiPaintObjectIndicator get mainIndicator {
    return _flexiKlineConfig.mainIndicator;
  }

  @protected
  FixedHashQueue<Indicator> get subIndicatorQueue {
    return _flexiKlineConfig.subRectIndicatorQueue;
  }

  @override
  List<Indicator> get subRectIndicators {
    if (indicatorsConfig.time.position == DrawPosition.bottom) {
      return [...subIndicatorQueue, indicatorsConfig.time];
    } else {
      return [indicatorsConfig.time, ...subIndicatorQueue];
    }
  }

  /// 更新主区指标的布局参数
  @protected
  bool updateMainIndicatorParam({
    double? height,
    EdgeInsets? padding,
  }) {
    bool changed = mainIndicator.updateLayout(
      height: height,
      padding: padding,
      // reset: true,
    );
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
    if (supportMainIndicators.containsKey(key)) {
      final indicator = supportMainIndicators[key]!;
      mainIndicator.appendIndicator(indicator, this);
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
    final indicator = supportSubIndicators.getItem(key);
    if (indicator != null) {
      // 使用前先解绑
      indicator.dispose();
      subIndicatorQueue.append(indicator)?.dispose();
      invokeSizeChanged();
    }
  }

  /// 删除副图[key]指定的指标
  void delIndicatorInSub(ValueKey key) {
    bool hasRemove = false;
    subIndicatorQueue.removeWhere((indicator) {
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
      // 初始化设置自定义指标.
      _updateCustomIndicators();
      final config = configuration.getFlexiKlineConfig();
      _flexiKlineConfig = config;
    }
    return __flexiKlineConfig!;
  }

  set _flexiKlineConfig(config) {
    __flexiKlineConfig = config.clone();
    __flexiKlineConfig!.init(
      customMainIndicators: _customMainIndicators,
      customSubIndicators: _customSubIndicators,
    );
  }

  void initFlexiKlineState({bool isInit = false}) {
    /// 修正mainRect大小
    if (mainRect.isEmpty) {
      final initSize = configuration.initialMainSize;
      if (isInit && initSize < settingConfig.mainMinSize) {
        throw Exception('initMainRect(size:$initSize) is invalid!!!');
      }
      settingConfig.setMainRect(initSize);
      invokeSizeChanged();
    }

    /// TODO: 此处考虑对其他参数的修正
  }

  /// 保存当前FlexiKline配置到本地
  @override
  void storeFlexiKlineConfig() {
    configuration.saveFlexiKlineConfig(_flexiKlineConfig);
  }

  /// 更新[config]到[_flexiKlineConfig]
  @override
  void updateFlexiKlineConfig(FlexiKlineConfig config) {
    if (config.key != _flexiKlineConfig.key) {
      /// 保存当前配置
      storeFlexiKlineConfig();

      /// 使用当前配置更新config
      config.update(_flexiKlineConfig);

      /// 释放当前配置所有指标
      _flexiKlineConfig.dispose();

      /// 配置变更重置自定义指标.
      _updateCustomIndicators();

      /// 更新当前配置为[config]
      _flexiKlineConfig = config;

      /// 初始化状态
      initFlexiKlineState();

      /// 保存当前配置
      if (autoSave) storeFlexiKlineConfig();
    } else {
      _flexiKlineConfig = config;

      /// 初始化状态
      initFlexiKlineState();

      /// 保存当前配置
      if (autoSave) storeFlexiKlineConfig();
    }
  }

  @override
  Map<ValueKey, dynamic> getIndicatorCalcParams() {
    // 收集所有指标预计算参数.
    return indicatorsConfig.getAllIndicatorCalcParams();
    // 收集已打开的指标计算参数. TODO: 性能优化后使用.
    // return _flexiKlineConfig.getOpenedIndicatorCalcParams();
  }

  /// IndicatorsConfig
  @override
  IndicatorsConfig get indicatorsConfig => _flexiKlineConfig.indicators;
  set indicatorsConfig(IndicatorsConfig config) {
    final keys = config.megerAndDisposeOldIndicator(
      _flexiKlineConfig.indicators,
    );
    _flexiKlineConfig.indicators = config;
    for (var key in keys) {
      if (indicatorsConfig.mainIndicators.containsKey(key)) {
        addIndicatorInMain(key);
      }
      if (indicatorsConfig.subIndicators.containsKey(key)) {
        addIndicatorInSub(key);
      }
    }
  }

  /// SettingConfig
  @override
  SettingConfig get settingConfig => _flexiKlineConfig.setting;
  set settingConfig(SettingConfig config) {
    final isChangeSize = config.mainRect != mainRect;
    _flexiKlineConfig.setting = config;
    initFlexiKlineState();
    if (isChangeSize) invokeSizeChanged();
    markRepaintChart();
    markRepaintCross();
  }

  /// SettingConfig
  @override
  GestureConfig get gestureConfig => _flexiKlineConfig.gesture;
  set gestureConfig(GestureConfig config) {
    _flexiKlineConfig.gesture = config;
    markRepaintChart();
    markRepaintCross();
  }

  /// GridConfig
  @override
  GridConfig get gridConfig => _flexiKlineConfig.grid;
  set gridConfig(GridConfig config) {
    _flexiKlineConfig.grid = config;
    markRepaintChart();
    markRepaintCross();
    markRepaintGrid();
  }

  /// CrossConfig
  @override
  CrossConfig get crossConfig => _flexiKlineConfig.cross;
  set crossConfig(CrossConfig config) {
    _flexiKlineConfig.cross = config;
    markRepaintChart();
    markRepaintCross();
  }

  /// TooltipConfig
  @override
  TooltipConfig get tooltipConfig => _flexiKlineConfig.tooltip;
  set tooltipConfig(TooltipConfig config) {
    _flexiKlineConfig.tooltip = config;
    markRepaintChart();
    markRepaintCross();
  }

  /// 从配置中心, 更新自定义指标集.
  /// 1. 初始化时更新
  /// 2. 配置发生变更时重置.
  void _updateCustomIndicators() {
    // 更新自定义指标配置.
    _customMainIndicators.clear();
    _customSubIndicators.clear();
    configuration.customMainIndicators().forEach(
          (indicator) => addCustomMainIndicatorConfig(indicator),
        );
    configuration.customSubIndicators().forEach(
          (indicator) => addCustomSubIndicatorConfig(indicator),
        );
  }

  /// 用户自定义主区指标集合
  final Map<ValueKey, SinglePaintObjectIndicator> _customMainIndicators = {};

  /// 用户自定义副区指标集合
  final Map<ValueKey, Indicator> _customSubIndicators = {};

  /// 添加主区指标配置
  /// [indicator] 指标配置
  /// 注: 如果指标的key使用内置的ValueKey([IndicatorType]), 将会替换内置的指标.
  void addCustomMainIndicatorConfig(SinglePaintObjectIndicator indicator) {
    _customMainIndicators[indicator.key] = indicator;
  }

  /// 删除[key]对应的指标配置.
  /// 注: 此处删除的是自定义的主区指标.
  void delCustomMainIndicatorConifg(ValueKey key) {
    _customMainIndicators.remove(key);
  }

  /// 添加副区指标配置
  /// [indicator] 指标配置
  /// 注: 如果指标的key使用内置的ValueKey([IndicatorType]), 将会替换内置的指标.
  void addCustomSubIndicatorConfig(Indicator indicator) {
    _customSubIndicators[indicator.key] = indicator;
  }

  /// 删除副区[key]对应的指标配置.
  /// 注: 此处删除的是自定义的副区指标.
  void delCustomSubIndicatorConfig(ValueKey key) {
    _customSubIndicators.remove(key);
  }
}
