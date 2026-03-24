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
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// 辅助：轻量时间戳 item，镜像 combineCandleList 的测试场景
// ---------------------------------------------------------------------------
class _Item {
  final int ts;
  final String val;

  _Item(this.ts, [String? val]) : val = val ?? ts.toString();

  @override
  String toString() => val;

  @override
  int get hashCode => ts.hashCode ^ val.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Item &&
          runtimeType == other.runtimeType &&
          ts == other.ts &&
          val == other.val;
}

bool _listEq(List a, List b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 镜像 CandleListData.mergeCandleList 逻辑的本地实现，用于测试合并算法。
({List<_Item> list, Range? range}) _merge(
  List<_Item> curList,
  List<_Item> newList,
) {
  if (newList.isEmpty) return (list: List.of(curList), range: null);
  if (curList.isEmpty) {
    return (list: List.of(newList), range: Range(0, newList.length));
  }
  if (curList.first.ts <= newList.first.ts) {
    int start = 0;
    while (start < curList.length && curList[start].ts >= newList.last.ts) {
      start++;
    }
    final tail = curList.getRange(start, curList.length);
    final merged = List.of(newList, growable: true)..addAll(tail);
    return (list: merged, range: Range(0, newList.length));
  } else if (curList.last.ts >= newList.last.ts) {
    int end = curList.length - 1;
    while (end >= 0 && curList[end].ts <= newList.first.ts) {
      end--;
    }
    final head = curList.getRange(0, end + 1);
    final merged = List.of(head, growable: true)..addAll(newList);
    return (list: merged, range: Range(end + 1, merged.length));
  }
  return (list: List.of(curList), range: null);
}

CandleModel _makeCandle(int ts) => CandleModel(
      timestamp: ts,
      open: Decimal.fromInt(1),
      high: Decimal.fromInt(1),
      low: Decimal.fromInt(1),
      close: Decimal.fromInt(1),
      volume: Decimal.fromInt(1),
    );

void main() {
  // ---------------------------------------------------------------------------
  // combineCandleList — 直接测试 kline_data.dart 中的库函数
  // ---------------------------------------------------------------------------
  group('combineCandleList', () {
    test('newList 为空：返回 oldList，range 为 Range.empty', () {
      final old = [_makeCandle(10), _makeCandle(9), _makeCandle(8)];
      final (list, range) = combineCandleList(old, []);
      expect(list.map((e) => e.ts).toList(), [10, 9, 8]);
      expect(range, Range.empty);
    });

    test('oldList 为空：使用 newList，range=[0, newList.length)', () {
      final newList = [_makeCandle(10), _makeCandle(9), _makeCandle(8)];
      final (list, range) = combineCandleList([], newList);
      expect(list.map((e) => e.ts).toList(), [10, 9, 8]);
      expect(range, Range(0, 3));
    });

    test('newList 比 oldList 新（前插）', () {
      final old = [_makeCandle(10), _makeCandle(9), _makeCandle(8)];
      final newList = [_makeCandle(12), _makeCandle(11)];
      final (list, range) = combineCandleList(old, newList);
      expect(list.map((e) => e.ts).toList(), [12, 11, 10, 9, 8]);
      expect(range, Range(0, 2));
    });

    test('newList 与 oldList 首端重叠（覆盖最新）', () {
      final old = [_makeCandle(10), _makeCandle(9), _makeCandle(8)];
      final newList = [_makeCandle(11), _makeCandle(10), _makeCandle(9)];
      final (list, range) = combineCandleList(old, newList);
      expect(list.map((e) => e.ts).toList(), [11, 10, 9, 8]);
      expect(range, Range(0, 3));
    });

    test('newList 比 oldList 旧（尾追加）', () {
      final old = [_makeCandle(10), _makeCandle(9), _makeCandle(8)];
      final newList = [_makeCandle(7), _makeCandle(6)];
      final (list, range) = combineCandleList(old, newList);
      expect(list.map((e) => e.ts).toList(), [10, 9, 8, 7, 6]);
      expect(range, Range(3, 5));
    });

    test('newList 与 oldList 尾端重叠（覆盖历史）', () {
      final old = [_makeCandle(10), _makeCandle(9), _makeCandle(8)];
      final newList = [_makeCandle(9), _makeCandle(8), _makeCandle(7)];
      final (list, range) = combineCandleList(old, newList);
      expect(list.map((e) => e.ts).toList(), [10, 9, 8, 7]);
      expect(range, Range(1, 4));
    });

    test('newList 完全覆盖 oldList', () {
      final old = [_makeCandle(10), _makeCandle(9), _makeCandle(8)];
      final newList = [
        _makeCandle(10),
        _makeCandle(9),
        _makeCandle(8),
        _makeCandle(7),
      ];
      final (list, range) = combineCandleList(old, newList);
      expect(list.map((e) => e.ts).toList(), [10, 9, 8, 7]);
      expect(range, Range(0, 4));
    });

    test('newList 完全在 oldList 内部（不处理，返回原列表）', () {
      final old = [_makeCandle(10), _makeCandle(9), _makeCandle(8)];
      final newList = [_makeCandle(9)];
      final (list, range) = combineCandleList(old, newList);
      expect(range, Range.empty);
      expect(list.map((e) => e.ts).toList(), [10, 9, 8]);
    });
  });

  // ---------------------------------------------------------------------------
  // mergeCandleList 算法逻辑 — 用轻量 _Item 覆盖各合并分支
  // ---------------------------------------------------------------------------
  group('mergeCandleList（算法逻辑）', () {
    test('空列表', () {
      final r = _merge([], []);
      expect(r.list, isEmpty);
      expect(r.range, isNull);
    });

    test('仅 curList', () {
      final r = _merge([_Item(10), _Item(9), _Item(8)], []);
      expect(_listEq(r.list, [_Item(10), _Item(9), _Item(8)]), isTrue);
      expect(r.range, isNull);
    });

    test('仅 newList', () {
      final newList = [_Item(10, '10-new'), _Item(9, '9-new'), _Item(8, '8-new')];
      final r = _merge([], newList);
      expect(_listEq(r.list, newList), isTrue);
      expect(r.range, Range(0, newList.length));
    });

    test('before1：newList 覆盖 curList 头部', () {
      final cur = [_Item(10), _Item(9), _Item(8)];
      final newList = [_Item(11, '11-new'), _Item(10, '10-new'), _Item(9, '9-new')];
      final r = _merge(cur, newList);
      expect(_listEq(r.list, [...newList, _Item(8)]), isTrue);
      expect(r.range, Range(0, newList.length));
    });

    test('before2：newList 单条更新最新', () {
      final cur = [_Item(10), _Item(9), _Item(8)];
      final newList = [_Item(10, '10-new')];
      final r = _merge(cur, newList);
      expect(_listEq(r.list, [...newList, _Item(9), _Item(8)]), isTrue);
      expect(r.range, Range(0, 1));
    });

    test('before3：newList 更新超出最新', () {
      final cur = [_Item(10), _Item(9), _Item(8)];
      final newList = [_Item(11, '11-new')];
      final r = _merge(cur, newList);
      expect(_listEq(r.list, [...newList, ...cur]), isTrue);
      expect(r.range, Range(0, 1));
    });

    test('before4：newList 覆盖全部 curList', () {
      final cur = [_Item(10), _Item(9), _Item(8)];
      final newList = [
        _Item(10, '10-new'),
        _Item(9, '9-new'),
        _Item(8, '8-new'),
        _Item(7, '7-new'),
      ];
      final r = _merge(cur, newList);
      expect(_listEq(r.list, newList), isTrue);
      expect(r.range, Range(0, newList.length));
    });

    test('after1：newList 在 curList 尾部追加', () {
      final cur = [_Item(10), _Item(9), _Item(8)];
      final newList = [_Item(9, '9-new'), _Item(8, '8-new'), _Item(7, '7-new')];
      final r = _merge(cur, newList);
      expect(_listEq(r.list, [_Item(10), ...newList]), isTrue);
      expect(r.range, Range(1, r.list.length));
    });

    test('after2：newList 追加到尾部', () {
      final cur = [_Item(10), _Item(9), _Item(8)];
      final newList = [_Item(8, '8-new'), _Item(7, '7-new')];
      final r = _merge(cur, newList);
      expect(_listEq(r.list, [_Item(10), _Item(9), ...newList]), isTrue);
      expect(r.range, Range(2, r.list.length));
    });

    test('after3：newList 完全在 curList 之后', () {
      final cur = [_Item(10), _Item(9), _Item(8)];
      final newList = [_Item(7, '7-new')];
      final r = _merge(cur, newList);
      expect(_listEq(r.list, [...cur, ...newList]), isTrue);
      expect(r.range, Range(3, r.list.length));
    });

    test('after4：newList 完全覆盖（更早）', () {
      final cur = [_Item(10), _Item(9), _Item(8)];
      final newList = [
        _Item(11, '11-new'),
        _Item(10, '10-new'),
        _Item(9, '9-new'),
        _Item(8, '8-new'),
      ];
      final r = _merge(cur, newList);
      expect(_listEq(r.list, newList), isTrue);
      expect(r.range, Range(0, r.list.length));
    });

    test('after5：newList 完全嵌套在 curList 内部，不处理', () {
      final cur = [_Item(10), _Item(9), _Item(8)];
      final newList = [_Item(9, '9-new')];
      final r = _merge(cur, newList);
      expect(_listEq(r.list, cur), isTrue);
      expect(r.range, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // removeDuplicate — 去重算法
  // ---------------------------------------------------------------------------
  group('removeDuplicate', () {
    // 注意：removeDuplicate 不支持空列表（slow 从 1 开始，sublist 会越界）
    test('单元素：原样返回', () {
      final result = removeDuplicate([_makeCandle(10)]);
      expect(result.map((e) => e.ts).toList(), [10]);
    });

    test('无重复：原样返回', () {
      final result = removeDuplicate(List.of([_makeCandle(10), _makeCandle(9), _makeCandle(8)]));
      expect(result.map((e) => e.ts).toList(), [10, 9, 8]);
    });

    test('相邻重复：去除重复，保留第一个', () {
      final list = [
        _makeCandle(10),
        _makeCandle(10),
        _makeCandle(9),
        _makeCandle(8),
        _makeCandle(8),
      ];
      final result = removeDuplicate(list);
      expect(result.map((e) => e.ts).toList(), [10, 9, 8]);
    });

    test('全部相同：只保留一个', () {
      final list = [_makeCandle(5), _makeCandle(5), _makeCandle(5)];
      final result = removeDuplicate(list);
      expect(result.map((e) => e.ts).toList(), [5]);
    });

    test('头部有重复：正确去重', () {
      final list = [_makeCandle(10), _makeCandle(10), _makeCandle(9)];
      final result = removeDuplicate(list);
      expect(result.map((e) => e.ts).toList(), [10, 9]);
    });

    test('尾部有重复：正确去重', () {
      final list = [_makeCandle(10), _makeCandle(9), _makeCandle(9)];
      final result = removeDuplicate(list);
      expect(result.map((e) => e.ts).toList(), [10, 9]);
    });
  });
}
