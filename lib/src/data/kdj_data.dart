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

import '../config/kdj_param/kdj_param.dart';
import '../framework/common.dart';
import '../model/export.dart';
import 'base_data.dart';
import 'candle_data.dart';

mixin KDJData on BaseData, CandleData {
  @override
  void initData() {
    super.initData();
    logd('init KDJ');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose KDJ');
    for (var model in list) {
      model.cleanKdj();
    }
  }

  @override
  void precompute(
    ValueKey key, {
    dynamic calcParam,
    required Range range,
    bool reset = false,
  }) {
    if (key == kdjKey && calcParam is KDJParam) {
      calcuAndCacheKDJ(
        param: calcParam,
        start: math.max(0, range.start - calcParam.n), // 补起上一次未算数据
        end: range.end,
        reset: reset,
      );
      return;
    }
    super.precompute(key, calcParam: calcParam, range: range, reset: reset);
  }

  /// 首先要计算周期（n日、n周等）的RSV值（即未成熟随机指标值），然后再计算K值、D值、J值等。
  /// 以日KDJ数值的计算为例，其计算公式为：n日RSV=（Cn－Ln）÷（Hn－Ln）×100
  /// 公式中，Cn为第n日收盘价；Ln为n日内的最低价；Hn为第n日内的最高价。RSV值始终在1—100间波动。
  /// 其次，计算K值与D值：
  /// 当日K值=2/3×前一日K值＋1/3×当日RSV
  /// 当日D值=2/3×前一日D值＋1/3×当日K值
  /// 若无前一日K 值与D值，则可分别用50（1-100的中间值）来代替。
  /// J值=3*当日K值-2*当日D值
  /// 以9日为周期的KD线为例。首先须计算出最近9日的RSV值，即未成熟随机值，计算公式为 9日RSV=（C－L9）÷（H9－L9）×100
  /// 公式中，C为第9日的收盘价；L9为9日内的最低价；H9为9日内的最高价。
  /// K值=2/3×第8日K值＋1/3×第9日RSV
  /// D值=2/3×第8日D值＋1/3×第9日K值
  /// J值=3*第9日K值-2*第9日D值
  /// 若无前一日K值与D值，则可以分别用50代替。
  void calcuAndCacheKDJ({
    required KDJParam param,
    int? start,
    int? end,
    bool reset = false,
  }) {
    final len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (!param.isValid(len) || !checkStartAndEnd(start, end)) return;
    logd('calcuAndCacheKDJ [end:$end ~ start:$start] param:$param');

    // 计算从end到len之间n的偏移量
    end = math.min(len - param.n, end - 1);

    final m1pre = param.m1 - 1;
    final m2pre = param.m2 - 1;
    BagNum rsv;
    CandleModel m;
    BagNum k = BagNum.fifty;
    BagNum d = BagNum.fifty;
    BagNum j;

    // 计算KDJ
    for (int i = end; i >= start; i--) {
      m = list[i];

      final minmax = calculateMinmax(start: i, end: i + param.n);
      if (minmax == null) continue;
      rsv = (m.close - minmax.min).div(minmax.diffDivisor) * BagNum.hundred;
      k = (rsv + k.mulNum(m1pre)).divNum(param.m1);
      d = (k + d.mulNum(m2pre)).divNum(param.m2);
      j = BagNum.three * k - BagNum.two * d;

      m.k = k;
      m.d = d;
      m.j = j;
    }
  }

  MinMax? calcuKdjMinmax({
    required KDJParam param,
    int? start,
    int? end,
  }) {
    final len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (!param.isValid(len) || !checkStartAndEnd(start, end)) return null;

    end = math.min(len - param.n, end - 1);

    if (end < start) return null;
    if (!list[end].isValidKdjData) {
      calcuAndCacheKDJ(param: param, start: 0, end: len);
    }

    MinMax? minmax;
    CandleModel m;
    for (int i = end; i >= start; i--) {
      m = list[i];
      minmax ??= m.kdjMinmax;
      minmax?.updateMinMax(m.kdjMinmax);
    }
    return minmax;
  }
}

// @Deprecated('废弃的')
// mixin KDJData2 on BaseData, CandleData {
//   @override
//   void initData() {
//     super.initData();
//     logd('init KDJ');
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     logd('dispose KDJ');
//     _kdjResultMap.clear();
//   }

//   @override
//   void preprocess(
//     Indicator indicator, {
//     required int start,
//     required int end,
//     bool reset = false,
//   }) {
//     if (indicator is KDJIndicator) {
//       calculateAndCacheKDJ(
//         param: indicator.calcParam,
//         start: start,
//         end: end,
//         reset: reset,
//       );
//     } else {
//       super.preprocess(indicator, start: start, end: end, reset: reset);
//     }
//   }

