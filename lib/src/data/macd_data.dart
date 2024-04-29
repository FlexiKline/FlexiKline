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
import 'results.dart';

mixin MACDData on BaseData {
  @override
  void initData() {
    super.initData();
    logd('init MACD');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose MACD');
    _macdResultMap.clear();
  }

  /// MACD数据缓存 <timestamp, MacdResult>
  final Map<int, MacdResult> _macdResultMap = {};

  MacdResult? getMacdResult(int? ts) {
    return _macdResultMap.getItem(ts);
  }

  MinMax? calculateMacdMinMax() {
    final len = list.length;
    if (start < 0 && end > len) return null;
    MinMax? minMax;
    MacdResult? ret;
    for (int i = end - 1; i >= start; i--) {
      ret = _macdResultMap[list[i].timestamp];
      if (ret != null) {
        minMax ??= ret.minmax;
        minMax.updateMinMax(ret.minmax);
      }
    }
    return minMax;
  }

  MinMax? calculateAndCacheMACD({
    required int s,
    required int l,
    required int m,
  }) {
    if (list.isEmpty) return null;
    final len = list.length;
    if (start < 0 || end > len || len < l + m) return null;

    /// 校验是否已有缓存好的数据.如有不需要计算.
    if (_macdResultMap.length >= len - l - m) {
      return calculateMacdMinMax();
    }
    // 清理缓存重头计算
    _macdResultMap.clear();

    final sPre = Decimal.fromInt(s - 1);
    final sNext = Decimal.fromInt(s + 1);
    final lPre = Decimal.fromInt(l - 1);
    final lNext = Decimal.fromInt(l + 1);
    final mPre = Decimal.fromInt(m - 1);
    final mNext = Decimal.fromInt(m + 1);

    CandleModel model;
    Decimal emaShort = Decimal.zero;
    Decimal emaLong = Decimal.zero;
    Decimal dif;
    Decimal dea = Decimal.zero;
    Decimal macd;

    MinMax? minmax;
    int count = 0;
    Decimal closeSum = Decimal.zero;
    Decimal difSum = Decimal.zero;
    MacdResult ret;
    for (int i = len - 1; i >= 0; i--) {
      model = list[i];
      closeSum += model.close;
      count++;
      if (count >= s) {
        if (count > s) {
          emaShort = ((two * model.close) + emaShort * sPre).div(sNext);
        } else {
          emaShort = closeSum.div(s.d);
        }
      }

      if (count >= l) {
        if (count > l) {
          emaLong = ((two * model.close) + emaLong * lPre).div(lNext);
        } else {
          emaLong = closeSum.div(l.d);
        }
      }

      if (count > l) {
        dif = emaShort - emaLong;
        difSum += dif;
        if (count >= l + m) {
          if (count > l + m) {
            dea = ((two * dif) + dea * mPre).div(mNext);
          } else {
            dea = difSum.div(m.d);
          }

          macd = (dif - dea) * two;
          ret = MacdResult(
            ts: model.timestamp,
            dif: dif,
            dea: dea,
            macd: macd,
            emaShort: emaShort,
            emaLong: emaLong,
          );
          minmax ??= ret.minmax;
          minmax.updateMinMax(ret.minmax);
          _macdResultMap[model.timestamp] = ret;
          // logi(
          //   'calculateAndCacheMACD emaShort:${emaShort.str}, emaLong:${emaLong.str} macd:$ret',
          // );
          // logi('calculateAndCacheMACD minmax:$minmax');
        }
      }
    }

    return minmax;
  }
}
