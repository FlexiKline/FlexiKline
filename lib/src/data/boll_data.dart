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
import '../framework/indicator.dart';
import '../indicators/boll.dart';
import '../model/export.dart';
import 'base_data.dart';
import 'ma_data.dart';
import 'params.dart';
import 'results.dart';

mixin BOLLData on BaseData, MAData {
  @override
  void initData() {
    super.initData();
    logd('init BOLL');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose BOLL');
    _bollResultMap.clear();
  }

  @override
  void preprocess(
    Indicator indicator, {
    required int start,
    required int end,
    bool reset = false,
  }) {
    super.preprocess(indicator, start: start, end: end, reset: reset);
    if (indicator is BOLLIndicator) {
      logd('preprocess BOLL => ${indicator.calcParam}');
      calculateAndCacheBoll(
        param: indicator.calcParam,
        start: start,
        end: end,
        reset: reset,
      );
    }
  }

  /// boll数据缓存 <timestamp, result>
  final Map<BOLLParam, Map<int, BollResult>> _bollResultMap = {};

  Map<int, BollResult> getBollMap(BOLLParam param) {
    _bollResultMap[param] ??= {};
    return _bollResultMap[param]!;
  }

  BollResult? getBollResult({BOLLParam? param, int? ts}) {
    if (param != null && ts != null) {
      return _bollResultMap[param]?[ts];
    }
    return null;
  }

  /// 计算标准差MD
  /// MD=平方根N日的（C－MA）的两次方之和除以N
  Decimal _calculateBollMd({
    required Decimal ma,
    required int index,
    required int n,
  }) {
    final start = math.min(index, list.length);
    final end = math.min(index + n, list.length);
    Decimal sum = Decimal.zero;
    Decimal closeMa;
    for (int i = start; i < end; i++) {
      closeMa = list[i].close - ma;
      sum += closeMa * closeMa;
    }
    n = end - start;
    return math.sqrt(sum.toDouble() / n).d;
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
  MinMax? calculateAndCacheBoll({
    required BOLLParam param,
    int? start,
    int? end,
    bool reset = false,
  }) {
    if (!param.isValid || list.isEmpty) return null;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (start < 0 || end > len) return null;

    // 获取count对应的Emap数据结果
    final bollMap = getBollMap(param);
    if (reset) {
      bollMap.clear();
    }

    // 计算从end到len之间mid的偏移量
    int offset = math.max(end + param.n - len, 0);
    int index = end - offset;

    Decimal sum = Decimal.zero;
    // 计算index之前N-1日的收盘价之和.
    for (int i = index + 1; i < index + param.n; i++) {
      sum += list[i].close;
    }

    Decimal ma;
    Decimal md;
    Decimal up;
    Decimal dn;
    CandleModel m;
    BollResult? ret;
    MinMax? minmax;
    final stdD = Decimal.fromInt(param.std);
    for (int i = index; i >= start; i--) {
      m = list[i];
      sum += m.close;

      ret = bollMap[m.timestamp];
      if (ret == null || ret.dirty) {
        ma = sum.div(param.n.d);
        md = _calculateBollMd(ma: ma, index: i, n: param.n);
        up = ma + stdD * md;
        dn = ma - stdD * md;
        ret = BollResult(
          ts: m.timestamp,
          mb: ma,
          up: up,
          dn: dn,
          dirty: i == 0,
        );
        // logd('calculateAndCacheBOLL ret:$ret');
        bollMap[m.timestamp] = ret;
      }

      minmax ??= MinMax(max: ret.up, min: ret.dn);
      minmax.updateMinMax(MinMax(max: ret.up, min: ret.dn));

      sum -= list[i + param.n - 1].close;
    }

    return minmax;
  }
}
