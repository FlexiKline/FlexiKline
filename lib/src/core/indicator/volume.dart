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
import '../../render/export.dart';
import '../../utils/num_util.dart';
import 'indicator.dart';

class VolumeChart extends IndicatorChart {
  VolumeChart({
    required super.index,
    required super.controller,
    super.type = IndicatorType.volume,
    required super.height,
    super.tipHeight,
    super.padding,
  });

  @override
  Paint get longPaint => setting.volBarLongPaint;
  @override
  Paint get shortPaint => setting.volBarShortPaint;

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
  void paintSubChart(Canvas canvas, Size size) {
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
        isLong ? longPaint : shortPaint,
      );
    }

    paintYAxisTick(canvas, size);
  }

  @override
  void paintTooltip(Canvas canvas, Size size) {}

  @override
  void paintYAxisTick(Canvas canvas, Size size) {
    double yAxisStep = drawRect.height / volBarYAxisTickCount;
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
          dy + setting.priceTickRectHeight,
        ),
        drawDirection: DrawDirection.rtl,
        drawableSize: Size(setting.canvasWidth, setting.canvasHeight),
        text: text,
        style: setting.priceTickStyle.copyWith(color: Colors.blue),
        // textWidth: tickTextWidth,
        textAlign: TextAlign.end,
        padding: setting.priceTickRectPadding,
        maxLines: 1,
      );
    }
  }
}
