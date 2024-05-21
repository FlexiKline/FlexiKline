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

import '../config/export.dart';
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
  /// 主绘制区域
  late MultiPaintObjectIndicator _mainIndicator;

  /// 副图区域
  late Queue<Indicator> _subIndicators;

  /// 支持的主图指标集
  // late Map<ValueKey, SinglePaintObjectIndicator> _supportMainIndicators;

  /// 支持的副图指标集
  // late Map<ValueKey, Indicator> _supportSubIndicators;

  @override
  void init() {
    super.init();
    logd('init config');

    // _indicatorsConfig = IndicatorsConfig.fromJson(indicatorsConfigData);

    /// 初始化指标配置:
    /// 1. 优先从storage中反序列化所有指标配置.
    /// 2. 如果storage中不存在, 默认构造
    // _supportMainIndicators = {
    //   candleKey: restoreMainSupportIndicator(
    //         candleKey,
    //         CandleIndicator.fromJson,
    //       ) ??
    //       CandleIndicator(
    //         height: mainRect.height,
    //       ),
    //   volumeKey: restoreMainSupportIndicator(
    //         volumeKey,
    //         VolumeIndicator.fromJson,
    //       ) ??
    //       VolumeIndicator(),
    //   maKey: restoreMainSupportIndicator(
    //         maKey,
    //         MAIndicator.fromJson,
    //       ) ??
    //       MAIndicator(
    //         height: mainRect.height,
    //       ),
    //   emaKey: restoreMainSupportIndicator(
    //         emaKey,
    //         EMAIndicator.fromJson,
    //       ) ??
    //       EMAIndicator(
    //         height: mainRect.height,
    //       ),
    //   bollKey: restoreMainSupportIndicator(
    //         bollKey,
    //         BOLLIndicator.fromJson,
    //       ) ??
    //       BOLLIndicator(
    //         height: mainRect.height,
    //       )
    // };

    // _supportSubIndicators = {
    //   timeKey: TimeIndicator(),
    //   macdKey: restoreSubSupportIndicator(
    //         macdKey,
    //         MACDIndicator.fromJson,
    //       ) ??
    //       MACDIndicator(),
    //   kdjKey: restoreSubSupportIndicator(
    //         kdjKey,
    //         KDJIndicator.fromJson,
    //       ) ??
    //       KDJIndicator(),
    //   maVolKey: restoreSubSupportIndicator(
    //         maVolKey,
    //         MAVolumeIndicator.fromJson,
    //       ) ??
    //       MAVolumeIndicator(
    //         volumeIndicator: VolumeIndicator(
    //           paintMode: PaintMode.combine,
    //           showYAxisTick: true,
    //           showCrossMark: true,
    //           showTips: true,
    //           useTint: false,
    //         ),
    //         volMaIndicator: VolMaIndicator(),
    //       ),
    // };

    // (_supportSubIndicators[maVolKey] as MultiPaintObjectIndicator)
    //     .appendIndicators([
    //   restoreSubSupportIndicator(
    //         maVolKey,
    //         VolumeIndicator.fromJson,
    //         childKey: volumeKey,
    //       ) ??
    //       VolumeIndicator(),
    //   restoreSubSupportIndicator(
    //         maVolKey,
    //         VolMaIndicator.fromJson,
    //         childKey: volMaKey,
    //       ) ??
    //       VolMaIndicator(),
    // ], this);

    _mainIndicator = MultiPaintObjectIndicator(
      key: mainChartKey,
      name: 'MAIN',
      height: 0,
      padding: defaultMainIndicatorPadding,
      drawBelowTipsArea: true,
    );
    _mainIndicator.appendIndicator(indicatorsConfig.candle, this);
    // for (var childKey in mainChildrenKeys) {
    //   addIndicatorInMain(childKey);
    // }

    _subIndicators = ListQueue<Indicator>(defaultSubChartMaxCount);
    // addIndicatorInSub(timeKey);
    // for (var childKey in subChildrenKeys) {
    //   addIndicatorInSub(childKey);
    // }
  }

  @override
  void initState() {
    super.initState();
    logd("initState config");

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
    // _supportMainIndicators.clear();
    // _supportSubIndicators.clear();
  }

  @override
  void storeState() {
    super.storeState();
    logd('storeState config');
    // storeMainIndicator(_mainIndicator);
    // storeSubIndicators(_subIndicators);
    // storeSupportMainIndicators(_supportMainIndicators);
    // storeSupportSubIndicators(_supportSubIndicators);
  }

  // late IndicatorsConfig _indicatorsConfig;

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
    // if (_supportMainIndicators.containsKey(key)) {
    //   mainIndicator.appendIndicator(_supportMainIndicators[key]!, this);
    //   markRepaintChart();
    // }
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
    // if (_supportSubIndicators.containsKey(key)) {
    //   if (subIndicators.length >= subChartMaxCount) {
    //     final deleted = subIndicators.removeFirst();
    //     deleted.dispose();
    //   }
    //   subIndicators.addLast(_supportSubIndicators[key]!);
    //   onSizeChange?.call();
    //   markRepaintChart();
    // }
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
