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
    _mainIndicator = MultiPaintObjectIndicator(
      key: const ValueKey('main'),
      height: mainRect.height,
      tipsHeight: mainTipsHeight,
      padding: mainPadding,
      drawChartAlawaysBelowTipsArea: true,
    );

    addIndicatorInMain(CandleIndicator(
      height: mainRect.height,
      tipsHeight: mainTipsHeight,
      padding: mainPadding,
    ));

    // addIndicatorInMain(VolumeIndicator(
    //   height: subChartDefaultHeight,
    //   paintMode: PaintMode.alone,
    //   showYAxisTick: false,
    //   showCrossMark: false,
    //   showTips: false,
    //   useTint: true,
    // ));

    // addIndicatorInMain(MAIndicator(
    //   height: mainRect.height,
    // ));

    // addIndicatorInMain(EMAIndicator(
    //   height: mainRect.height,
    // ));

    // addIndicatorInMain(BOLLIndicator(
    //   height: mainRect.height,
    // ));

    _subIndicators = ListQueue<Indicator>(
      subChartMaxCount,
    );

    // addIndicatorInSub(MacdIndicator(
    //   height: 60,
    //   tipsHeight: 12,
    // ));

    // addIndicatorInSub(MultiPaintObjectIndicator(
    //   key: ValueKey('${IndicatorType.volume.name}+${IndicatorType.maVol.name}'),
    //   height: subChartDefaultHeight,
    //   tipsHeight: 12,
    //   children: [
    //     VolumeIndicator(
    //       height: subChartDefaultHeight,
    //     ),
    //     MAVolIndicator(
    //       height: subChartDefaultHeight,
    //     ),
    //   ],
    // ));

    // addIndicatorInSub(KDJIndicator(
    //   height: 60,
    //   tipsHeight: 12,
    // ));
  }

  /// 主绘制区域
  late final MultiPaintObjectIndicator _mainIndicator;
  @protected
  @override
  MultiPaintObjectIndicator get mainIndicator => _mainIndicator;

  /// 副图区域
  late final Queue<Indicator> _subIndicators;

  @override
  @protected
  Queue<Indicator> get subIndicators => _subIndicators;

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

  @override
  void ensurePaintObjectInstance() {
    mainIndicator.ensurePaintObject(this);
    for (var indicator in subIndicators) {
      indicator.ensurePaintObject(this);
    }
  }

  /// 在主图中增加指标
  @override
  void addIndicatorInMain(SinglePaintObjectIndicator indicator) {
    mainIndicator.appendIndicator(indicator, this);
  }

  /// 删除主图中key指定的指标
  @override
  void delIndicatorInMain(Key key) {
    mainIndicator.deleteIndicator(key);
  }

  /// 在副图中增加指标
  @override
  void addIndicatorInSub(Indicator indicator) {
    if (subIndicators.length > subChartMaxCount) {
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
