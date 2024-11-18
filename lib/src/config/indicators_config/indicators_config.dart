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

    /// 副区指标
    required this.time,
    required this.mavol,
  });

  /// 主区指标
  late CandleIndicator candle;
  late VolumeIndicator volume;
  late MAIndicator ma;

  /// 副区指标
  late TimeIndicator time;
  late MAVolumeIndicator mavol;

  /// 内置主区指标
  Map<IIndicatorKey, SinglePaintObjectIndicator> get mainIndicators => {
        candle.key: candle,
        volume.key: volume,
        ma.key: ma,
      };

  /// 内置副区指标
  Map<IIndicatorKey, Indicator> get subIndicators => {
        time.key: time,
        mavol.key: mavol,
      };

  /// 收集当前所有支持的指标的计算参数
  Map<IIndicatorKey, dynamic> getAllIndicatorCalcParams() {
    final calcParams = <IIndicatorKey, dynamic>{};
    mainIndicators.forEach((key, indicator) {
      calcParams.addAll(indicator.getCalcParams());
    });

    // 暂时 通过key的判断去掉主区与副区相同指标的重复计算参数.
    for (var entry in subIndicators.entries) {
      final params = entry.value.getCalcParams();
      if (entry.key == IndicatorType.subBoll &&
          calcParams[IndicatorType.boll] == params[entry.key]) {
        continue;
      }
      if (entry.key == IndicatorType.subSar &&
          calcParams[IndicatorType.sar] == params[entry.key]) {
        continue;
      }
      calcParams.addAll(params);
    }

    return calcParams;
  }

  /// 从[oldConfig]指标配置集合更新自定义指标. 并清理无效的旧指标.
  Set<IIndicatorKey> megerAndDisposeOldIndicator(IndicatorsConfig oldConfig) {
    Set<IIndicatorKey> keys = {};

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
