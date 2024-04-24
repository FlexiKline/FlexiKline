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
import 'package:flutter/material.dart';

import '../constant.dart';
import '../core/export.dart';
import '../framework/export.dart';
import '../model/export.dart';

/// 指数平滑移动平均线
/// 参考: https://zhuanlan.zhihu.com/p/361132689
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
///
/// ⒈首先分别计算出收盘价12日指数平滑移动平均线与26日指数平滑移动平均线，分别记为EMA(12）与EMA(26）。
/// ⒉求这两条指数平滑移动平均线的差，即：DIFF = EMA(SHORT) － EMA(LONG)。
/// ⒊再计算DIFF的M日的平均的指数平滑移动平均线，记为DEA。
/// ⒋最后用DIFF减DEA，得MACD。MACD通常绘制成围绕零轴线波动的柱形图。MACD柱状大于0涨颜色，小于0跌颜色。
class MacdIndicator extends SinglePaintObjectIndicator {
  MacdIndicator({
    super.key = const ValueKey(IndicatorType.macd),
    super.height = defaultSubIndicatorHeight,
    super.tipsHeight = defaultSubIndicatorTipsHeight,
    super.padding = defaultSubIndicatorPadding,
  });

  @override
  SinglePaintObjectBox createPaintObject(KlineBindingBase controller) {
    return MacdPaintObject(controller: controller, indicator: this);
  }
}

class MacdPaintObject extends SinglePaintObjectBox<MacdIndicator> {
  MacdPaintObject({required super.controller, required super.indicator});

  @override
  MinMax? initData({
    required List<CandleModel> list,
    required int start,
    required int end,
  }) {
    return null;
  }

  @override
  void onCross(Canvas canvas, Offset offset) {}

  @override
  void paintChart(Canvas canvas, Size size) {}

  @override
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {}
}
