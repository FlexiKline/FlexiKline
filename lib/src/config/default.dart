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

import '../constant.dart';
import '../framework/export.dart';
import '../indicators/export.dart';
import 'cross_config/cross_config.dart';
import 'flexi_kline_config/flexi_kline_config.dart';
import 'grid_config/grid_config.dart';
import 'indicators_config/indicators_config.dart';
import 'setting_config/setting_config.dart';
import 'tooltip_config/tooltip_config.dart';

final FlexiKlineConfig defaultFlexiKlineConfig = FlexiKlineConfig(
  grid: const GridConfig(),
  setting: SettingConfig(),
  cross: CrossConfig(),
  tooltip: TooltipConfig(),
  main: {candleKey},
  sub: {timeKey},
  indicators: IndicatorsConfig(
    candle: CandleIndicator(height: defaultMainIndicatorHeight),
    volume: VolumeIndicator(
      height: defaultSubIndicatorHeight,
      showYAxisTick: false,
      showCrossMark: false,
      showTips: false,
      useTint: true,
    ),
    ma: MAIndicator(height: defaultMainIndicatorHeight),
    ema: EMAIndicator(height: defaultMainIndicatorHeight),
    boll: BOLLIndicator(height: defaultMainIndicatorHeight),
    time: TimeIndicator(height: defaultTimeIndicatorHeight),
    macd: MACDIndicator(),
    kdj: KDJIndicator(),
    mavol: MAVolumeIndicator(
      volumeIndicator: VolumeIndicator(
        height: defaultSubIndicatorHeight,
        showYAxisTick: true,
        showCrossMark: true,
        showTips: true,
        useTint: false,
      ),
      volMaIndicator: VolMaIndicator(),
    ),
  ),
);

class FlexiKlineDefaultConfiguration implements IConfiguration {
  const FlexiKlineDefaultConfiguration();
  @override
  FlexiKlineConfig getFlexiKlineConfig() {
    return defaultFlexiKlineConfig;
  }

  @override
  void saveFlexiKlineConfig(FlexiKlineConfig config) {
    // TODO: implement saveFlexiKlineConfig
  }
}
