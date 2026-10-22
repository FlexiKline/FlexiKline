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

import 'package:flexi_formatter/flexi_formatter.dart' show RoundMode, formatAmount;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';

typedef VolMaParam = ({int count, Color color});

/// 副区 VOLMA: 量柱 + 5 / 10 均量线。
///
/// 计算与绘制对标 `flexi_kline_indicators` 的 `VolMaIndicator`（Y 轴刻度与十字线刻度按成交量格式化、
/// 量柱与均线半透明、tips 为 `Vol MA5 MA10`），配置最小化：只保留高度、边距、均线参数（周期与颜色）、
/// 精度、透明度与 tips 样式，不做序列化与 copyWith。
class BenchVolMaIndicator extends ComputedIndicator {
  BenchVolMaIndicator({
    super.height = defaultSubIndicatorHeight,
    super.padding = defaultSubIndicatorPadding,
    this.calcParam = const [
      (count: 5, color: Color(0xFFE278E9)),
      (count: 10, color: Color(0xFF71B5F3)),
    ],
    this.precision = 4,
    this.volOpacity = 0.5,
    this.lineOpacity = 0.5,
    this.tipsStyle = const TextStyle(
      fontSize: defaultTextSize,
      overflow: TextOverflow.ellipsis,
      height: defaultTextHeight,
    ),
  }) : super(key: const ComputedIndicatorKey('bench_vol_ma'));

  @override
  final List<VolMaParam> calcParam;
  final int precision;
  final double volOpacity;
  final double lineOpacity;
  final TextStyle tipsStyle;

  @override
  ComputedPaintObject<ComputedIndicator> createPaintObject() => _BenchVolMaPaintObject();

  @override
  IndicatorCalculator createCalculator(int dataIndex) => _BenchVolMaCalculator(this, dataIndex);
}

class _BenchVolMaCalculator extends IndicatorCalculator<BenchVolMaIndicator> {
  _BenchVolMaCalculator(super.indicator, super.dataIndex);

  @override
  void compute(KlineData data, Range range, {bool reset = false}) {
    final params = indicator.calcParam;
    if (data.isEmpty || params.isEmpty) return;
    if (reset) {
      range = data.computableRange;
      for (int i = range.start; i < range.end; i++) {
        data.list[i].clean(dataIndex);
      }
    }
    for (int i = 0; i < params.length; i++) {
      // 周期非正的线不写值, tips 显示 `--`; 否则 sum.divNum(count) 会除以 0。
      if (params[i].count <= 0) continue;
      _calculateVolMa(
        data,
        params[i].count,
        paramIndex: i,
        paramLen: params.length,
        start: math.max(0, range.start - params[i].count), // 补起上一次未算数据
        end: range.end,
      );
    }
  }

  /// 计算 [count] 周期均量, 写入 [start, end) 区间。
  void _calculateVolMa(
    KlineData data,
    int count, {
    required int paramIndex,
    required int paramLen,
    required int start,
    required int end,
  }) {
    final len = data.list.length;
    if (count > len || !data.checkStartAndEnd(start, end)) return;

    end = math.min(len - count, end - 1);

    FlexiCandleModel m = data.list[end];
    FlexiNum sum = m.vol;
    for (int i = end + 1; i < end + count; i++) {
      sum += data.list[i].vol;
    }
    m.getOrInitList(dataIndex, paramLen)[paramIndex] = sum.divNum(count);

    for (int i = end - 1; i >= start; i--) {
      m = data.list[i];
      sum = sum - data.list[i + count].vol + m.vol;
      m.getOrInitList(dataIndex, paramLen)[paramIndex] = sum.divNum(count);
    }
  }
}

