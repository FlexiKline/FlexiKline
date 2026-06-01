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

import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flexi_kline/src/framework/serializers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IIndicatorKey 创建和基本属性', () {
    test('DirectIndicatorKey 创建 - 只提供 id', () {
      const key = DirectIndicatorKey('test_id');
      expect(key.id, 'test_id');
      expect(key.label, 'test_id'); // label 默认为 id
    });

    test('DirectIndicatorKey 创建 - 提供 id 和 label', () {
      const key = DirectIndicatorKey('test_id', label: 'Test Label');
      expect(key.id, 'test_id');
      expect(key.label, 'Test Label');
    });

    test('ComputedIndicatorKey 创建 - 只提供 id', () {
      const key = ComputedIndicatorKey('kdj');
      expect(key.id, 'kdj');
      expect(key.label, 'kdj');
    });

    test('ComputedIndicatorKey 创建 - 提供 id 和 label', () {
      const key = ComputedIndicatorKey('macd', label: 'MACD Indicator');
      expect(key.id, 'macd');
      expect(key.label, 'MACD Indicator');
    });

    test('ExternalIndicatorKey 创建 - 只提供 id', () {
      const key = ExternalIndicatorKey('trade');
      expect(key.id, 'trade');
      expect(key.label, 'trade');
    });

    test('ExternalIndicatorKey 创建 - 提供 id 和 label', () {
      const key = ExternalIndicatorKey('order', label: 'Order Info');
      expect(key.id, 'order');
      expect(key.label, 'Order Info');
    });
  });

  group('IIndicatorKey 相等性和哈希', () {
    test('相同类型的相同 id 应该相等', () {
      const key1 = DirectIndicatorKey('test');
      const key2 = DirectIndicatorKey('test');
      expect(key1, equals(key2));
      expect(key1.hashCode, equals(key2.hashCode));
    });

    test('相同类型的不同 id 应该不相等', () {
      const key1 = DirectIndicatorKey('test1');
      const key2 = DirectIndicatorKey('test2');
      expect(key1, isNot(equals(key2)));
    });

    test('不同类型的相同 id 应该不相等', () {
      const key1 = DirectIndicatorKey('test');
      const key2 = ComputedIndicatorKey('test');
      expect(key1, isNot(equals(key2)));
    });

    test('label 不同不影响相等性', () {
      const key1 = DirectIndicatorKey('test', label: 'Label 1');
      const key2 = DirectIndicatorKey('test', label: 'Label 2');
      expect(key1, equals(key2)); // 只比较 id 和 runtimeType
    });
  });

  group('IIndicatorKey toString', () {
    test('DirectIndicatorKey toString 格式', () {
      const key = DirectIndicatorKey('main', label: 'Main');
      final str = key.toString();
      expect(str, contains('DirectIndicatorKey'));
      expect(str, contains('main'));
      expect(str, contains('Main'));
    });

    test('ComputedIndicatorKey toString 格式', () {
      const key = ComputedIndicatorKey('kdj', label: 'KDJ');
      final str = key.toString();
      expect(str, contains('ComputedIndicatorKey'));
      expect(str, contains('kdj'));
      expect(str, contains('KDJ'));
    });

    test('ExternalIndicatorKey toString 格式', () {
      const key = ExternalIndicatorKey('trade', label: 'Trade');
      final str = key.toString();
      expect(str, contains('ExternalIndicatorKey'));
      expect(str, contains('trade'));
      expect(str, contains('Trade'));
    });
  });

  group('IIndicatorKeyConvert 序列化 (toJson)', () {
    const converter = IIndicatorKeyConvert();

    test('DirectIndicatorKey 序列化', () {
      const key = DirectIndicatorKey('main', label: 'Main');
      final json = converter.toJson(key);
      expect(json, isA<String>());
      expect(json, contains('DirectIndicatorKey'));
      expect(json, contains('main'));
      expect(json, contains('Main'));
    });

    test('ComputedIndicatorKey 序列化', () {
      const key = ComputedIndicatorKey('kdj', label: 'KDJ Indicator');
      final json = converter.toJson(key);
      expect(json, isA<String>());
      expect(json, contains('ComputedIndicatorKey'));
      expect(json, contains('kdj'));
      expect(json, contains('KDJ Indicator'));
    });

    test('ExternalIndicatorKey 序列化', () {
      const key = ExternalIndicatorKey('trade', label: 'Trade Info');
      final json = converter.toJson(key);
      expect(json, isA<String>());
      expect(json, contains('ExternalIndicatorKey'));
      expect(json, contains('trade'));
      expect(json, contains('Trade Info'));
    });

    test('label 包含冒号的序列化', () {
      const key = DirectIndicatorKey('test', label: 'Label:With:Colons');
      final json = converter.toJson(key);
      expect(json, contains('Label:With:Colons'));
    });
  });

  group('IIndicatorKeyConvert 反序列化 (fromJson)', () {
    const converter = IIndicatorKeyConvert();

    test('DirectIndicatorKey 反序列化', () {
      const json = 'DirectIndicatorKey:main:Main';
      final key = converter.fromJson(json);
      expect(key, isA<DirectIndicatorKey>());
      expect(key.id, 'main');
      expect(key.label, 'Main');
    });

    test('ComputedIndicatorKey 反序列化', () {
      const json = 'ComputedIndicatorKey:kdj:KDJ Indicator';
      final key = converter.fromJson(json);
      expect(key, isA<ComputedIndicatorKey>());
      expect(key.id, 'kdj');
      expect(key.label, 'KDJ Indicator');
    });

    test('ExternalIndicatorKey 反序列化', () {
      const json = 'ExternalIndicatorKey:trade:Trade Info';
      final key = converter.fromJson(json);
      expect(key, isA<ExternalIndicatorKey>());
      expect(key.id, 'trade');
      expect(key.label, 'Trade Info');
    });

    test('label 包含冒号的反序列化', () {
      const json = 'DirectIndicatorKey:test:Label:With:Colons';
      final key = converter.fromJson(json);
      expect(key, isA<DirectIndicatorKey>());
      expect(key.id, 'test');
      expect(key.label, 'Label:With:Colons');
    });

    test('无效格式 - 少于3段返回 unknownIndicatorKey', () {
      final key1 = converter.fromJson('DirectIndicatorKey:test');
      expect(key1, equals(unknownIndicatorKey));

      final key2 = converter.fromJson('DirectIndicatorKey');
      expect(key2, equals(unknownIndicatorKey));

      final key3 = converter.fromJson('');
      expect(key3, equals(unknownIndicatorKey));
    });

    test('无效格式 - id 为空返回 unknownIndicatorKey', () {
      final key = converter.fromJson('DirectIndicatorKey::Label');
      expect(key, equals(unknownIndicatorKey));
    });

    test('未知类型前缀 - 默认返回 DirectIndicatorKey', () {
      const json = 'UnknownType:test:Test Label';
      final key = converter.fromJson(json);
      expect(key, isA<DirectIndicatorKey>());
      expect(key.id, 'test');
      expect(key.label, 'Test Label');
    });
  });

  group('IIndicatorKeyConvert 序列化-反序列化往返', () {
    const converter = IIndicatorKeyConvert();

    test('DirectIndicatorKey 往返', () {
      const original = DirectIndicatorKey('main', label: 'Main Indicator');
      final json = converter.toJson(original);
      final restored = converter.fromJson(json);
      expect(restored, isA<DirectIndicatorKey>());
      expect(restored.id, original.id);
      expect(restored.label, original.label);
    });

    test('ComputedIndicatorKey 往返', () {
      const original = ComputedIndicatorKey('macd', label: 'MACD');
      final json = converter.toJson(original);
      final restored = converter.fromJson(json);
      expect(restored, isA<ComputedIndicatorKey>());
      expect(restored.id, original.id);
      expect(restored.label, original.label);
    });

    test('ExternalIndicatorKey 往返', () {
      const original = ExternalIndicatorKey('order', label: 'Order');
      final json = converter.toJson(original);
      final restored = converter.fromJson(json);
      expect(restored, isA<ExternalIndicatorKey>());
      expect(restored.id, original.id);
      expect(restored.label, original.label);
    });

    test('label 包含冒号的往返', () {
      const original = DirectIndicatorKey('test', label: 'A:B:C:D');
      final json = converter.toJson(original);
      final restored = converter.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.label, original.label);
    });
  });

  group('DirectIndicatorKeyConvert 序列化和反序列化', () {
    const converter = DirectIndicatorKeyConvert();

    test('DirectIndicatorKey 序列化', () {
      const key = DirectIndicatorKey('main', label: 'Main');
      final json = converter.toJson(key);
      expect(json, contains('DirectIndicatorKey'));
      expect(json, contains('main'));
      expect(json, contains('Main'));
    });

    test('DirectIndicatorKey 反序列化', () {
      const json = 'DirectIndicatorKey:main:Main';
      final key = converter.fromJson(json);
      expect(key, isA<DirectIndicatorKey>());
      expect(key.id, 'main');
      expect(key.label, 'Main');
    });

    test('反序列化其他类型时转换为 DirectIndicatorKey', () {
      const json = 'ComputedIndicatorKey:test:Test';
      final key = converter.fromJson(json);
      expect(key, isA<DirectIndicatorKey>());
      expect(key.id, 'test');
      expect(key.label, 'Test');
    });
  });

  group('ComputedIndicatorKeyConvert 序列化和反序列化', () {
    const converter = ComputedIndicatorKeyConvert();

    test('ComputedIndicatorKey 序列化', () {
      const key = ComputedIndicatorKey('kdj', label: 'KDJ');
      final json = converter.toJson(key);
      expect(json, contains('ComputedIndicatorKey'));
      expect(json, contains('kdj'));
      expect(json, contains('KDJ'));
    });

    test('ComputedIndicatorKey 反序列化', () {
      const json = 'ComputedIndicatorKey:kdj:KDJ';
      final key = converter.fromJson(json);
      expect(key, isA<ComputedIndicatorKey>());
      expect(key.id, 'kdj');
      expect(key.label, 'KDJ');
    });

    test('反序列化其他类型时转换为 ComputedIndicatorKey', () {
      const json = 'DirectIndicatorKey:test:Test';
      final key = converter.fromJson(json);
      expect(key, isA<ComputedIndicatorKey>());
      expect(key.id, 'test');
      expect(key.label, 'Test');
    });
  });

  group('ExternalIndicatorKeyConvert 序列化和反序列化', () {
    const converter = ExternalIndicatorKeyConvert();

    test('ExternalIndicatorKey 序列化', () {
      const key = ExternalIndicatorKey('trade', label: 'Trade');
      final json = converter.toJson(key);
      expect(json, contains('ExternalIndicatorKey'));
      expect(json, contains('trade'));
      expect(json, contains('Trade'));
    });

    test('ExternalIndicatorKey 反序列化', () {
      const json = 'ExternalIndicatorKey:trade:Trade';
      final key = converter.fromJson(json);
      expect(key, isA<ExternalIndicatorKey>());
      expect(key.id, 'trade');
      expect(key.label, 'Trade');
    });

    test('反序列化其他类型时转换为 ExternalIndicatorKey', () {
      const json = 'DirectIndicatorKey:test:Test';
      final key = converter.fromJson(json);
      expect(key, isA<ExternalIndicatorKey>());
      expect(key.id, 'test');
      expect(key.label, 'Test');
    });
  });

  group('常量 IndicatorKey', () {
    test('unknownIndicatorKey 属性', () {
      expect(unknownIndicatorKey, isA<DirectIndicatorKey>());
      expect(unknownIndicatorKey.id, 'unknown');
      expect(unknownIndicatorKey.label, 'unknown');
    });

    test('mainIndicatorKey 属性', () {
      expect(mainIndicatorKey, isA<DirectIndicatorKey>());
      expect(mainIndicatorKey.id, 'main');
      expect(mainIndicatorKey.label, 'Main');
    });

    test('candleIndicatorKey 属性', () {
      expect(candleIndicatorKey, isA<DirectIndicatorKey>());
      expect(candleIndicatorKey.id, 'candle');
      expect(candleIndicatorKey.label, 'Candle');
    });

    test('timeIndicatorKey 属性', () {
      expect(timeIndicatorKey, isA<DirectIndicatorKey>());
      expect(timeIndicatorKey.id, 'time');
      expect(timeIndicatorKey.label, 'Time');
    });
  });

  group('边界情况测试', () {
    const converter = IIndicatorKeyConvert();

    test('空字符串 id', () {
      const key = DirectIndicatorKey('');
      expect(key.id, '');
      expect(key.label, '');
    });

    test('空字符串 label', () {
      const key = DirectIndicatorKey('test', label: '');
      expect(key.id, 'test');
      expect(key.label, '');
    });

    test('很长的 id 和 label', () {
      final longId = 'a' * 1000;
      final longLabel = 'b' * 1000;
      final longKey = DirectIndicatorKey(longId, label: longLabel);
      final json = converter.toJson(longKey);
      final restored = converter.fromJson(json);
      expect(restored.id, longId);
      expect(restored.label, longLabel);
    });

    test('特殊字符在 id 和 label 中', () {
      const key = DirectIndicatorKey('test-id_123', label: 'Test@Label#123');
      final json = converter.toJson(key);
      final restored = converter.fromJson(json);
      expect(restored.id, 'test-id_123');
      expect(restored.label, 'Test@Label#123');
    });
  });
}
