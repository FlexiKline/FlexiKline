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

import 'dart:ui';

import 'package:decimal/decimal.dart';

import '../constant.dart';
import '../core/export.dart';
import '../framework/export.dart';
import '../model/export.dart';

/// 指数平滑移动平均线
/// MACD由长线均线DEA，短期的线DIF，绿色能量柱（多头），红色能量柱（空头），O轴（多空分界线）五部分组成。
/// 它是利用短期均线DIF与长期线DEA交叉作为信号。DIF是核心，DEA是辅助，其作用首先是发现股市的投资机会，其次则是保护股市中的投资收益不受损失。
/// 默认参数值12、26、9。
/// 公式：
/// ⒈首先分别计算出收盘价12日指数平滑移动平均线与26日指数平滑移动平均线，分别记为EMA(12）与EMA(26）。
/// ⒉求这两条指数平滑移动平均线的差，即：DIFF = EMA(SHORT) － EMA(LONG)。
/// ⒊再计算DIFF的M日的平均的指数平滑移动平均线，记为DEA。
/// ⒋最后用DIFF减DEA，得MACD。MACD通常绘制成围绕零轴线波动的柱形图。MACD柱状大于0涨颜色，小于0跌颜色。
class MacdIndicator extends PaintObjectIndicator {
  MacdIndicator({
    required super.key,
    super.height = defaultSubIndicatorHeight,
    super.tipsHeight = defaultSubIndicatorTipsHeight,
    super.padding = defaultSubIndicatorPadding,
  });

  @override
  PaintObject createPaintObject(KlineBindingBase controller) {
    return MacdPaintObject(controller: controller, indicator: this);
  }
}

class MacdPaintObject extends PaintObjectBox<MacdIndicator> {
  MacdPaintObject({required super.controller, required super.indicator});

  @override
  void initData(List<CandleModel> list, {int start = 0, int end = 0}) {}

  @override
  Decimal get maxVal => throw UnimplementedError();

  @override
  Decimal get minVal => throw UnimplementedError();

  @override
  void onCross(Canvas canvas, Offset offset) {}

  @override
  void paintChart(Canvas canvas, Size size) {}
}
