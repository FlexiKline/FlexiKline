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

mixin PaintDrawData on BaseData {
  bool get canPaintChart {
    return isNotEmpty && list.checkIndex(start); // TODO && list.checkIndex(end);
  }

  @override
  bool checkStartAndEnd(int start, int end) {
    return isNotEmpty && start < end && start >= 0 && end <= length;
  }

  void ensureStartAndEndIndex(
    int startIndex,
    int maxCandleCount,
  ) {
    start = startIndex;
    end = startIndex + maxCandleCount;
  }

  Range get computableRange => Range(0, length);

  Range? get drawTimeRange {
    if (checkStartAndEnd(start, end)) {
      return Range(list[start].ts, list[end].ts);
    }
    return null;
  }

  /// 将[ts]转换为当前KlineData数据列表的下标和剩余偏移率
  /// 如果ts > 最新价, 将为负
  double? timestampToIndex(int ts) {
    if (list.isEmpty || req.timeBar == null) return null;
    int latestIndex = 0; // TODO: 后续性能优化考虑数据方向
    final timespans = req.timeBar!.milliseconds;
    final first = list.first;
    final last = list.last;
    if (ts > first.ts) {
      // 超出蜡烛数据时间范围, 不予考虑交易时间问题
      final distance = first.ts - ts;
      final value = distance / timespans;
      return latestIndex + value;
    } else if (ts <= last.ts) {
      // 超出蜡烛数据时间范围, 不予考虑交易时间问题
      final distance = last.ts - ts;
      final value = distance / timespans;
      return list.length - 1 + value;
    } else {
      int i = latestIndex;
      final distance = first.ts - ts;
      final indexValue = distance / timespans;
      final index = indexValue.truncate();
      final patch = indexValue - index;
      for (; i < list.length; i++) {
        if (ts == list[i].ts) break;
        if (ts > list[i].ts) {
          i--;
          break;
        }
      }
      return i + patch;
    }
  }

  /// 将[indexValue]转换为以当前KlineData数据范围为基础的timestamp
  int? indexToTimestamp(double indexValue) {
    if (list.isEmpty || req.timeBar == null) return null;
    final timespans = req.timeBar!.milliseconds;
    final index = indexValue.toInt();
    final patchTs = ((indexValue - index) * timespans).truncate();
    if (index < 0) {
      return list.first.ts - index * timespans - patchTs;
    } else if (index >= list.length - 1) {
      return list.last.ts - (index + 1 - list.length) * timespans - patchTs;
    } else {
      return list[index].ts - patchTs;
    }
  }
}
