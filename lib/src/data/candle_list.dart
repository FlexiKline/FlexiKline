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
  ///
  /// 重置 [range] 范围内每条蜡烛的 OHLCV 数值，
  /// 保留原有 slots 长度（不依赖外部 indicatorCount）。
  void initBasicData(Range range) {
    for (int i = range.start; i < range.end; i++) {
      _list[i] = _list[i].reset(computeMode, _list[i].slotCount);
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

  /// 合并多批蜡烛数据到当前列表中。
  ///
  /// [indicatorCount] 指定新蜡烛模型的 slots 数量，传递给 [mergeCandleList]。
  Range? mergeCandleData(
    List<List<ICandleModel>> data, {
    required int indicatorCount,
  }) {
    if (data.isEmpty) return null;
    Range? result;
    for (final newList in data) {
      /// 合并[newList]到[data]中
      final range = mergeCandleList(newList, indicatorCount: indicatorCount);
      if (range != null) {
        result ??= range;
        result = result.merge(range);
      }
    }
    updateState();
    return result;
  }

  /// 合并[list]和[candleList]为一个新数组
  ///
  /// 约定: [candleList]和[list]都是按时间倒序排好的, 即最近/新的蜡烛数据以数组0开始依次存放.
  /// 去重: 如两个数组拼接过程中发现重复的, 要去掉[list]中重复的元素.
  /// [indicatorCount] 指定新蜡烛模型的 slots 数量，由调用方（Manager）提供。
  /// return: 返回新列表中被更新的范围[start] ~ [end]
  Range? mergeCandleList(
    List<ICandleModel> candleList, {
    required int indicatorCount,
  }) {
    if (candleList.isEmpty) {
      logw('mergeCandleList candleList is empty!');
      return null;
    }

    final newList = candleList.map((e) => e.toFlexiCandleModel(indicatorCount, computeMode));
    if (list.isEmpty) {
      logw('mergeCandleList Use candleList directly!');
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
