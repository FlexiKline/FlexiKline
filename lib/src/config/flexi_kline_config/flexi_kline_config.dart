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
import 'package:json_annotation/json_annotation.dart';

import '../../extension/export.dart';
import '../../framework/export.dart';
import '../cross_config/cross_config.dart';
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
    required this.tooltip,
    required this.indicators,
    this.main = const <ValueKey>{},
    this.sub = const <ValueKey>{},
  });

  final String key;
  GridConfig grid;
  SettingConfig setting;
  GestureConfig gesture;
  CrossConfig cross;
  TooltipConfig tooltip;
  IndicatorsConfig indicators;
  Set<ValueKey> main;
  Set<ValueKey> sub;

  @JsonKey(includeFromJson: false, includeToJson: false)
  late final MultiPaintObjectIndicator mainIndicator;
  @JsonKey(includeFromJson: false, includeToJson: false)
  late final ListQueue<Indicator> subIndicators;

  void init() {
    mainIndicator = MultiPaintObjectIndicator(
      key: mainChartKey,
      name: IndicatorType.main.label,
      height: setting.mainRect.height,
      padding: setting.mainPadding,
      drawBelowTipsArea: setting.mainDrawBelowTipsArea,
    );

    subIndicators = ListQueue<Indicator>(
      setting.subChartMaxCount,
    );

    if (!main.contains(candleKey)) {
      main.add(candleKey);
    }
    for (var key in main) {
      final indicator = indicators.mainIndicators.getItem(key);
      if (indicator != null) {
        indicator.dispose();
        mainIndicator.children.add(indicator);
      }
    }

    if (sub.contains(timeKey)) {
      sub.remove(timeKey);
    }
    if (sub.isNotEmpty) {
      if (sub.length > setting.subChartMaxCount) {
        sub = sub.skip(sub.length - setting.subChartMaxCount).toSet();
      }
      for (var key in sub) {
        final indicator = indicators.subIndicators.getItem(key);
        if (indicator != null) {
          indicator.dispose();
          subIndicators.add(indicator);
        }
      }
    }
  }

  FlexiKlineConfig clone() {
    try {
      return FlexiKlineConfig.fromJson(toJson());
    } catch (e) {
      debugPrint('FlexiKlineConfig clonse failed!!!');
    }
    return this;
  }

  void update(FlexiKlineConfig config) {
    main = config.main;
    sub = config.sub;
    setting.update(config.setting);
  }

  void dispose() {
    indicators.dispose();
    mainIndicator.dispose();
    for (var indicator in subIndicators) {
      indicator.dispose();
    }
  }

  factory FlexiKlineConfig.fromJson(Map<String, dynamic> json) =>
      _$FlexiKlineConfigFromJson(json);

  Map<String, dynamic> toJson() {
    main = mainIndicator.children.map((e) => e.key).toSet();
    sub = subIndicators.map((e) => e.key).toSet();
    return _$FlexiKlineConfigToJson(this);
  }
}
