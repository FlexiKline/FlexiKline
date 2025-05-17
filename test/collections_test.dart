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

import 'dart:collection';

import 'package:flexi_kline/src/extension/export.dart';
import 'package:flexi_kline/src/framework/collection/fixed_hash_queue.dart';
import 'package:flexi_kline/src/framework/collection/fifo_hash_map.dart';
import 'package:flexi_kline/src/framework/collection/sortable_hash_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

class Item implements Comparable<Item> {
  Item(this.name, this.weight);

  final String name;
  final int weight;

  @override
  int compareTo(Item other) {
    int ret = weight.compareTo(other.weight);
    if (ret != 0) return ret;
    if (name == other.name) return 0;
    return -1;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Item) {
      return other.runtimeType == runtimeType && other.name == other.name;
    }
    return false;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    return 'Item($name, $weight)';
  }
}

void main() {
  final stopwatch = Stopwatch();
  setUp(() {
    stopwatch.reset();
    stopwatch.start();
  });

  tearDown(() {
    stopwatch.stop();
    debugPrint('spent:${stopwatch.elapsedMicroseconds}');
  });

  test('HashSortSet', () {
    final l = List.filled(0, null);
    print(l.length);
  });

  test('SplayTreeSet', () {
    SplayTreeSet set = SplayTreeSet();
    set.add(Item('zp3', 3));
    set.add(Item('zp0', 0));
    set.add(Item('zp2', 0));
    set.add(Item('zp1', 0));
    set.add(Item('zp-1', -1));

    set.add(Item('zp-4', 0));
    printIterable(set);
  });

  test('SplayTreeMap', () {
    SplayTreeMap map = SplayTreeMap<Item, String>();
    map[Item('zp3', 3)] = 'zp3-3';
    map[Item('zp0', 0)] = 'zp0-0';
    map[Item('zp2', -1)] = 'zp2_-1';
    map[Item('zp1', 0)] = 'zp1_0';
    map[Item('zp1', -1)] = 'zp1_-1';

    printMap(map);
    print('-----');
    map.remove(map.firstKey());
    map[Item('zp4', 0)] = 'zp4-0';
    printMap(map);
  });

  test('LinkedHashSet', () {
    LinkedHashSet set = LinkedHashSet();
    set.add(Item('zp-1', -1));
    set.add(Item('zp0', 0));
    set.add(Item('zp1', 1));
    set.add(Item('zp2', 2));

    set.remove(set.first);
    printIterable(set);
  });

  test('SortableHashSet', () {
    Set set = SortableHashSet<Item>();
    set.add(Item('A', 1));
    set.add(Item('B', 2));
    set.add(Item('C', 3));
    set.add(Item('a', -1));
    set.add(Item('b', -2));
    set.add(Item('c', -3));

    print(set);

    set.add(Item('B', 0));
    set.add(Item('b', 0));

    print(set);

    set.remove(Item('A', 1111));
    print(set);

    set.removeWhere((element) {
      return element.name.toLowerCase() == 'b';
    });

    print(set);
  });

  test('FixedHashQueue', () {
    final queue = FixedHashQueue<Item>(3);
    queue.append(Item('A', 1));
    queue.append(Item('B', 2));
    queue.append(Item('C', 3));

    print(queue);

    final old = queue.append(Item('B', 4));
    print(old);
    print(queue);

    queue.append(Item('D', 1), atFirst: true);
    print(queue);
  });

  test('FIFOHashMap', () {
    final map = FIFOHashMap<Item, String>(capacity: 5);
    map[Item('BTCUSDT-15m', 0)] = 'BTCUSDT-15m-List-0';

    map[Item('ETHUSDT-15m', 2)] = 'ETHUSDT-15m-List-2';
    map[Item('A10000-15m', 3)] = 'A10000-15m-List-3';
    map[Item('A10000-1h', 4)] = 'A10000-1h-List-4';
    map[Item('A10000-1h', 5)] = 'A10000-1h-List-5';
    map[Item('SOLUSDT-1h', 6)] = 'SOLUSDT-1h-List-6';
    map[Item('BTCUSDT-15m', 1)] = 'BTCUSDT-15m-List-1';
    printMap(map);
    print('---');
    map[Item('OKBUSDT-1h', 7)] = 'OKBUSDT-1h-List-7';

    printMap(map);
  });

  test('merger addAll', () {
    final list1 = List.filled(100000000, fillData1);
    final list2 = List.filled(100000000, fillData2);

    debugPrint('merger addAll');
    final newList = List.of(list1, growable: true)..addAll(list2);

    assert(newList.length == 200000000);
  });

  test('merger ...', () {
    final list1 = List.filled(100000000, fillData1);
    final list2 = List.filled(100000000, fillData2);

    debugPrint('merger ...');
    final newList = List.of([...list1, ...list2]);

    assert(newList.length == 200000000);
  });

  test('merger insertAll', () {
    final list1 = List.filled(100000000, fillData1, growable: true);
    final list2 = List.filled(100000000, fillData2);

    debugPrint('merger insertAll');
    final newList = List.of(list1, growable: true);
    newList.insertAll(newList.length, list2);
    assert(newList.length == 200000000);
  });

  test('test list is null or empty', () {
    final list = List<int?>.filled(3, null);

    debugPrint('list.len:${list.length}');
    debugPrint('list.len:${list.isEmpty}');
  });

  test('test secondWhereOrNull', () {
    final list = [0, 1, 2];
    var result = list.secondWhereOrNull((item) => item > 0);
    debugPrint('result:$result');
    expect(result, 2);

    result = list.secondWhereOrNull((item) => item > 1);
    debugPrint('result:$result');
    expect(result, isNull);

    result = list.secondWhereOrNull((item) => item > 2);
    debugPrint('result:$result');
    expect(result, isNull);
  });
}

const fillData1 = 'AAABBBCCC';
const fillData2 = 'XXXYYYZZZ';
