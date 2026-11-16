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

/// [RevealConfig] 的默认值与 JSON 契约, 以及它嵌入 [SettingConfig] 后的缺省行为。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RevealConfig', () {
    test('默认关闭, 首次加载一次, 600ms, easeInOut', () {
      const config = RevealConfig();

      expect(config.enabled, isFalse);
      expect(config.trigger, RevealTrigger.controllerFirst);
      expect(config.duration, 600);
      expect(config.curve, 'easeInOut');
    });

    test('JSON 往返保留字段', () {
      const config = RevealConfig(enabled: true, trigger: RevealTrigger.specFirstLoad, duration: 250, curve: 'linear');

      final restored = RevealConfig.fromJson(config.toJson());

      expect(restored.enabled, isTrue);
      expect(restored.trigger, RevealTrigger.specFirstLoad);
      expect(restored.duration, 250);
      expect(restored.curve, 'linear');
    });

    test('缺少字段时取默认值', () {
      final config = RevealConfig.fromJson(const <String, dynamic>{});

      expect(config.enabled, isFalse);
      expect(config.trigger, RevealTrigger.controllerFirst);
      expect(config.duration, 600);
    });
  });

  group('SettingConfig.reveal', () {
    test('默认嵌入关闭的 RevealConfig', () {
      expect(const SettingConfig().reveal.enabled, isFalse);
    });

    test('JSON 缺少 reveal 键时取默认值, 不抛错', () {
      final json = const SettingConfig().toJson()..remove('reveal');

      expect(SettingConfig.fromJson(json).reveal.enabled, isFalse);
    });

    test('reveal 字段往返不变', () {
      const config = SettingConfig(reveal: RevealConfig(enabled: true, trigger: RevealTrigger.specFirstLoad));

      final restored = SettingConfig.fromJson(config.toJson());

      expect(restored.reveal.enabled, isTrue);
      expect(restored.reveal.trigger, RevealTrigger.specFirstLoad);
    });
  });
}
