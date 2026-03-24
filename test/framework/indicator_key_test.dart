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
    test('NormalIndicatorKey 创建 - 只提供 id', () {
      const key = NormalIndicatorKey('test_id');
      expect(key.id, 'test_id');
      expect(key.label, 'test_id'); // label 默认为 id
    });

    test('NormalIndicatorKey 创建 - 提供 id 和 label', () {
      const key = NormalIndicatorKey('test_id', label: 'Test Label');
      expect(key.id, 'test_id');
      expect(key.label, 'Test Label');
    });

    test('DataIndicatorKey 创建 - 只提供 id', () {
      const key = DataIndicatorKey('kdj');
      expect(key.id, 'kdj');
      expect(key.label, 'kdj');
    });

    test('DataIndicatorKey 创建 - 提供 id 和 label', () {
      const key = DataIndicatorKey('macd', label: 'MACD Indicator');
      expect(key.id, 'macd');
      expect(key.label, 'MACD Indicator');
    });

    test('BusinessIndicatorKey 创建 - 只提供 id', () {
      const key = BusinessIndicatorKey('trade');
      expect(key.id, 'trade');
      expect(key.label, 'trade');
    });

    test('BusinessIndicatorKey 创建 - 提供 id 和 label', () {
      const key = BusinessIndicatorKey('order', label: 'Order Info');
      expect(key.id, 'order');
      expect(key.label, 'Order Info');
    });
  });

  group('IIndicatorKey 相等性和哈希', () {
    test('相同类型的相同 id 应该相等', () {
      const key1 = NormalIndicatorKey('test');
      const key2 = NormalIndicatorKey('test');
      expect(key1, equals(key2));
      expect(key1.hashCode, equals(key2.hashCode));
    });

    test('相同类型的不同 id 应该不相等', () {
      const key1 = NormalIndicatorKey('test1');
      const key2 = NormalIndicatorKey('test2');
      expect(key1, isNot(equals(key2)));
    });

    test('不同类型的相同 id 应该不相等', () {
      const key1 = NormalIndicatorKey('test');
      const key2 = DataIndicatorKey('test');
      expect(key1, isNot(equals(key2)));
    });

    test('label 不同不影响相等性', () {
      const key1 = NormalIndicatorKey('test', label: 'Label 1');
      const key2 = NormalIndicatorKey('test', label: 'Label 2');
      expect(key1, equals(key2)); // 只比较 id 和 runtimeType
    });
  });

  group('IIndicatorKey toString', () {
    test('NormalIndicatorKey toString 格式', () {
      const key = NormalIndicatorKey('main', label: 'Main');
      final str = key.toString();
      expect(str, contains('NormalIndicatorKey'));
      expect(str, contains('main'));
      expect(str, contains('Main'));
    });

    test('DataIndicatorKey toString 格式', () {
      const key = DataIndicatorKey('kdj', label: 'KDJ');
      final str = key.toString();
      expect(str, contains('DataIndicatorKey'));
      expect(str, contains('kdj'));
      expect(str, contains('KDJ'));
    });

    test('BusinessIndicatorKey toString 格式', () {
      const key = BusinessIndicatorKey('trade', label: 'Trade');
      final str = key.toString();
      expect(str, contains('BusinessIndicatorKey'));
      expect(str, contains('trade'));
      expect(str, contains('Trade'));
    });
  });

  group('IIndicatorKeyConvert 序列化 (toJson)', () {
    const converter = IIndicatorKeyConvert();

    test('NormalIndicatorKey 序列化', () {
      const key = NormalIndicatorKey('main', label: 'Main');
      final json = converter.toJson(key);
      expect(json, isA<String>());
      expect(json, contains('NormalIndicatorKey'));
      expect(json, contains('main'));
      expect(json, contains('Main'));
    });

    test('DataIndicatorKey 序列化', () {
      const key = DataIndicatorKey('kdj', label: 'KDJ Indicator');
      final json = converter.toJson(key);
      expect(json, isA<String>());
      expect(json, contains('DataIndicatorKey'));
      expect(json, contains('kdj'));
      expect(json, contains('KDJ Indicator'));
    });

    test('BusinessIndicatorKey 序列化', () {
      const key = BusinessIndicatorKey('trade', label: 'Trade Info');
      final json = converter.toJson(key);
      expect(json, isA<String>());
      expect(json, contains('BusinessIndicatorKey'));
      expect(json, contains('trade'));
      expect(json, contains('Trade Info'));
    });

    test('label 包含冒号的序列化', () {
      const key = NormalIndicatorKey('test', label: 'Label:With:Colons');
      final json = converter.toJson(key);
      expect(json, contains('Label:With:Colons'));
    });
  });

  group('IIndicatorKeyConvert 反序列化 (fromJson)', () {
    const converter = IIndicatorKeyConvert();

    test('NormalIndicatorKey 反序列化', () {
      const json = 'NormalIndicatorKey:main:Main';
      final key = converter.fromJson(json);
      expect(key, isA<NormalIndicatorKey>());
      expect(key.id, 'main');
      expect(key.label, 'Main');
    });

    test('DataIndicatorKey 反序列化', () {
      const json = 'DataIndicatorKey:kdj:KDJ Indicator';
      final key = converter.fromJson(json);
      expect(key, isA<DataIndicatorKey>());
      expect(key.id, 'kdj');
      expect(key.label, 'KDJ Indicator');
    });

    test('BusinessIndicatorKey 反序列化', () {
      const json = 'BusinessIndicatorKey:trade:Trade Info';
      final key = converter.fromJson(json);
      expect(key, isA<BusinessIndicatorKey>());
      expect(key.id, 'trade');
      expect(key.label, 'Trade Info');
    });

    test('label 包含冒号的反序列化', () {
      const json = 'NormalIndicatorKey:test:Label:With:Colons';
      final key = converter.fromJson(json);
      expect(key, isA<NormalIndicatorKey>());
      expect(key.id, 'test');
      expect(key.label, 'Label:With:Colons');
    });

    test('无效格式 - 少于3段返回 unknownIndicatorKey', () {
      final key1 = converter.fromJson('NormalIndicatorKey:test');
      expect(key1, equals(unknownIndicatorKey));

      final key2 = converter.fromJson('NormalIndicatorKey');
      expect(key2, equals(unknownIndicatorKey));

      final key3 = converter.fromJson('');
      expect(key3, equals(unknownIndicatorKey));
    });

    test('无效格式 - id 为空返回 unknownIndicatorKey', () {
      final key = converter.fromJson('NormalIndicatorKey::Label');
      expect(key, equals(unknownIndicatorKey));
    });

    test('未知类型前缀 - 默认返回 NormalIndicatorKey', () {
      const json = 'UnknownType:test:Test Label';
      final key = converter.fromJson(json);
      expect(key, isA<NormalIndicatorKey>());
      expect(key.id, 'test');
      expect(key.label, 'Test Label');
    });
  });

  group('IIndicatorKeyConvert 序列化-反序列化往返', () {
    const converter = IIndicatorKeyConvert();

    test('NormalIndicatorKey 往返', () {
      const original = NormalIndicatorKey('main', label: 'Main Indicator');
      final json = converter.toJson(original);
      final restored = converter.fromJson(json);
      expect(restored, isA<NormalIndicatorKey>());
      expect(restored.id, original.id);
      expect(restored.label, original.label);
    });

    test('DataIndicatorKey 往返', () {
      const original = DataIndicatorKey('macd', label: 'MACD');
      final json = converter.toJson(original);
      final restored = converter.fromJson(json);
      expect(restored, isA<DataIndicatorKey>());
      expect(restored.id, original.id);
      expect(restored.label, original.label);
    });

    test('BusinessIndicatorKey 往返', () {
      const original = BusinessIndicatorKey('order', label: 'Order');
      final json = converter.toJson(original);
      final restored = converter.fromJson(json);
      expect(restored, isA<BusinessIndicatorKey>());
      expect(restored.id, original.id);
      expect(restored.label, original.label);
    });

    test('label 包含冒号的往返', () {
      const original = NormalIndicatorKey('test', label: 'A:B:C:D');
      final json = converter.toJson(original);
      final restored = converter.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.label, original.label);
    });
  });

  group('NormalIndicatorKeyConvert 序列化和反序列化', () {
    const converter = NormalIndicatorKeyConvert();

    test('NormalIndicatorKey 序列化', () {
      const key = NormalIndicatorKey('main', label: 'Main');
      final json = converter.toJson(key);
      expect(json, contains('NormalIndicatorKey'));
      expect(json, contains('main'));
      expect(json, contains('Main'));
    });

    test('NormalIndicatorKey 反序列化', () {
      const json = 'NormalIndicatorKey:main:Main';
      final key = converter.fromJson(json);
      expect(key, isA<NormalIndicatorKey>());
      expect(key.id, 'main');
      expect(key.label, 'Main');
    });

    test('反序列化其他类型时转换为 NormalIndicatorKey', () {
      const json = 'DataIndicatorKey:test:Test';
      final key = converter.fromJson(json);
      expect(key, isA<NormalIndicatorKey>());
      expect(key.id, 'test');
      expect(key.label, 'Test');
    });
  });

  group('DataIndicatorKeyConvert 序列化和反序列化', () {
    const converter = DataIndicatorKeyConvert();

    test('DataIndicatorKey 序列化', () {
      const key = DataIndicatorKey('kdj', label: 'KDJ');
      final json = converter.toJson(key);
      expect(json, contains('DataIndicatorKey'));
      expect(json, contains('kdj'));
      expect(json, contains('KDJ'));
    });

    test('DataIndicatorKey 反序列化', () {
      const json = 'DataIndicatorKey:kdj:KDJ';
      final key = converter.fromJson(json);
      expect(key, isA<DataIndicatorKey>());
      expect(key.id, 'kdj');
      expect(key.label, 'KDJ');
    });

    test('反序列化其他类型时转换为 DataIndicatorKey', () {
      const json = 'NormalIndicatorKey:test:Test';
      final key = converter.fromJson(json);
      expect(key, isA<DataIndicatorKey>());
      expect(key.id, 'test');
      expect(key.label, 'Test');
    });
  });

  group('BusinessIndicatorKeyConvert 序列化和反序列化', () {
    const converter = BusinessIndicatorKeyConvert();

    test('BusinessIndicatorKey 序列化', () {
      const key = BusinessIndicatorKey('trade', label: 'Trade');
      final json = converter.toJson(key);
      expect(json, contains('BusinessIndicatorKey'));
      expect(json, contains('trade'));
      expect(json, contains('Trade'));
    });

    test('BusinessIndicatorKey 反序列化', () {
      const json = 'BusinessIndicatorKey:trade:Trade';
      final key = converter.fromJson(json);
      expect(key, isA<BusinessIndicatorKey>());
      expect(key.id, 'trade');
      expect(key.label, 'Trade');
    });

    test('反序列化其他类型时转换为 BusinessIndicatorKey', () {
      const json = 'NormalIndicatorKey:test:Test';
      final key = converter.fromJson(json);
      expect(key, isA<BusinessIndicatorKey>());
      expect(key.id, 'test');
      expect(key.label, 'Test');
    });
  });

  group('常量 IndicatorKey', () {
    test('unknownIndicatorKey 属性', () {
      expect(unknownIndicatorKey, isA<NormalIndicatorKey>());
      expect(unknownIndicatorKey.id, 'unknown');
      expect(unknownIndicatorKey.label, 'unknown');
    });

    test('mainIndicatorKey 属性', () {
      expect(mainIndicatorKey, isA<NormalIndicatorKey>());
      expect(mainIndicatorKey.id, 'main');
      expect(mainIndicatorKey.label, 'Main');
    });

    test('candleIndicatorKey 属性', () {
      expect(candleIndicatorKey, isA<NormalIndicatorKey>());
      expect(candleIndicatorKey.id, 'candle');
      expect(candleIndicatorKey.label, 'Candle');
    });

    test('timeIndicatorKey 属性', () {
      expect(timeIndicatorKey, isA<NormalIndicatorKey>());
      expect(timeIndicatorKey.id, 'time');
      expect(timeIndicatorKey.label, 'Time');
    });
  });

  group('边界情况测试', () {
    const converter = IIndicatorKeyConvert();

    test('空字符串 id', () {
      const key = NormalIndicatorKey('');
      expect(key.id, '');
      expect(key.label, '');
    });

    test('空字符串 label', () {
      const key = NormalIndicatorKey('test', label: '');
      expect(key.id, 'test');
      expect(key.label, '');
    });

    test('很长的 id 和 label', () {
      final longId = 'a' * 1000;
      final longLabel = 'b' * 1000;
      final longKey = NormalIndicatorKey(longId, label: longLabel);
      final json = converter.toJson(longKey);
      final restored = converter.fromJson(json);
      expect(restored.id, longId);
      expect(restored.label, longLabel);
    });

    test('特殊字符在 id 和 label 中', () {
      const key = NormalIndicatorKey('test-id_123', label: 'Test@Label#123');
      final json = converter.toJson(key);
      final restored = converter.fromJson(json);
      expect(restored.id, 'test-id_123');
      expect(restored.label, 'Test@Label#123');
    });
  });
}
