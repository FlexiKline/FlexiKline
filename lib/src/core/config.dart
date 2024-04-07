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

import 'package:flexi_kline/src/constant.dart';
import 'package:flutter/material.dart';

import '../model/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

/// 负责 Kline所有指标图的 配置
/// 1. Indicator的setting.
/// 2. 增/删 不同的指标图.
/// 3. 主题配置切换.
mixin ConfigBinding on KlineBindingBase, SettingBinding implements IConfig {
  @override
  void initBinding() {
    super.initBinding();
    logd("init config");
    _mainIndicator = MainIndicator(
      tipsHeight: mainTipsHeight,
      padding: mainPadding,
    );
  }

  @override
  void dispose() {
    super.dispose();
    logd("dispose config");
  }

  late final MainIndicator _mainIndicator;
  final Queue<Indicator> _subIndicators = ListQueue<Indicator>();

  @override
  @protected
  MainIndicator get mainIndicator => _mainIndicator;

  @override
  @protected
  Queue<Indicator> get subIndicators => _subIndicators;

  /// 在主图中增加指标
  void addIndicatorInMain(Indicator indicator) {
    final oldIndicator = mainIndicator.appendIndicator(indicator);
    if (oldIndicator != null) {
      // TODO: 发生替换操作. 是否要做些处理.
    }
  }

  void delIndicatorInMain(IndicatorType type) {
    final deleted = mainIndicator.delIndicator(type);
    if (deleted != null) {
      // TODO: 删除主图指标后的操作.
    }
  }

  /// 在副图中增加指标
  void addIndicatorInSub(Indicator indicator) {
    subIndicators.addLast(indicator);
    while (subIndicators.length > subIndicatorChartMaxCount) {
      subIndicators.removeFirst();
    }
  }

  void delIndicatorInSub(IndicatorType type) {
    subIndicators.removeWhere((e) => e.type == type);
  }
}
