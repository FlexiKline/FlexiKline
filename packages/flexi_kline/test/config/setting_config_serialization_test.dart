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

/// [SettingConfig] 的 JSON 契约：宿主落盘的配置要能原样读回，读到不认识的键时取默认值而不是抛错。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingConfig JSON', () {
    test('latestCandleInitOffset 往返不变', () {
      const config = SettingConfig(latestCandleInitOffset: 123);

      final json = config.toJson();
      expect(json['latestCandleInitOffset'], 123);
      expect(SettingConfig.fromJson(json).latestCandleInitOffset, 123);
    });

    test('缺少 latestCandleInitOffset 时取默认值 80', () {
      final json = const SettingConfig().toJson()..remove('latestCandleInitOffset');

      expect(SettingConfig.fromJson(json).latestCandleInitOffset, 80);
    });

    test('键名 firstCandleInitOffset 不被识别：不抛错，取默认值', () {
      final json = const SettingConfig().toJson()
        ..remove('latestCandleInitOffset')
        ..['firstCandleInitOffset'] = 123;

      final config = SettingConfig.fromJson(json);

      expect(config.latestCandleInitOffset, 80);
      expect(config.toJson().containsKey('firstCandleInitOffset'), isFalse);
    });
  });
}
