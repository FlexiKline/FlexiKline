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

import '../config/boll_param/boll_param.dart';
import '../framework/export.dart';
import '../model/export.dart';
import 'base_data.dart';

mixin BOLLData on BaseData {
  @override
  void initData() {
    super.initData();
    logd('init BOLL');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose BOLL');
    for (var model in list) {
      model.cleanBoll();
    }
  }

  @override
  void precompute(
    ValueKey key, {
    dynamic calcParam,
    required Range range,
    bool reset = false,
  }) {
    if ((key == bollKey || key == subBollKey) && calcParam is BOLLParam) {
      calcuAndCacheBoll(
        param: calcParam,
        start: math.max(0, range.start - calcParam.n), // 补起上一次未算数据
        end: range.end,
        reset: reset,
      );
      return;
    }
    super.precompute(key, calcParam: calcParam, range: range, reset: reset);
  }

  /// 计算标准差MD
  /// MD=平方根N日的（C－MA）的两次方之和除以N
  BagNum _calculateBollMd({
    required BagNum ma,
    required int index,
    required int n,
  }) {
    final start = math.min(index, list.length);
    final end = math.min(index + n, list.length);
    BagNum sum = BagNum.zero;
    BagNum closeMa;
    for (int i = start; i < end; i++) {
      closeMa = list[i].close - ma;
      sum += closeMa * closeMa;
    }
    n = end - start;
    return math.sqrt(sum.toDouble() / n).toBagNum();
  }

  /// 中轨线=N日的移动平均线
  /// 上轨线=中轨线＋两倍的标准差
  /// 下轨线=中轨线－两倍的标准差
  /// 1）计算MA
  ///   MA=N日内的收盘价之和÷N
  /// 2）计算标准差MD
  ///   MD=平方根N日的（C－MA）的两次方之和除以N
  /// 3）计算MB、UP、DN线
  ///   MB=（N－1）日的MA
  ///   UP=MB＋2×MD
  ///   DN=MB－2×MD
  void calcuAndCacheBoll({
    required BOLLParam param,
    int? start,
    int? end,
    bool reset = false,
  }) {
    final len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (!param.isValid(len) || !checkStartAndEnd(start, end)) return;
    logd('calcuAndCacheBoll [end:$end ~ start:$start] param:$param');

    // 计算从end到len之间mid的偏移量
    end = math.min(len - param.n, end - 1);

    BagNum sum = BagNum.zero;
    // 计算index之前N-1日的收盘价之和.
    for (int i = end + 1; i < end + param.n; i++) {
      sum += list[i].close;
    }

    BagNum ma;
    BagNum md;
    CandleModel m;
    final std = BagNum.fromInt(param.std);
    for (int i = end; i >= start; i--) {
      m = list[i];
      sum += m.close;

      // 1. 计算N日MA
      m.mb = ma = sum.divNum(param.n);
      // 2. 计算标准差MD
      md = _calculateBollMd(ma: ma, index: i, n: param.n);
      // 3. 计算MB、UP、DN线
      m.up = ma + std * md;
      m.dn = ma - std * md;

      sum -= list[i + param.n - 1].close;
    }
  }

  MinMax? calcuBollMinmax({
    required BOLLParam param,
    int? start,
    int? end,
  }) {
    final len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (!param.isValid(len) || !checkStartAndEnd(start, end)) return null;

    end = math.min(len - param.n, end - 1);

    if (end < start) return null;
    if (!list[end].isValidBollData) {
      calcuAndCacheBoll(param: param, start: 0, end: len);
    }

    MinMax? minmax;
    CandleModel m;
    for (int i = end; i >= start; i--) {
      m = list[i];
      minmax ??= m.bollMinmax;
      minmax?.updateMinMax(m.bollMinmax);
    }
    return minmax;
  }
}

// @Deprecated('废弃的')
// mixin BOLLData2 on BaseData, MAData {
//   @override
//   void initData() {
//     super.initData();
//     logd('init BOLL');
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     logd('dispose BOLL');
//     _bollResultMap.clear();
//   }

//   @override
//   void preprocess(
//     Indicator indicator, {
//     required int start,
//     required int end,
//     bool reset = false,
//   }) {
//     if (indicator is BOLLIndicator) {
//       calculateAndCacheBoll(
//         param: indicator.calcParam,
//         start: start,
//         end: end,
//         reset: reset,
//       );
//     } else {
//       super.preprocess(indicator, start: start, end: end, reset: reset);
//     }
//   }

