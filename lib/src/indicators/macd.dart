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
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../constant.dart';
import '../core/export.dart';
import '../data/export.dart';
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
    super.tipsHeight = defaultIndicatorTipsHeight,
    super.padding = defaultIndicatorPadding,
    this.emaShortCount = 12,
    this.emaLongCount = 26,
    this.macdCount = 9,
    this.difColor = const Color(0xFFDFBF47),
    this.deaColor = const Color(0xFF795583),
    this.tickCount,
    this.precision = 2,
  });

  /// Macd相关参数
  final int emaShortCount;
  final int emaLongCount;
  final int macdCount;
  final Color difColor;
  final Color deaColor;

  /// 绘制相关参数
  final int? tickCount;
  final int precision;

  @override
  SinglePaintObjectBox createPaintObject(KlineBindingBase controller) {
    return MacdPaintObject(controller: controller, indicator: this);
  }
}

class MacdPaintObject extends SinglePaintObjectBox<MacdIndicator>
    with PaintYAxisTickMixin, PaintYAxisMarkOnCrossMixin {
  MacdPaintObject({required super.controller, required super.indicator});

  @override
  MinMax? initData({
    required List<CandleModel> list,
    required int start,
    required int end,
  }) {
    final minmax = klineData.calculateAndCacheMACD(
      s: indicator.emaShortCount,
      l: indicator.emaLongCount,
      m: indicator.macdCount,
    );

    return minmax;
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    /// 绘制Y轴刻度值
    paintYAxisTick(
      canvas,
      size,
      tickCount: indicator.tickCount ?? setting.subChartYAxisTickCount,
    );

    paintMacdChart(canvas, size);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    /// onCross时, 绘制Y轴上的标记值
    paintYAxisMarkOnCross(canvas, offset);
  }

  /// 绘制MACD图
  void paintMacdChart(Canvas canvas, Size size) {
    final data = klineData;
    if (data.isEmpty) return;
    int start = data.start;
    int end = (data.end + 1).clamp(start, data.list.length); //多绘制一根蜡烛

    final offset = startCandleDx - candleWidthHalf;
    CandleModel m;
    MacdResult? ret, next;
    final List<Offset> difPoints = [];
    final List<Offset> deaPoints = [];
    double zeroDy = valueToDy(Decimal.zero);
    final candleHalf = candleWidthHalf - setting.candleMargin;
    for (int i = start; i < end; i++) {
      m = data.list[i];
      ret = klineData.getMacdResult(m.timestamp);
      if (ret == null) continue;
      final dx = offset - (i - start) * candleActualWidth;
      difPoints.add(Offset(dx, valueToDy(ret.dif, correct: false)));
      deaPoints.add(Offset(dx, valueToDy(ret.dea, correct: false)));

      next = klineData.getMacdResult(data.list.getItem(i + 1)?.timestamp);

      if (next != null && next.macd < ret.macd) {
        // 空心
        canvas.drawPath(
          Path()
            ..addRect(Rect.fromPoints(
              Offset(dx - candleHalf, zeroDy),
              Offset(dx + candleHalf, valueToDy(ret.macd, correct: false)),
            )),
          ret.macd > Decimal.zero
              ? setting.macdBarLongHollowPaint
              : setting.macdBarShortHollowPaint,
        );
      } else {
        // 实心
        canvas.drawLine(
          Offset(dx, zeroDy),
          Offset(dx, valueToDy(ret.macd, correct: false)),
          ret.macd > Decimal.zero
              ? setting.macdBarLongPaint
              : setting.macdBarShortPaint,
        );
      }
    }

    canvas.drawPath(
      Path()..addPolygon(difPoints, false),
      Paint()
        ..color = indicator.difColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = setting.maLineStrokeWidth,
    );

    canvas.drawPath(
      Path()..addPolygon(deaPoints, false),
      Paint()
        ..color = indicator.deaColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = setting.maLineStrokeWidth,
    );
  }

  @override
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    if (indicator.tipsHeight <= 0) return null;
    model ??= offsetToCandle(offset);
    if (model == null) return null;

    final ret = klineData.getMacdResult(model.timestamp);
    if (ret == null) return null;

    Rect drawRect = nextTipsRect;
    final children = <TextSpan>[];

    final difTxt = formatNumber(
      ret.dif,
      precision: indicator.precision,
      cutInvalidZero: true,
      prefix: 'DIF: ',
      suffix: ' ',
    );
    final deaTxt = formatNumber(
      ret.dea,
      precision: indicator.precision,
      cutInvalidZero: true,
      prefix: 'DEA: ',
      suffix: ' ',
    );
    final macdTxt = formatNumber(
      ret.macd,
      precision: indicator.precision,
      cutInvalidZero: true,
      prefix: 'MACD: ',
      suffix: ' ',
    );

    children.add(TextSpan(
      text: difTxt,
      style: TextStyle(
        fontSize: setting.tipsDefaultTextSize,
        color: indicator.difColor,
        height: setting.tipsDefaultTextHeight,
      ),
    ));

    children.add(TextSpan(
      text: deaTxt,
      style: TextStyle(
        fontSize: setting.tipsDefaultTextSize,
        color: indicator.deaColor,
        height: setting.tipsDefaultTextHeight,
      ),
    ));

    children.add(TextSpan(
      text: macdTxt,
      style: TextStyle(
        fontSize: setting.tipsDefaultTextSize,
        color: setting.tipsDefaultTextColor,
        height: setting.tipsDefaultTextHeight,
      ),
    ));

    return canvas.drawText(
      offset: drawRect.topLeft,
      textSpan: TextSpan(children: children),
      drawDirection: DrawDirection.ltr,
      drawableRect: drawRect,
      textAlign: TextAlign.left,
      padding: setting.tipsRectDefaultPadding,
      maxLines: 1,
    );
  }
}
