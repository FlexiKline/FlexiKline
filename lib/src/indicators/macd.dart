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

import 'package:flutter/material.dart';

import '../config/export.dart';
import '../constant.dart';
import '../core/export.dart';
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../utils/export.dart';

part 'macd.g.dart';

/// 指数平滑移动平均线MACD
@FlexiIndicatorSerializable
class MACDIndicator extends SinglePaintObjectIndicator {
  MACDIndicator({
    super.key = macdKey,
    super.name = 'MACD',
    super.height = defaultSubIndicatorHeight,
    super.padding = defaultSubIndicatorPadding,

    /// Macd相关参数
    this.calcParam = const MACDParam(s: 12, l: 26, m: 9),

    /// 绘制相关参数
    this.difTips = const TipsConfig(
      label: 'DIF: ',
      precision: 2,
      style: TextStyle(
        fontSize: defaulTextSize,
        color: Color(0xFFDFBF47),
        overflow: TextOverflow.ellipsis,
        height: defaultTipsTextHeight,
      ),
    ),
    this.deaTips = const TipsConfig(
      label: 'DEA: ',
      precision: 2,
      style: TextStyle(
        fontSize: defaulTextSize,
        color: Color(0xFF795583),
        overflow: TextOverflow.ellipsis,
        height: defaultTipsTextHeight,
      ),
    ),
    this.macdTips = const TipsConfig(
      label: 'MACD: ',
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
    this.lineWidth = defaultIndicatorLineWidth,
    this.precision = 2,
  });

  /// Macd相关参数
  final MACDParam calcParam;

  /// 绘制相关参数
  final TipsConfig difTips;
  final TipsConfig deaTips;
  final TipsConfig macdTips;
  final EdgeInsets tipsPadding;
  final int tickCount;
  final double lineWidth;
  // 默认精度
  final int precision;

  @override
  SinglePaintObjectBox createPaintObject(KlineBindingBase controller) {
    return MACDPaintObject(controller: controller, indicator: this);
  }

  factory MACDIndicator.fromJson(Map<String, dynamic> json) =>
      _$MACDIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MACDIndicatorToJson(this);
}

class MACDPaintObject<T extends MACDIndicator> extends SinglePaintObjectBox<T>
    with PaintHorizontalTickMixin, PaintHorizontalTickOnCrossMixin {
  MACDPaintObject({required super.controller, required super.indicator});

  @override
  MinMax? initState({required int start, required int end}) {
    if (!klineData.canPaintChart) return null;

    return klineData.calcuMacdMinmax(
      param: indicator.calcParam,
      start: start,
      end: end,
    );
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    paintMacdChart(canvas, size);

    /// 绘制Y轴刻度值
    paintHorizontalTick(
      canvas,
      size,
      tickCount: indicator.tickCount,
      precision: indicator.precision,
    );
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    /// onCross时, 绘制Y轴上的标记值
    paintHorizontalTickOnCross(
      canvas,
      offset,
      precision: indicator.precision,
    );
  }

  /// 绘制MACD图
  void paintMacdChart(Canvas canvas, Size size) {
    if (!klineData.canPaintChart) return;
    if (!indicator.calcParam.isValid) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = (klineData.end + 1).clamp(start, list.length); // 多绘制一根蜡烛

    final List<Offset> difPoints = [];
    final List<Offset> deaPoints = [];
    double zeroDy = valueToDy(BagNum.zero);
    final offset = startCandleDx - candleWidthHalf;
    final candleHalf = candleWidthHalf - settingConfig.candleSpacing;

    CandleModel m;
    CandleModel? next;
    for (int i = start; i < end; i++) {
      m = list[i];
      if (!m.isValidMacdData) continue;
      final dx = offset - (i - start) * candleActualWidth;
      difPoints.add(Offset(dx, valueToDy(m.dif!, correct: false)));
      deaPoints.add(Offset(dx, valueToDy(m.dea!, correct: false)));

      next = list.getItem(i + 1);
      if (next?.macd != null && m.macd! > next!.macd!) {
        // 空心
        canvas.drawPath(
          Path()
            ..addRect(Rect.fromPoints(
              Offset(dx - candleHalf, zeroDy),
              Offset(dx + candleHalf, valueToDy(m.macd!, correct: false)),
            )),
          m.macd! > BagNum.zero
              ? settingConfig.defLongHollowBarPaint
              : settingConfig.defShortHollowBarPaint,
        );
      } else {
        // 实心
        canvas.drawLine(
          Offset(dx, zeroDy),
          Offset(dx, valueToDy(m.macd!)),
          m.macd! > BagNum.zero
              ? settingConfig.defLongBarPaint
              : settingConfig.defShortBarPaint,
        );
      }
    }

    canvas.drawPath(
      Path()..addPolygon(difPoints, false),
      Paint()
        ..color = indicator.difTips.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = indicator.lineWidth,
    );

    canvas.drawPath(
      Path()..addPolygon(deaPoints, false),
      Paint()
        ..color = indicator.deaTips.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = indicator.lineWidth,
    );
  }

  @override
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    model ??= offsetToCandle(offset);
    if (model == null || !model.isValidMacdData) return null;

    final precision = indicator.precision;
    final children = <TextSpan>[];

    children.add(TextSpan(
      text: formatNumber(
        model.dif?.toDecimal(),
        precision: indicator.difTips.getP(precision),
        cutInvalidZero: true,
        prefix: indicator.difTips.label,
        suffix: ' ',
      ),
      style: indicator.difTips.style,
    ));

    children.add(TextSpan(
      text: formatNumber(
        model.dea?.toDecimal(),
        precision: indicator.deaTips.getP(precision),
        cutInvalidZero: true,
        prefix: indicator.deaTips.label,
        suffix: ' ',
      ),
      style: indicator.deaTips.style,
    ));

    children.add(TextSpan(
      text: formatNumber(
        model.macd?.toDecimal(),
        precision: indicator.macdTips.getP(precision),
        cutInvalidZero: true,
        prefix: indicator.macdTips.label,
        suffix: ' ',
      ),
      style: indicator.macdTips.style,
    ));

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
