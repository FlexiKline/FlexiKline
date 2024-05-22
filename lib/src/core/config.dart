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
    _mainIndicator.appendIndicator(indicatorsConfig.candle, this);

    _subIndicators = ListQueue<Indicator>(defaultSubChartMaxCount);
  }

  @override
  void initState() {
    super.initState();
    logd("initState config");

    _mainIndicator.appendIndicator(indicatorsConfig.candle, this);
    // addIndicatorInSub(timeKey);

    /// 最终渲染前, 如果用户更改了配置, 此处做下更新. TODO: 待优化.
    updateMainIndicatorParam(
      height: mainRect.height,
      padding: mainPadding,
    );
  }

  @override
  void dispose() {
    super.dispose();
    logd("dispose config");
    mainIndicator.dispose();
    for (var indicator in subIndicators) {
      indicator.dispose();
    }
    subIndicators.clear();
  }

  @override
  void storeState() {
    super.storeState();
    logd('storeState config');
  }

  Set<ValueKey> get supportMainIndicatorKeys {
    return indicatorsConfig.mainIndicators.keys.toSet()..remove(candleKey);
  }

  Set<ValueKey> get supportSubIndicatorKeys {
    return indicatorsConfig.subIndicators.keys.toSet();
  }

  Set<ValueKey> get mainIndicatorKeys {
    return mainIndicator.children.map((e) => e.key).toSet();
  }

  Set<ValueKey> get subIndicatorKeys {
    return subIndicators.map((e) => e.key).toSet();
  }

  @protected
  @override
  MultiPaintObjectIndicator get mainIndicator => _mainIndicator;

  @override
  @protected
  Queue<Indicator> get subIndicators => _subIndicators;

  @override
  List<double> get subIndicatorHeightList {
    return subIndicators.map((e) => e.height).toList();
  }

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
    final hList = subIndicatorHeightList;
    if (slot >= 0 && slot < hList.length) {
      for (int i = 0; i < slot; i++) {
        top += hList[i];
      }
    }
    return top;
  }

  @override
  double get subRectHeight {
    if (subIndicatorHeightList.isEmpty) return 0.0;
    return subIndicatorHeightList.reduce((curr, next) => curr + next);
  }

  @override
  void ensurePaintObjectInstance() {
    mainIndicator.ensurePaintObject(this);
    for (var indicator in subIndicators) {
      indicator.ensurePaintObject(this);
    }
  }

  @override
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
  @override
  void delIndicatorInMain(ValueKey<dynamic> key) {
    mainIndicator.deleteIndicator(key);
    markRepaintChart();
  }

  /// 在副图中增加指标
  @override
  void addIndicatorInSub(ValueKey<dynamic> key) {
    if (indicatorsConfig.subIndicators.containsKey(key)) {
      if (subIndicators.length >= subChartMaxCount) {
        final deleted = subIndicators.removeFirst();
        deleted.dispose();
      }
      subIndicators.addLast(indicatorsConfig.subIndicators[key]!);
      onSizeChange?.call();
      markRepaintChart();
    }
  }

  /// 删除副图key指定的指标
  @override
  void delIndicatorInSub(ValueKey key) {
    subIndicators.removeWhere((indicator) {
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
