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

/// 指标 key 的相等语义与 JSON 形式 `类型:id:label`（label 可含冒号）。
library;

import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flexi_kline/src/framework/serializers.dart';
import 'package:flutter_test/flutter_test.dart';

/// 三类 key 与各自类型名。
final _kinds = <({String type, IIndicatorKey Function(String id, {String? label}) create})>[
  (type: 'DirectIndicatorKey', create: DirectIndicatorKey.new),
  (type: 'ComputedIndicatorKey', create: ComputedIndicatorKey.new),
  (type: 'ExternalIndicatorKey', create: ExternalIndicatorKey.new),
];

void main() {
  for (final (:type, :create) in _kinds) {
    group(type, () {
      test('label 缺省取 id', () {
        expect(create('kdj').label, 'kdj');
        expect(create('kdj', label: 'KDJ').label, 'KDJ');
        expect(create('kdj', label: '').label, '');
        expect(create('').label, '');
      });

      test('相等只看类型与 id, 不看 label', () {
        expect(create('a', label: 'A'), create('a', label: 'B'));
        expect(create('a').hashCode, create('a').hashCode);
        expect(create('a'), isNot(create('b')));
      });

      test('toString 带类型、id 与 label', () {
        expect(create('kdj', label: 'KDJ').toString(), allOf(contains(type), contains('kdj'), contains('KDJ')));
      });

      test('IIndicatorKeyConvert 按 类型:id:label 往返, 保留具体类型', () {
        const converter = IIndicatorKeyConvert();
        for (final (id, label) in [
          ('main', 'Main'),
          ('test', 'A:B:C'),
          ('test-id_123', 'Test@Label#123'),
          ('a' * 1000, 'b' * 1000),
        ]) {
          final key = create(id, label: label);
          final json = converter.toJson(key);
          expect(json, '$type:$id:$label');

          final restored = converter.fromJson(json);
          expect(restored, key);
          expect(restored.runtimeType, key.runtimeType);
          expect(restored.label, label);
        }
      });
    });
  }

  test('不同类型的同 id 不相等', () {
    expect(const DirectIndicatorKey('a'), isNot(const ComputedIndicatorKey('a')));
    expect(const ComputedIndicatorKey('a'), isNot(const ExternalIndicatorKey('a')));
  });

  group('IIndicatorKeyConvert.fromJson 的回落', () {
    const converter = IIndicatorKeyConvert();

    test('少于三段或 id 为空时返回 unknownIndicatorKey', () {
      for (final json in ['', 'DirectIndicatorKey', 'DirectIndicatorKey:test', 'DirectIndicatorKey::Label']) {
        expect(converter.fromJson(json), unknownIndicatorKey, reason: json);
      }
    });

    test('未知类型前缀按 DirectIndicatorKey 读回', () {
      final key = converter.fromJson('UnknownType:test:Test Label');

      expect(key, isA<DirectIndicatorKey>());
      expect(key.id, 'test');
      expect(key.label, 'Test Label');
    });
  });

  test('具体类型的转换器读回时统一成自己的类型', () {
    const json = 'ExternalIndicatorKey:test:Test';
    final readers = <(IIndicatorKey Function(String), Type)>[
      (const DirectIndicatorKeyConvert().fromJson, DirectIndicatorKey),
      (const ComputedIndicatorKeyConvert().fromJson, ComputedIndicatorKey),
      (const ExternalIndicatorKeyConvert().fromJson, ExternalIndicatorKey),
    ];
    for (final (read, type) in readers) {
      final key = read(json);
      expect(key.runtimeType, type);
      expect(key.id, 'test');
      expect(key.label, 'Test');
    }
    expect(
      const ComputedIndicatorKeyConvert().toJson(const ComputedIndicatorKey('kdj', label: 'KDJ')),
      'ComputedIndicatorKey:kdj:KDJ',
    );
  });

  test('内置 key', () {
    final builtIns = {
      unknownIndicatorKey: ('unknown', 'unknown'),
      mainIndicatorKey: ('main', 'Main'),
      candleIndicatorKey: ('candle', 'Candle'),
      timeIndicatorKey: ('time', 'Time'),
    };
    builtIns.forEach((key, idAndLabel) {
      expect(key, isA<DirectIndicatorKey>());
      expect((key.id, key.label), idAndLabel);
    });
  });
}
