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

import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../extension/export.dart';
import '../model/export.dart';

class CalcuData {
  final int count;
  final int ts;
  final Decimal val;
  final bool dirty;

  CalcuData({
    required this.count,
    required this.ts,
    required this.val,
    this.dirty = false,
  });
}

class CalcuDataManager {
  // CalcuDataManager._internal();
  // factory CalcuDataManager() => _instance;
  // static final CalcuDataManager _instance = CalcuDataManager._internal();
  // static CalcuDataManager get instance => _instance;

  final Decimal two = Decimal.fromInt(2);

  /// MA数据缓存 <count, <timestamp, Decimal>>
  final Map<int, Map<int, CalcuData>> count2ts2MaMap = {};

  Map<int, CalcuData>? getCountMaMap(int count) {
    return count2ts2MaMap[count];
  }

  CalcuData? getMaData(int? ts, int? count) {
    if (count != null && ts != null) {
      return count2ts2MaMap[count]?[ts];
    }
    return null;
  }

  /// MAVOL数据缓存 <count, <timestamp, Decimal>>
  final Map<int, Map<int, CalcuData>> count2ts2MaVolMap = {};

  Map<int, CalcuData>? getCountMaVolMap(int count) {
    return count2ts2MaVolMap[count];
  }

  CalcuData? getMaVolData(int? ts, int? count) {
    if (count != null && ts != null) {
      return count2ts2MaVolMap[count]?[ts];
    }
    return null;
  }

  /// EMA数据缓存 <count, <timestamp, val>>
  Map<int, Map<int, CalcuData>> count2ts2dataEmaMap = {};

  Map<int, CalcuData>? getCountEmaMap(int count) {
    return count2ts2dataEmaMap[count];
  }

  CalcuData? getEmaData(int? ts, int? count) {
    if (count != null && ts != null) {
      return count2ts2dataEmaMap[count]?[ts];
    }
    return null;
  }
}

extension CalculateMA on CalcuDataManager {
  /// 计算从index开始的count个close指标和
  /// 如果后续数据不够count个, 动态改变count. 最后平均. 所以最后的(count-1)个数据是不准确的.
  /// 注: 如果有旧数据加入, 需要重新计算最后的MA指标数据.
  CalcuData calculateMA(
    List<CandleModel> list,
    int index,
    int count,
  ) {
    final dataLen = list.length;
    assert(
      index >= 0 && index < dataLen,
      'calculateMa index is invalid',
    );
    count = math.min(count, dataLen - index);
    Decimal sum = Decimal.zero;
    CandleModel m = list[index];
    for (int i = index; i < index + count; i++) {
      sum += list[i].close;
    }
    return CalcuData(
      count: count,
      ts: m.timestamp,
      val: (sum / count.d).toDecimal(scaleOnInfinitePrecision: 18),
    );
  }

  /// 计算并缓存MA数据.
  /// 如果start和end指定了, 只计算[start, end]区间内.
  MinMax? calculateAndCacheMA(
    List<CandleModel> list,
    int count, {
    int? start,
    int? end,
    bool reset = false,
  }) {
    if (list.isEmpty) return null;
    int len = list.length;
    if (len < count) return null;

    bool needReturn = start != null && end != null && start >= 0 && end < len;
    start ??= 0;
    end ??= len;
    if (start < 0 || end > len) return null;

    Map<int, CalcuData>? maMap = getCountMaMap(count);

    if (maMap != null) {
      if (reset ||
          maMap.getItem(list.getItem(start)?.timestamp) == null ||
          maMap.getItem(list.getItem(end)?.timestamp) == null) {
        debugPrint(
          'calculateAndCacheMA reset:$reset >>> maMapLen:${maMap.length}, listLen$len : [$start, $end]',
        );
        // countMaMap.clear(); // 清理旧数据. TODO: 如何清理dirty数据
      } else {
        debugPrint('calculateAndCacheMA use cache!!! [$start, $end]');
        if (start == 0) {
          //如果start是0, 有可能更新了最新价, 重新计算
          maMap[list.first.timestamp] = calculateMA(list, 0, count);
        }
      }
    } else {
      count2ts2MaMap[count] = maMap = {};
    }

    int index = end; // 多算一个
    CandleModel m = list[index];
    CalcuData pre = maMap[m.timestamp] ?? calculateMA(list, index, count);
    maMap[m.timestamp] = pre;
    final minmax = MinMax(max: pre.val, min: pre.val);
    for (int i = index - 1; i >= start; i--) {
      m = list[i];
      CalcuData? data = maMap[m.timestamp];
      if (data == null) {
        // TODO: 优化: 利用pre去计算.
        // val = pre * math.
      }
      data ??= calculateMA(list, i, count);
      if (needReturn) minmax.updateMinMaxByVal(data.val);
      pre = data;
      maMap[m.timestamp] = data;
    }
    return needReturn ? minmax : null;
  }
}

extension CalculateMAVol on CalcuDataManager {
  /// 计算从index开始的count个vol指标和
  /// 如果后续数据不够count个, 动态改变count. 最后平均. 所以最后的(count-1)个数据是不准确的.
  /// 注: 如果有旧数据加入, 需要重新计算最后的MA指标数据.
  CalcuData calculateMAVol(
    List<CandleModel> list,
    int index,
    int count,
  ) {
    final dataLen = list.length;
    assert(
      index >= 0 && index < dataLen,
      'calculateMAVol index is invalid',
    );
    count = math.min(count, dataLen - index);
    Decimal sum = Decimal.zero;
    CandleModel m = list[index];
    for (int i = index; i < index + count; i++) {
      sum += list[i].vol;
    }
    return CalcuData(
      count: count,
      ts: m.timestamp,
      val: (sum / count.d).toDecimal(scaleOnInfinitePrecision: 18),
    );
  }

