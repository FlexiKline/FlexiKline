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

import '../config/rsi_param/rsi_param.dart';
import '../framework/common.dart';
import '../model/export.dart';
import 'base_data.dart';

mixin RSIData on BaseData {
  @override
  void initData() {
    super.initData();
    logd('init RSI');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose RSI');
    for (var model in list) {
      model.cleanRsi();
    }
  }

  @override
  void precompute(
    ValueKey key, {
    dynamic calcParam,
    required Range range,
    bool reset = false,
  }) {
    if (key == rsiKey && calcParam is List<RsiParam>) {
      calcuAndCacheRsi(
        calcParam,
        // start: range.start,
        // end: range.end,
        reset: reset,
      );
      return;
    }
    super.precompute(key, calcParam: calcParam, range: range, reset: reset);
  }

  /// 计算[index]位置的RSI指标上升值
  BagNum _calculateUpVal(int index) {
    if (index >= 0 && index < list.length - 1) {
      return list[index].close - list[index + 1].close;
    }
    return BagNum.zero;
  }

  /// RSI相对强弱指数计算
  /// 1. 收盘价变化
  ///   Diff = CurrClose - PrevClose;
  /// 2. 得与失
  ///   Sum Gain = Sum({...Diff > 0});
  ///   Sum Loss = Sum({...Diff < 0}).abs();
  /// 3. 平均收益和损失
  ///   Avg Gain = Sum Gain / count;
  ///   [（以前的平均增益）* (count-1)）+ 当前增益）]/count
  /// 4. 计算RS
  ///   RS = (Avg Gain)/(Avg Loss)
  /// 5. 计算RSI
  ///   RSI = [100 - (100/{1+ RS})]。
  void _calculateRsi(
    int count, {
    required int paramIndex,
    required int paramLen,
    // int? start,
    // int? end,
  }) {
    final len = list.length;
    // start ??= this.start;
    // end ??= this.end;
    // if (count >= len || !checkStartAndEnd(start, end)) return;
    // logd('calculateRsi [end:$end ~ start:$start] count:$count');
    if (count >= len || paramIndex >= paramLen) return;
    logd('calculateRsi [len:$len ~ 0] count:$count');

    /// RSI要从end前的count+1个数据开始计算.
    // final index = math.min(end + count, len - 1);
    final index = len - 1;

    CandleModel m = list[index];
    BagNum prevClose = m.close;
    BagNum sumGain = BagNum.zero;
    BagNum sumLoss = BagNum.zero;
    BagNum? avgGain;
    BagNum? avgLoss;
    BagNum diff;
    BagNum gain = BagNum.zero;
    BagNum loss = BagNum.zero;
    for (int i = index - 1; i >= start; i--) {
      m = list[i];

      diff = m.close - prevClose;
      prevClose = m.close;
      if (diff.signum > 0) {
        gain = diff;
        loss = BagNum.zero;
        sumGain = gain + sumGain;
      } else {
        loss = diff.abs();
        gain = BagNum.zero;
        sumLoss = loss + sumLoss;
      }

      if (i <= index - count) {
        m.rsiList ??= List.filled(paramLen, null, growable: false);

        if (avgGain == null) {
          avgGain = sumGain.divNum(count);
        } else {
          avgGain = (avgGain.mulNum(count - 1) + gain).divNum(count);
        }
        if (avgLoss == null) {
          avgLoss = sumLoss.divNum(count);
        } else {
          avgLoss = (avgLoss.mulNum(count - 1) + loss).divNum(count);
        }

        m.rsiList![paramIndex] = avgLoss == BagNum.zero
            ? 0
            : 100 - (100 / (1 + avgGain.div(avgLoss).toDouble()));

        diff = _calculateUpVal(i + count - 1);
        if (diff.signum > 0) {
          sumGain -= diff;
        } else {
          sumLoss -= diff.abs();
        }
      }
    }
  }

  void calcuAndCacheRsi(
    List<RsiParam> calcParams, {
    // required int start,
    // required int end,
    bool reset = false,
  }) {
    if (isEmpty || calcParams.isEmpty) return;
    final paramLen = calcParams.length;
    for (int i = 0; i < paramLen; i++) {
      _calculateRsi(
        calcParams[i].count,
        paramIndex: i,
        paramLen: paramLen,
        // start: math.max(0, start - calcParams[i].count), // 补起上一次未算数据
        // end: end,
      );
    }
  }

  MinMax? calcuRsiMinmax(
    List<RsiParam> calcParams, {
    int? start,
    int? end,
  }) {
    start ??= this.start;
    end ??= this.end;
    if (calcParams.isEmpty || !checkStartAndEnd(start, end)) return null;
    final len = list.length;

    int minCount = RsiParam.getMinCountByList(calcParams)!;
    end = math.min(len - minCount - 1, end - 1);

    if (!list[end].isValidRsiList) {
      // calcuAndCacheRsi(calcParams, start: 0, end: len);
      calcuAndCacheRsi(calcParams);
    }

    MinMax? minmax;
    CandleModel m;
    for (int i = end; i >= start; i--) {
      m = list[i];
      minmax ??= m.rsiListMinmax;
      minmax?.updateMinMax(m.rsiListMinmax);
    }
    return minmax;
  }
}
