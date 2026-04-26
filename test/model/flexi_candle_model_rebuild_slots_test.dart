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

import 'package:flexi_kline/src/model/flexi_candle_model.dart';
import 'package:flexi_kline/src/types.dart';
import 'package:flutter_test/flutter_test.dart';

/// 模拟 ICandleModel 用于测试
class MockCandle implements ICandleModel {
  @override
  final int timestamp;
  @override
  final Object open;
  @override
  final Object high;
  @override
  final Object low;
  @override
  final Object close;
  @override
  final Object volume;
  @override
  final Object? turnover;
  @override
  final int? tradeCount;
  @override
  final bool confirmed;

  MockCandle({
    required this.timestamp,
    this.open = 100.0,
    this.high = 110.0,
    this.low = 90.0,
    this.close = 105.0,
    this.volume = 1000.0,
    this.turnover,
    this.tradeCount,
    this.confirmed = true,
  });
}

void main() {
  group('FlexiCandleModel.rebuildSlots', () {
    /// **Property 9: rebuildSlots 数据保留**
    /// **Validates: Requirements 6.2, 6.3**
    ///
    /// 对于任意 FlexiCandleModel 实例和任意 newCount：
    /// - 如果 slots.length >= newCount，rebuildSlots 应返回自身（引用相等）
    /// - 如果 slots.length < newCount，rebuildSlots 应返回新实例，新实例的 slots.length 等于 newCount，
    ///   且前 slots.length 个元素与原实例相同，其余为 null
    test('returns self when slots.length >= newCount', () {
      final candle = MockCandle(timestamp: 1000);
      final model = FlexiCandleModel.init(candle: candle, count: 5, mode: ComputeMode.fast);

      // 当 newCount <= 当前 slots.length 时，应返回自身
      final result1 = model.rebuildSlots(5);
      expect(identical(result1, model), true, reason: 'Should return self when newCount == slots.length');

      final result2 = model.rebuildSlots(3);
      expect(identical(result2, model), true, reason: 'Should return self when newCount < slots.length');
    });

    test('creates new instance with expanded slots when slots.length < newCount', () {
      final candle = MockCandle(timestamp: 1000);
      final model = FlexiCandleModel.init(candle: candle, count: 3, mode: ComputeMode.fast);

      // 设置一些数据到 slots
      model[0] = 'data0';
      model[1] = 'data1';
      model[2] = 'data2';

      // 扩容到 5
      final result = model.rebuildSlots(5);

      // 应返回新实例
      expect(identical(result, model), false, reason: 'Should return new instance when newCount > slots.length');

      // 新实例的 slots.length 应为 5
      expect(result.slotCount, 5, reason: 'New instance should have slots.length == 5');

      // 前 3 个元素应与原实例相同
      expect(result[0], 'data0', reason: 'First element should be preserved');
      expect(result[1], 'data1', reason: 'Second element should be preserved');
      expect(result[2], 'data2', reason: 'Third element should be preserved');

      // 新增的 2 个元素应为 null
      expect(result[3], null, reason: 'New slot should be null');
      expect(result[4], null, reason: 'New slot should be null');

      // 原实例的 slots.length 应保持不变
      expect(model.slotCount, 3, reason: 'Original instance should not be modified');
    });

    test('preserves all slot data types during rebuild', () {
      final candle = MockCandle(timestamp: 1000);
      final model = FlexiCandleModel.init(candle: candle, count: 2, mode: ComputeMode.fast);

      // 设置不同类型的数据
      model[0] = 42;
      model[1] = [1, 2, 3];

      final result = model.rebuildSlots(4);

      // 验证数据类型和值都被保留
      expect(result[0], 42, reason: 'Integer data should be preserved');
      expect(result[1], [1, 2, 3], reason: 'List data should be preserved');
      expect(result[2], null, reason: 'New slot should be null');
      expect(result[3], null, reason: 'New slot should be null');
    });

    test('handles empty slots correctly', () {
      final candle = MockCandle(timestamp: 1000);
      final model = FlexiCandleModel.init(candle: candle, count: 0, mode: ComputeMode.fast);

      // 从 0 个 slots 扩容到 3
      final result = model.rebuildSlots(3);

      expect(identical(result, model), false, reason: 'Should return new instance');
      expect(result.slotCount, 3, reason: 'New instance should have 3 slots');
      expect(result[0], null, reason: 'All slots should be null');
      expect(result[1], null, reason: 'All slots should be null');
      expect(result[2], null, reason: 'All slots should be null');
    });

    test('preserves candle data during rebuild', () {
      final candle = MockCandle(
        timestamp: 1234567890,
        open: 100.5,
        high: 110.5,
        low: 90.5,
        close: 105.5,
        volume: 5000.0,
      );
      final model = FlexiCandleModel.init(candle: candle, count: 2, mode: ComputeMode.fast);

      final result = model.rebuildSlots(5);

      // 验证蜡烛数据保持不变
      expect(result.ts, 1234567890, reason: 'Timestamp should be preserved');
      expect(result.open.toDouble(), 100.5, reason: 'Open price should be preserved');
      expect(result.high.toDouble(), 110.5, reason: 'High price should be preserved');
      expect(result.low.toDouble(), 90.5, reason: 'Low price should be preserved');
      expect(result.close.toDouble(), 105.5, reason: 'Close price should be preserved');
      expect(result.vol.toDouble(), 5000.0, reason: 'Volume should be preserved');
    });

    test('multiple sequential rebuilds work correctly', () {
      final candle = MockCandle(timestamp: 1000);
      var model = FlexiCandleModel.init(candle: candle, count: 2, mode: ComputeMode.fast);

      model[0] = 'initial';
      model[1] = 'data';

      // 第一次扩容：2 -> 4
      model = model.rebuildSlots(4);
      expect(model.slotCount, 4);
      expect(model[0], 'initial');
      expect(model[1], 'data');
      expect(model[2], null);
      expect(model[3], null);

      // 设置新数据
      model[2] = 'new';

      // 第二次扩容：4 -> 6
      model = model.rebuildSlots(6);
      expect(model.slotCount, 6);
      expect(model[0], 'initial');
      expect(model[1], 'data');
      expect(model[2], 'new');
      expect(model[3], null);
      expect(model[4], null);
      expect(model[5], null);

      // 不扩容的调用应返回自身
      final same = model.rebuildSlots(6);
      expect(identical(same, model), true);
    });
  });
}
