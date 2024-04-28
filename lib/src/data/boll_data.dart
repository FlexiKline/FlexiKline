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
import 'ma_data.dart';
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

  final Map<int, BOLLResult> _bollResultMap = {};

  BOLLResult? getBollResult(int? ts) {
    return _bollResultMap.getItem(ts);
  }

  /// 计算标准差MD
  /// MD=平方根N日的（C－MA）的两次方之和除以N
  Decimal calculateBollMd({
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
  MinMax? calculateAndCacheBOLL({
    required int n,
    required int std,
    int? start,
    int? end,
  }) {
    if (list.isEmpty) return null;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (len < n || start < 0 || end > len) return null;

    // 计算从end到len之间mid的偏移量
    int offset = math.max(end + n - len, 0);
    int index = end - offset;

    Decimal sum = Decimal.zero;
    // 计算index之前N-1日的收盘价之和.
    for (int i = index + 1; i < index + n; i++) {
      sum += list[i].close;
    }

    Decimal ma;
    Decimal md;
    Decimal up;
    Decimal dn;
    CandleModel m;
    BOLLResult ret;
    MinMax? minmax;
    for (int i = index; i >= start; i--) {
      m = list[i];
      sum += m.close;
      ma = sum.div(n.d);
      md = calculateBollMd(ma: ma, index: i, n: n);
      up = ma + std.d * md;
      dn = ma - std.d * md;
      ret = BOLLResult(ts: m.timestamp, mb: ma, up: up, dn: dn);
      // logd('calculateAndCacheBOLL ret:$ret');
      _bollResultMap[m.timestamp] = ret;

      minmax ??= MinMax(max: up, min: dn);
      minmax.updateMinMax(MinMax(max: up, min: dn));

      sum -= list[i + n - 1].close;
    }

    return minmax;
  }
}
