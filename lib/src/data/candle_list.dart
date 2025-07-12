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

extension CandleListData on BaseData {
  CandleModel? get latest => list.firstOrNull;

  Range get allRange => Range(0, list.length);

  bool checkIndex(int index) => index >= 0 && index < length;

  /// 获取index位置的蜡烛数据.
  CandleModel operator [](int index) => _list[index];

  /// 获取index位置的蜡烛数据.
  CandleModel? get(int? index) => index != null && checkIndex(index) ? _list[index] : null;

  /// 初始化基础数据
  void initBasicData(
    ComputeMode mode,
    Range range,
    int indicatorCount, {
    bool reset = false,
  }) {
    for (int i = range.start; i < range.end; i++) {
      // for (var m in _list) {
      _list[i].initBasicData(mode, indicatorCount, reset: reset);
    }
  }

  /// 根据[start, end]下标计算最大最小值
  MinMax? calculateMinmax(int start, int end) {
    if (!checkStartAndEnd(start, end)) return null;

    CandleModel m = list[end - 1];
    BagNum maxHigh = m.high;
    BagNum minLow = m.low;
    for (int i = end - 2; i >= start; i--) {
      m = list[i];
      maxHigh = m.high > maxHigh ? m.high : maxHigh;
      minLow = m.low < minLow ? m.low : minLow;
    }
    return MinMax(max: maxHigh, min: minLow);
  }

  Range? mergeCandleData(
    List<List<CandleModel>> data, {
    ComputeMode computeMode = ComputeMode.fast,
  }) {
    if (data.isEmpty) return null;
    Range? result;
    for (List<CandleModel> newList in data) {
      /// 合并[newList]到[data]中
      final range = mergeCandleList(newList);
      if (range != null) {
        // 初始化[range]内的数据.
        initBasicData(
          computeMode,
          range,
          indicatorCount,
          // reset: reset,
        );
        result ??= range;
        result = result.merge(range);
      }
    }
    updateState();
    return result;
  }

  /// 合并[list]和[newList]为一个新数组
  /// 约定: [newList]和[list]都是按时间倒序排好的, 即最近/新的蜡烛数据以数组0开始依次存放.
  /// 去重: 如两个数组拼接过程中发现重复的, 要去掉[list]中重复的元素.
  /// return: 返回新列表中被更新的范围[start] ~ [end]
  Range? mergeCandleList(List<CandleModel> newList) {
    if (newList.isEmpty) {
      logw("mergeCandleList newList is empty!");
      return null;
    }
    if (list.isEmpty) {
      logw("mergeCandleList Use newList directly!");
      _list = List.of(newList);
      return Range(0, newList.length);
    }

    if (list.first.ts <= newList.first.ts) {
      int start = 0;
      while (start < list.length && list[start].ts >= newList.last.ts) {
        start++;
      }
      final curIterable = list.getRange(start, list.length);
      _list = List.of(newList, growable: true)..addAll(curIterable);
      // _list = List.of([...newList, ...curIterable]);
      return Range(0, newList.length);
    } else if (list.last.ts >= newList.last.ts) {
      int end = list.length - 1;
      while (end >= 0 && list[end].ts <= newList.first.ts) {
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
