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

import '../core/export.dart';
import '../data/export.dart';
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../utils/export.dart';

class VolumeIndicator extends SinglePaintObjectIndicator {
  VolumeIndicator({
    super.key = const ValueKey(IndicatorType.volume),
    required super.height,
    super.tipsHeight,
    super.padding,
  });

  @override
  VolumePaintObject createPaintObject(KlineBindingBase controller) =>
      VolumePaintObject(
        controller: controller,
        indicator: this,
      );
}

class VolumePaintObject extends SinglePaintObjectBox<VolumeIndicator>
    with PaintYAxisTickMixin {
  VolumePaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initData({
    required List<CandleModel> list,
    required int start,
    required int end,
  }) {
    MinMax? minmaxVol = klineData.minmaxVol;
    if (minmaxVol == null) {
      klineData.calculateMaxmin();
      minmaxVol = klineData.minmaxVol;
    }
    minmaxVol?.minToZero();
    return minmaxVol;
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    /// 绘制Y轴刻度值
    paintSubChartYAxisTick(canvas, size);

    /// 绘制Volume柱状图
    paintIndicatorChart(canvas, size);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    /// 绘制Cross命中的Y轴刻度值
    _paintCrossYAxisVolumeMark(canvas, offset);
  }

  /// 绘制Volume柱状图
  void paintIndicatorChart(Canvas canvas, Size size) {
    final data = klineData;
    if (data.list.isEmpty) return;
    int start = data.start;
    int end = data.end;

    final offset = startCandleDx - candleWidthHalf;
    final dyBottom = chartRect.bottom;
    for (var i = start; i < end; i++) {
      final model = data.list[i];
      final dx = offset - (i - start) * candleActualWidth;
      final dy = valueToDy(model.vol);
      final isLong = model.close >= model.open;

      canvas.drawLine(
        Offset(dx, dy),
        Offset(dx, dyBottom),
        isLong ? setting.volBarLongPaint : setting.volBarShortPaint,
      );
    }
  }

  // /// 绘制Y轴刻度值
  // void paintYAxisTick(Canvas canvas, Size size) {
  //   double yAxisStep = chartRect.height / (setting.subChartYAxisTickCount - 1);
  //   final dx = chartRect.right;
  //   double dy = 0.0;
  //   double drawTop = chartRect.top;

  //   for (int i = 0; i < setting.subChartYAxisTickCount; i++) {
  //     dy = drawTop + i * yAxisStep;
  //     final vol = dyToValue(dy);
  //     if (vol == null) continue;

  //     final text = formatNumber(
  //       vol,
  //       precision: 2,
  //       defIfZero: '0.00',
  //       showCompact: true,
  //     );

  //     canvas.drawText(
  //       offset: Offset(
  //         dx,
  //         dy - setting.subChartYAxisTickRectHeight,
  //       ),
  //       drawDirection: DrawDirection.rtl,
  //       drawableRect: drawBounding,
  //       text: text,
  //       style: setting.subChartYAxisTickStyle,
  //       // textWidth: tickTextWidth,
  //       textAlign: TextAlign.end,
  //       padding: setting.subChartYAxisTickRectPadding,
  //       maxLines: 1,
  //     );
  //   }
  // }

  /// 绘制Cross命中的Y轴刻度值
  void _paintCrossYAxisVolumeMark(Canvas canvas, Offset offset) {
    final volume = dyToValue(offset.dy);
    if (volume == null) return;

    final text = formatNumber(
      volume,
      precision: 2,
      // cutInvalidZero: true,
      defIfZero: '0.00',
      showCompact: true,
    );

    canvas.drawText(
      offset: Offset(
        chartRect.right - setting.crossYTickRectRigthMargin,
        offset.dy - setting.crossYTickRectHeight / 2,
      ),
      drawDirection: DrawDirection.rtl,
      drawableRect: drawBounding,
      text: text,
      style: setting.crossYTickTextStyle,
      textAlign: TextAlign.end,
      textWidthBasis: TextWidthBasis.longestLine,
      padding: setting.crossYTickRectPadding,
      backgroundColor: setting.crossYTickRectBackgroundColor,
      radius: setting.crossYTickRectBorderRadius,
      borderWidth: setting.crossYTickRectBorderWidth,
      borderColor: setting.crossYTickRectBorderColor,
    );
  }

  /// 绘制tips区域信息
  /// 1. 正常展示最新一根蜡烛交易量
  /// 2. 当Cross时, 展示命中的蜡烛交易量
  @override
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    if (indicator.tipsHeight <= 0) return null;
    model ??= offsetToCandle(offset);
    if (model == null) return null;
    Rect drawRect = nextTipsRect;

    final text = formatNumber(
      model.vol,
      precision: 2,
      cutInvalidZero: true,
      showCompact: true,
      prefix: 'Vol: ',
    );

    return canvas.drawText(
      offset: drawRect.topLeft,
      drawDirection: DrawDirection.ltr,
      drawableRect: tipsRect,
      text: text,
      style: setting.volTipStyle.copyWith(
        height: drawRect.height / setting.volTipFontSize,
        // height: 1.2,
      ),
      textAlign: TextAlign.left,
      padding: setting.volTipsRectPadding,
      maxLines: 1,
    );
  }
}
