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

import 'package:flexi_kline/src/extension/export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // FlexiKlineListExt.binarySearch
  // ---------------------------------------------------------------------------
  group('FlexiKlineListExt.binarySearch', () {
    // compare(element) = element.compareTo(target)
    // < 0 → 目标在右侧（go right），> 0 → 目标在左侧（go left）
    final asc = [1, 3, 5, 7, 9];

    test('找到元素：返回正确索引', () {
      expect(asc.binarySearch((e) => e.compareTo(5)), 2);
    });

    test('找首元素', () {
      expect(asc.binarySearch((e) => e.compareTo(1)), 0);
    });

    test('找末尾元素', () {
      expect(asc.binarySearch((e) => e.compareTo(9)), 4);
    });

    test('未找到：返回 -1', () {
      expect(asc.binarySearch((e) => e.compareTo(4)), -1);
    });

    test('空列表：返回 -1', () {
      expect(<int>[].binarySearch((e) => e.compareTo(5)), -1);
    });

    test('单元素 — 找到', () {
      expect([42].binarySearch((e) => e.compareTo(42)), 0);
    });

    test('单元素 — 未找到', () {
      expect([42].binarySearch((e) => e.compareTo(1)), -1);
    });

    test('降序列表（target.compareTo(element)）', () {
      // K 线时间戳倒序排列时，compare = target.compareTo(element)
      final desc = [9, 7, 5, 3, 1];
      expect(desc.binarySearch((e) => 5.compareTo(e)), 2);
      expect(desc.binarySearch((e) => 4.compareTo(e)), -1);
    });
  });

  // ---------------------------------------------------------------------------
  // FlexiIterableExt extensions
  // ---------------------------------------------------------------------------
  group('FlexiIterableExt.secondWhereOrNull', () {
    test('返回第二个连续满足条件的元素', () {
      expect([0, 1, 2].secondWhereOrNull((e) => e > 0), 2);
    });

    test('只有一个满足条件时返回 null', () {
      expect([0, 1, 2].secondWhereOrNull((e) => e > 1), isNull);
    });

    test('没有满足条件时返回 null', () {
      expect([0, 1, 2].secondWhereOrNull((e) => e > 2), isNull);
    });
  });

  group('FlexiIterableExt.range', () {
    test('空列表返回空', () {
      expect(<double>[].range(1), isEmpty);
    });

    test('从指定偏移截取', () {
      expect([1.0, 2.0, 3.0].range(1).toList(), [2.0, 3.0]);
    });

    test('指定 start 和 end', () {
      expect([1, 2, 3, 4, 5].range(1, 4).toList(), [2, 3, 4]);
    });

    test('start < 0 抛出 ArgumentError', () {
      expect(() => [1, 2, 3].range(-1).toList(), throwsArgumentError);
    });

    test('end <= start 抛出 ArgumentError', () {
      expect(() => [1, 2, 3].range(2, 1).toList(), throwsArgumentError);
    });
  });

  group('FlexiIterableExt.groupBy', () {
    test('按奇偶分组', () {
      final result = [1, 2, 3, 4, 5].groupBy((e) => e.isEven ? 'even' : 'odd');
      expect(result['even'], [2, 4]);
      expect(result['odd'], [1, 3, 5]);
    });

    test('全部归入同一组', () {
      final result = [1, 2, 3].groupBy((_) => 'all');
      expect(result['all'], [1, 2, 3]);
    });

    test('空列表返回空 Map', () {
      expect(<int>[].groupBy((e) => e), isEmpty);
    });
  });

  group('FlexiIterableExt.chunk', () {
    test('均匀分块', () {
      final chunks = [1, 2, 3, 4].chunk(2).toList();
      expect(chunks, [
        [1, 2],
        [3, 4]
      ]);
    });

    test('最后一块不足时保留剩余元素', () {
      final chunks = [1, 2, 3, 4, 5].chunk(2).toList();
      expect(chunks.last, [5]);
    });

    test('size=0 抛出 ArgumentError', () {
      expect(() => [1, 2, 3].chunk(0).toList(), throwsArgumentError);
    });

    test('空列表返回空', () {
      expect(<int>[].chunk(2).toList(), isEmpty);
    });
  });

  group('FlexiIterableExt.partition', () {
    test('按奇偶分割', () {
      final (evens, odds) = [1, 2, 3, 4, 5].partition((e) => e.isEven);
      expect(evens, [2, 4]);
      expect(odds, [1, 3, 5]);
    });

    test('全部匹配', () {
      final (matched, unmatched) = [2, 4, 6].partition((e) => e.isEven);
      expect(matched, [2, 4, 6]);
      expect(unmatched, isEmpty);
    });

    test('全部不匹配', () {
      final (matched, unmatched) = [1, 3, 5].partition((e) => e.isEven);
      expect(matched, isEmpty);
      expect(unmatched, [1, 3, 5]);
    });

    test('空列表', () {
      final (matched, unmatched) = <int>[].partition((e) => e.isEven);
      expect(matched, isEmpty);
      expect(unmatched, isEmpty);
    });
  });

  group('FlexiIterableExt.sum / average', () {
    test('sum：无 selector，直接求和', () {
      expect([1, 2, 3, 4].sum(), 10);
    });

    test('sum：带 selector（字符串长度）', () {
      expect(['a', 'bb', 'ccc'].sum((e) => e.length), 6);
    });

    test('average：空列表返回 0', () {
      expect(<int>[].average(), 0.0);
    });

    test('average：正常计算', () {
      expect([1, 2, 3].average(), 2.0);
    });

    test('average：带 selector', () {
      expect(['a', 'bb', 'ccc'].average((e) => e.length), closeTo(2.0, 1e-9));
    });
  });

  group('FlexiIterableExt.maxBy / minBy', () {
    test('maxBy：返回最大元素', () {
      expect(
        ['cat', 'elephant', 'dog'].maxBy((s) => s.length),
        'elephant',
      );
    });

    test('minBy：返回最小元素', () {
      expect(
        ['cat', 'elephant', 'dog'].minBy((s) => s.length),
        'cat',
      );
    });

    test('空列表返回 null', () {
      expect(<String>[].maxBy((s) => s.length), isNull);
      expect(<String>[].minBy((s) => s.length), isNull);
    });
  });

  group('FlexiIterableExt.distinctBy', () {
    test('按 key 去重，保留第一个出现的', () {
      final result = [
        {'id': 1, 'name': 'A'},
        {'id': 2, 'name': 'B'},
        {'id': 1, 'name': 'A2'},
      ].distinctBy((e) => e['id']).toList();

      expect(result.length, 2);
      expect(result[0]['name'], 'A');
    });

    test('全不重复：原样返回', () {
      final result = [1, 2, 3].distinctBy((e) => e).toList();
      expect(result, [1, 2, 3]);
    });
  });

  group('FlexiIterableExt.firstWhereOrNull', () {
    test('找到元素时返回', () {
      expect([1, 2, 3].firstWhereOrNull((e) => e > 1), 2);
    });

    test('未找到时返回 null', () {
      expect([1, 2, 3].firstWhereOrNull((e) => e > 10), isNull);
    });

    test('空列表返回 null', () {
      expect(<int>[].firstWhereOrNull((_) => true), isNull);
    });
  });

  group('FlexiIterableExt.toMap', () {
    test('正常转换为 Map（key 为字符串，value 为元素本身）', () {
      // toMap<K> 中 value 类型 = 元素类型 T；List<int> → Map<String, int>
      final result = [1, 2, 3].toMap((e) => MapEntry('item_$e', e));
      expect(result, {'item_1': 1, 'item_2': 2, 'item_3': 3});
    });

    test('test 返回 null 时跳过元素', () {
      final result = [1, 2, 3, 4].toMap((e) => e.isEven ? MapEntry('k$e', e) : null);
      expect(result, {'k2': 2, 'k4': 4});
    });

    test('空列表返回空 Map', () {
      expect(<int>[].toMap((e) => MapEntry('k', e)), isEmpty);
    });
  });
}
