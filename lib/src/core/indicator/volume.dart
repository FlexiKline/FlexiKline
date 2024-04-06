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

import '../../constant.dart';
import '../../extension/export.dart';
import '../../model/export.dart';
import '../../render/export.dart';
import '../../utils/num_util.dart';
import 'indicator.dart';

class VolumeChart extends IndicatorChart {
  VolumeChart({
    super.debug,
    required super.index,
    required super.controller,
    super.type = IndicatorType.volume,
    required super.height,
    super.tipHeight,
    super.padding,
  });

  Decimal get volDataHeight => curKlineData.volDataHeight;

  int get volBarYAxisTickCount => setting.volBarYAxisTickCount;

  double get dyVolFactor {
    return drawRect.height / curKlineData.volDataHeight.toDouble();
  }

  /// Volume转换为dy坐标
  double volToDy(Decimal vol) {
    vol = vol.clamp(curKlineData.minVol, curKlineData.maxVol);
    return drawRect.bottom -
        (vol - curKlineData.minVol).toDouble() * dyVolFactor;
  }

  /// dy坐标转换为Volume
  Decimal? dyToVol(double dy) {
    final drawTop = drawRect.top;
    if (dy < drawTop) return null;
    if (dy > drawRect.bottom) return null;
    return curKlineData.maxVol - ((dy - drawTop) / dyVolFactor).d;
  }

  @override
  void paintIndicatorChart(Canvas canvas, Size size) {
    final data = curKlineData;
    if (data.list.isEmpty) return;
    int start = data.start;
    int end = data.end;

    final offset = startCandleDx - candleWidthHalf;
    final dyBottom = drawRect.bottom;
    for (var i = start; i < end; i++) {
      final model = data.list[i];
      final dx = offset - (i - start) * candleActualWidth;
      final isLong = model.close >= model.open;

      final dy = volToDy(model.vol);

      canvas.drawLine(
        Offset(dx, dy),
        Offset(dx, dyBottom),
        isLong ? setting.volBarLongPaint : setting.volBarShortPaint,
      );
    }

    paintYAxisTick(canvas, size);
  }

  void paintYAxisTick(Canvas canvas, Size size) {
    double yAxisStep = drawRect.height / (volBarYAxisTickCount - 1);
    final dx = drawRect.right;
    double dy = 0.0;
    double drawTop = drawRect.top;

    for (int i = 0; i < volBarYAxisTickCount; i++) {
      dy = drawTop + i * yAxisStep;
      final vol = dyToVol(dy);
      if (vol == null) continue;

      final text = formatNumber(
        vol,
        precision: 2,
        cutInvalidZero: true,
        showCompact: true,
      );

      canvas.drawText(
        offset: Offset(
          dx,
          dy - setting.priceTickRectHeight,
        ),
        drawDirection: DrawDirection.rtl,
        // drawableSize: Size(setting.canvasWidth, setting.canvasHeight + 200),
        text: text,
        style: setting.volBarTickStyle,
        // textWidth: tickTextWidth,
        textAlign: TextAlign.end,
        padding: setting.volBarTickRectPadding,
        maxLines: 1,
      );
    }
  }

  @override
  void paintSubTooltip(Canvas canvas, Size size) {
    if (state.isCrossing) return;
    final model = state.curKlineData.latest;
    if (model == null) return;
    _paintTooltipVolume(canvas, model);
  }

  @override
  void handleIndicatorCross(Canvas canvas, Offset offset) {
    _paintCrossYAxisVolumeMark(canvas, offset);

    CandleModel? model = state.offsetToCandle(offset);
    if (model != null) {
      _paintTooltipVolume(canvas, model);
    }
  }

  void _paintCrossYAxisVolumeMark(Canvas canvas, Offset offset) {
    final volume = dyToVol(offset.dy);
    if (volume == null) return;

    final text = formatNumber(
      volume,
      precision: 2,
      cutInvalidZero: true,
      showCompact: true,
    );

    canvas.drawText(
      offset: Offset(
        drawRect.right - setting.crossYTickRectRigthMargin,
        offset.dy - setting.crossYTickRectHeight / 2,
      ),
      drawDirection: DrawDirection.rtl,
      drawableSize: setting.canvasRect.size,
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

  void _paintTooltipVolume(Canvas canvas, CandleModel model) {
    final dx = tipRect.left;
    final dy = tipRect.top;

    final text = formatNumber(
      model.vol,
      precision: 2,
      cutInvalidZero: true,
      showCompact: true,
      prefix: 'Vol: ',
    );

    canvas.drawText(
      offset: Offset(
        dx,
        dy,
      ),
      drawDirection: DrawDirection.ltr,
      drawableSize: setting.canvasRect.size,
      text: text,
      style: setting.volTipStyle,
      textAlign: TextAlign.left,
      padding: setting.volTipRectPadding,
      maxLines: 1,
      // backgroundColor: Colors.white, // TODO: 增加背景防止重叠.
    );
  }
}
