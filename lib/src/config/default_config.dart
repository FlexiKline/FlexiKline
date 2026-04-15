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

import '../framework/export.dart';
import '../indicators/export.dart';
import 'cross_config/cross_config.dart';
import 'draw_config/draw_config.dart';
import 'flexi_kline_config/flexi_kline_config.dart';
import 'gesture_config/gesture_config.dart';
import 'grid_config/grid_config.dart';
import 'setting_config/setting_config.dart';

/// 通过[IFlexiKlineTheme]来配置FlexiKline基类.
mixin FlexiKlineThemeConfigurationMixin implements IConfiguration {
  String getCacheKey(String key) => '$configKey-$key';

  @override
  FlexiKlineConfig generateFlexiKlineConfig([FlexiKlineConfig? origin]) {
    return FlexiKlineConfig(
      grid: genGridConfig(origin?.grid),
      setting: genSettingConfig(origin?.setting),
      gesture: genGestureConfig(origin?.gesture),
      cross: genCrossConfig(origin?.cross),
      draw: genDrawConfig(origin?.draw),
      mainIndicator: genMainIndicator(origin?.mainIndicator),
      sub: genSubIndicators(origin?.sub),
    );
  }

  @override
  IndicatorBuilder<CandleIndicator> get candleIndicatorBuilder {
    return (json) => genCandleIndicator(
          jsonToInstance(json, CandleIndicator.fromJson),
        );
  }

  @override
  IndicatorBuilder<TimeIndicator> get timeIndicatorBuilder {
    return (json) => genTimeIndicator(
          jsonToInstance(json, TimeIndicator.fromJson),
        );
  }

  MainPaintObjectIndicator genMainIndicator(MainPaintObjectIndicator<Indicator>? mainIndicator);

  Set<IIndicatorKey> genSubIndicators([Set<IIndicatorKey>? sub]) {
    return sub ?? {};
  }

  @override
  Map<IIndicatorKey, IndicatorBuilder> get mainIndicatorBuilders => {};

  @override
  Map<IIndicatorKey, IndicatorBuilder> get subIndicatorBuilders => {};

  @override
  Map<IDrawType, DrawObjectBuilder> get drawObjectBuilders => {};

  GridConfig genGridConfig([GridConfig? grid]) {
    return grid ?? const GridConfig();
  }

  GestureConfig genGestureConfig([GestureConfig? gesture]) {
    return gesture ?? GestureConfig();
  }

  SettingConfig genSettingConfig([SettingConfig? setting]) {
    return setting ?? const SettingConfig();
  }

  CrossConfig genCrossConfig([CrossConfig? cross]) {
    return cross ?? const CrossConfig();
  }

  DrawConfig genDrawConfig([DrawConfig? draw]) {
    return draw ?? const DrawConfig();
  }

  CandleIndicator genCandleIndicator(CandleIndicator? instance) {
    return instance ?? CandleIndicator();
  }

  TimeIndicator genTimeIndicator(TimeIndicator? instance) {
    return instance ?? TimeIndicator();
  }
}
