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

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';

import '../../framework/export.dart';
import '../../indicators/export.dart';

part 'indicators_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class IndicatorsConfig {
  // IndicatorsConfig({
  //   /// 主区指标
  //   required this.candle,
  //   required this.volume,
  //   required this.ma,
  //   required this.ema,
  //   required this.boll,

  //   /// 副区指标
  //   required this.time,
  //   required this.macd,
  //   required this.kdj,
  //   required this.mavol,
  // });

  IndicatorsConfig({
    /// 主区指标
    CandleIndicator? candle,
    VolumeIndicator? volume,
    MAIndicator? ma,
    EMAIndicator? ema,
    BOLLIndicator? boll,

    /// 副区指标
    TimeIndicator? time,
    MACDIndicator? macd,
    KDJIndicator? kdj,
    MAVolumeIndicator? mavol,
  }) {
    /// 主区指标
    this.candle = candle ?? CandleIndicator(height: 0);
    this.volume = volume ?? VolumeIndicator();
    this.ma = ma ?? MAIndicator(height: 0);
    this.ema = ema ?? EMAIndicator(height: 0);
    this.boll = boll ?? BOLLIndicator(height: 0);

    /// 副区指标
    this.time = time ?? TimeIndicator();
    this.macd = macd ?? MACDIndicator();
    this.kdj = kdj ?? KDJIndicator();
    this.mavol = mavol ??
        MAVolumeIndicator(
          volumeIndicator: VolumeIndicator(
            paintMode: PaintMode.combine,
            showYAxisTick: true,
            showCrossMark: true,
            showTips: true,
            useTint: false,
          ),
          volMaIndicator: VolMaIndicator(),
        );
  }

  /// 主区指标
  late CandleIndicator candle;
  late VolumeIndicator volume;
  late MAIndicator ma;
  late EMAIndicator ema;
  late BOLLIndicator boll;

  /// 副区指标
  late TimeIndicator time;
  late MACDIndicator macd;
  late KDJIndicator kdj;
  late MAVolumeIndicator mavol;

  /// 内置主区指标
  Map<ValueKey, SinglePaintObjectIndicator> get _innerMainIndicators => {
        // candle.key: candle,
        volume.key: volume,
        ma.key: ma,
        ema.key: ema,
        boll.key: boll,
      };

  /// 内置副区指标
  Map<ValueKey, Indicator> get _innerSubIndicators => {
        // time.key: time,
        macd.key: macd,
        kdj.key: kdj,
        mavol.key: mavol,
      };

  /// 用户自定义主区指标
  final Map<ValueKey, SinglePaintObjectIndicator> _customMainIndicators = {};

  /// 用户自定义副区指标
  final Map<ValueKey, Indicator> _customSubIndicators = {};

  /// 添加主区指标
  /// [indicator] 如果使用内置的ValueKey([IndicatorType]), 将会替换内置的指标.
  void addMainIndicator(SinglePaintObjectIndicator indicator) {
    _customMainIndicators[indicator.key] = indicator;
  }

  /// 删除[key]对应的指标. 注仅能删除自定义的指标.
  void delMainIndicator(ValueKey key) {
    _customMainIndicators.remove(key);
  }

  /// 添加副区指标
  /// [indicator] 如果使用内置的ValueKey([IndicatorType]), 将会替换内置的指标.
  void addSubIndicator(Indicator indicator) {
    _customSubIndicators[indicator.key] = indicator;
  }

  /// 删除副区[key]对应的指标.
  /// 注: 仅能删除自定义的指标.
  void delSubIndicator(ValueKey key) {
    _customSubIndicators.remove(key);
  }

  /// 主区指标集
  Map<ValueKey, SinglePaintObjectIndicator> get mainIndicators => {
        ..._innerMainIndicators,
        ..._customMainIndicators,
      };

  /// 副区指标集
  Map<ValueKey, Indicator> get subIndicators => {
        ..._innerSubIndicators,
        ..._customSubIndicators,
      };

  factory IndicatorsConfig.fromJson(Map<String, dynamic> json) =>
      _$IndicatorsConfigFromJson(json);

  Map<String, dynamic> toJson() => _$IndicatorsConfigToJson(this);
}
