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

import 'dart:convert';

import 'package:example/src/theme/flexi_theme.dart';
import 'package:example/src/utils/cache_util.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../config.dart';

class BitFlexiKlineStorage extends IStore {
  @override
  String get flexKlineConfigKey => 'flexi_kline_config_key_bit';

  @override
  Map<String, dynamic>? getFlexiKlineConfig() {
    try {
      final String? jsonStr = CacheUtil().get(flexKlineConfigKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final json = jsonDecode(jsonStr);
        if (json is Map<String, dynamic>) {
          // return json;
          return {};
        }
      }
    } catch (err, stack) {
      defLogger.e('getModelList error:$err', stackTrace: stack);
    }
    return null;
  }

  @override
  void saveFlexiKlineConfig(Map<String, dynamic> klineConfig) {
    if (klineConfig.isNotEmpty) {
      final jsonSrc = jsonEncode(klineConfig);
      CacheUtil().setString(flexKlineConfigKey, jsonSrc);
    }
  }

  FlexiKlineConfig getFlexiKlineConfigObject(FKTheme theme) {
    return FlexiKlineConfig(
      grid: GridConfig(
        show: true,
        horizontal: GridAxis(
          show: true,
          width: 0.5,
          color: theme.dividerLine,
          type: LineType.solid,
          dashes: const [2, 2],
        ),
        vertical: GridAxis(
          show: true,
          width: 0.5,
          color: theme.dividerLine,
          type: LineType.solid,
          dashes: const [2, 2],
        ),
      ),
      setting: SettingConfig(),
      cross: CrossConfig(
        enable: true,
        crosshair: LineConfig(
          width: 0.5,
          color: theme.t1,
          type: LineType.dashed,
          dashes: const [3, 3],
        ),
        point: CrossPointConfig(
          radius: 2,
          width: 6,
          color: theme.t1,
        ),
        tickText: TextAreaConfig(
          style: TextStyle(
            color: theme.t1,
            fontSize: 10,
            fontWeight: FontWeight.normal,
            height: 1,
          ),
          background: theme.lightBg,
          padding: const EdgeInsets.all(2),
          border: BorderSide.none,
          borderRadius: const BorderRadius.all(
            Radius.circular(2),
          ),
        ),
      ),
    );
  }
}
