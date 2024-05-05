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

import 'package:flexi_kline/flexi_kline.dart';

import '../config.dart';
import 'cache_util.dart';

class FlexiKlineStorage extends IStore {
  @override
  Map<String, dynamic>? getFlexiKlineConfig() {
    try {
      final String? jsonStr = CacheUtil().get(flexKlineConfigKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final json = jsonDecode(jsonStr);
        if (json is Map<String, dynamic>) {
          return json;
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
}
