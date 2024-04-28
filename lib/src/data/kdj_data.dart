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
import '../model/export.dart';
import 'base_data.dart';
import 'candle_data.dart';
import 'results.dart';

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
    _kdjResultMap.clear();
  }

  final Map<int, KDJReset> _kdjResultMap = {};

  KDJReset? getKdjResult(int? ts) {
    return _kdjResultMap.getItem(ts);
  }

  /// 首先要计算周期（n日、n周等）的RSV值（即未成熟随机指标值），然后再计算K值、D值、J值等。
  /// 以日KDJ数值的计算为例，其计算公式为：n日RSV=（Cn－Ln）÷（Hn－Ln）×100
  /// 公式中，Cn为第n日收盘价；Ln为n日内的最低价；Hn为n日内的最高价。RSV值始终在1—100间波动。
  /// 其次，计算K值与D值：当日K值=2/3×前一日K值＋1/3×当日RSV
  /// 当日D值=2/3×前一日D值＋1/3×当日K值
  /// 若无前一日K 值与D值，则可分别用50（1-100的中间值）来代替。
  /// J值=3*当日K值-2*当日D值
  /// 以9日为周期的KD线为例。首先须计算出最近9日的RSV值，即未成熟随机值，计算公式为 9日RSV=（C－L9）÷（H9－L9）×100
  /// 公式中，C为第9日的收盘价；L9为9日内的最低价；H9为9日内的最高价。
  /// K值=2/3×第8日K值＋1/3×第9日RSV
  /// D值=2/3×第8日D值＋1/3×第9日K值
  /// J值=3*第9日K值-2*第9日D值
  /// 若无前一日K值与D值，则可以分别用50代替。
  MinMax? calculateAndCacheKDJ({
    required int n,
    required int m1,
    required int m2,
  }) {
    if (list.isEmpty) return null;
    int len = list.length;
    if (len < n || start < 0 || end > len) return null;

    MinMax? minmaxRet;
    KDJReset kdjRet;
    Decimal rsv;
    CandleModel m;
    Decimal k = fifty;
    final m1k = Decimal.fromInt(m1 - 1);
    final m1Div = Decimal.fromInt(m1);
    Decimal d = fifty;
    final m2d = Decimal.fromInt(m2 - 1);
    final m2Div = Decimal.fromInt(m2);
    Decimal j;
    // 计算KDJ
    for (int i = end; i >= start; i--) {
      final minmax = calculateMaxmin(start: i, end: i + n);
      if (minmax == null) continue;
      m = list[i];
      rsv = (m.close - minmax.min).div(minmax.divisor) * hundred;
      k = (m1k * k + rsv).div(m1Div);
      d = (m2d * d + k).div(m2Div);
      j = three * k - two * d;

      kdjRet = KDJReset(ts: m.timestamp, k: k, d: d, j: j);
      _kdjResultMap[m.timestamp] = kdjRet;
      minmaxRet ??= kdjRet.minmax;
      minmaxRet.updateMinMax(kdjRet.minmax);
    }
    return minmaxRet;
  }
}