  /// 计算并缓存MA数据.
  /// 如果start和end指定了, 只计算[start, end]区间内.
  MinMax? calculateAndCacheMAVol(
    List<CandleModel> list,
    int count, {
    int? start,
    int? end,
    bool reset = false,
  }) {
    if (list.isEmpty) return null;
    int len = list.length;
    if (len < count) return null;

    bool needReturn = start != null && end != null && start >= 0 && end < len;
    start ??= 0;
    end ??= len;
    if (start < 0 || end > len) return null;

    Map<int, CalcuData>? maVolMap = getCountMaVolMap(count);

    if (maVolMap != null) {
      if (reset ||
          maVolMap.getItem(list.getItem(start)?.timestamp) == null ||
          maVolMap.getItem(list.getItem(end)?.timestamp) == null) {
        debugPrint(
          'calculateAndCacheMAVol reset:$reset >>> maVolMapLen:${maVolMap.length}, listLen$len : [$start, $end]',
        );
        // countMaMap.clear(); // 清理旧数据. TODO: 如何清理dirty数据
      } else {
        debugPrint('calculateAndCacheMAVol use cache!!! [$start, $end]');
        if (start == 0) {
          //如果start是0, 有可能更新了最新价, 重新计算
          maVolMap[list.first.timestamp] = calculateMAVol(list, 0, count);
        }
      }
    } else {
      count2ts2MaVolMap[count] = maVolMap = {};
    }

    int index = end; // 多算一个
    CandleModel m = list[index];
    CalcuData pre = maVolMap[m.timestamp] ?? calculateMAVol(list, index, count);
    maVolMap[m.timestamp] = pre;
    final minmax = MinMax(max: pre.val, min: pre.val);
    for (int i = index - 1; i >= start; i--) {
      m = list[i];
      CalcuData? data = maVolMap[m.timestamp];
      if (data == null) {
        // TODO: 优化: 利用pre去计算.
        // val = pre * math.
      }
      data ??= calculateMAVol(list, i, count);
      if (needReturn) minmax.updateMinMaxByVal(data.val);
      pre = data;
      maVolMap[m.timestamp] = data;
    }
    return needReturn ? minmax : null;
  }
}

extension CalculateEMA on CalcuDataManager {
  /// 加权移动平均数Weighted Moving Average
  Decimal calculateWMA(
    List<CandleModel> list,
    int index,
    int count,
  ) {
    final dataLen = list.length;
    assert(
      index >= 0 && index < dataLen,
      'calculateWMA($count) index is invalid',
    );
    count = math.min(count, dataLen - index);
    final weight = count * (count + 1) / 2;
    int j = count;

    Decimal sum = Decimal.zero;
    for (int i = index; i < index + count; i++) {
      sum += list[i].close * (j-- / weight).d;
    }
    return sum;
  }

  /// 指数平滑移动平均线Exponential Moving Averages
  /// 由于当日EMA计算依赖于昨日EMA, 所以数据从最后开始计算, 并缓存,
  /// 注: 如果有旧数据加入列表, 需要从最旧的数据开始重新计算.
  /// 公式：
  /// 1）快速平滑移动平均线（EMA）是12日的，计算公式为：
  ///   EMA(12)=2*今收盘价/(12+1)+11*昨日EMA(12)/(12+1)
  /// 2）慢速平滑移动平均线（EMA）是26日的，计算公式为：
  ///   EMA(26)=2*今收盘价/(26+1)+25*昨日EMA(26)/(26+1)
  void calculateAnCacheEMA(
    List<CandleModel> list,
    int count, {
    bool reset = false,
  }) {
    if (list.isEmpty) return;
    final len = list.length;
    if (len < count) return;

    Map<int, CalcuData>? countEmaMap = getCountEmaMap(count);
    if (countEmaMap != null) {
      if (reset || countEmaMap.length < len - count) {
        debugPrint(
          'calculateAnCacheEMA reset:$reset >>>  countEmaMapLen:${countEmaMap.length} < ${len - count} >>> ($len, $count)',
        );
        countEmaMap.clear(); // 清理旧数据.
      } else {
        debugPrint('calculateAnCacheEMA use cache!!!');
        return;
      }
    } else {
      count2ts2dataEmaMap[count] = countEmaMap = {};
    }

    // 初始采用WMA
    int index = len - count;
    Decimal lastEma = calculateWMA(list, index, count);
    CandleModel m = list[index];
    countEmaMap[m.timestamp] = CalcuData(
      ts: m.timestamp,
      count: count,
      val: lastEma,
    );
    for (int i = index - 1; i >= 0; i--) {
      m = list[i];
      lastEma = (((two * m.close) + lastEma * (count - 1).d) / (count + 1).d)
          .toDecimal(scaleOnInfinitePrecision: 18);
      countEmaMap[m.timestamp] = CalcuData(
        ts: m.timestamp,
        count: count,
        val: lastEma,
      );
    }
    return;
  }
}
