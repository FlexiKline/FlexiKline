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

/// [DateMarkConfig] 的序列化与 [CandleIndicator.dateMark] 的旧配置兼容。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateMarkConfig 序列化', () {
    test('非默认值往返', () {
      const config = DateMarkConfig(
        show: false,
        spacing: 6,
        arrowSize: Size(12, 6),
        holdDuration: 0,
        position: DateMarkPosition.below,
        text: TextAreaConfig(
          style: TextStyle(fontSize: 12),
          backgroundColor: Color(0xFF123456),
          padding: EdgeInsets.all(3),
        ),
      );

      final restored = DateMarkConfig.fromJson(config.toJson());

      expect(restored.show, isFalse);
      expect(restored.spacing, 6);
      expect(restored.arrowSize, const Size(12, 6));
      expect(restored.holdDuration, 0);
      expect(restored.position, DateMarkPosition.below);
      expect(restored.text.style.fontSize, 12);
      expect(restored.text.backgroundColor?.toARGB32(), 0xFF123456);
      expect(restored.text.padding, const EdgeInsets.all(3));
    });

    test('空 JSON 回落默认值: 默认开启、auto、停留 2 秒', () {
      final restored = DateMarkConfig.fromJson(const {});

      expect(restored.show, isTrue);
      expect(restored.position, DateMarkPosition.auto);
      expect(restored.holdDuration, 2000);
      expect(restored.arrowSize, const DateMarkConfig().arrowSize);
    });

    test('未知 position 回落 auto', () {
      expect(DateMarkConfig.fromJson(const {'position': 'left'}).position, DateMarkPosition.auto);
    });
  });

  group('CandleIndicator.dateMark', () {
    test('旧配置没有 dateMark 键时取默认值', () {
      final json = CandleIndicator().toJson()..remove('dateMark');

      final restored = CandleIndicator.fromJson(json);

      expect(restored.dateMark.show, isTrue);
      expect(restored.dateMark.position, DateMarkPosition.auto);
    });

    test('随指标配置往返', () {
      final indicator = CandleIndicator(
        dateMark: const DateMarkConfig(show: false, position: DateMarkPosition.above),
      );

      final restored = CandleIndicator.fromJson(indicator.toJson());

      expect(restored.dateMark.show, isFalse);
      expect(restored.dateMark.position, DateMarkPosition.above);
    });
  });
}
