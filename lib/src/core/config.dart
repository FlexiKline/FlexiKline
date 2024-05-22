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

import 'package:flutter/material.dart';

import '../constant.dart';
import '../framework/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

/// 负责 Kline所有指标图的 配置
/// 1. Indicator的setting.
/// 2. 增/删 不同的指标图.
/// 3. 主题配置切换.
mixin ConfigBinding
    on KlineBindingBase, SettingBinding
    implements IConfig, IChart {
  /// 主绘制区域指标
  late MultiPaintObjectIndicator _mainIndicator;

  /// 副图区域绘制指标集合
  late Queue<Indicator> _subIndicators;

  @override
  void init() {
    super.init();
    logd('init config');
    _mainIndicator = MultiPaintObjectIndicator(
      key: mainChartKey,
      name: 'MAIN',
      height: 0,
      padding: defaultMainIndicatorPadding,
      drawBelowTipsArea: true,
    );

    _subIndicators = ListQueue<Indicator>(subChartMaxCount);
  }

  @override
  void initState() {
    super.initState();
    logd("initState config");

    _mainIndicator.appendIndicator(indicatorsConfig.candle, this);
    _mainIndicator.appendIndicator(getCandleIndicator(), this);
    final mainChildIndicators = genMainChildIndicators();
    _mainIndicator.appendIndicators(mainChildIndicators, this);

    /// 最终渲染前, 如果用户更改了配置, 此处做下更新.
    updateMainIndicatorParam(
      height: mainRect.height,
      padding: mainPadding,
    );

    for (var subKey in subConfig) {
      addIndicatorInSub(subKey);
    }
  }

  @override
  void dispose() {
    super.dispose();
    logd("dispose config");
    mainIndicator.dispose();
    for (var indicator in subRectIndicators) {
      indicator.dispose();
    }
    subRectIndicators.clear();
  }

  @override
  void storeState() {
    super.storeState();
    logd('storeState config');
  }

  Set<ValueKey> get supportMainIndicatorKeys {
    return indicatorsConfig.mainIndicators.keys.toSet();
  }

  Set<ValueKey> get supportSubIndicatorKeys {
    return indicatorsConfig.subIndicators.keys.toSet();
  }

  Set<ValueKey> get mainIndicatorKeys {
    return mainIndicator.children.map((e) => e.key).toSet();
  }

  Set<ValueKey> get subIndicatorKeys {
    return subRectIndicators.map((e) => e.key).toSet();
  }

  @protected
  @override
  MultiPaintObjectIndicator get mainIndicator => _mainIndicator;

  @protected
  @override
  List<Indicator> get subRectIndicators {
    if (indicatorsConfig.time.position == DrawPosition.bottom) {
      return [..._subIndicators, indicatorsConfig.time];
    } else {
      return [indicatorsConfig.time, ..._subIndicators];
    }
  }

  @protected
  @override
  void updateMainIndicatorParam({
    double? height,
    EdgeInsets? padding,
  }) {
    bool changed = mainIndicator.updateLayout(
      height: height,
      padding: padding,
      reset: true,
    );
    if (changed) {
      markRepaintChart(reset: true);
    }
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

  void addIndicatorInMain(ValueKey<dynamic> key) {
    if (indicatorsConfig.mainIndicators.containsKey(key)) {
      mainIndicator.appendIndicator(
        indicatorsConfig.mainIndicators[key]!,
        this,
      );
      markRepaintChart();
    }
  }

  /// 删除主图中key指定的指标
  void delIndicatorInMain(ValueKey<dynamic> key) {
    mainIndicator.deleteIndicator(key);
    markRepaintChart();
  }

  /// 在副图中增加指标
  void addIndicatorInSub(ValueKey<dynamic> key) {
    if (indicatorsConfig.subIndicators.containsKey(key)) {
      if (_subIndicators.length >= subChartMaxCount) {
        final deleted = _subIndicators.removeFirst();
        deleted.dispose();
      }
      _subIndicators.addLast(indicatorsConfig.subIndicators[key]!);
      onSizeChange?.call();
      markRepaintChart();
    }
  }

  /// 删除副图key指定的指标
  void delIndicatorInSub(ValueKey key) {
    _subIndicators.removeWhere((indicator) {
      if (indicator.key == key) {
        indicator.dispose();
        onSizeChange?.call();
        markRepaintChart();
        return true;
      }
      return false;
    });
  }
}
