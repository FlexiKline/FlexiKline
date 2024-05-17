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
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../utils/export.dart';

part 'volume.g.dart';

@FlexiIndicatorSerializable
class VolumeIndicator extends SinglePaintObjectIndicator {
  VolumeIndicator({
    super.key = volumeKey,
    super.name = 'VOL',
    super.height = defaultSubIndicatorHeight,
    super.padding = defaultSubIndicatorPadding,
    super.paintMode,

    /// 绘制相关参数
    this.volTips = const TipsConfig(
      label: 'Vol: ',
      precision: 2,
      style: TextStyle(
        fontSize: defaulTextSize,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
        height: defaultTipsTextHeight,
      ),
    ),
    this.tipsPadding = defaultTipsPadding,
    this.tickCount = defaultSubTickCount,
    this.precision = 2,

    /// 控制参数
    this.showYAxisTick = true,
    this.showCrossMark = true,
    this.showTips = true,
    this.useTint = false,
  });

  /// 绘制相关参数
  final TipsConfig volTips;
  final EdgeInsets tipsPadding;
  final int tickCount;
  // 默认精度
  final int precision;

  /// 控制参数(Volume可用于主图和副图, 以下开关控制在主/副图的展示效果)
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

  @override
  Map<String, dynamic> toJson() => _$VolumeIndicatorToJson(this);
}

class VolumePaintObject<T extends VolumeIndicator>
    extends SinglePaintObjectBox<T>
    with PaintHorizontalTickMixin, PaintHorizontalTickOnCrossMixin {
  VolumePaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initState({required int start, required int end}) {
    if (!klineData.canPaintChart) return null;

    final minmax = klineData.calculateVolMinmax(
      start: start,
      end: end,
    );
    minmax?.minToZero();
    return minmax;
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    /// 绘制Volume柱状图
    paintVolumeChart(canvas, size);

    if (indicator.showYAxisTick) {
      /// 绘制Y轴刻度值
      paintHorizontalTick(
        canvas,
        size,
        tickCount: indicator.tickCount,
        precision: indicator.precision,
      );
    }
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    if (indicator.showCrossMark) {
      /// onCross时, 绘制Y轴上的标记值
      paintHorizontalTickOnCross(
        canvas,
        offset,
        precision: indicator.precision,
      );
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
        ? settingConfig.defLongTintBarPaint
        : settingConfig.defLongBarPaint;
    final shortPaint = indicator.useTint
        ? settingConfig.defShortTintBarPaint
        : settingConfig.defShortBarPaint;

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
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    if (!indicator.showTips) return null;
    model ??= offsetToCandle(offset);
    if (model == null) return null;

    final text = formatNumber(
      model.vol.toDecimal(),
      precision: indicator.volTips.getP(indicator.precision),
      cutInvalidZero: true,
      showCompact: true,
      prefix: indicator.volTips.label,
    );

    tipsRect ??= drawableRect;
    return canvas.drawText(
      offset: tipsRect.topLeft,
      text: text,
      style: indicator.volTips.style,
      drawDirection: DrawDirection.ltr,
      drawableRect: tipsRect,
      textAlign: TextAlign.left,
      padding: indicator.tipsPadding,
      maxLines: 1,
    );
  }
}
