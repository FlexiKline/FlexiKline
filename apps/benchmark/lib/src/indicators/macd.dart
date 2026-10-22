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

import 'package:flexi_formatter/flexi_formatter.dart' show formatPrice;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';

typedef MacdParam = ({int short, int long, int signal});

/// 副区 MACD(12, 26, 9)。
///
/// 计算与绘制对标 `flexi_kline_indicators` 的 `MACDIndicator`（首值种子、每次全量计算、涨空心 / 跌实心柱、
/// Y 轴刻度与十字线刻度、`MACD(12,26,9) MACD DIF DEA` tips），配置最小化：只保留高度、边距、参数与颜色，
/// 不做序列化与 copyWith。
class BenchMacdIndicator extends ComputedIndicator {
  BenchMacdIndicator({
    super.height = defaultSubIndicatorHeight,
    super.padding = defaultSubIndicatorPadding,
    this.calcParam = const (short: 12, long: 26, signal: 9),
    this.difColor = const Color(0xFFF15866),
    this.deaColor = const Color(0xFF326AD5),
    this.macdColor = const Color(0xFFF4BE4E),
  }) : super(key: const ComputedIndicatorKey('bench_macd'));

  @override
  final MacdParam calcParam;
  final Color difColor;
  final Color deaColor;
  final Color macdColor;

  @override
  IndicatorCalculator createCalculator(int dataIndex) => _BenchMacdCalculator(this, dataIndex);

  @override
  ComputedPaintObject<ComputedIndicator> createPaintObject() => _BenchMacdPaintObject();
}

/// 一根蜡烛上的 MACD 结果, 整体存进该指标的 computed slot。
class BenchMacdResult {
  const BenchMacdResult({
    required this.dif,
    required this.dea,
    required this.macd,
    required this.emaShort,
    required this.emaLong,
  });

  final FlexiNum emaShort;
  final FlexiNum emaLong;
  final FlexiNum dif;
  final FlexiNum dea;
  final FlexiNum macd;

  MinMax get minmax => MinMax.getMinMaxByList([dif, dea, macd])!;
}

/// 快慢两条 EMA 都以最旧一根的收盘价起步, DEA 的首值等于 DIF 的首值(恒为 0); 柱 = (DIF − DEA) × 2。
/// 每次全量计算, 不看 [Range]。
class _BenchMacdCalculator extends IndicatorCalculator<BenchMacdIndicator> {
  _BenchMacdCalculator(super.indicator, super.dataIndex);

  @override
  void compute(KlineData data, Range range, {bool reset = false}) {
    if (reset) {
      for (final model in data.list) {
        model.clean(dataIndex);
      }
    }
    final len = data.length;
    if (len <= 0) return;

    final s = indicator.calcParam.short, l = indicator.calcParam.long, m = indicator.calcParam.signal;
    final oldest = len - 1;
    FlexiNum emaS = data[oldest].close, emaL = emaS;
    // 首值由数据算出, 不用 FlexiNum.zero: 常量作左操作数会让 accurate 模式退化为 double。
    FlexiNum dif = emaS - emaL, dea = dif;
    data[oldest].set(
      dataIndex,
      BenchMacdResult(
        dif: dif,
        dea: dea,
        macd: (dif - dea).mulNum(2),
        emaShort: emaS,
        emaLong: emaL,
      ),
    );

    for (int i = oldest - 1; i >= 0; i--) {
      final model = data[i];
      final close2 = model.close.mulNum(2);
      // 递推状态每步 clampScale: 除数只含因子 2、5 时 divNum 的商是精确的, scale 会逐根增长直到溢出为 NaN。
      emaS = (close2 + emaS.mulNum(s - 1)).divNum(s + 1).clampScale();
      emaL = (close2 + emaL.mulNum(l - 1)).divNum(l + 1).clampScale();
      dif = emaS - emaL;
      dea = (dif.mulNum(2) + dea.mulNum(m - 1)).divNum(m + 1).clampScale();
      model.set(
        dataIndex,
        BenchMacdResult(
          dif: dif,
          dea: dea,
          macd: (dif - dea).mulNum(2),
          emaShort: emaS,
          emaLong: emaL,
        ),
      );
    }
  }
}