//   final Map<KDJParam, Map<int, KdjReset>> _kdjResultMap = {};

//   Map<int, KdjReset> getKdjMap(KDJParam param) {
//     _kdjResultMap[param] ??= {};
//     return _kdjResultMap[param]!;
//   }

//   KdjReset? getKdjResult({KDJParam? param, int? ts}) {
//     if (param != null && ts != null) {
//       return _kdjResultMap[param]?[ts];
//     }
//     return null;
//   }

//   /// 首先要计算周期（n日、n周等）的RSV值（即未成熟随机指标值），然后再计算K值、D值、J值等。
//   /// 以日KDJ数值的计算为例，其计算公式为：n日RSV=（Cn－Ln）÷（Hn－Ln）×100
//   /// 公式中，Cn为第n日收盘价；Ln为n日内的最低价；Hn为n日内的最高价。RSV值始终在1—100间波动。
//   /// 其次，计算K值与D值：当日K值=2/3×前一日K值＋1/3×当日RSV
//   /// 当日D值=2/3×前一日D值＋1/3×当日K值
//   /// 若无前一日K 值与D值，则可分别用50（1-100的中间值）来代替。
//   /// J值=3*当日K值-2*当日D值
//   /// 以9日为周期的KD线为例。首先须计算出最近9日的RSV值，即未成熟随机值，计算公式为 9日RSV=（C－L9）÷（H9－L9）×100
//   /// 公式中，C为第9日的收盘价；L9为9日内的最低价；H9为9日内的最高价。
//   /// K值=2/3×第8日K值＋1/3×第9日RSV
//   /// D值=2/3×第8日D值＋1/3×第9日K值
//   /// J值=3*第9日K值-2*第9日D值
//   /// 若无前一日K值与D值，则可以分别用50代替。
//   void calculateAndCacheKDJ({
//     required KDJParam param,
//     int? start,
//     int? end,
//     bool reset = false,
//   }) {
//     if (!param.isValid || isEmpty) return;
//     int len = list.length;
//     start ??= this.start;
//     end ??= this.end;
//     if (start < 0 || end > len) return;

//     final kdjMap = getKdjMap(param);
//     if (reset) {
//       kdjMap.clear();
//     }

//     // 计算从end到len之间n的偏移量
//     int offset = math.max(end + param.n - len, 0);
//     int index = end - offset;

//     final m1k = BagNum.fromInt(param.m1 - 1);
//     final m1Div = BagNum.fromInt(param.m1);
//     final m2d = BagNum.fromInt(param.m2 - 1);
//     final m2Div = BagNum.fromInt(param.m2);
//     KdjReset? ret;
//     BagNum rsv;
//     CandleModel m;
//     BagNum k = BagNum.fifty;
//     BagNum d = BagNum.fifty;
//     BagNum j;

//     // 计算KDJ
//     for (int i = index; i >= start; i--) {
//       m = list[i];

//       ret = kdjMap[m.timestamp];
//       if (ret == null || ret.dirty) {
//         final minmax = calculateMinmax(start: i, end: i + param.n);
//         if (minmax == null) continue;
//         rsv = (m.close - minmax.min).div(minmax.divisor) * BagNum.hundred;
//         k = (m1k * k + rsv).div(m1Div);
//         d = (m2d * d + k).div(m2Div);
//         j = BagNum.three * k - BagNum.two * d;

//         ret = KdjReset(
//           ts: m.timestamp,
//           k: k,
//           d: d,
//           j: j,
//           dirty: i == 0,
//         );
//         kdjMap[m.timestamp] = ret;
//       }
//     }
//   }

//   MinMax? calculateKdjMinmax({
//     required KDJParam param,
//     int? start,
//     int? end,
//   }) {
//     if (!param.isValid || isEmpty) return null;
//     int len = list.length;
//     start ??= this.start;
//     end ??= this.end;
//     if (start < 0 || end > len) return null;

//     final kdjMap = getKdjMap(param);

//     // 计算从end到len之间n的偏移量
//     int offset = math.max(end + param.n - len, 0);
//     int index = end - offset;

//     if (index < start) return null;
//     if (kdjMap.isEmpty ||
//         kdjMap[list[start].timestamp] == null ||
//         kdjMap[list[index].timestamp] == null) {
//       calculateAndCacheKDJ(param: param, start: start, end: end, reset: true);
//     }

//     MinMax? minmax;
//     KdjReset? ret;
//     for (int i = index; i >= start; i--) {
//       ret = kdjMap[list[i].timestamp];
//       if (ret != null) {
//         minmax ??= ret.minmax;
//         minmax.updateMinMax(ret.minmax);
//       }
//     }
//     return minmax;
//   }
// }
