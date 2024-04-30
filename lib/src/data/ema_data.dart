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

import '../extension/export.dart';
import '../framework/indicator.dart';
import '../indicators/ema.dart';
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
    _emaResultMap.clear();
  }

  @override
  void preprocess(
    Indicator indicator, {
    required int start,
    required int end,
    bool reset = false,
  }) {
    super.preprocess(indicator, start: start, end: end, reset: reset);
    if (indicator is EMAIndicator) {
      for (var param in indicator.calcParams) {
        logd('preprocess EMA => ${param.count}');
        calculateEma(param.count);
      }
    }
  }

  /// EMA数据缓存 <count, <timestamp, result>>
  final Map<int, Map<int, MaResult>> _emaResultMap = {};

  Map<int, MaResult> getEmaMap(int count) {
    _emaResultMap[count] ??= {};
    return _emaResultMap[count]!;
  }

  MaResult? getEmaResult({int? count, int? ts}) {
    if (count != null && ts != null) {
      return _emaResultMap[count]?[ts];
    }
    return null;
  }

  /// 加权移动平均数Weighted Moving Average
  /// WMA = price[1] * n + price[2] * (n-1) + ... + price[n] / n * (n+1) / 2
  Decimal? calculateWMA(
    int index,
    int count,
  ) {
    if (isEmpty) return null;
    int len = list.length;
    if (count <= 0 || index < 0 || index + count > len) return null;

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
  /// 注: 如果有旧数据加入列表, 需要从最后的数据开始重新计算.
  /// 公式：
  /// 1）快速平滑移动平均线（EMA）是12日的，计算公式为：
  ///   EMA(12)=2*今收盘价/(12+1)+11*昨日EMA(12)/(12+1)
  /// 2）慢速平滑移动平均线（EMA）是26日的，计算公式为：
  ///   EMA(26)=2*今收盘价/(26+1)+25*昨日EMA(26)/(26+1)
  void calculateEma(int count) {
    if (count <= 0 || !canPaintChart) return;
    final len = list.length;
    if (len < count) return;

    // 获取count对应的Emap数据结果, 并清空它.
    Map<int, MaResult> emaMap = getEmaMap(count);
    if (emaMap.isNotEmpty) emaMap.clear();

    // 计算从end到len之间count的偏移量
    int index = len - count;
    CandleModel m = list[index];

    /// 初始值采用count日的WMA
    final weight = count * (count + 1) / 2;
    int j = count;
    Decimal ema = Decimal.zero;
    for (int i = index; i < index + count; i++) {
      ema += list[i].close * (j-- / weight).d;
    }

    emaMap[m.timestamp] = MaResult(
      ts: m.timestamp,
      count: count,
      val: ema,
      dirty: true,
    );

    final preCount = Decimal.fromInt(count - 1);
    final nextCount = Decimal.fromInt(count + 1);
    for (int i = index - 1; i >= 0; i--) {
      m = list[i];
      ema = ((two * m.close) + ema * preCount).div(nextCount);
      emaMap[m.timestamp] = MaResult(
        ts: m.timestamp,
        count: count,
        val: ema,
        dirty: true,
      );
    }
  }

  /// 计算并缓存EMA数据
  /// 注: 计算会全量计算
  MinMax? calculateMinmaxEma(
    int count, {
    int? start,
    int? end,
    bool reset = false,
  }) {
    if (count <= 0 || isEmpty) return null;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (start < 0 || end > len) return null;

    final emaMap = getEmaMap(count);
    if (reset) {
      emaMap.clear();
    }

    // 说明当前count对应的EMA数量不够; 需要重新计算
    if (emaMap.length < len - count + 1) {
      calculateEma(count);
    }

    MinMax? minMax;
    MaResult? data;
    for (int i = end - 1; i >= start; i--) {
      data = emaMap[list[i].timestamp];
      if (data != null) {
        minMax ??= MinMax(max: data.val, min: data.val);
        minMax.updateMinMaxByVal(data.val);
      }
    }
    return minMax;
  }
}
