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
import 'package:flexi_kline/src/framework/indicator.dart';
import 'package:flexi_kline/src/framework/object.dart';
import 'package:flutter/material.dart';

import '../indicators/export.dart';
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
    _mainIndicator = MultiPaintObjectIndicator(
      key: const ValueKey('main'),
      tipsHeight: mainTipsHeight,
      padding: mainPadding,
    );
  }

  @override
  void dispose() {
    super.dispose();
    logd("dispose config");
  }

  /// 主绘制区域
  late final MultiPaintObjectIndicator _mainIndicator;
  @protected
  @override
  MultiPaintObjectIndicator get mainIndicator => _mainIndicator;

  final Queue<PaintObjectIndicator> _subIndicators =
      ListQueue<PaintObjectIndicator>();
  @override
  @protected
  Queue<PaintObjectIndicator> get subIndicators => _subIndicators;

  /// 在主图中增加指标
  void addIndicatorInMain(PaintObjectIndicator indicator) {
    final oldIndicator = mainIndicator.appendIndicator(indicator);
  }

  void delIndicatorInMain(ValueKey key) {
    final deleted = mainIndicator.deleteIndicator(key);
    if (deleted != null) {
      // TODO: 删除主图指标后的操作.
    }
  }

  /// 在副图中增加指标
  void addIndicatorInSub(PaintObjectIndicator indicator) {
    subIndicators.addLast(indicator);
    while (subIndicators.length > subIndicatorChartMaxCount) {
      subIndicators.removeFirst();
    }
  }

  void delIndicatorInSub(IndicatorType type) {
    // subIndicators.removeWhere((e) => e.type == type);
  }
}
