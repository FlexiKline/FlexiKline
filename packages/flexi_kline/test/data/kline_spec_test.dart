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

/// 加载更多与刷新请求的规格：宿主据此向服务端要数据。
///
/// 数据升序存储：`list.first` 最旧、`list.last` 最新。「有效」指蜡烛已有指标计算结果
/// （任一 slot 非空），刷新请求从最新端向旧方向找第一对相邻的有效蜡烛，取其中较旧的一根。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

const _spec = KlineSpec(symbol: 'SPEC', interval: FlexiTimeInterval(1, TimeUnit.day), from: 1, to: 2);

/// 时间戳为 10, 20, ... 的 [count] 根蜡烛；[valid] 中的下标写入计算结果。
KlineData _data(int count, {Iterable<int> valid = const []}) {
  final data = KlineData(_spec);
  data.replace([
    for (var i = 0; i < count; i++) CandleModel(timestamp: (i + 1) * 10, open: 1, high: 2, low: 0, close: 1, volume: 1),
  ], slotCount: 1);
  for (final i in valid) {
    data.list[i].set(0, FlexiNum.one);
  }
  return data;
}

void main() {
  group('getLoadMoreSpec', () {
    test('from 为最旧一根的 ts, to 置空', () {
      final data = _data(5);
      addTearDown(data.dispose);

      final spec = data.getLoadMoreSpec();

      expect(spec.from, 10);
      expect(spec.to, isNull);
      expect(spec.symbol, _spec.symbol);
    });

    test('空数据时 from 与 to 都为空', () {
      final data = KlineData(_spec);
      addTearDown(data.dispose);

      final spec = data.getLoadMoreSpec();

      expect(spec.from, isNull);
      expect(spec.to, isNull);
    });
  });

  group('getRefreshSpec', () {
    test('全部有效时 to 为最新端第二根的 ts', () {
      final data = _data(5, valid: [0, 1, 2, 3, 4]);
      addTearDown(data.dispose);

      final spec = data.getRefreshSpec();

      expect(spec.from, isNull);
      expect(spec.to, 40);
    });

    test('最新一根尚无结果时跳过它，取下一对相邻有效蜡烛中较旧的一根', () {
      final data = _data(5, valid: [0, 1, 2, 3]);
      addTearDown(data.dispose);

      expect(data.getRefreshSpec().to, 30);
    });

    test('有效蜡烛不相邻时继续向旧方向找', () {
      // 自最新端: 4 有效、3 无效、2 有效、1 有效 → 第一对相邻有效是 (2, 1)。
      final data = _data(5, valid: [1, 2, 4]);
      addTearDown(data.dispose);

      expect(data.getRefreshSpec().to, 20);
    });

    test('找不到相邻的有效蜡烛时 to 为空', () {
      final noneValid = _data(5);
      final onlyLatest = _data(5, valid: [4]);
      addTearDown(noneValid.dispose);
      addTearDown(onlyLatest.dispose);

      expect(noneValid.getRefreshSpec().to, isNull);
      expect(onlyLatest.getRefreshSpec().to, isNull);
    });

    test('reset 或空数据时 from 与 to 都为空', () {
      final data = _data(5, valid: [0, 1, 2, 3, 4]);
      final empty = KlineData(_spec);
      addTearDown(data.dispose);
      addTearDown(empty.dispose);

      final reset = data.getRefreshSpec(true);
      expect(reset.from, isNull);
      expect(reset.to, isNull);

      final fromEmpty = empty.getRefreshSpec();
      expect(fromEmpty.from, isNull);
      expect(fromEmpty.to, isNull);
    });
  });
}
