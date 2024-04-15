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

import '../framework/export.dart';
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
    initIndicators();
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

  void initIndicators() {
    logd("initIndicators");
    _mainIndicator = CandleIndicator(
      key: const ValueKey('main'),
      height: mainRect.height,
      tipsHeight: mainTipsHeight,
      padding: mainPadding,
    );

    addIndicatorInMain(MAIndicator(
      key: const ValueKey(IndicatorType.ma),
      height: mainRect.height,
      calcParams: [
        MaParam(label: 'MA7', count: 7, color: Colors.red),
        MaParam(label: 'MA30', count: 30, color: Colors.blue)
      ],
    ));

    _subIndicators = ListQueue<PaintObjectIndicator>(
      subIndicatorChartMaxCount,
    );

    addIndicatorInSub(VolumeIndicator(
      key: const ValueKey(IndicatorType.volume),
      height: subIndicatorDefaultHeight,
      tipsHeight: 22,
    ));

    addIndicatorInSub(VolumeIndicator(
      key: const ValueKey(IndicatorType.volume),
      height: 120,
      tipsHeight: 0,
    ));
  }

  /// 主绘制区域
  late final MultiPaintObjectIndicator _mainIndicator;
  @protected
  @override
  MultiPaintObjectIndicator get mainIndicator => _mainIndicator;

  /// 副图区域
  late final Queue<PaintObjectIndicator> _subIndicators;

  @override
  @protected
  Queue<PaintObjectIndicator> get subIndicators => _subIndicators;

  @override
  List<double> get subIndicatorHeightList {
    return subIndicators.map((e) => e.height).toList();
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

  // bool isNeedCreate = false;
  @override
  void checkAndCreatePaintObject() {
    mainIndicator.paintObject ??= mainIndicator.createPaintObject(this);
    for (var indicator in subIndicators) {
      indicator.paintObject ??= indicator.createPaintObject(this);
    }
  }

  /// 在主图中增加指标
  @override
  void addIndicatorInMain(PaintObjectIndicator indicator) {
    mainIndicator.appendIndicator(indicator, this);
  }

  /// 删除主图中key指定的指标
  @override
  void delIndicatorInMain(Key key) {
    mainIndicator.deleteIndicator(key);
  }

  /// 在副图中增加指标
  @override
  void addIndicatorInSub(PaintObjectIndicator indicator) {
    if (subIndicators.length > subIndicatorChartMaxCount) {
      final deleted = subIndicators.removeFirst();
      deleted.dispose();
    }
    subIndicators.addLast(indicator);
  }

  /// 删除副图key指定的指标
  @override
  void delIndicatorInSub(Key key) {
    subIndicators.removeWhere((indicator) {
      if (indicator.key == key) {
        indicator.dispose();
        return true;
      }
      return false;
    });
  }
}
