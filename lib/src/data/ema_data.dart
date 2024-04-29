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

import '../extension/export.dart';
import '../model/export.dart';
import 'base_data.dart';
import 'results.dart';

mixin EMAData on BaseData {
  @override
  void initData() {
    super.initData();
    logd('init EMA');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose EMA');
    // TODO: 是否要缓存
    _count2ts2dataEmaMap.clear();
  }

  /// EMA数据缓存 <count, <timestamp, result>>
  final Map<int, Map<int, MAResult>> _count2ts2dataEmaMap = {};

  Map<int, MAResult> getCountEmaMap(int count) {
    _count2ts2dataEmaMap[count] ??= {};
    return _count2ts2dataEmaMap[count]!;
  }

  void clearEmaMap(int count) {
    _count2ts2dataEmaMap[count]?.clear();
  }

  bool isEnoughEmaDataInCache(List<CandleModel> list, int count) {
    final emaMap = getCountEmaMap(count);
    if (emaMap.isNotEmpty) {
      return emaMap.length >= list.length - count;
    }
    return false;
  }

  MAResult? getEmaResult(int? ts, int? count) {
    if (count != null && ts != null) {
      return _count2ts2dataEmaMap[count]?[ts];
    }
    return null;
  }

  /// 加权移动平均数Weighted Moving Average
  Decimal calculateWMA(
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

  /// 从缓存中获取[start, end]之间的最大最小值.
  MinMax? getEMAMinmaxFromCache(
    List<CandleModel> list,
    int count,
    int start,
    int end,
  ) {
    final len = list.length;
    if (start < 0 && end > len) return null;
    final emaMap = getCountEmaMap(count);
    if (emaMap.isEmpty ||
        emaMap.length < len - count ||
        emaMap.getItem(list[start].timestamp) == null) {
      // 校验emaMap中是否存在缓存数据. 如果不存在直接返回null
      return null;
    }
    MinMax? minMax;
    MAResult? data;
    for (int i = end - 1; i >= start; i--) {
      data = emaMap[list[i].timestamp];
      if (data != null) {
        minMax ??= MinMax(max: data.val, min: data.val);
        minMax.updateMinMaxByVal(data.val);
      }
    }
    return minMax;
  }

  /// 指数平滑移动平均线Exponential Moving Averages
  /// 由于当日EMA计算依赖于昨日EMA, 所以数据从最后开始计算, 并缓存,
  /// 注: 如果有旧数据加入列表, 需要从最旧的数据开始重新计算.
  /// 公式：
  /// 1）快速平滑移动平均线（EMA）是12日的，计算公式为：
  ///   EMA(12)=2*今收盘价/(12+1)+11*昨日EMA(12)/(12+1)
  /// 2）慢速平滑移动平均线（EMA）是26日的，计算公式为：
  ///   EMA(26)=2*今收盘价/(26+1)+25*昨日EMA(26)/(26+1)
  /// TODO: 待优化
  MinMax? calculateAndCacheEMA(
    List<CandleModel> list,
    int count, {
    int? start,
    int? end,
    bool reset = false,
  }) {
    if (list.isEmpty) return null;
    final len = list.length;
    if (len < count) return null;

    bool needReturn = start != null && end != null && start >= 0 && end < len;
    start ??= 0;
    end ??= len;
    if (start < 0 || end > len) return null;

    if (reset || !isEnoughEmaDataInCache(list, count)) {
      // EMA指标保证从[end-count, start(0)]的计算. 如果不够, 说明有新数据加入, 需要重新计算
      logd('calculateAnCacheEMA(reset:$reset) clearEmaMap($count)');
      clearEmaMap(count);
    }

    Map<int, MAResult> countEmaMap = getCountEmaMap(count);
    if (countEmaMap.isNotEmpty) {
      //logd('calculateAnCacheEMA immediate use cache!!!');
      if (needReturn) {
        return getEMAMinmaxFromCache(list, count, start, end);
      }
      return null;
    }

    // 初始采用WMA
    int index = len - count;
    Decimal lastEma = calculateWMA(index, count);
    CandleModel m = list[index];
    countEmaMap[m.timestamp] = MAResult(
      ts: m.timestamp,
      count: count,
      val: lastEma,
      dirty: true,
    );
    for (int i = index - 1; i >= 0; i--) {
      m = list[i];
      lastEma = ((two * m.close) + lastEma * (count - 1).d).div((count + 1).d);
      countEmaMap[m.timestamp] = MAResult(
        ts: m.timestamp,
        count: count,
        val: lastEma,
      );
    }
    if (needReturn) {
      return getEMAMinmaxFromCache(list, count, start, end);
    }
    return null;
  }
}
