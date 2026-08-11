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

  /// 返回不晚于[ts]的最近一根真实蜡烛下标.
  int? indexAtOrBefore(int ts) {
    if (list.isEmpty || ts > list.first.ts || ts < list.last.ts) return null;

    var low = 0;
    var high = list.length - 1;
    while (low < high) {
      final mid = low + ((high - low) >> 1);
      if (list[mid].ts <= ts) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    return low;
  }

  @override
  void initData() {
    super.initData();
    initBasicData(allRange);
  }

  /// 初始化基础数据.
  void initBasicData(Range range) {
    for (int i = range.start; i < range.end; i++) {
      _list[i] = _list[i].reset(computeMode, _list[i].slotCount);
    }
  }

  /// 根据[start, end]下标计算最大最小值.
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

  /// 完整替换蜡烛列表并要求全量计算.
  Range replace(List<ICandleModel> batch, {required int slotCount}) {
    _list = batch.map((item) => item.toFlexiCandleModel(slotCount, computeMode)).toList(growable: true);
    updateState();
    return Range.fullRecompute;
  }

  /// 合并最新方向数据，方向错误时返回 null.
  Range? updateLatest(List<ICandleModel> batch, {required int slotCount}) {
    if (batch.isEmpty || list.isEmpty) return null;
    if (batch.first.timestamp < list.first.ts || batch.last.timestamp < list.last.ts) return null;

    int start = 0;
    while (start < list.length && list[start].ts >= batch.last.ts) {
      start++;
    }

    final incoming = List<FlexiCandleModel?>.filled(batch.length, null, growable: false);
    int oldIndex = start - 1;
    for (int i = batch.length - 1; i >= 0; i--) {
      final candle = batch[i];
      while (oldIndex >= 0 && list[oldIndex].ts < candle.timestamp) {
        oldIndex--;
      }
      FlexiCandleModel? current;
      if (oldIndex >= 0 && list[oldIndex].ts == candle.timestamp) {
        current = list[oldIndex--].rebuildSlots(slotCount);
      }
      incoming[i] = current?.copyWith(
            open: candle.open,
            high: candle.high,
            low: candle.low,
            close: candle.close,
            volume: candle.volume,
            turnover: candle.turnover,
            tradeCount: candle.tradeCount,
            confirmed: candle.confirmed,
          ) ??
          candle.toFlexiCandleModel(slotCount, computeMode);
    }

    final merged = incoming.cast<FlexiCandleModel>();
    if (merged.length == start) {
      for (int i = 0; i < merged.length; i++) {
        _list[i] = merged[i];
      }
    } else {
      _list = List.of(merged, growable: true)..addAll(list.getRange(start, list.length));
    }
    updateState();
    return Range(0, merged.length);
  }

  /// 合并历史方向数据，方向错误时返回 null.
  Range? appendHistory(List<ICandleModel> batch, {required int slotCount}) {
    if (batch.isEmpty || list.isEmpty || batch.first.timestamp > list.last.ts) return null;

    final incoming = batch.map((item) => item.toFlexiCandleModel(slotCount, computeMode)).toList(growable: false);
    int end = list.length - 1;
    while (end >= 0 && list[end].ts <= incoming.first.ts) {
      end--;
    }
    final tailStart = end + 1;
    final oldTailCount = list.length - tailStart;
    if (incoming.length == oldTailCount) {
      for (int i = 0; i < incoming.length; i++) {
        _list[tailStart + i] = incoming[i];
      }
    } else {
      _list.length = tailStart;
      _list.addAll(incoming);
    }
    updateState();
    return Range.fullRecompute;
  }
}
