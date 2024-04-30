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
import '../indicators/macd.dart';
import '../model/export.dart';
import 'base_data.dart';
import 'params.dart';
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

  @override
  void preprocess(
    Indicator indicator, {
    required int start,
    required int end,
    bool reset = false,
  }) {
    super.preprocess(indicator, start: start, end: end, reset: reset);
    if (indicator is MacdIndicator) {
      logd('preprocess MACD => ${indicator.calcParam}');
      calculateMacd(indicator.calcParam);
    }
  }

  /// MACD数据缓存 <timestamp, MacdResult>
  final Map<MACDParam, Map<int, MacdResult>> _macdResultMap = {};

  Map<int, MacdResult> getMacdMap(MACDParam param) {
    _macdResultMap[param] ??= {};
    return _macdResultMap[param]!;
  }

  MacdResult? getMacdResult({MACDParam? param, int? ts}) {
    if (param != null && ts != null) {
      return _macdResultMap[param]?[ts];
    }
    return null;
  }

  /// 指数平滑移动平均线MACD
  /// 由于当日EMA计算依赖于昨日EMA, 所以数据从最后开始计算, 并缓存,
  ///
  /// MACD由长线均线DEA，短期的线DIF，绿色能量柱（多头），红色能量柱（空头），O轴（多空分界线）五部分组成。
  /// 它是利用短期均线DIF与长期线DEA交叉作为信号。DIF是核心，DEA是辅助，其作用首先是发现股市的投资机会，其次则是保护股市中的投资收益不受损失。
  /// DIF—— 离差值，是快速移动平均线与慢速移动平均线的差
  /// DEA—— 异同平均数，其本质是DIF的移动平均线指。
  /// EMA—— 平滑移动平均线
  /// 默认参数值12、26、9。
  /// 公式：
  /// 1）快速平滑移动平均线（EMA）是12日的，计算公式为：
  ///   EMA(12)=2*今收盘价/(12+1)+11*昨日EMA(12)/(12+1)
  /// 2）慢速平滑移动平均线（EMA）是26日的，计算公式为：
  ///   EMA(26)=2*今收盘价/(26+1)+25*昨日EMA(26)/(26+1)
  /// 3）计算MACD指标
  ///   DIF=EMA(12)-EMA(26)
  ///   今日DEA(MACD)=2/(9+1)*今日DIF+8/(9+1)*昨日DEA
  ///
  /// MACD指标中的柱状线（BAR）的计算公式为：
  ///   BAR=2*(DIF-DEA)
  void calculateMacd(MACDParam param) {
    if (!param.isValid || !canPaintChart) return;
    final len = list.length;
    if (len < param.l) return;

    // 清空param对应的缓存, 重头计算.
    Map<int, MacdResult> macdMap = getMacdMap(param);
    if (macdMap.isNotEmpty) macdMap.clear();

    final sPre = Decimal.fromInt(param.s - 1);
    final sNext = Decimal.fromInt(param.s + 1);
    final lPre = Decimal.fromInt(param.l - 1);
    final lNext = Decimal.fromInt(param.l + 1);
    final mPre = Decimal.fromInt(param.m - 1);
    final mNext = Decimal.fromInt(param.m + 1);

    CandleModel model;
    Decimal emaShort = Decimal.zero;
    Decimal emaLong = Decimal.zero;
    Decimal dif;
    Decimal dea = Decimal.zero;
    Decimal macd;

    int count = 0;
    Decimal closeSum = Decimal.zero;
    Decimal difSum = Decimal.zero;
    MacdResult ret;
    for (int i = len - 1; i >= 0; i--) {
      model = list[i];
      closeSum += model.close;
      count++;
      if (count >= param.s) {
        if (count > param.s) {
          emaShort = ((two * model.close) + emaShort * sPre).div(sNext);
        } else {
          emaShort = closeSum.div(param.s.d);
        }
      }

      if (count >= param.l) {
        if (count > param.l) {
          emaLong = ((two * model.close) + emaLong * lPre).div(lNext);
        } else {
          emaLong = closeSum.div(param.l.d);
        }
      }

      if (count > param.l) {
        dif = emaShort - emaLong;
        difSum += dif;
        if (count >= param.l + param.m) {
          if (count > param.l + param.m) {
            dea = ((two * dif) + dea * mPre).div(mNext);
          } else {
            dea = difSum.div(param.m.d);
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
          macdMap[model.timestamp] = ret;
          // logi(
          //   'calculateAndCacheMACD emaShort:${emaShort.str}, emaLong:${emaLong.str} macd:$ret',
          // );
        }
      }
    }
  }

  MinMax? calculateMacdMinmax({
    required MACDParam param,
    int? start,
    int? end,
  }) {
    if (!param.isValid || isEmpty) return null;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (start < 0 || end > len) return null;

    final macdMap = getMacdMap(param);

    if (macdMap.length < len - param.paramCount + 1) {
      calculateMacd(param);
    }

    MinMax? minmax;
    MacdResult? data;
    for (int i = end - 1; i >= start; i--) {
      data = macdMap[list[i].timestamp];
      if (data != null) {
        minmax ??= data.minmax;
        minmax.updateMinMax(data.minmax);
      }
    }
    return minmax;
  }
}
