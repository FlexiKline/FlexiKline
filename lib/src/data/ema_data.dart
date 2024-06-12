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

import 'package:flutter/material.dart';

import '../config/ma_param/ma_param.dart';
import '../framework/common.dart';
import '../model/export.dart';
import 'base_data.dart';

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
    for (var model in list) {
      model.cleanEma();
    }
  }

  @override
  void precompute(
    ValueKey key, {
    dynamic calcParam,
    required Range range,
    bool reset = false,
  }) {
    if (key == emaKey && calcParam is List<MaParam>) {
      calcuAndCacheEma(
        calcParam,
        // start: range.start,
        // end: range.end,
        reset: reset,
      );
      return;
    }
    super.precompute(key, calcParam: calcParam, range: range, reset: reset);
  }

  /// 加权移动平均数Weighted Moving Average
  /// WMA = price[1] * n + price[2] * (n-1) + ... + price[n] / n * (n+1) / 2
  BagNum? calculateWMA(
    int index,
    int count,
  ) {
    if (isEmpty) return null;
    int len = list.length;
    if (count <= 0 || index < 0 || index + count > len) return null;

    final weight = count * (count + 1) / 2;
    int j = count;
    BagNum sum = BagNum.zero;
    for (int i = index; i < index + count; i++) {
      sum += list[i].close.mulNum(j-- / weight);
    }
    return sum;
  }

  /// 计算[count]的EMA数据
  /// [paramIndex] 代表在CandleModel中缓存的位置
  /// [paramLen] 代表在CandleModel中EMA列表长度
  void _calculateEma(
    int count, {
    required int paramIndex,
    required int paramLen,
  }) {
    final len = list.length;
    if (count > len || paramIndex >= paramLen) return;
    logd('calculateEma [len:$len ~ 0] count:$count');

    // 计算从end到len之间count的偏移量
    int index = len - count;
    CandleModel m = list[index];

    /// 初始值采用count日的WMA
    final weight = count * (count + 1) / 2;
    int j = count;
    BagNum ema = BagNum.zero;
    for (int i = index; i < index + count; i++) {
      ema += list[i].close.mulNum(j-- / weight);
    }

    m.emaList ??= List.filled(paramLen, null, growable: false);
    m.emaList![paramIndex] = ema;

    final preCount = count - 1;
    final nextCount = count + 1;
    for (int i = index - 1; i >= 0; i--) {
      m = list[i];
      ema = ((BagNum.two * m.close) + ema.mulNum(preCount)).divNum(nextCount);
      m.emaList ??= List.filled(paramLen, null, growable: false);
      m.emaList![paramIndex] = ema;
    }
  }

  /// 指数平滑移动平均线Exponential Moving Averages
  /// 由于当日EMA计算依赖于昨日EMA, 所以数据从最后开始计算, 并缓存,
  /// 注: 如果有旧数据加入列表, 需要从最后的数据开始重新计算.
  /// 公式：
  /// 1）快速平滑移动平均线（EMA）是12日的，计算公式为：
  ///   EMA(12)=2*今收盘价/(12+1)+11*昨日EMA(12)/(12+1)
  /// 2）慢速平滑移动平均线（EMA）是26日的，计算公式为：
  ///   EMA(26)=2*今收盘价/(26+1)+25*昨日EMA(26)/(26+1)
  void calcuAndCacheEma(
    List<MaParam> calcParams, {
    bool reset = false,
  }) {
    if (isEmpty || calcParams.isEmpty) return;
    final paramLen = calcParams.length;
    for (int i = 0; i < paramLen; i++) {
      _calculateEma(
        calcParams[i].count,
        paramIndex: i,
        paramLen: paramLen,
      );
    }
  }

  /// 计算并缓存EMA数据
  /// 注: 计算会全量计算
  MinMax? calcuEmaMinmax(
    List<MaParam> calcParams, {
    int? start,
    int? end,
  }) {
    start ??= this.start;
    end ??= this.end;
    if (calcParams.isEmpty || !checkStartAndEnd(start, end)) return null;
    final len = list.length;

    int minCount = MaParam.getMinCountByList(calcParams)!;
    end = math.min(len - minCount, end - 1);

    if (!list[end].isValidEmaList) {
      calcuAndCacheEma(calcParams);
    }

    MinMax? minmax;
    CandleModel m;
    for (int i = end; i >= start; i--) {
      m = list[i];
      minmax ??= m.emaListMinmax;
      minmax?.updateMinMax(m.emaListMinmax);
    }
    return minmax;
  }
}
