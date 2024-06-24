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

import 'package:flutter/material.dart';

import '../config/export.dart';
import '../extension/export.dart';
import '../model/export.dart';
import '../utils/export.dart';
import 'indicator.dart';
import 'object.dart';

mixin PaintYAxisScaleMixin<T extends SinglePaintObjectIndicator>
    on SinglePaintObjectBox<T> {
  /// 为副区的指标图绘制Y轴上的刻度信息
  @protected
  void paintYAxisScale(
    Canvas canvas,
    Size size, {
    required int tickCount, // 刻度数量.
    required int precision,
  }) {
    if (minMax.isZero) return;
    if (tickCount <= 0) return;

    double dyStep = 0;
    double drawTop;
    if (tickCount == 1) {
      drawTop = chartRect.top + chartRect.height / 2;
    } else {
      drawTop = chartRect.top;
      dyStep = chartRect.height / (tickCount - 1);
    }

    final dx = chartRect.right;
    double dy = 0.0;
    for (int i = 0; i < tickCount; i++) {
      dy = drawTop + i * dyStep;
      final value = dyToValue(dy);
      if (value == null) continue;

      final text = fromatTickValue(value, precision: precision);

      final tickText = settingConfig.tickText;

      canvas.drawTextArea(
        offset: Offset(
          dx,
          dy - tickText.areaHeight, // 绘制在刻度线之上
        ),
        drawDirection: DrawDirection.rtl,
        drawableRect: drawableRect,
        text: text,
        textConfig: tickText,
      );
    }
  }

  /// 如果要定制格式化刻度值. 在PaintObject中覆写此方法.
  @protected
  String fromatTickValue(BagNum value, {required int precision}) {
    return formatNumber(
      value.toDecimal(),
      precision: precision,
      defIfZero: '0.00',
      showCompact: true,
    );
  }
}

mixin PaintYAxisMarkOnCrossMixin<T extends SinglePaintObjectIndicator>
    on SinglePaintObjectBox<T> {
  /// onCross时, 绘制Y轴上的刻度值
  @protected
  void paintYAxisMarkOnCross(
    Canvas canvas,
    Offset offset, {
    required int precision,
  }) {
    final value = dyToValue(offset.dy);
    if (value == null) return;

    final text = formatMarkValueOnCross(value, precision: precision);

    final tickText = crossConfig.tickText;

    canvas.drawTextArea(
      offset: Offset(
        chartRect.right - crossConfig.spacing,
        offset.dy - tickText.areaHeight / 2,
      ),
      drawDirection: DrawDirection.rtl,
      drawableRect: drawableRect,
      text: text,
      textConfig: tickText,
    );
  }

  @protected
  String formatMarkValueOnCross(BagNum value, {required int precision}) {
    return formatNumber(
      value.toDecimal(),
      precision: precision,
      defIfZero: '0.00',
      showCompact: true,
    );
  }
}

/// 绘制简易蜡烛图
/// 主要用于SubBoll图和SubSar图中
mixin PaintSimpleCandleMixin<T extends SinglePaintObjectIndicator>
    on SinglePaintObjectBox<T> {
  void paintSimpleCandleChart(
    Canvas canvas,
    Size size, {
    double? lineWidth, // 简易蜡烛线宽.
  }) {
    if (!klineData.canPaintChart) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = klineData.end;

    final offset = startCandleDx - candleWidthHalf;

    CandleModel m;
    for (var i = start; i < end; i++) {
      m = list[i];
      final dx = offset - (i - start) * candleActualWidth;
      final isLong = m.close >= m.open;

      final linePaint = isLong
          ? settingConfig.defLongLinePaint
          : settingConfig.defShortLinePaint;

      if (lineWidth != null) linePaint.strokeWidth = lineWidth;

      final highOff = Offset(dx, valueToDy(m.high));
      final lowOff = Offset(dx, valueToDy(m.low));

      canvas.drawLine(
        highOff,
        lowOff,
        linePaint,
      );

      final openDy = valueToDy(m.open);
      canvas.drawLine(
        Offset(dx - candleWidthHalf, openDy),
        Offset(dx, openDy),
        linePaint,
      );

      final closeDy = valueToDy(m.close);
      canvas.drawLine(
        Offset(dx, closeDy),
        Offset(dx + candleWidthHalf, closeDy),
        linePaint,
      );
    }
  }
}
