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

// ignore_for_file: prefer_final_locals

import 'package:flexi_kline/src/framework/collection/fifo_hash_map.dart';
import 'package:flexi_kline/src/framework/collection/fixed_hash_queue.dart';
import 'package:flexi_kline/src/framework/collection/sortable_hash_set.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// 公共测试辅助类：按 name 判等，weight 参与排序
// ---------------------------------------------------------------------------
class Item implements Comparable<Item> {
  Item(this.name, this.weight);

  final String name;
  final int weight;

  @override
  int compareTo(Item other) {
    final ret = weight.compareTo(other.weight);
    if (ret != 0) return ret;
    if (name == other.name) return 0;
    return -1;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && runtimeType == other.runtimeType && name == other.name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'Item($name, $weight)';
}

void main() {
  // ---------------------------------------------------------------------------
  // SortableHashSet
  // ---------------------------------------------------------------------------
  group('SortableHashSet', () {
    test('添加元素后按权重排序迭代', () {
      final set = SortableHashSet<Item>();
      set.add(Item('C', 3));
      set.add(Item('A', 1));
      set.add(Item('B', 2));

      final names = set.map((e) => e.name).toList();
      expect(names, ['A', 'B', 'C']); // 升序
    });

    test('add：元素已存在时替换（按 == 判等），权重更新', () {
      final set = SortableHashSet<Item>();
      set.add(Item('X', 1));
      set.add(Item('X', 5)); // 同名，替换

      expect(set.length, 1);
      expect(set.first.weight, 5);
    });

    test('remove：正确删除元素', () {
      final set = SortableHashSet<Item>();
      set.add(Item('A', 1));
      set.add(Item('B', 2));
      set.remove(Item('A', 999)); // 按 == 删除，weight 无关

      expect(set.length, 1);
      expect(set.any((e) => e.name == 'A'), isFalse);
    });

    test('removeWhere：批量删除', () {
      final set = SortableHashSet<Item>()
        ..add(Item('A', 1))
        ..add(Item('B', 2))
        ..add(Item('C', 3));

      set.removeWhere((e) => e.weight > 1);
      expect(set.length, 1);
      expect(set.first.name, 'A');
    });

    test('append：元素存在时替换并返回旧元素', () {
      final set = SortableHashSet<Item>();
      set.add(Item('X', 1));
      final old = set.append(Item('X', 5));

      expect(old?.weight, 1);
      expect(set.length, 1);
      expect(set.first.weight, 5);
    });

    test('append：元素不存在时添加，返回 null', () {
      final set = SortableHashSet<Item>();
      set.add(Item('A', 1));
      final old = set.append(Item('B', 2));

      expect(old, isNull);
      expect(set.length, 2);
    });

    test('append replaceIfPresent=false：元素已存在时不替换，返回 null', () {
      final set = SortableHashSet<Item>();
      set.add(Item('X', 1));
      final result = set.append(Item('X', 99), replaceIfPresent: false);

      expect(result, isNull);
      expect(set.first.weight, 1); // 未被替换
    });

    test('reversed：以降序迭代', () {
      final set = SortableHashSet<Item>()
        ..add(Item('A', 1))
        ..add(Item('B', 2))
        ..add(Item('C', 3));

      final names = set.reversed.map((e) => e.name).toList();
      expect(names, ['C', 'B', 'A']);
    });

    test('originList：返回未排序的原始插入集合', () {
      final set = SortableHashSet<Item>();
      set.add(Item('C', 3));
      set.add(Item('A', 1));
      set.add(Item('B', 2));

      // originList 是内部 Set，不保证顺序，但包含所有元素
      expect(set.originList.length, 3);
      expect(set.originList.any((e) => e.name == 'A'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // FixedHashQueue
  // ---------------------------------------------------------------------------
  group('FixedHashQueue', () {
    test('容量内正常追加', () {
      final q = FixedHashQueue<int>(3);
      q.append(1);
      q.append(2);
      q.append(3);

      expect(q.length, 3);
      expect(q.first, 1);
      expect(q.last, 3);
    });

    test('超出容量时淘汰队首（最早）元素', () {
      final q = FixedHashQueue<int>(3);
      q.append(1);
      q.append(2);
      q.append(3);
      q.append(4); // 淘汰 1

      expect(q.length, 3);
      expect(q.contains(1), isFalse);
      expect(q.contains(4), isTrue);
      expect(q.first, 2);
    });

    test('append：元素已存在时就地替换，返回旧元素，不改变位置', () {
      final q = FixedHashQueue<Item>(3);
      q.append(Item('A', 1));
      q.append(Item('B', 2));
      q.append(Item('C', 3));

      final old = q.append(Item('B', 99)); // 替换 B
      expect(old?.weight, 2);
      expect(q.length, 3);
      expect(q.elementAt(1).weight, 99); // B 仍在原来位置（index 1）
    });

    test('append atFirst：向队首插入，超出容量淘汰队尾', () {
      final q = FixedHashQueue<int>(3);
      q.append(1);
      q.append(2);
      q.append(3);
      q.append(4, atFirst: true); // 淘汰尾部 3

      expect(q.length, 3);
      expect(q.first, 4);
      expect(q.contains(3), isFalse);
    });

    test('capacity=0：所有 append 均不入队', () {
      final q = FixedHashQueue<int>(0);
      q.append(1);
      expect(q.length, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // FIFOHashMap
  // ---------------------------------------------------------------------------
  group('FIFOHashMap', () {
    test('容量内正常插入', () {
      final map = FIFOHashMap<String, int>(capacity: 3);
      map['A'] = 1;
      map['B'] = 2;
      map['C'] = 3;

      expect(map.length, 3);
      expect(map['A'], 1);
    });

    test('超出容量时淘汰最早插入的 key', () {
      final map = FIFOHashMap<String, int>(capacity: 3);
      map['A'] = 1;
      map['B'] = 2;
      map['C'] = 3;
      map['D'] = 4; // A 被淘汰

      expect(map.length, 3);
      expect(map.containsKey('A'), isFalse);
      expect(map.containsKey('D'), isTrue);
    });

    test('更新已有 key：移到最新位置，不触发淘汰', () {
      final map = FIFOHashMap<String, int>(capacity: 3);
      map['A'] = 1;
      map['B'] = 2;
      map['C'] = 3;
      map['B'] = 99; // B 更新并移到队尾

      expect(map.length, 3);
      expect(map['B'], 99);
      expect(map.containsKey('A'), isTrue); // A 未被淘汰

      map['D'] = 4; // A 是最老的，被淘汰
      expect(map.containsKey('A'), isFalse);
      expect(map.containsKey('B'), isTrue);
    });

    test('无容量限制：不淘汰', () {
      final map = FIFOHashMap<String, int>();
      for (int i = 0; i < 100; i++) {
        map['key$i'] = i;
      }
      expect(map.length, 100);
    });
  });
}