class _BenchMacdPaintObject extends ComputedPaintObject<BenchMacdIndicator>
    with PaintGridTicksMixin, PaintYAxisTicksOnCrossMixin {
  final Paint _barPaint = Paint()..style = PaintingStyle.stroke;

  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    if (klineData.length <= 0) return null;
    MinMax? minmax;
    for (int i = end - 1; i >= start; i--) {
      final ret = klineData[i].get<BenchMacdResult>(dataIndex);
      if (ret == null) continue;
      final itemMinmax = ret.minmax;
      minmax ??= itemMinmax;
      minmax.updateMinMax(itemMinmax);
    }
    return minmax;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintMacdChart(canvas);

    if (settingConfig.showYAxisTick) {
      paintYAxisTicks(
        canvas,
        dys: tickPositions(
          defaultSubTickCount,
          start: chartRect.top,
          length: chartRect.height,
        ),
        precision: klineData.precision,
      );
    }
  }

  @override
  void paintCross(Canvas canvas, Offset offset, {FlexiCandleModel? model}) {
    paintYAxisTicksOnCross(canvas, offset, precision: klineData.precision);
  }

  void _paintMacdChart(Canvas canvas) {
    final int start = klineData.start;
    final int end = (klineData.end + 1).clamp(start, klineData.length); // 多绘制一根蜡烛

    final List<Offset> difPoints = [];
    final List<Offset> deaPoints = [];
    final double zeroDy = valueToDy(FlexiNum.zero);
    final offset = startCandleDx - candleWidthHalf;
    final hollowHalf = candleWidthHalf - candleSpacing;

    BenchMacdResult? ret;
    BenchMacdResult? next;
    for (int i = start; i < end; i++) {
      ret = klineData[i].get(dataIndex);
      if (ret == null) continue;
      final dx = offset - (i - start) * candleActualWidth;
      difPoints.add(Offset(dx, valueToDy(ret.dif, correct: false)));
      deaPoints.add(Offset(dx, valueToDy(ret.dea, correct: false)));

      next = klineData.get(i + 1)?.get(dataIndex);
      final isLong = ret.macd.signum >= 0; // 0 归涨色
      if (next != null && ret.macd > next.macd) {
        // 空心
        canvas.drawPath(
          Path()..addRect(
            Rect.fromPoints(
              Offset(dx - hollowHalf, zeroDy),
              Offset(dx + hollowHalf, valueToDy(ret.macd, correct: false)),
            ),
          ),
          isLong ? defLongHollowBarPaint : defShortHollowBarPaint,
        );
      } else {
        // 实心
        canvas.drawLine(
          Offset(dx, zeroDy),
          Offset(dx, valueToDy(ret.macd)),
          _barPaint
            ..color = isLong ? longColor : shortColor
            ..strokeWidth = candleWidth,
        );
      }
    }

    _drawLine(canvas, difPoints, indicator.difColor);
    _drawLine(canvas, deaPoints, indicator.deaColor);
  }

  void _drawLine(Canvas canvas, List<Offset> points, Color color) {
    if (points.isEmpty) return;
    canvas.drawPath(
      Path()..addPolygon(points, false),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = defaultIndicatorLineWidth,
    );
  }

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) {
    model ??= offsetToCandle(offset);
    if (model == null) return null;
    // 只要十字线落在K线上就画参数头; 没有结果时各线显示 `--`。
    final macd = model.get<BenchMacdResult>(dataIndex);
    final precision = klineData.precision;

    TextSpan item(String label, FlexiNum? value, Color color) => TextSpan(
      text: formatPrice(
        value?.toDecimal(),
        precision: precision,
        prefix: '$label:$nbsp',
        suffix: ' ',
      ),
      style: TextStyle(fontSize: defaultTextSize, height: defaultTextHeight, color: color),
    );

    final s = indicator.calcParam.short, l = indicator.calcParam.long, m = indicator.calcParam.signal;
    final children = <TextSpan>[
      TextSpan(
        text: 'MACD($s,$l,$m)$nbsp',
        style: TextStyle(fontSize: defaultTextSize, height: defaultTextHeight, color: theme.ticksTextColor),
      ),
      item('MACD', macd?.macd, indicator.macdColor),
      item('DIF', macd?.dif, indicator.difColor),
      item('DEA', macd?.dea, indicator.deaColor),
    ];

    tipsRect ??= drawableRect;
    return canvas.drawText(
      offset: tipsRect.topLeft,
      textSpan: TextSpan(children: children),
      drawDirection: DrawDirection.ltr,
      drawableRect: tipsRect,
      textAlign: TextAlign.start,
      padding: defaultTipsPadding,
    );
  }
}
