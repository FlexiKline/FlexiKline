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
import '../indicators/export.dart';
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
  @override
  void init() {
    super.init();
    logd('init config');
    _candleMainIndicator = restoreIndicator(
      candleIndicatorKey,
      CandleIndicator.fromJson,
    );
  }

  @override
  void initState() {
    super.initState();
    logd("initState config");
    initIndicators();
  }

  @override
  void dispose() {
    super.dispose();
    logd("dispose config");
    storeState();
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
    saveIndicator(candleIndicatorKey, candleMainIndicator.toJson());
    // saveMultiIndicator(mainIndicator);
    // for (var indicator in subIndicators) {
    //   saveIndicator(indicator);
    // }
  }

  // final Map<String, IndicatorBuilder> indicatorBuilderMap = {
  //   IndicatorType.candle.name:
  // };

  /// 主绘制区域
  final MultiPaintObjectIndicator _mainIndicator = MultiPaintObjectIndicator(
    key: const ValueKey('main'),
    name: 'MAIN',
    height: 0,
    drawChartAlawaysBelowTipsArea: true,
  );

  /// 副图区域
  final Queue<Indicator> _subIndicators = ListQueue<Indicator>(
    defaultSubChartMaxCount,
  );

  final Set<SinglePaintObjectIndicator> _supportMainIndicators =
      LinkedHashSet<SinglePaintObjectIndicator>(
    equals: (p0, p1) => p0.key == p1.key,
    hashCode: (p0) => p0.key.hashCode,
  );

  final Set<Indicator> _supportSubIndicators = LinkedHashSet<Indicator>(
    equals: (p0, p1) => p0.key == p1.key,
    hashCode: (p0) => p0.key.hashCode,
  );

  void initIndicators() {
    logd("initIndicators");
    _supportMainIndicators.addAll([
      volumeMainIndicator,
      maMainIndicator,
      emaMainIndicator,
      bollMainIndicator,
    ]);

    _supportSubIndicators.addAll([
      macdSubIndicator,
      kdjSubIndicator,
      volumeMavolSubIndicator,
    ]);

    _mainIndicator.height = mainRect.height;
    _mainIndicator.tipsHeight = mainTipsHeight;
    _mainIndicator.padding = mainPadding;

    addIndicatorInMain(candleMainIndicator);

    /// 主图
    // addIndicatorInMain(volumeMainIndicator);

    // addIndicatorInMain(maMainIndicator);

    // addIndicatorInMain(emaMainIndicator);

    // addIndicatorInMain(bollMainIndicator);

    /// 副图
    // addIndicatorInSub(macdSubIndicator);

    // addIndicatorInSub(volumeMavolSubIndicator);

    // addIndicatorInSub(kdjSubIndicator);
  }

  Set<SinglePaintObjectIndicator> get supportMainIndicators =>
      _supportMainIndicators;

  Set<Indicator> get supportSubIndicators => _supportSubIndicators;

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

  Set<ValueKey> get mainIndicatorKeys {
    return mainIndicator.children.map((e) => e.key).toSet();
  }

  /// 在主图中增加指标
  @override
  void addIndicatorInMain(SinglePaintObjectIndicator indicator) {
    mainIndicator.appendIndicator(indicator, this);
    markRepaintChart();
  }

  /// 删除主图中key指定的指标
  @override
  void delIndicatorInMain(ValueKey key) {
    mainIndicator.deleteIndicator(key);
    markRepaintChart();
  }

  Set<ValueKey> get subIndicatorKeys {
    return subIndicators.map((e) => e.key).toSet();
  }

  /// 在副图中增加指标
  @override
  void addIndicatorInSub(Indicator indicator) {
    if (subIndicators.length >= subChartMaxCount) {
      final deleted = subIndicators.removeFirst();
      deleted.dispose();
    }
    subIndicators.addLast(indicator);
    onSizeChange?.call();
    markRepaintChart();
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

  CandleIndicator? _candleMainIndicator;
  CandleIndicator get candleMainIndicator {
    _candleMainIndicator ??= CandleIndicator(
      height: mainRect.height,
      tipsHeight: mainTipsHeight,
      padding: mainPadding,
    );
    return _candleMainIndicator!;
  }

  set candleMainIndicator(covariant CandleIndicator val) {
    _candleMainIndicator = val;
    saveIndicator(candleIndicatorKey, val.toJson());
  }

  VolumeIndicator get volumeMainIndicator => VolumeIndicator(
        height: subChartDefaultHeight,
        paintMode: PaintMode.alone,
        showYAxisTick: false,
        showCrossMark: false,
        showTips: false,
        useTint: true,
      );
  MAIndicator get maMainIndicator => MAIndicator(
        height: mainRect.height,
      );
  EMAIndicator get emaMainIndicator => EMAIndicator(
        height: mainRect.height,
      );
  BOLLIndicator get bollMainIndicator => BOLLIndicator(
        height: mainRect.height,
      );

  MACDIndicator get macdSubIndicator => MACDIndicator(
        height: 60,
        tipsHeight: 12,
      );

  KDJIndicator get kdjSubIndicator => KDJIndicator(
        height: 60,
        tipsHeight: 12,
      );

  Indicator get volumeMavolSubIndicator => MultiPaintObjectIndicator(
        key: ValueKey(
          '${IndicatorType.volume.name}+${IndicatorType.maVol.name}',
        ),
        name: 'MAVOL',
        height: subChartDefaultHeight,
        tipsHeight: 12,
        children: [
          VolumeIndicator(
            height: subChartDefaultHeight,
          ),
          MAVolIndicator(
            height: subChartDefaultHeight,
          ),
        ],
      );
}
