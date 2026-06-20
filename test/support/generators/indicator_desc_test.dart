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

import 'dart:math';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import 'indicator_desc.dart';

void main() {
  group('v2.2.0/generators/indicator_desc', () {
    test('便捷构造产出正确 kind 与 key', () {
      expect(computed(1).kind, IndicatorKind.computed);
      expect(computed(1).keyToken, 'computed_1');
      expect(computedKey(1), const ComputedIndicatorKey('computed_1'));
      expect(externalKey(2), const ExternalIndicatorKey('external_2'));
      expect(directKey(3), const DirectIndicatorKey('direct_3'));
      expect(external_(5).kind, IndicatorKind.external_);
      expect(external_(5).keyToken, 'external_5');
      expect(direct(7).kind, IndicatorKind.direct);
      expect(direct(7).keyToken, 'direct_7');
    });

    test('descToKey 根据 kind 返回对应 key 类型', () {
      expect(descToKey(direct(0)), isA<DirectIndicatorKey>());
      expect(descToKey(computed(0)), isA<ComputedIndicatorKey>());
      expect(descToKey(external_(0)), isA<ExternalIndicatorKey>());
    });

    test('createIndicator 根据 kind 创建对应 Indicator 类型', () {
      expect(createIndicator(direct(0)), isA<DirectIndicator>());
      expect(createIndicator(computed(0)), isA<ComputedIndicator>());
      expect(createIndicator(external_(0)), isA<ExternalIndicator>());
    });

    test('randomSubset 覆盖非前缀元素', () {
      final rng = Random(1);
      final source = List.generate(8, (i) => i);
      final seen = <int>{};
      for (int i = 0; i < 200; i++) {
        seen.addAll(randomSubset(rng, source));
      }
      // 末尾元素也应被取到（旧 .take 前缀偏差无法保证）
      expect(seen.contains(7), isTrue);
      expect(seen.length, 8);
    });

    test('randomMainSub 的 main/sub key 不重复', () {
      final rng = Random(2);
      for (int i = 0; i < 100; i++) {
        final (:main, :sub) = randomMainSub(rng);
        final mainKeys = main.map((d) => d.keyToken).toSet();
        final subKeys = sub.map((d) => d.keyToken).toSet();
        expect(mainKeys.intersection(subKeys), isEmpty);
      }
    });

    test('randomIndicatorList 列表自身 key 不重复', () {
      final rng = Random(3);
      for (int i = 0; i < 100; i++) {
        final list = randomIndicatorList(rng);
        final keys = list.map((d) => d.keyToken).toList();
        expect(keys.length, keys.toSet().length);
      }
    });
  });
}
