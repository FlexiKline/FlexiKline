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

part of 'kline_data.dart';

mixin CandleListData on BaseData {
  FlexiCandleModel? get latest => list.firstOrNull;

  Range get allRange => Range(0, list.length);

  bool checkIndex(int index) => index >= 0 && index < length;

  /// 获取index位置的蜡烛数据.
  FlexiCandleModel operator [](int index) => _list[index];

  /// 获取index位置的蜡烛数据.
  FlexiCandleModel? get(int? index) => index != null && checkIndex(index) ? _list[index] : null;

  int? tsToIndex(int ts) {
    final index = list.indexWhere((m) => m.ts == ts);
    return checkIndex(index) ? index : null;
  }

  @override
  void initData() {
    super.initData();
    initBasicData(allRange);
  }

  /// 初始化基础数据
  void initBasicData(Range range) {
    for (int i = range.start; i < range.end; i++) {
      _list[i] = _list[i].reset(computeMode, indicatorCount);
    }
  }

  /// 根据[start, end]下标计算最大最小值
  MinMax? calculateMinmax(int start, int end) {
    if (!checkStartAndEnd(start, end)) return null;

    FlexiCandleModel m = list[end - 1];
    FlexiNum maxHigh = m.high;
    FlexiNum minLow = m.low;
    for (int i = end - 2; i >= start; i--) {
      m = list[i];
      maxHigh = m.high > maxHigh ? m.high : maxHigh;
      minLow = m.low < minLow ? m.low : minLow;
    }
    return MinMax(max: maxHigh, min: minLow);
  }

  Range? mergeCandleData(List<List<ICandleModel>> data) {
    if (data.isEmpty) return null;
    Range? result;
    for (final newList in data) {
      /// 合并[newList]到[data]中
      final range = mergeCandleList(newList);
      if (range != null) {
        result ??= range;
        result = result.merge(range);
      }
    }
    updateState();
    return result;
  }

  /// 合并 [candleList] 到当前 [list] 中.
  ///
  /// 约定: [candleList] 与 [list] 都按时间倒序排列, 即最新的蜡烛位于 0 号位.
  /// 去重: 如两数组在时间维度上有重叠, 重叠位置以 [candleList] 为准.
  /// 返回: 新列表中被更新的范围 [start] ~ [end], 没有更新返回 null.
  Range? mergeCandleList(List<ICandleModel> candleList) {
    if (candleList.isEmpty) {
      logw('mergeCandleList candleList is empty!');
      return null;
    }

    final newList = candleList.map((e) => e.toFlexiCandleModel(indicatorCount, computeMode)).toList(growable: false);

    if (list.isEmpty) {
      logw('mergeCandleList Use candleList directly!');
      _list = List.of(newList);
      return Range(0, newList.length);
    }

    final firstNew = newList.first.ts;
    final lastNew = newList.last.ts;

    if (list.first.ts <= firstNew) {
      int start = 0;
      while (start < list.length && list[start].ts >= lastNew) {
        start++;
      }

      if (newList.length == start) {
        // 快路径: 头部对齐且数量一致, 原地覆盖前 N 根, 不重建 List.
        for (int i = 0; i < newList.length; i++) {
          _list[i] = newList[i];
        }
      } else {
        _list = List.of(newList, growable: true)..addAll(list.getRange(start, list.length));
      }
      return Range(0, newList.length);
    } else if (list.last.ts >= lastNew) {
      int end = list.length - 1;
      while (end >= 0 && list[end].ts <= firstNew) {
        end--;
      }
      final tailStart = end + 1;
      final oldTailCount = list.length - tailStart;

      if (newList.length == oldTailCount) {
        // 快路径: 尾部对齐且数量一致, 原地覆盖末尾 N 根.
        for (int i = 0; i < newList.length; i++) {
          _list[tailStart + i] = newList[i];
        }
      } else {
        // 原地截断 + 追加, 避免把 [0, tailStart) 段元素重复拷一次.
        if (tailStart < _list.length) {
          _list.length = tailStart;
        }
        _list.addAll(newList);
      }
      return Range(tailStart, _list.length);
    }
    return null;
  }
}