//   /// boll数据缓存 <timestamp, result>
//   final Map<BOLLParam, Map<int, BollResult>> _bollResultMap = {};

//   Map<int, BollResult> getBollMap(BOLLParam param) {
//     _bollResultMap[param] ??= {};
//     return _bollResultMap[param]!;
//   }

//   BollResult? getBollResult({BOLLParam? param, int? ts}) {
//     if (param != null && ts != null) {
//       return _bollResultMap[param]?[ts];
//     }
//     return null;
//   }

//   /// 计算标准差MD
//   /// MD=平方根N日的（C－MA）的两次方之和除以N
//   BagNum _calculateBollMd({
//     required BagNum ma,
//     required int index,
//     required int n,
//   }) {
//     final start = math.min(index, list.length);
//     final end = math.min(index + n, list.length);
//     BagNum sum = BagNum.zero;
//     BagNum closeMa;
//     for (int i = start; i < end; i++) {
//       closeMa = list[i].close - ma;
//       sum += closeMa * closeMa;
//     }
//     n = end - start;
//     return math.sqrt(sum.toDouble() / n).toBagNum();
//   }

//   /// 中轨线=N日的移动平均线
//   /// 上轨线=中轨线＋两倍的标准差
//   /// 下轨线=中轨线－两倍的标准差
//   /// 1）计算MA
//   ///   MA=N日内的收盘价之和÷N
//   /// 2）计算标准差MD
//   ///   MD=平方根N日的（C－MA）的两次方之和除以N
//   /// 3）计算MB、UP、DN线
//   ///   MB=（N－1）日的MA
//   ///   UP=MB＋2×MD
//   ///   DN=MB－2×MD
//   void calculateAndCacheBoll({
//     required BOLLParam param,
//     int? start,
//     int? end,
//     bool reset = false,
//   }) {
//     if (!param.isValid || list.isEmpty) return;
//     int len = list.length;
//     start ??= this.start;
//     end ??= this.end;
//     if (start < 0 || end > len) return;

//     // 获取count对应的Emap数据结果
//     final bollMap = getBollMap(param);
//     if (reset) {
//       bollMap.clear();
//     }

//     // 计算从end到len之间mid的偏移量
//     int offset = math.max(end + param.n - len, 0);
//     int index = end - offset;

//     BagNum sum = BagNum.zero;
//     // 计算index之前N-1日的收盘价之和.
//     for (int i = index + 1; i < index + param.n; i++) {
//       sum += list[i].close;
//     }

//     BagNum ma;
//     BagNum md;
//     BagNum up;
//     BagNum dn;
//     CandleModel m;
//     BollResult? ret;
//     final stdD = BagNum.fromInt(param.std);
//     for (int i = index; i >= start; i--) {
//       m = list[i];
//       sum += m.close;

//       ret = bollMap[m.timestamp];
//       if (ret == null || ret.dirty) {
//         ma = sum.divNum(param.n);
//         md = _calculateBollMd(ma: ma, index: i, n: param.n);
//         up = ma + stdD * md;
//         dn = ma - stdD * md;
//         ret = BollResult(
//           ts: m.timestamp,
//           mb: ma,
//           up: up,
//           dn: dn,
//           dirty: i == 0,
//         );
//         // logd('calculateAndCacheBOLL ret:$ret');
//         bollMap[m.timestamp] = ret;
//       }
//       sum -= list[i + param.n - 1].close;
//     }
//   }

//   MinMax? calculateBollMinmax({
//     required BOLLParam param,
//     int? start,
//     int? end,
//   }) {
//     if (!param.isValid || list.isEmpty) return null;
//     int len = list.length;
//     start ??= this.start;
//     end ??= this.end;
//     if (start < 0 || end > len) return null;

//     // 获取count对应的Emap数据结果
//     final bollMap = getBollMap(param);

//     int offset = math.max(end + param.n - len, 0);
//     int index = end - offset;

//     if (index < start) return null;
//     if (bollMap.isEmpty ||
//         bollMap[list[start].timestamp] == null ||
//         bollMap[list[index].timestamp] == null) {
//       calculateAndCacheBoll(param: param, start: start, end: end, reset: true);
//     }

//     MinMax? minmax;
//     BollResult? ret;
//     for (int i = index; i >= start; i--) {
//       ret = bollMap[list[i].timestamp];
//       if (ret != null) {
//         minmax ??= MinMax(max: ret.up, min: ret.dn);
//         minmax.updateMinMax(MinMax(max: ret.up, min: ret.dn));
//       }
//     }
//     return minmax;
//   }
// }
