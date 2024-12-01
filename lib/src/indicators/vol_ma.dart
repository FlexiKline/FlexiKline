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

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/painting.dart';

import '../config/export.dart';
import '../constant.dart';
import '../core/core.dart';
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../utils/export.dart';

part 'vol_ma.g.dart';

/// VolMa 移动平均指标线
@CopyWith()
@FlexiIndicatorSerializable
class VolMaIndicator extends SinglePaintObjectIndicator
    implements IPrecomputable {
  VolMaIndicator({
    super.zIndex = 0,
    super.height = defaultSubIndicatorHeight,
    super.padding = defaultSubIndicatorPadding,

    /// 绘制相关参数
    required this.volTips,
    required this.calcParams,
    required this.tipsPadding,
    this.ticksCount = defaultSubTickCount,
    required this.maLineWidth,
    this.precision = 2,
  }) : super(key: IndicatorType.volMa);

  final TipsConfig volTips;
  @override
  final List<MaParam> calcParams;
  final EdgeInsets tipsPadding;
  final int ticksCount;
  final double maLineWidth;
  // 默认精度
  final int precision;

  @override
  VolMaPaintObject createPaintObject(IPaintContext context) {
    return VolMaPaintObject(context: context, indicator: this);
  }

  factory VolMaIndicator.fromJson(Map<String, dynamic> json) =>
      _$VolMaIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$VolMaIndicatorToJson(this);
}

class VolMaPaintObject<T extends VolMaIndicator> extends SinglePaintObjectBox<T>
    with PaintYAxisTicksMixin, PaintYAxisTicksOnCrossMixin {
  VolMaPaintObject({
    required super.context,
    required super.indicator,
  });

  @override
  MinMax? initState({required int start, required int end}) {
    if (!klineData.canPaintChart) return null;

    final volMinmax = klineData.calculateVolMinmax(
      start: start,
      end: end,
    );

    final maMinmax = klineData.calcuVolMaMinmax(
      indicator.calcParams,
      start: start,
      end: end,
    );

    if (volMinmax != null) {
      return volMinmax..updateMinMax(maMinmax);
    } else if (maMinmax != null) {
      return maMinmax..updateMinMax(volMinmax);
    }
    return null;
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    /// 绘制Volume柱状图
    paintVolumeChart(canvas, size);

    /// 绘制VOLMA指标线
    paintVolMALine(canvas, size);

    if (settingConfig.showYAxisTick) {
      /// 绘制Y轴刻度值
      paintYAxisTicks(
        canvas,
        size,
        tickCount: indicator.ticksCount,
        precision: indicator.precision,
      );
    }
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    /// onCross时, 绘制Y轴上的标记值
    paintYAxisTicksOnCross(
      canvas,
      offset,
      precision: indicator.precision,
    );
  }

  /// 绘制Volume柱状图
  void paintVolumeChart(Canvas canvas, Size size) {
    if (!klineData.canPaintChart) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = klineData.end;

    final offset = startCandleDx - candleWidthHalf;
    final dyBottom = chartRect.bottom;

    final longPaint = settingConfig.defLongBarPaint;
    final shortPaint = settingConfig.defShortBarPaint;

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

  /// 绘制VOLMA指标线
  void paintVolMALine(Canvas canvas, Size size) {
    if (!klineData.canPaintChart) return;
    if (indicator.calcParams.isEmpty) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = (klineData.end + 1).clamp(start, list.length); // 多绘制一根蜡烛

    final offset = startCandleDx - candleWidthHalf;
    for (int j = 0; j < indicator.calcParams.length; j++) {
      BagNum? val;
      final List<Offset> points = [];
      for (int i = start; i < end; i++) {
        val = list[i].volMaList?.getItem(j);
        if (val == null) continue;
        points.add(Offset(
          offset - (i - start) * candleActualWidth,
          valueToDy(val, correct: false),
        ));
      }

      canvas.drawPath(
        Path()..addPolygon(points, false),
        Paint()
          ..color = indicator.calcParams[j].tips.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = indicator.maLineWidth,
      );
    }
  }

  /// VOLMA 绘制tips区域
  @override
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    model ??= offsetToCandle(offset);
    if (model == null) return null;
    final children = <TextSpan>[];

    /// Vol Tips文本
    final text = formatNumber(
      model.vol.toDecimal(),
      precision: indicator.volTips.getP(indicator.precision),
      cutInvalidZero: true,
      showCompact: true,
      prefix: indicator.volTips.label,
    );
    children.add(TextSpan(
      text: '$text  ',
      style: indicator.volTips.style,
    ));

    if (model.isValidVolMaList) {
      /// Ma Tips文本
      BagNum? val;
      for (int i = 0; i < model.volMaList!.length; i++) {
        val = model.volMaList?.getItem(i);
        if (val == null) continue;
        final param = indicator.calcParams.getItem(i);
        if (param == null) continue;

        final text = formatNumber(
          val.toDecimal(),
          precision: param.tips.getP(klineData.precision),
          cutInvalidZero: true,
          prefix: param.tips.label,
          suffix: '  ',
        );
        children.add(TextSpan(
          text: text,
          style: param.tips.style,
        ));
      }
    }

    tipsRect ??= drawableRect;
    return canvas.drawText(
      offset: tipsRect.topLeft,
      textSpan: TextSpan(children: children),
      drawDirection: DrawDirection.ltr,
      drawableRect: tipsRect,
      textAlign: TextAlign.left,
      padding: indicator.tipsPadding,
      maxLines: 1,
    );
  }
}