class _BenchVolMaPaintObject extends ComputedPaintObject<BenchVolMaIndicator>
    with PaintGridTicksMixin, PaintYAxisTicksOnCrossMixin {
  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    FlexiCandleModel model = klineData.list[end - 1];
    FlexiNum minVol = model.vol;
    FlexiNum maxVol = model.vol;
    for (int i = end - 2; i >= start; i--) {
      model = klineData.list[i];
      maxVol = model.vol > maxVol ? model.vol : maxVol;
      minVol = model.vol < minVol ? model.vol : minVol;
    }
    final volMinmax = MinMax(max: maxVol, min: minVol);

    MinMax? maMinmax;
    final params = indicator.calcParam;
    final len = klineData.length;
    // 任一周期长于数据时均线整体不出值(与计算器一致)。
    if (params.isNotEmpty && params.every((p) => p.count <= len)) {
      final minCount = params.map((p) => p.count).reduce(math.min);
      final maEnd = math.min(len - minCount, end - 1);
      for (int i = maEnd; i >= start; i--) {
        final itemMinmax = klineData.list[i].getList<FlexiNum>(dataIndex)?.minmax;
        maMinmax ??= itemMinmax;
        maMinmax?.updateMinMax(itemMinmax);
      }
    }

    return volMinmax..updateMinMax(maMinmax);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintVolumeChart(canvas);
    _paintVolMaLines(canvas);

    if (settingConfig.showYAxisTick) {
      paintYAxisTicks(
        canvas,
        dys: tickPositions(defaultSubTickCount, start: chartRect.top, length: chartRect.height),
        precision: indicator.precision,
      );
    }
  }

  // 刻度值是核心库按像素反推的, 与数据值差浮点误差; 截断时误差落在边界下方会少显示末位, 所以先收到比显示位数多 3 位。
  String _formatTicks(FlexiNum value, int precision) => formatAmount(
    value.toDecimal().round(scale: precision + 3),
    precision: precision,
    roundMode: RoundMode.truncate,
    defIfZero: '0.00',
  );

  @override
  String formatTicksValue(FlexiNum value, {required int precision}) => _formatTicks(value, precision);

  @override
  String formatTicksValueOnCross(FlexiNum value, {required int precision}) => _formatTicks(value, precision);

  @override
  void paintCross(Canvas canvas, Offset offset, {FlexiCandleModel? model}) {
    paintYAxisTicksOnCross(canvas, offset, precision: indicator.precision);
  }

  void _paintVolumeChart(Canvas canvas) {
    final list = klineData.list;
    final int start = klineData.start;
    final int end = klineData.end;

    final offset = startCandleDx - candleWidthHalf;
    final dyBottom = chartRect.bottom;

    final longPaint = defLongBarPaint..color = longColor.withAlpha(indicator.volOpacity.alpha);
    final shortPaint = defShortBarPaint..color = shortColor.withAlpha(indicator.volOpacity.alpha);

    for (var i = start; i < end; i++) {
      final model = list[i];
      final dx = offset - (i - start) * candleActualWidth;
      var dy = valueToDy(model.vol);
      // Y 轴以可见区最小值为底, 最小那根量柱高度为 0; 不足 0.5 时画 1px, 避免看不见。
      if (dyBottom - dy < 0.5) dy = dyBottom - 1;
      final isLong = model.close >= model.open;

      canvas.drawLine(Offset(dx, dy), Offset(dx, dyBottom), isLong ? longPaint : shortPaint);
    }
  }

  void _paintVolMaLines(Canvas canvas) {
    final list = klineData.list;
    final int start = klineData.start;
    final int end = (klineData.end + 1).clamp(start, list.length); // 多绘制一根蜡烛

    final offset = startCandleDx - candleWidthHalf;
    for (int j = 0; j < indicator.calcParam.length; j++) {
      FlexiNum? val;
      final List<Offset> points = [];
      for (int i = start; i < end; i++) {
        val = list[i].getList<FlexiNum>(dataIndex)?.getItem(j);
        if (val == null) continue;
        points.add(Offset(offset - (i - start) * candleActualWidth, valueToDy(val, correct: false)));
      }

      canvas.drawPath(
        Path()..addPolygon(points, false),
        Paint()
          ..color = indicator.calcParam[j].color.withAlpha(indicator.lineOpacity.alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = defaultIndicatorLineWidth,
      );
    }
  }

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) {
    model ??= offsetToCandle(offset);
    if (model == null) return null;
    final children = <TextSpan>[];

    final text = formatAmount(
      model.vol.toDecimal(),
      precision: indicator.precision,
      roundMode: RoundMode.truncate,
      prefix: 'Vol:$nbsp',
    );
    children.add(
      TextSpan(
        text: '$text  ',
        style: indicator.tipsStyle.copyWith(color: theme.ticksTextColor),
      ),
    );

    final volMaList = model.getList<FlexiNum>(dataIndex);
    final params = indicator.calcParam;
    for (int i = 0; i < params.length; i++) {
      final text = formatAmount(
        volMaList?.getItem(i)?.toDecimal(),
        precision: indicator.precision,
        roundMode: RoundMode.truncate,
        prefix: 'MA${params[i].count}:$nbsp',
        suffix: '  ',
      );
      children.add(
        TextSpan(
          text: text,
          style: indicator.tipsStyle.copyWith(color: params[i].color),
        ),
      );
    }

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
