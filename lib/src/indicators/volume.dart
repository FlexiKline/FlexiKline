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

import '../core/export.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../render/export.dart';
import '../utils/export.dart';

class VolumeIndicator extends SinglePaintObjectIndicator {
  VolumeIndicator({
    required super.key,
    required super.height,
    super.tipsHeight,
    super.padding,
  });

  @override
  SinglePaintObjectBox createPaintObject(KlineBindingBase controller) =>
      VolumePaintObject(
        controller: controller,
        indicator: this,
      );
}

class VolumePaintObject extends SinglePaintObjectBox<VolumeIndicator> {
  VolumePaintObject({
    required super.controller,
    required super.indicator,
  });

  Decimal _max = Decimal.zero;
  Decimal _min = Decimal.zero;

  @override
  MinMax? initData({
    required List<CandleModel> list,
    required int start,
    required int end,
  }) {
    if (list.isEmpty || start < 0 || end > list.length) return null;
    CandleModel m = list[start];
    _max = m.vol;
    _min = m.vol;
    for (var i = start + 1; i < end; i++) {
      m = list[i];
      _max = m.vol > _max ? m.vol : _max;
      _min = m.vol < _min ? m.vol : _min;
    }
    // 增加vol区域的margin为高度的1/10
    final volH = _max == _min ? Decimal.one : _max - _min;
    final margin = volH * twentieth;
    _max += margin;
    _min -= margin;

    return MinMax(max: _max, min: _min);
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    /// 绘制Volume柱状图
    paintIndicatorChart(canvas, size);

    /// 绘制Y轴刻度值
    paintYAxisTick(canvas, size);

    // if (!cross.isCrossing) {
    //   paintTips(canvas, model: state.curKlineData.latest);
    // }
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    /// 绘制Cross命中的Y轴刻度值
    _paintCrossYAxisVolumeMark(canvas, offset);

    // paintTips(canvas, offset: offset);
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

  /// 绘制Y轴刻度值
  void paintYAxisTick(Canvas canvas, Size size) {
    double yAxisStep = chartRect.height / (setting.volBarYAxisTickCount - 1);
    final dx = chartRect.right;
    double dy = 0.0;
    double drawTop = chartRect.top;

    for (int i = 0; i < setting.volBarYAxisTickCount; i++) {
      dy = drawTop + i * yAxisStep;
      final vol = dyToValue(dy);
      if (vol == null) continue;

      final text = formatNumber(
        vol,
        precision: 2,
        defIfZero: '--',
        cutInvalidZero: true,
        showCompact: true,
      );

      canvas.drawText(
        offset: Offset(
          dx,
          dy - setting.priceTickRectHeight,
        ),
        drawDirection: DrawDirection.rtl,
        drawableRect: drawBounding,
        text: text,
        style: setting.volBarTickStyle,
        // textWidth: tickTextWidth,
        textAlign: TextAlign.end,
        padding: setting.volBarTickRectPadding,
        maxLines: 1,
      );
    }
  }

  /// 绘制Cross命中的Y轴刻度值
  void _paintCrossYAxisVolumeMark(Canvas canvas, Offset offset) {
    final volume = dyToValue(offset.dy);
    if (volume == null) return;

    final text = formatNumber(
      volume,
      precision: 2,
      cutInvalidZero: true,
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

    final dx = tipsRect.left;
    final dy = tipsRect.top;

    final text = formatNumber(
      model.vol,
      precision: 2,
      cutInvalidZero: true,
      showCompact: true,
      prefix: 'Vol: ',
    );

    return canvas.drawText(
      offset: Offset(
        dx,
        dy,
      ),
      drawDirection: DrawDirection.ltr,
      drawableRect: tipsRect,
      text: text,
      style: setting.volTipStyle.copyWith(
        height: indicator.tipsHeight / setting.volTipFontSize,
      ),
      textAlign: TextAlign.center,
      padding: setting.volTipsRectPadding,
      maxLines: 1,
    );
  }
}
