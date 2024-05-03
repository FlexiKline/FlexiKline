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

import '../constant.dart';
import '../core/export.dart';
import '../data/export.dart';
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../utils/export.dart';

part 'volume.g.dart';

@indicatorSerializable
class VolumeIndicator extends SinglePaintObjectIndicator {
  VolumeIndicator({
    super.key = const ValueKey(IndicatorType.volume),
    super.name = 'VOL',
    super.height = defaultSubIndicatorHeight,
    super.tipsHeight,
    super.padding,
    super.paintMode,
    this.tickCount,
    this.tipsTextColor,
    this.showYAxisTick = true,
    this.showCrossMark = true,
    this.showTips = true,
    this.useTint = false,
  });

  /// 绘制相关参数
  final int? tickCount;
  final Color? tipsTextColor;
  final bool showYAxisTick;
  final bool showCrossMark;
  final bool showTips;
  final bool useTint;

  @override
  VolumePaintObject createPaintObject(KlineBindingBase controller) =>
      VolumePaintObject(
        controller: controller,
        indicator: this,
      );

  factory VolumeIndicator.fromJson(Map<String, dynamic> json) =>
      _$VolumeIndicatorFromJson(json);
  Map<String, dynamic> toJson() => _$VolumeIndicatorToJson(this);
}

class VolumePaintObject extends SinglePaintObjectBox<VolumeIndicator>
    with PaintYAxisTickMixin, PaintYAxisMarkOnCrossMixin {
  VolumePaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initData({int? start, int? end}) {
    if (!klineData.canPaintChart) return null;

    final minmax = klineData.calculateVolMinmax();
    minmax?.minToZero();
    return minmax;
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    if (indicator.showYAxisTick) {
      /// 绘制Y轴刻度值
      paintYAxisTick(
        canvas,
        size,
        tickCount: indicator.tickCount ?? setting.subChartYAxisTickCount,
      );
    }

    /// 绘制Volume柱状图
    paintVolumeChart(canvas, size);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    if (indicator.showCrossMark) {
      /// onCross时, 绘制Y轴上的标记值
      paintYAxisMarkOnCross(canvas, offset);
    }
  }

  /// 绘制Volume柱状图
  void paintVolumeChart(Canvas canvas, Size size) {
    if (!klineData.canPaintChart) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = klineData.end;

    final offset = startCandleDx - candleWidthHalf;
    final dyBottom = chartRect.bottom;

    final longPaint = indicator.useTint
        ? setting.defLongTintBarPaint
        : setting.defLongBarPaint;
    final shortPaint = indicator.useTint
        ? setting.defShortTintBarPaint
        : setting.defShortBarPaint;

    for (var i = start; i < end; i++) {
      final model = list[i];
      final dx = offset - (i - start) * candleActualWidth;
      final dy = valueToDy(model.vol);
      final isLong = model.close >= model.open;

      canvas.drawLine(
        Offset(dx, dy),
        Offset(dx, dyBottom),
        isLong ? longPaint : shortPaint,
      );
    }
  }

  /// 绘制tips区域信息
  /// 1. 正常展示最新一根蜡烛交易量
  /// 2. 当Cross时, 展示命中的蜡烛交易量
  @override
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    if (!indicator.showTips) return null;
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
      text: text,
      style: TextStyle(
        fontSize: setting.tipsDefaultTextSize,
        color: indicator.tipsTextColor ?? setting.tipsDefaultTextColor,
        height: setting.tipsDefaultTextHeight,
      ),
      drawDirection: DrawDirection.ltr,
      drawableRect: tipsRect,
      textAlign: TextAlign.left,
      padding: setting.tipsRectDefaultPadding,
      maxLines: 1,
    );
  }
}
