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
  // ---------------------------------------------------------------------------
  // FlexiCandleModel.init
  // ---------------------------------------------------------------------------
  group('FlexiCandleModel.init', () {
    test('fast mode: 从 CandleModel 正确初始化', () {
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

    test('accurate mode: 从 CandleModel 正确初始化', () {
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
      // 默认 confirmed 为 true
      expect(model.confirmed, isTrue);
    });

    test('初始化后所有槽位为 null', () {
      final candle = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '100',
        low: '100',
        close: '100',
        volume: '100',
      );
      final model = FlexiCandleModel.init(candle: candle, count: 15);

      for (int i = 0; i < 15; i++) {
        expect(model.get<Object>(i), isNull);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // OHLCV getters
  // ---------------------------------------------------------------------------
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

    test('ts', () => expect(model.ts, 1715769600000));
    test('open', () => expect(model.open.toDouble(), 100.0));
    test('high', () => expect(model.high.toDouble(), 120.0));
    test('low', () => expect(model.low.toDouble(), 80.0));
    test('close', () => expect(model.close.toDouble(), 110.0));
    test('vol', () => expect(model.vol.toDouble(), 5000.0));
    test('turnover', () => expect(model.turnover?.toDouble(), 500000.0));
    test('tradeCount', () => expect(model.tradeCount, 100));
    test('confirmed', () => expect(model.confirmed, isTrue));

    test('isLong: close > open', () => expect(model.isLong, isTrue));
    test('isShort: close < open', () {
      final short = CandleModel(
        timestamp: 1715769600000,
        open: '110',
        high: '120',
        low: '80',
        close: '100',
        volume: '100',
      );
      expect(FlexiCandleModel.init(candle: short, count: 1).isShort, isTrue);
    });
    test('isLong: close == open', () {
      final doji = CandleModel(
        timestamp: 1715769600000,
        open: '100',
        high: '120',
        low: '80',
        close: '100',
        volume: '100',
      );
      expect(FlexiCandleModel.init(candle: doji, count: 1).isLong, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // getData / setData (get / set)
  // ---------------------------------------------------------------------------
  group('FlexiCandleModel get / set', () {
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

    test('set 后 get 返回正确值', () {
      model.set(0, '100');
      model.set(1, '101');
      model.set(2, '102');

      expect(model.get<String>(0), '100');
      expect(model.get<String>(1), '101');
      expect(model.get<String>(2), '102');
    });

    test('set 支持多种类型', () {
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

    test('get 类型不匹配返回 null', () {
      model.set(0, 'string_value');
      model.set(1, 123);

      expect(model.get<int>(0), isNull);
      expect(model.get<String>(1), isNull);
    });

    test('set 覆盖已有数据', () {
      model.set(0, 'first');
      expect(model.get<String>(0), 'first');

      model.set(0, 'second');
      expect(model.get<String>(0), 'second');

      model.set(0, 123);
      expect(model.get<int>(0), 123);
      expect(model.get<String>(0), isNull);
    });

    test('set 有效索引返回 true', () {
      expect(model.set(0, 'value'), isTrue);
      expect(model.set(9, 'value'), isTrue);
    });

    test('set 越界返回 false', () {
      expect(model.set(-1, 'value'), isFalse);
      expect(model.set(10, 'value'), isFalse);
      expect(model.set(100, 'value'), isFalse);
    });

    test('get 越界返回 null', () {
      expect(model.get<String>(-1), isNull);
      expect(model.get<String>(10), isNull);
      expect(model.get<String>(100), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // operator[] / operator[]=
  // 注：[] 越界按文档抛 RangeError
  // ---------------------------------------------------------------------------
  group('FlexiCandleModel operator[] / operator[]=', () {
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

    test('operator[]= 赋值后 operator[] 读取正确', () {
      model[0] = 'value0';
      model[1] = 123;
      model[2] = 3.14;

      expect(model[0], 'value0');
      expect(model[1], 123);
      expect(model[2], 3.14);
    });

    test('operator[] 空槽返回 null', () {
      expect(model[0], isNull);
      expect(model[5], isNull);
      expect(model[9], isNull);
    });

    test('operator[]= 覆盖已有值', () {
      model[0] = 'first';
      expect(model[0], 'first');

      model[0] = 'second';
      expect(model[0], 'second');

      model[0] = 999;
      expect(model[0], 999);
    });

    /// 越界读取抛 RangeError（文档明确说明）
    test('operator[] 越界抛 RangeError', () {
      expect(() => model[-1], throwsA(isA<RangeError>()));
      expect(() => model[10], throwsA(isA<RangeError>()));
      expect(() => model[100], throwsA(isA<RangeError>()));
    });

    /// 越界写入抛 RangeError（文档明确说明）
    test('operator[]= 越界抛 RangeError', () {
      expect(() => model[-1] = 'value', throwsA(isA<RangeError>()));
      expect(() => model[10] = 'value', throwsA(isA<RangeError>()));
      expect(() => model[100] = 'value', throwsA(isA<RangeError>()));
    });

    test('operator[] 与 get<T> 访问同一槽位结果一致', () {
      model[0] = 'test_value';
      model.set(1, 'another_value');

      expect(model[0], model.get<String>(0));
      expect(model[1], model.get<String>(1));
    });

    test('operator[]= 与 set 互换后数据一致', () {
      model[0] = 'via_operator';
      model.set(1, 'via_set');

      expect(model.get<String>(0), 'via_operator');
      expect(model[1], 'via_set');
    });

    test('operator[] 支持复杂类型', () {
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

    test('operator[]= 赋 null 后槽位变为空', () {
      model[0] = 'value';
      expect(model[0], 'value');
      expect(model.isEmpty(0), isFalse); // 有数据，isEmpty 为 false

      model[0] = null;
      expect(model[0], isNull);
      expect(model.isEmpty(0), isTrue); // null 后，isEmpty 为 true
    });
  });

  // ---------------------------------------------------------------------------
  // isEmpty / isNotEmpty / clean / cleanAll
  // ---------------------------------------------------------------------------
  group('FlexiCandleModel isEmpty / clean / cleanAll', () {
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

    test('初始化后所有槽位 isEmpty 为 true', () {
      expect(model.isEmpty(0), isTrue);
      expect(model.isEmpty(1), isTrue);
      expect(model.isEmpty(4), isTrue);
    });

    test('set 数据后 isEmpty 为 false', () {
      model.set(0, 'value');
      model.set(2, 123);

      expect(model.isEmpty(0), isFalse); // 有数据
      expect(model.isEmpty(1), isTrue);  // 未赋值
      expect(model.isEmpty(2), isFalse); // 有数据
    });

    test('越界索引 isEmpty 为 true', () {
      expect(model.isEmpty(-1), isTrue);
      expect(model.isEmpty(5), isTrue);
      expect(model.isEmpty(100), isTrue);
    });

    test('clean 清除指定槽位', () {
      model.set(0, 'value0');
      model.set(1, 'value1');
      model.set(2, 'value2');

      model.clean(1);

      expect(model.isEmpty(0), isFalse); // 未清除
      expect(model.isEmpty(1), isTrue);  // 已清除
      expect(model.isEmpty(2), isFalse); // 未清除
      expect(model.get<String>(1), isNull);
    });

    test('clean 返回值：越界返回 false，有效返回 true', () {
      model.set(0, 'value');

      expect(model.clean(0), isTrue);    // 有效索引
      expect(model.clean(-1), isFalse);  // 越界
      expect(model.clean(10), isFalse);  // 越界
    });

    test('clean 越界不抛异常', () {
      model.set(0, 'value');
      expect(() => model.clean(-1), returnsNormally);
      expect(() => model.clean(10), returnsNormally);
      expect(model.isEmpty(0), isFalse); // 未受影响
    });

    test('cleanAll 清除所有槽位', () {
      model.set(0, 'value0');
      model.set(1, 'value1');
      model.set(2, 'value2');
      model.set(3, 'value3');
      model.set(4, 'value4');

      model.cleanAll();

      for (int i = 0; i < 5; i++) {
        expect(model.isEmpty(i), isTrue);
        expect(model.get<String>(i), isNull);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // hasValidData
  // ---------------------------------------------------------------------------
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

    test('所有槽位为空时 hasValidData 为 false', () {
      expect(model.hasValidData, isFalse);
    });

    test('任一槽位有数据时 hasValidData 为 true', () {
      model.set(2, 'some_value');
      expect(model.hasValidData, isTrue);
    });

    test('cleanAll 后 hasValidData 为 false', () {
      model.set(0, 'value');
      expect(model.hasValidData, isTrue);

      model.cleanAll();
      expect(model.hasValidData, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // ComputeMode
  // ---------------------------------------------------------------------------
  group('FlexiCandleModel ComputeMode', () {
    test('fast mode 内部使用 double，存在精度损失', () {
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

      final openDouble = model.open.toDouble();
      expect(openDouble, closeTo(100.12345678912346, 0.0000001));
    });

    test('accurate mode 内部使用 Decimal，保持精度', () {
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

      final openDecimal = model.open.toDecimal();
      expect(openDecimal, Decimal.parse('100.123456789123456789'));
    });
  });

  // ---------------------------------------------------------------------------
  // 边界情况
  // ---------------------------------------------------------------------------
  group('FlexiCandleModel 边界情况', () {
    test('count=0 时越界，isEmpty 为 true，set 返回 false', () {
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
      expect(model.isEmpty(0), isTrue); // 越界，返回 true
      expect(model.hasValidData, isFalse);
    });

    test('turnover 为 null', () {
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

    test('大量槽位时首尾正常写读', () {
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
