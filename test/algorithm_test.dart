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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Item {
  final int timestamp;
  final String val;

  Item(this.timestamp, [String? val]) : val = val ?? timestamp.toString();

  static Item empty = Item(0);

  @override
  String toString() {
    return val.toString();
  }

  @override
  int get hashCode => timestamp.hashCode ^ val.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          val == other.val;
}

bool equalsLists(List list1, List list2) {
  if (list1.length != list2.length) {
    return false;
  }

  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) {
      return false;
    }
  }

  return true;
}

void main() {
  final stopwatch = Stopwatch();
  setUpAll(() {
    stopwatch.start();
  });

  tearDownAll(() {
    stopwatch.stop();
    debugPrint('total spent:${stopwatch.elapsedMicroseconds}');
  });

  test('mergeCandleList empty list', () {
    final curList = <Item>[];
    final newList = <Item>[];

    final kData = KlineData(curList);
    final range = kData.mergeCandleLists(newList);
    final list = kData.list;

    debugPrint(range?.toString());
    debugPrint(list.toString());
    assert(equalsLists(list, []));
    assert(range == null);
  });

  test('mergeCandleList only curList', () {
    final curList = [Item(10), Item(9), Item(8)];
    final newList = <Item>[];

    final kData = KlineData(curList);
    final range = kData.mergeCandleLists(newList);
    final list = kData.list;

    debugPrint(range?.toString());
    debugPrint(list.toString());
    assert(equalsLists(list, curList));
    assert(range == null);
  });

  test('mergeCandleList only newList', () {
    final curList = <Item>[];
    final newList = [Item(10, '10-new'), Item(9, '9-new'), Item(8, '8-new')];

    final kData = KlineData(curList);
    final range = kData.mergeCandleLists(newList);
    final list = kData.list;

    debugPrint(range?.toString());
    debugPrint(list.toString());
    assert(equalsLists(list, newList));
    assert(range == Range(0, newList.length));
  });

  test('mergeCandleList before1', () {
    final curList = [Item(10), Item(9), Item(8)];
    final newList = [Item(11, '11-new'), Item(10, '10-new'), Item(9, '9-new')];

    final kData = KlineData(curList);
    final range = kData.mergeCandleLists(newList);
    final list = kData.list;

    debugPrint(range?.toString());
    debugPrint(list.toString());
    assert(equalsLists(list, [...newList, Item(8)]));
    assert(range == Range(0, newList.length));
  });

  test('mergeCandleList before2', () {
    final curList = [Item(10), Item(9), Item(8)];
    final newList = [Item(10, '10-new')];

    final kData = KlineData(curList);
    final range = kData.mergeCandleLists(newList);
    final list = kData.list;

    debugPrint(range?.toString());
    debugPrint(list.toString());
    assert(equalsLists(list, [...newList, Item(9), Item(8)]));
    assert(range == Range(0, newList.length));
  });

  test('mergeCandleList before3', () {
    final curList = [Item(10), Item(9), Item(8)];
    final newList = [Item(11, '11-new')];

    final kData = KlineData(curList);
    final range = kData.mergeCandleLists(newList);
    final list = kData.list;

    debugPrint(range?.toString());
    debugPrint(list.toString());
    assert(equalsLists(list, [...newList, ...curList]));
    assert(range == Range(0, newList.length));
  });

  test('mergeCandleList before4', () {
    final curList = [Item(10), Item(9), Item(8)];
    final newList = [
      Item(10, '10-new'),
      Item(9, '9-new'),
      Item(8, '8-new'),
      Item(7, '7-new')
    ];

    final kData = KlineData(curList);
    final range = kData.mergeCandleLists(newList);
    final list = kData.list;

    debugPrint(range?.toString());
    debugPrint(list.toString());
    assert(equalsLists(list, [...newList]));
    assert(range == Range(0, newList.length));
  });

  test('mergeCandleList after1', () {
    final curList = [Item(10), Item(9), Item(8)];
    final newList = [Item(9, '9-new'), Item(8, '8-new'), Item(7, '7-new')];

    final kData = KlineData(curList);
    final range = kData.mergeCandleLists(newList);
    final list = kData.list;

    debugPrint(range?.toString());
    debugPrint(list.toString());
    assert(equalsLists(list, [Item(10), ...newList]));
    assert(range == Range(1, list.length));
  });

  test('mergeCandleList after2', () {
    final curList = [Item(10), Item(9), Item(8)];
    final newList = [Item(8, '8-new'), Item(7, '7-new')];

    final kData = KlineData(curList);
    final range = kData.mergeCandleLists(newList);
    final list = kData.list;

    debugPrint(range?.toString());
    debugPrint(list.toString());
    assert(equalsLists(list, [Item(10), Item(9), ...newList]));
    assert(range == Range(2, list.length));
  });

  test('mergeCandleList after3', () {
    final curList = [Item(10), Item(9), Item(8)];
    final newList = [Item(7, '7-new')];

    final kData = KlineData(curList);
    final range = kData.mergeCandleLists(newList);
    final list = kData.list;

    debugPrint(range?.toString());
    debugPrint(list.toString());
    assert(equalsLists(list, [...curList, ...newList]));
    assert(range == Range(3, list.length));
  });

  test('mergeCandleList after4', () {
    final curList = [Item(10), Item(9), Item(8)];
    final newList = [
      Item(11, '11-new'),
      Item(10, '10-new'),
      Item(9, '9-new'),
      Item(8, '8-new'),
    ];

    final kData = KlineData(curList);
    final range = kData.mergeCandleLists(newList);
    final list = kData.list;

    debugPrint(range?.toString());
    debugPrint(list.toString());
    assert(equalsLists(list, [...newList]));
    assert(range == Range(0, list.length));
  });
}

class KlineData {
  KlineData(List<Item> list) : _list = List.of(list);

  late List<Item> _list;
  List<Item> get list => _list;

  /// 合并[list]和[newList]为一个新数组
  /// 约定: [newList]和[list]都是按时间倒序排好的, 即最近/新的蜡烛数据以数组0开始依次存放.
  /// 去重: 如两个数组拼接过程中发现重复的, 要去掉[list]中重复的元素.
  /// return: 返回新列表中被更新的范围[start] ~ [end]
  Range? mergeCandleLists(List<Item> newList) {
    if (newList.isEmpty) return null;
    if (list.isEmpty) {
      _list = List.of(newList);
      return Range(0, newList.length);
    }

    if (list.first.timestamp <= newList.first.timestamp) {
      int start = 0;
      while (start < list.length &&
          list[start].timestamp >= newList.last.timestamp) {
        start++;
      }
      final curIterable = list.getRange(start, list.length);
      _list = List.of(newList, growable: true)..addAll(curIterable);
      // _list = List.of([...newList, ...curIterable]);
      return Range(0, newList.length);
    } else {
      int end = list.length - 1;
      while (end >= 0 && list[end].timestamp <= newList.first.timestamp) {
        end--;
      }
      final curIterable = list.getRange(0, end + 1);
      _list = List.of(curIterable, growable: true)..addAll(newList);
      // _list =  List.of([...curIterable, ...newList]);
      return Range(end + 1, _list.length);
    }
  }
}
