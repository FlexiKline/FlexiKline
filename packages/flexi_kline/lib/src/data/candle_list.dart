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
  /// 最新一根蜡烛(列表末尾)。
  FlexiCandleModel? get latest => list.lastOrNull;

  Range get allRange => Range(0, list.length);

  bool checkIndex(int index) => index >= 0 && index < length;

  /// 获取index位置的蜡烛数据.
  FlexiCandleModel operator [](int index) => _list[index];

  /// 获取index位置的蜡烛数据.
  FlexiCandleModel? get(int? index) => index != null && checkIndex(index) ? _list[index] : null;

  int? tsToIndex(int ts) {
    final i = _lowerBound(ts);
    return i < length && _list[i].ts == ts ? i : null;
  }

  /// 返回不晚于[ts]的最近一根真实蜡烛下标.
  int? indexAtOrBefore(int ts) {
    if (isEmpty || ts < _list.first.ts || ts > _list.last.ts) return null;
    final i = _lowerBound(ts);
    return _list[i].ts == ts ? i : i - 1;
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

    FlexiCandleModel m = list[start];
    FlexiNum maxHigh = m.high;
    FlexiNum minLow = m.low;
    for (int i = start + 1; i < end; i++) {
      m = list[i];
      maxHigh = m.high > maxHigh ? m.high : maxHigh;
      minLow = m.low < minLow ? m.low : minLow;
    }
    return MinMax(max: maxHigh, min: minLow);
  }

  /// 仅供 assert 使用: 批次按时间严格升序。
  bool _isAscending(List<ICandleModel> batch) {
    for (var i = 1; i < batch.length; i++) {
      if (batch[i].timestamp <= batch[i - 1].timestamp) return false;
    }
    return true;
  }

  /// 完整替换蜡烛列表并要求全量计算; [batch] 须按时间升序。
  Range replace(List<ICandleModel> batch, {required int slotCount}) {
    assert(_isAscending(batch), 'replace batch must be in ascending time order');
    _list = batch.map((item) => item.toFlexiCandleModel(slotCount, computeMode)).toList(growable: true);
    updateState();
    return Range.fullRecompute;
  }

  /// 把最新方向的 [batch](升序)合并进尾部, 返回被改写的尾段; 方向不符时返回 null。
  ///
  /// [batch] 覆盖的时间段以 [batch] 为准: 同 ts 蜡烛保留计算槽后更新行情, 其余替换或追加。
  Range? updateLatest(List<ICandleModel> batch, {required int slotCount}) {
    if (batch.isEmpty || list.isEmpty) return null;
    if (batch.last.timestamp < _list.last.ts || batch.first.timestamp < _list.first.ts) return null;
    assert(_isAscending(batch), 'updateLatest batch must be in ascending time order');

    var tailStart = length;
    while (tailStart > 0 && _list[tailStart - 1].ts >= batch.first.timestamp) {
      tailStart--;
    }

    final merged = <FlexiCandleModel>[];
    var old = tailStart;
    for (final candle in batch) {
      while (old < length && _list[old].ts < candle.timestamp) {
        old++;
      }
      final current = old < length && _list[old].ts == candle.timestamp ? _list[old++].rebuildSlots(slotCount) : null;
      merged.add(
        current?.copyWith(
              open: candle.open,
              high: candle.high,
              low: candle.low,
              close: candle.close,
              volume: candle.volume,
              turnover: candle.turnover,
              tradeCount: candle.tradeCount,
              confirmed: candle.confirmed,
            ) ??
            candle.toFlexiCandleModel(slotCount, computeMode),
      );
    }

    _list.replaceRange(tailStart, length, merged);
    updateState();
    return Range(tailStart, length);
  }

  /// 把历史方向的 [batch](升序)合并进头部并要求全量计算; 方向不符时返回 null。
  Range? prependHistory(List<ICandleModel> batch, {required int slotCount}) {
    if (batch.isEmpty || list.isEmpty || batch.last.timestamp > _list.first.ts) return null;
    assert(_isAscending(batch), 'prependHistory batch must be in ascending time order');

    final incoming = batch.map((item) => item.toFlexiCandleModel(slotCount, computeMode)).toList(growable: false);
    var headEnd = 0;
    while (headEnd < length && _list[headEnd].ts <= incoming.last.ts) {
      headEnd++;
    }
    _list.replaceRange(0, headEnd, incoming);
    updateState();
    return Range.fullRecompute;
  }
}
