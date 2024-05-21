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
import 'common.dart';
import 'indicator.dart';
import 'logger.dart';
import 'serializers.dart';

typedef IndicatorFromJson<T extends Indicator> = T Function(
  Map<String, dynamic>,
);

const defaultFlexKlineConfigKey = 'flexi_kline_config_key';

abstract class IConfiguration {
  String get flexKlineConfigKey => defaultFlexKlineConfigKey;

  Map<String, dynamic>? getFlexiKlineConfig();

  void saveFlexiKlineConfig(Map<String, dynamic> klineConfig);
}

mixin KlineConfiguration implements IConfiguration, ILogger {
  IConfiguration? configuration;

  @override
  String get flexKlineConfigKey {
    return configuration?.flexKlineConfigKey ?? defaultFlexKlineConfigKey;
  }

  @override
  Map<String, dynamic> getFlexiKlineConfig() {
    return configuration?.getFlexiKlineConfig() ?? <String, dynamic>{};
  }

  @override
  void saveFlexiKlineConfig(Map<String, dynamic> klineConfig) {
    final configData = Map<String, dynamic>.of(klineConfig);
    return configuration?.saveFlexiKlineConfig(configData);
  }

  Map<String, dynamic>? _flexiKlineConfig;

  Map<String, dynamic> get flexiKlineConfig {
    if (_flexiKlineConfig == null) {
      final initConfig = configuration?.getFlexiKlineConfig();
      if (initConfig != null && initConfig.isNotEmpty) {
        _flexiKlineConfig = Map<String, dynamic>.of(initConfig);
      }
      _flexiKlineConfig ??= <String, dynamic>{};
    }
    return _flexiKlineConfig!;
  }

  Map<String, dynamic> _getRootConfig(String key) {
    dynamic config = flexiKlineConfig[key];
    if (config == null || config is! Map<String, dynamic>) {
      flexiKlineConfig[key] = config = <String, dynamic>{};
    }
    return config;
  }

  Map<String, dynamic> get mainIndicatorConfig => _getRootConfig(jsonKeyMain);

  List<ValueKey> get mainChildrenKeys {
    dynamic list = mainIndicatorConfig[jsonKeyChildren];
    if (list is List) {
      return list.map((e) => parseValueKey(e)).toList();
    }
    return <ValueKey>[];
  }

  List<ValueKey> get subChildrenKeys {
    final list = flexiKlineConfig[jsonKeySub];
    if (list is List) {
      return list.map((e) => parseValueKey(e)).toList();
    }
    return <ValueKey>[];
  }

  Map<String, dynamic> get supportMainIndicatorsConfig {
    return _getRootConfig(jsonKeySupportMainIndicators);
  }

  Map<String, dynamic> get supportSubIndicatorsConfig {
    return _getRootConfig(jsonKeySupportSubIndicators);
  }

  MultiPaintObjectIndicator? restoreMainIndicator() {
    return _restoreIndicator(
      mainIndicatorConfig,
      mainChartKey,
      MultiPaintObjectIndicator.fromJson,
    );
  }

  T? restoreMainSupportIndicator<T extends Indicator>(
    ValueKey key,
    IndicatorFromJson<T> fromJson,
  ) {
    return _restoreIndicator(
      supportMainIndicatorsConfig,
      key,
      fromJson,
    );
  }

  T? restoreSubSupportIndicator<T extends Indicator>(
    ValueKey key,
    IndicatorFromJson<T> fromJson, {
    ValueKey? childKey,
  }) {
    return _restoreIndicator(
      supportSubIndicatorsConfig,
      key,
      fromJson,
      childKey: childKey,
    );
  }

  T? _restoreIndicator<T extends Indicator>(
    Map<String, dynamic> configs,
    ValueKey key,
    IndicatorFromJson<T> fromJson, {
    ValueKey? childKey,
  }) {
    if (configs.isEmpty) return null;
    try {
      final json = configs[convertValueKey(key)];
      if (json != null && json is Map<String, dynamic> && json.isNotEmpty) {
        if (childKey == null) {
          return fromJson(json);
        }
        final childJson = json[convertValueKey(childKey)];
        if (childJson != null &&
            childJson is Map<String, dynamic> &&
            childJson.isNotEmpty) {
          return fromJson(childJson);
        }
      }
    } catch (err, stack) {
      loge(
        '_restoreIndicator error',
        error: err,
        stackTrace: stack,
      );
    }
    return null;
  }

  void storeMainIndicator(
    MultiPaintObjectIndicator mainIndicator,
  ) {
    flexiKlineConfig[jsonKeyMain] = mainIndicator.toJson();
    flexiKlineConfig[jsonKeyMain][jsonKeyChildren] = mainIndicator.children
        .map(
          (e) => convertValueKey(e.key),
        )
        .toList();
  }

  void storeSubIndicators(Queue<Indicator> subIndicators) {
    flexiKlineConfig[jsonKeySub] = subIndicators
        .map(
          (e) => convertValueKey(e.key),
        )
        .toList();
  }

  void storeSupportMainIndicators(
    Map<ValueKey, SinglePaintObjectIndicator> supportIndicator,
  ) {
    flexiKlineConfig[jsonKeySupportMainIndicators] = supportIndicator.map(
      (key, value) => MapEntry<String, Map<String, dynamic>>(
        convertValueKey(key),
        value.toJson(),
      ),
    );
  }

  void storeSupportSubIndicators(
    Map<ValueKey, Indicator> supportIndicator,
  ) {
    flexiKlineConfig[jsonKeySupportSubIndicators] = supportIndicator.map(
      (key, value) => MapEntry<String, Map<String, dynamic>>(
        convertValueKey(key),
        value.toJson(),
      ),
    );
  }

  /// IndicatorsConfig
  Map<String, dynamic> get indicatorsConfigData => _getRootConfig(
        jsonKeyIndicators,
      );
  void storeIndicatorsData(IndicatorsConfig config) {
    flexiKlineConfig[jsonKeyIndicators] = config.toJson();
  }

  /// SettingConfig
  Map<String, dynamic> get settingConfigData => _getRootConfig(jsonKeySetting);
  void storeSettingData(SettingConfig config) {
    flexiKlineConfig[jsonKeySetting] = config.toJson();
  }

  /// GridConfig
  Map<String, dynamic> get gridConfigData => _getRootConfig(jsonKeyGrid);
  void storeGridConfig(GridConfig config) {
    flexiKlineConfig[jsonKeyGrid] = config.toJson();
  }

  /// CrossConfig
  Map<String, dynamic> get crossConfigData => _getRootConfig(jsonKeyCross);
  void storeCrossConfig(CrossConfig config) {
    flexiKlineConfig[jsonKeyCross] = config.toJson();
  }

  /// TooltipConfig
  Map<String, dynamic> get tooltipConfigData => _getRootConfig(jsonKeyTooltip);
  void storeTooltipConfig(TooltipConfig config) {
    flexiKlineConfig[jsonKeyTooltip] = config.toJson();
  }
}