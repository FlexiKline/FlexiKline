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
  IndicatorsConfig({
    /// 主区指标
    required this.candle,
    required this.volume,
    required this.ma,
    required this.ema,
    required this.boll,
    required this.sar,

    /// 副区指标
    required this.time,
    required this.macd,
    required this.kdj,
    required this.mavol,
    required this.subBoll,
    required this.subSar,
    required this.rsi,
  });

  // IndicatorsConfig({
  //   /// 主区指标
  //   CandleIndicator? candle,
  //   VolumeIndicator? volume,
  //   MAIndicator? ma,
  //   EMAIndicator? ema,
  //   BOLLIndicator? boll,

  //   /// 副区指标
  //   TimeIndicator? time,
  //   MACDIndicator? macd,
  //   KDJIndicator? kdj,
  //   MAVolumeIndicator? mavol,
  // }) {
  //   /// 主区指标
  //   this.candle = candle ?? CandleIndicator(height: 0);
  //   this.volume = volume ?? VolumeIndicator();
  //   this.ma = ma ?? MAIndicator(height: 0);
  //   this.ema = ema ?? EMAIndicator(height: 0);
  //   this.boll = boll ?? BOLLIndicator(height: 0);

  //   /// 副区指标
  //   this.time = time ?? TimeIndicator();
  //   this.macd = macd ?? MACDIndicator();
  //   this.kdj = kdj ?? KDJIndicator();
  //   this.mavol = mavol ??
  //       MAVolumeIndicator(
  //         volumeIndicator: VolumeIndicator(
  //           paintMode: PaintMode.combine,
  //           showYAxisTick: true,
  //           showCrossMark: true,
  //           showTips: true,
  //           useTint: false,
  //         ),
  //         volMaIndicator: VolMaIndicator(),
  //       );
  // }

  /// 主区指标
  late CandleIndicator candle;
  late VolumeIndicator volume;
  late MAIndicator ma;
  late EMAIndicator ema;
  late BOLLIndicator boll;
  late SARIndicator sar;

  /// 副区指标
  late TimeIndicator time;
  late MACDIndicator macd;
  late KDJIndicator kdj;
  late MAVolumeIndicator mavol;
  late BOLLIndicator subBoll;
  late SARIndicator subSar;
  late RSIIndicator rsi;

  /// 内置主区指标
  Map<ValueKey, SinglePaintObjectIndicator> get mainIndicators => {
        candle.key: candle,
        volume.key: volume,
        ma.key: ma,
        ema.key: ema,
        boll.key: boll,
        sar.key: sar,
      };

  /// 内置副区指标
  Map<ValueKey, Indicator> get subIndicators => {
        time.key: time,
        macd.key: macd,
        kdj.key: kdj,
        mavol.key: mavol,
        subBoll.key: subBoll,
        subSar.key: subSar,
        rsi.key: rsi,
      };

  /// 收集当前所有支持的指标的计算参数
  Map<ValueKey, dynamic> getAllIndicatorCalcParams() {
    final calcParams = <ValueKey, dynamic>{};
    mainIndicators.forEach((key, indicator) {
      calcParams.addAll(indicator.getCalcParams());
    });

    // 暂时 通过key的判断去掉主区与副区相同指标的重复计算参数.
    for (var entry in subIndicators.entries) {
      final params = entry.value.getCalcParams();
      if (entry.key == subBollKey && calcParams[bollKey] == params[entry.key]) {
        continue;
      }
      if (entry.key == subSarKey && calcParams[sarKey] == params[entry.key]) {
        continue;
      }
      calcParams.addAll(params);
    }

    return calcParams;
  }

  /// 从[oldConfig]指标配置集合更新自定义指标. 并清理无效的旧指标.
  Set<ValueKey> megerAndDisposeOldIndicator(IndicatorsConfig oldConfig) {
    Set<ValueKey> keys = {};

    /// 清理变更的主区指标
    oldConfig.mainIndicators.forEach((key, value) {
      final newVale = mainIndicators[key];
      if (!identical(newVale, value)) {
        value.dispose();
        keys.add(key);
      }
    });

    /// 清理变更的副区指标
    oldConfig.subIndicators.forEach((key, value) {
      final newVale = subIndicators[key];
      if (!identical(newVale, value)) {
        value.dispose();
        keys.add(key);
      }
    });
    return keys;
  }

  void dispose() {
    mainIndicators.forEach((key, indicator) {
      indicator.dispose();
    });
    subIndicators.forEach((key, indicator) {
      indicator.dispose();
    });
  }

  factory IndicatorsConfig.fromJson(Map<String, dynamic> json) =>
      _$IndicatorsConfigFromJson(json);

  Map<String, dynamic> toJson() => _$IndicatorsConfigToJson(this);
}
