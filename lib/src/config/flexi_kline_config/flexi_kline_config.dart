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

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../extension/export.dart';
import '../../framework/export.dart';
import '../cross_config/cross_config.dart';
import '../draw_config/draw_config.dart';
import '../gesture_config/gesture_config.dart';
import '../grid_config/grid_config.dart';
import '../indicators_config/indicators_config.dart';
import '../setting_config/setting_config.dart';
import '../tooltip_config/tooltip_config.dart';

part 'flexi_kline_config.g.dart';

@FlexiConfigSerializable
class FlexiKlineConfig {
  FlexiKlineConfig({
    required this.key,
    required this.grid,
    required this.setting,
    required this.gesture,
    required this.cross,
    required this.draw,
    required this.tooltip,
    required this.indicators,
    this.main = const <IIndicatorKey>{},
    this.sub = const <IIndicatorKey>{},
  });

  final String key;
  GridConfig grid;
  SettingConfig setting;
  GestureConfig gesture;
  CrossConfig cross;
  DrawConfig draw;
  TooltipConfig tooltip;
  IndicatorsConfig indicators;
  Set<IIndicatorKey> main;
  Set<IIndicatorKey> sub;

  @JsonKey(includeFromJson: false, includeToJson: false)
  late final MultiPaintObjectIndicator mainIndicator;
  @JsonKey(includeFromJson: false, includeToJson: false)
  late final FixedHashQueue<Indicator> subRectIndicatorQueue;

  void init({
    required Map<IIndicatorKey, SinglePaintObjectIndicator>
        customMainIndicators,
    required Map<IIndicatorKey, Indicator> customSubIndicators,
  }) {
    mainIndicator = MultiPaintObjectIndicator(
      key: IndicatorType.main,
      name: IndicatorType.main.label,
      height: setting.mainRect.height,
      padding: setting.mainPadding,
      drawBelowTipsArea: setting.mainDrawBelowTipsArea,
    );

    subRectIndicatorQueue = FixedHashQueue<Indicator>(
      setting.subChartMaxCount,
    );

    if (!main.contains(IndicatorType.candle)) {
      main.add(IndicatorType.candle);
    }
    for (var key in main) {
      SinglePaintObjectIndicator? indicator = customMainIndicators.getItem(key);
      indicator ??= indicators.mainIndicators.getItem(key);
      if (indicator != null) {
        // 使用前先解绑
        indicator.dispose();
        mainIndicator.children.add(indicator);
      }
    }

    if (sub.contains(IndicatorType.time)) {
      sub.remove(IndicatorType.time); // Time指标是默认的
    }
    if (sub.isNotEmpty) {
      if (sub.length > setting.subChartMaxCount) {
        sub = sub.skip(sub.length - setting.subChartMaxCount).toSet();
      }
      for (var key in sub) {
        Indicator? indicator = customSubIndicators.getItem(key);
        indicator ??= indicators.subIndicators.getItem(key);
        if (indicator != null) {
          // 使用前先解绑
          indicator.dispose();
          subRectIndicatorQueue.append(indicator)?.dispose();
        }
      }
    }
  }

  /// 收集当前已打开指标的计算参数
  Map<IIndicatorKey, dynamic> getOpenedIndicatorCalcParams() {
    final calcParams = <IIndicatorKey, dynamic>{};
    calcParams.addAll(mainIndicator.getCalcParams());

    for (var subIndicator in subRectIndicatorQueue) {
      final params = subIndicator.getCalcParams();

      // 暂时 通过key的判断去掉主区与副区相同指标的重复计算参数.
      if (subIndicator.key == IndicatorType.subBoll &&
          calcParams[IndicatorType.boll] == params[IndicatorType.subBoll]) {
        continue;
      }
      if (subIndicator.key == IndicatorType.subSar &&
          calcParams[IndicatorType.sar] == params[IndicatorType.subSar]) {
        continue;
      }
      calcParams.addAll(params);
    }
    return calcParams;
  }

  FlexiKlineConfig clone() {
    try {
      return FlexiKlineConfig.fromJson(toJson());
    } catch (e) {
      debugPrint('FlexiKlineConfig clone failed!!!');
    }
    return this;
  }

  void update(FlexiKlineConfig config) {
    main = config.main;
    sub = config.sub;
    setting.update(config.setting);
  }

  /// 更新指标配置
  // void updateIndicatorsConfig(IndicatorsConfig config) {
  //   final keys = config.megerAndDisposeOldIndicator(indicators);
  //   indicators = config;

  //   for (var key in keys) {
  //     mainIndicator.appendIndicator(newIndicator, controller)
  //   }
  //   for (var indicator in mainIndicator.children) {
  //     if (keys.contains(indicator.key)) {
  //       indicator.dispose();
  //     }
  //   }
  //   for (var indicator in subIndicators) {
  //     if (keys.contains(indicator.key)) {
  //       indicator.dispose();
  //     }
  //   }
  // }

  void dispose() {
    indicators.dispose();
    mainIndicator.dispose();
    for (var indicator in subRectIndicatorQueue) {
      indicator.dispose();
    }
  }

  factory FlexiKlineConfig.fromJson(Map<String, dynamic> json) =>
      _$FlexiKlineConfigFromJson(json);

  Map<String, dynamic> toJson() {
    main = mainIndicator.children.map((e) => e.key).toSet();
    sub = subRectIndicatorQueue.map((e) => e.key).toSet();
    return _$FlexiKlineConfigToJson(this);
  }
}
