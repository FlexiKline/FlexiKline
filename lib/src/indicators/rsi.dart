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
import 'package:flutter/material.dart';

import '../config/export.dart';
import '../constant.dart';
import '../core/export.dart';
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../utils/export.dart';

part 'rsi.g.dart';

/// MA 移动平均指标线
@CopyWith()
@FlexiIndicatorSerializable
class RSIIndicator extends SinglePaintObjectIndicator
    implements IPrecomputable {
  RSIIndicator({
    super.key = rsiKey,
    super.name = 'RSI',
    super.zIndex = 0,
    super.height = defaultSubIndicatorHeight,
    super.padding = defaultSubIndicatorPadding,
    required this.calcParams,
    required this.tipsPadding,
    this.tickCount = defaultSubTickCount,
    required this.lineWidth,
    this.precision = 2,
  });

  final List<RsiParam> calcParams;
  final EdgeInsets tipsPadding;
  final int tickCount;
  final double lineWidth;
  // 默认精度
  final int precision;

  @override
  dynamic getCalcParam() => calcParams;

  @override
  SinglePaintObjectBox createPaintObject(KlineBindingBase controller) {
    return RSIPaintObject(controller: controller, indicator: this);
  }

  factory RSIIndicator.fromJson(Map<String, dynamic> json) =>
      _$RSIIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$RSIIndicatorToJson(this);
}

class RSIPaintObject<T extends RSIIndicator> extends SinglePaintObjectBox<T>
    with PaintYAxisScaleMixin, PaintYAxisMarkOnCrossMixin {
  RSIPaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initState({required int start, required int end}) {
    if (!klineData.canPaintChart) return null;

    return klineData.calcuRsiMinmax(
      indicator.calcParams,
      start: start,
      end: end,
    );
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    paintRsiLine(canvas, size);

    /// 绘制Y轴刻度值
    if (settingConfig.showYAxisTick) {
      paintYAxisScale(
        canvas,
        size,
        tickCount: indicator.tickCount,
        precision: indicator.precision,
      );
    }
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    /// onCross时, 绘制Y轴上的标记值
    paintYAxisMarkOnCross(
      canvas,
      offset,
      precision: indicator.precision,
    );
  }

  /// 绘制MA指标线
  void paintRsiLine(Canvas canvas, Size size) {
    if (!klineData.canPaintChart) return;
    if (indicator.calcParams.isEmpty) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = (klineData.end + 1).clamp(start, list.length); // 多绘制一根蜡烛

    final offset = startCandleDx - candleWidthHalf;
    for (int j = 0; j < indicator.calcParams.length; j++) {
      double? val;
      final List<Offset> points = [];
      for (int i = start; i < end; i++) {
        val = list[i].rsiList?.getItem(j);
        if (val == null) continue;
        points.add(Offset(
          offset - (i - start) * candleActualWidth,
          valueToDy(BagNum.fromNum(val), correct: false),
        ));
      }

      canvas.drawPath(
        Path()..addPolygon(points, false),
        Paint()
          ..color = indicator.calcParams[j].tips.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = indicator.lineWidth,
      );
    }
  }

  /// MA 绘制tips区域
  @override
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    model ??= offsetToCandle(offset);
    if (model == null || !model.isValidRsiList) return null;

    final precision = indicator.precision;
    final children = <TextSpan>[];
    double? val;
    for (int i = 0; i < model.rsiList!.length; i++) {
      val = model.rsiList?.getItem(i);
      if (val == null) continue;
      final param = indicator.calcParams.getItem(i);
      if (param == null) continue;

      final text = formatNumber(
        val.toDecimal(),
        precision: param.tips.getP(precision),
        cutInvalidZero: true,
        prefix: param.tips.label,
        suffix: '  ',
      );
      children.add(TextSpan(
        text: text,
        style: param.tips.style,
      ));
    }
    if (children.isNotEmpty) {
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
    return null;
  }
}
