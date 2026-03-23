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

import 'package:flexi_kline/src/model/export.dart';
import 'package:flexi_kline/src/model/minmax.dart';
import 'package:flexi_kline/src/model/flexi_num.dart';
import 'package:flexi_kline/src/utils/algorithm_util.dart';
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
      other is Item && runtimeType == other.runtimeType && timestamp == other.timestamp && val == other.val;
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

  test('calcuInertialPanDuration test', () {
    // velocity <= 1 应返回 0
    expect(calcuInertialPanDuration(0, maxDuration: 2000), 0);
    expect(calcuInertialPanDuration(1, maxDuration: 2000), 0);
    expect(calcuInertialPanDuration(-1, maxDuration: 2000), 0);

    // 负数取绝对值, 结果与正数一致
    expect(
      calcuInertialPanDuration(-3000, maxDuration: 2000),
      calcuInertialPanDuration(3000, maxDuration: 2000),
    );

    // maxDuration=2000 时的典型值验证
    const maxDur = 2000;
    final d500 = calcuInertialPanDuration(500, maxDuration: maxDur);
    final d1000 = calcuInertialPanDuration(1000, maxDuration: maxDur);
    final d2000 = calcuInertialPanDuration(2000, maxDuration: maxDur);
    final d5000 = calcuInertialPanDuration(5000, maxDuration: maxDur);
    final d10000 = calcuInertialPanDuration(10000, maxDuration: maxDur);

    debugPrint('v=500  => $d500');
    debugPrint('v=1000 => $d1000');
    debugPrint('v=2000 => $d2000');
    debugPrint('v=5000 => $d5000');
    debugPrint('v=10000 => $d10000');

    // 单调递增: 速度越快, 时长越长
    expect(d500 < d1000, true);
    expect(d1000 < d2000, true);
    expect(d2000 < d5000, true);
    expect(d5000 <= d10000, true);

    // 不超过 maxDuration
    expect(d10000 <= maxDur, true);

    // 合理范围检查: 中速滑动应在 500~1500ms 之间
    expect(d1000 >= 500, true);
    expect(d1000 <= 1500, true);
  });

  test('MinMax.lerp test', () {
    final a = MinMax(
      max: FlexiNum.fromNum(100.0),
      min: FlexiNum.fromNum(0.0),
    );
    final b = MinMax(
      max: FlexiNum.fromNum(200.0),
      min: FlexiNum.fromNum(50.0),
    );

    // t=0 应返回 a 的值
    final r0 = MinMax.lerp(a, b, 0.0);
    expect(r0.max.toDouble(), 100.0);
    expect(r0.min.toDouble(), 0.0);

    // t=1 应返回 b 的值
    final r1 = MinMax.lerp(a, b, 1.0);
    expect(r1.max.toDouble(), 200.0);
    expect(r1.min.toDouble(), 50.0);

    // t=0.5 应返回中间值
    final r05 = MinMax.lerp(a, b, 0.5);
    expect(r05.max.toDouble(), 150.0);
    expect(r05.min.toDouble(), 25.0);

    // t=0.15 (默认平滑因子)
    final r015 = MinMax.lerp(a, b, 0.15);
    expect(r015.max.toDouble(), closeTo(115.0, 0.01));
    expect(r015.min.toDouble(), closeTo(7.5, 0.01));

    // 返回值应是独立副本, 修改不影响原值
    r05.max = FlexiNum.fromNum(999.0);
    expect(a.max.toDouble(), 100.0);
    expect(b.max.toDouble(), 200.0);
  });

  test('MinMax.lerp boundary values', () {
    // 相同的 minMax 做 lerp, 结果不变
    final same = MinMax(
      max: FlexiNum.fromNum(50.0),
      min: FlexiNum.fromNum(10.0),
    );
    final rSame = MinMax.lerp(same, same, 0.5);
    expect(rSame.max.toDouble(), 50.0);
    expect(rSame.min.toDouble(), 10.0);

    // t 超出范围时 clamp 到边界
    final a = MinMax(max: FlexiNum.fromNum(10.0), min: FlexiNum.fromNum(0.0));
    final b = MinMax(max: FlexiNum.fromNum(20.0), min: FlexiNum.fromNum(5.0));

    final rNeg = MinMax.lerp(a, b, -0.5);
    expect(rNeg.max.toDouble(), 10.0); // clamp 到 a
    expect(rNeg.min.toDouble(), 0.0);

    final rOver = MinMax.lerp(a, b, 1.5);
    expect(rOver.max.toDouble(), 20.0); // clamp 到 b
    expect(rOver.min.toDouble(), 5.0);
  });

  test('MinMax.lerp convergence simulation', () {
    // 模拟连续平滑: 从 a 向 b 逐帧逼近, 验证收敛性
    var current = MinMax(
      max: FlexiNum.fromNum(100.0),
      min: FlexiNum.fromNum(0.0),
    );
    final target = MinMax(
      max: FlexiNum.fromNum(200.0),
      min: FlexiNum.fromNum(50.0),
    );

    const factor = 0.15;
    for (int i = 0; i < 30; i++) {
      current = MinMax.lerp(current, target, factor);
    }

    // 30帧后应非常接近目标值 (1 - 0.85^30 ≈ 0.9956)
    expect(current.max.toDouble(), closeTo(200.0, 1.0));
    expect(current.min.toDouble(), closeTo(50.0, 1.0));
  });

  test('ensureMinDistance test', () {
    var (a, b) = ensureMinDistance(0.1, 0.2);
    debugPrint('a:$a ~ b:$b');
    expect((a - b).abs() == 1, true);

    (a, b) = ensureMinDistance(0.2, 0.1);
    debugPrint('a:$a ~ b:$b');
    expect((a - b).abs() == 1, true);

    (a, b) = ensureMinDistance(10.2, 11.0);
    debugPrint('a:$a ~ b:$b');
    expect((a - b).abs() == 1, true);

    (a, b) = ensureMinDistance(11.0, 10.2);
    debugPrint('a:$a ~ b:$b');
    expect((a - b).abs() == 1, true);
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
    final newList = [Item(10, '10-new'), Item(9, '9-new'), Item(8, '8-new'), Item(7, '7-new')];

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

  test('mergeCandleList after5', () {
    final curList = [Item(10), Item(9), Item(8)];
    final newList = [Item(9, '9-new')];

    final kData = KlineData(curList);
    final range = kData.mergeCandleLists(newList);
    final list = kData.list;

    debugPrint(range?.toString());
    debugPrint(list.toString());
    assert(equalsLists(list, [...curList]));
    assert(range == null);
  });
}

class KlineData {
  KlineData(List<Item> list) : _list = List.of(list);

  late List<Item> _list;
  List<Item> get list => _list;

  /// 合并[list]和[newList]为一个新数组
  /// 约定:
  ///   1. [newList]和[list]都是按时间倒序排好的, 即最近/新的蜡烛数据以数组0开始依次存放.
  ///   2. 如果[newList]数据存在于[list]中间, 不矛处理.
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
      while (start < list.length && list[start].timestamp >= newList.last.timestamp) {
        start++;
      }
      final curIterable = list.getRange(start, list.length);
      _list = List.of(newList, growable: true)..addAll(curIterable);
      // _list = List.of([...newList, ...curIterable]);
      return Range(0, newList.length);
    } else if (list.last.timestamp >= newList.last.timestamp) {
      int end = list.length - 1;
      while (end >= 0 && list[end].timestamp <= newList.first.timestamp) {
        end--;
      }
      final curIterable = list.getRange(0, end + 1);
      _list = List.of(curIterable, growable: true)..addAll(newList);
      // _list =  List.of([...curIterable, ...newList]);
      return Range(end + 1, _list.length);
    }
    return null;
  }
}
