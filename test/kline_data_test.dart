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

import 'package:decimal/decimal.dart';
import 'package:flexi_kline/flexi_kline.dart' show ComputeMode;
import 'package:flexi_kline/src/model/export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlexiCandleModel.init', () {
    test('should create FlexiCandleModel from CandleModel with fast mode', () {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100.5',
        high: '110.0',
        low: '95.0',
        close: '105.0',
        volume: '1000',
        turnover: '100500',
        tradeCount: 100,
        confirmed: true,
      );
      final model = FlexiCandleModel.init(
        candle: candle,
        count: 10,
        mode: ComputeMode.fast,
      );

      expect(model.ts, 1715769600000);
      expect(model.open.toDouble(), 100.5);
      expect(model.high.toDouble(), 110.0);
      expect(model.low.toDouble(), 95.0);
      expect(model.close.toDouble(), 105.0);
      expect(model.vol.toDouble(), 1000.0);
      expect(model.turnover?.toDouble(), 100500.0);
      expect(model.confirmed, isTrue);
    });

    test('should create FlexiCandleModel from CandleModel with accurate mode', () {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100.123456789',
        high: '110.987654321',
        low: '95.111111111',
        close: '105.555555555',
        volume: '1000.12345',
      );
      final model = FlexiCandleModel.init(
        candle: candle,
        count: 5,
        mode: ComputeMode.accurate,
      );

      expect(model.ts, 1715769600000);
      expect(model.open.toDecimal(), Decimal.parse('100.123456789'));
      expect(model.high.toDecimal(), Decimal.parse('110.987654321'));
      expect(model.low.toDecimal(), Decimal.parse('95.111111111'));
      expect(model.close.toDecimal(), Decimal.parse('105.555555555'));
      expect(model.vol.toDecimal(), Decimal.parse('1000.12345'));
      expect(model.turnover, isNull);
      expect(model.confirmed, isTrue);
    });

    test('should initialize slots with correct count', () {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '100',
        low: '100',
        close: '100',
        volume: '100',
      );
      final model = FlexiCandleModel.init(candle: candle, count: 15);

      // 所有槽位初始为 null
      for (int i = 0; i < 15; i++) {
        expect(model.get<Object>(i), isNull);
      }
    });
  });

  group('FlexiCandleModel OHLCV getters', () {
    late FlexiCandleModel model;

    setUp(() {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '120',
        low: '80',
        close: '110',
        volume: '5000',
        turnover: '500000',
        tradeCount: 100,
        confirmed: true,
      );
      model = FlexiCandleModel.init(candle: candle, count: 5);
    });

    test('should return correct ts', () {
      expect(model.ts, 1715769600000);
    });

    test('should return correct open', () {
      expect(model.open.toDouble(), 100.0);
    });

    test('should return correct high', () {
      expect(model.high.toDouble(), 120.0);
    });

    test('should return correct low', () {
      expect(model.low.toDouble(), 80.0);
    });

    test('should return correct close', () {
      expect(model.close.toDouble(), 110.0);
    });

    test('should return correct vol', () {
      expect(model.vol.toDouble(), 5000.0);
    });

    test('should return correct turnover', () {
      expect(model.turnover?.toDouble(), 500000.0);
    });

    test('should return correct confirmed', () {
      expect(model.confirmed, isTrue);
    });
  });

  group('FlexiCandleModel getData/setData', () {
    late FlexiCandleModel model;

    setUp(() {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '100',
        low: '100',
        close: '100',
        volume: '100',
      );
      model = FlexiCandleModel.init(candle: candle, count: 10);
    });

    test('should setData and getData correctly', () {
      model.set(0, '100');
      model.set(1, '101');
      model.set(2, '102');

      expect(model.get<String>(0), '100');
      expect(model.get<String>(1), '101');
      expect(model.get<String>(2), '102');
    });

    test('should setData with different types', () {
      model.set(0, 'string_value');
      model.set(1, 123);
      model.set(2, 3.14);
      model.set(3, true);
      model.set(4, ['list', 'item']);
      model.set(5, {'key': 'value'});

      expect(model.get<String>(0), 'string_value');
      expect(model.get<int>(1), 123);
      expect(model.get<double>(2), 3.14);
      expect(model.get<bool>(3), true);
      expect(model.get<List<String>>(4), ['list', 'item']);
      expect(model.get<Map<String, String>>(5), {'key': 'value'});
    });

    test('should return null for type mismatch', () {
      model.set(0, 'string_value');
      model.set(1, 123);

      // 类型不匹配时返回 null
      expect(model.get<int>(0), isNull);
      expect(model.get<String>(1), isNull);
    });

    test('should overwrite existing data', () {
      model.set(0, 'first');
      expect(model.get<String>(0), 'first');

      model.set(0, 'second');
      expect(model.get<String>(0), 'second');

      model.set(0, 123);
      expect(model.get<int>(0), 123);
      expect(model.get<String>(0), isNull);
    });

    test('setData should return true on success', () {
      expect(model.set(0, 'value'), isTrue);
      expect(model.set(9, 'value'), isTrue);
    });

    test('setData should return false on out of bounds', () {
      expect(model.set(-1, 'value'), isFalse);
      expect(model.set(10, 'value'), isFalse);
      expect(model.set(100, 'value'), isFalse);
    });

    test('getData should return null for out of bounds', () {
      expect(model.get<String>(-1), isNull);
      expect(model.get<String>(10), isNull);
      expect(model.get<String>(100), isNull);
    });
  });

  group('FlexiCandleModel operator[] and operator[]=', () {
    late FlexiCandleModel model;

    setUp(() {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '100',
        low: '100',
        close: '100',
        volume: '100',
      );
      model = FlexiCandleModel.init(candle: candle, count: 10);
    });

    test('operator[]= should set data correctly', () {
      model[0] = 'value0';
      model[1] = 123;
      model[2] = 3.14;

      expect(model[0], 'value0');
      expect(model[1], 123);
      expect(model[2], 3.14);
    });

    test('operator[] should return null for empty slot', () {
      expect(model[0], isNull);
      expect(model[5], isNull);
      expect(model[9], isNull);
    });

    test('operator[]= should overwrite existing data', () {
      model[0] = 'first';
      expect(model[0], 'first');

      model[0] = 'second';
      expect(model[0], 'second');

      model[0] = 999;
      expect(model[0], 999);
    });

    test('operator[] should return null for out of bounds', () {
      expect(model[-1], isNull);
      expect(model[10], isNull);
      expect(model[100], isNull);
    });

    test('operator[]= should silently ignore out of bounds', () {
      // 不应抛出异常
      model[-1] = 'value';
      model[10] = 'value';
      model[100] = 'value';

      // 验证有效范围内的数据未受影响
      expect(model[0], isNull);
      expect(model[9], isNull);
    });

    test('operator[] and getData should return same value', () {
      model[0] = 'test_value';
      model.set(1, 'another_value');

      // 两种方式访问应该返回相同的值
      expect(model[0], model.get<String>(0));
      expect(model[1], model.get<String>(1));
    });

    test('operator[]= and setData should be interchangeable', () {
      model[0] = 'via_operator';
      model.set(1, 'via_setData');

      expect(model.get<String>(0), 'via_operator');
      expect(model[1], 'via_setData');
    });

    test('operator[] should work with complex types', () {
      final list = ['a', 'b', 'c'];
      final map = {'key': 'value'};
      final flexiNum = FlexiNum.fromNum(100.5);

      model[0] = list;
      model[1] = map;
      model[2] = flexiNum;

      expect(model[0], list);
      expect(model[1], map);
      expect(model[2], flexiNum);
    });

    test('operator[]= with null should clear the slot', () {
      model[0] = 'value';
      expect(model[0], 'value');
      expect(model.isEmpty(0), isTrue);

      model[0] = null;
      expect(model[0], isNull);
      expect(model.isEmpty(0), isFalse);
    });
  });

  group('FlexiCandleModel hasData/clearData', () {
    late FlexiCandleModel model;

    setUp(() {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '100',
        low: '100',
        close: '100',
        volume: '100',
      );
      model = FlexiCandleModel.init(candle: candle, count: 5);
    });

    test('hasData should return false for empty slot', () {
      expect(model.isEmpty(0), isFalse);
      expect(model.isEmpty(1), isFalse);
      expect(model.isEmpty(4), isFalse);
    });

    test('hasData should return true for non-empty slot', () {
      model.set(0, 'value');
      model.set(2, 123);

      expect(model.isEmpty(0), isTrue);
      expect(model.isEmpty(1), isFalse);
      expect(model.isEmpty(2), isTrue);
    });

    test('hasData should return false for out of bounds', () {
      expect(model.isEmpty(-1), isFalse);
      expect(model.isEmpty(5), isFalse);
      expect(model.isEmpty(100), isFalse);
    });

    test('clearData should clear specific slot', () {
      model.set(0, 'value0');
      model.set(1, 'value1');
      model.set(2, 'value2');

      model.clean(1);

      expect(model.isEmpty(0), isTrue);
      expect(model.isEmpty(1), isFalse);
      expect(model.isEmpty(2), isTrue);
      expect(model.get<String>(1), isNull);
    });

    test('clearData should handle out of bounds gracefully', () {
      model.set(0, 'value');

      // 不应该抛出异常
      model.clean(-1);
      model.clean(10);

      expect(model.isEmpty(0), isTrue);
    });

    test('clearAllData should clear all slots', () {
      model.set(0, 'value0');
      model.set(1, 'value1');
      model.set(2, 'value2');
      model.set(3, 'value3');
      model.set(4, 'value4');

      model.cleanAll();

      for (int i = 0; i < 5; i++) {
        expect(model.isEmpty(i), isFalse);
        expect(model.get<String>(i), isNull);
      }
    });
  });

  group('FlexiCandleModel hasValidData', () {
    late FlexiCandleModel model;

    setUp(() {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '100',
        low: '100',
        close: '100',
        volume: '100',
      );
      model = FlexiCandleModel.init(candle: candle, count: 5);
    });

    test('hasValidData should return false when all slots are empty', () {
      expect(model.hasValidData, isFalse);
    });

    test('hasValidData should return true when any slot has data', () {
      model.set(2, 'some_value');
      expect(model.hasValidData, isTrue);
    });

    test('hasValidData should return false after clearAllData', () {
      model.set(0, 'value');
      expect(model.hasValidData, isTrue);

      model.cleanAll();
      expect(model.hasValidData, isFalse);
    });
  });

  group('FlexiCandleModel isLong', () {
    test('isLong should return true when close >= open', () {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '120',
        low: '95',
        close: '110',
        volume: '100',
      );
      final model = FlexiCandleModel.init(candle: candle, count: 5);

      expect(model.isLong, isTrue);
    });

    test('isLong should return true when close == open', () {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '120',
        low: '95',
        close: '100',
        volume: '100',
      );
      final model = FlexiCandleModel.init(candle: candle, count: 5);

      expect(model.isLong, isTrue);
    });

    test('isLong should return false when close < open', () {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '105',
        low: '85',
        close: '90',
        volume: '100',
      );
      final model = FlexiCandleModel.init(candle: candle, count: 5);

      expect(model.isLong, isFalse);
    });
  });

  group('FlexiCandleModel ComputeMode', () {
    test('fast mode should use double internally', () {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100.123456789123456789',
        high: '100',
        low: '100',
        close: '100',
        volume: '100',
      );
      final model = FlexiCandleModel.init(
        candle: candle,
        count: 5,
        mode: ComputeMode.fast,
      );

      // fast mode 使用 double，会有精度损失
      final openDouble = model.open.toDouble();
      expect(openDouble, closeTo(100.12345678912346, 0.0000001));
    });

    test('accurate mode should use Decimal internally', () {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100.123456789123456789',
        high: '100',
        low: '100',
        close: '100',
        volume: '100',
      );
      final model = FlexiCandleModel.init(
        candle: candle,
        count: 5,
        mode: ComputeMode.accurate,
      );

      // accurate mode 使用 Decimal，保持精度
      final openDecimal = model.open.toDecimal();
      expect(openDecimal, Decimal.parse('100.123456789123456789'));
    });
  });

  group('FlexiCandleModel edge cases', () {
    test('should handle zero count', () {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '100',
        low: '100',
        close: '100',
        volume: '100',
      );
      final model = FlexiCandleModel.init(candle: candle, count: 0);

      expect(model.get<String>(0), isNull);
      expect(model.set(0, 'value'), isFalse);
      expect(model.isEmpty(0), isFalse);
      expect(model.hasValidData, isFalse);
    });

    test('should handle null turnover', () {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '100',
        low: '100',
        close: '100',
        volume: '100',
        turnover: null,
      );
      final model = FlexiCandleModel.init(candle: candle, count: 5);

      expect(model.turnover, isNull);
    });

    test('should handle large indicator count', () {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '100',
        low: '100',
        close: '100',
        volume: '100',
      );
      final model = FlexiCandleModel.init(candle: candle, count: 100);

      model.set(0, 'first');
      model.set(99, 'last');

      expect(model.get<String>(0), 'first');
      expect(model.get<String>(99), 'last');
      expect(model.get<String>(50), isNull);
    });
  });
}
