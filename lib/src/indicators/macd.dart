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

import '../constant.dart';
import '../core/export.dart';
import '../data/export.dart';
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../utils/export.dart';

part 'macd.g.dart';

@FlexiParamSerializable
final class MACDParam {
  final int s;
  final int l;
  final int m;

  const MACDParam({required this.s, required this.l, required this.m});

  bool get isValid => l > 0 && s > 0 && l > s && m > 0;

  int get paramCount => math.max(l, s) + m;

  @override
  int get hashCode => s.hashCode ^ l.hashCode ^ m.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MACDParam &&
          runtimeType == other.runtimeType &&
          s == other.s &&
          l == other.l &&
          m == other.m;

  @override
  String toString() {
    return 'MACDParam{s:$s, l:$l, m:$s}';
  }

  factory MACDParam.fromJson(Map<String, dynamic> json) =>
      _$MACDParamFromJson(json);
  Map<String, dynamic> toJson() => _$MACDParamToJson(this);
}

/// 指数平滑移动平均线MACD
@FlexiIndicatorSerializable
class MACDIndicator extends SinglePaintObjectIndicator {
  MACDIndicator({
    super.key = macdKey,
    super.name = 'MACD',
    super.height = defaultSubIndicatorHeight,
    super.tipsHeight = defaultIndicatorTipsHeight,
    super.padding = defaultIndicatorPadding,

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
    with PaintYAxisTickMixin, PaintYAxisMarkOnCrossMixin {
  MACDPaintObject({required super.controller, required super.indicator});

  @override
  MinMax? initState({required int start, required int end}) {
    if (!klineData.canPaintChart) return null;

    return klineData.calculateMacdMinmax(
      param: indicator.calcParam,
      start: start,
      end: end,
    );
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    paintMacdChart(canvas, size);

    /// 绘制Y轴刻度值
    paintYAxisTick(
      canvas,
      size,
      tickCount: indicator.tickCount,
    );
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    /// onCross时, 绘制Y轴上的标记值
    paintYAxisTickOnCross(canvas, offset);
  }

  /// 绘制MACD图
  void paintMacdChart(Canvas canvas, Size size) {
    final macdMap = klineData.getMacdMap(indicator.calcParam);
    if (macdMap.isEmpty || !klineData.canPaintChart) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = (klineData.end + 1).clamp(start, list.length); // 多绘制一根蜡烛

    CandleModel m;
    MacdResult? ret, next;
    final List<Offset> difPoints = [];
    final List<Offset> deaPoints = [];
    double zeroDy = valueToDy(BagNum.zero);
    final offset = startCandleDx - candleWidthHalf;
    final candleHalf = candleWidthHalf - settingConfig.candleSpacing;
    for (int i = start; i < end; i++) {
      m = list[i];
      ret = macdMap[m.timestamp];
      if (ret == null) continue;
      final dx = offset - (i - start) * candleActualWidth;
      difPoints.add(Offset(dx, valueToDy(ret.dif, correct: false)));
      deaPoints.add(Offset(dx, valueToDy(ret.dea, correct: false)));

      next = macdMap[list.getItem(i + 1)?.timestamp];
      if (next != null && next.macd < ret.macd) {
        // 空心
        canvas.drawPath(
          Path()
            ..addRect(Rect.fromPoints(
              Offset(dx - candleHalf, zeroDy),
              Offset(dx + candleHalf, valueToDy(ret.macd, correct: false)),
            )),
          ret.macd > BagNum.zero
              ? settingConfig.defLongHollowBarPaint
              : settingConfig.defShortHollowBarPaint,
        );
      } else {
        // 实心
        canvas.drawLine(
          Offset(dx, zeroDy),
          Offset(dx, valueToDy(ret.macd, correct: false)),
          ret.macd > BagNum.zero
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
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    if (indicator.tipsHeight <= 0) return null;
    model ??= offsetToCandle(offset);
    if (model == null) return null;

    final ret = klineData.getMacdResult(
      param: indicator.calcParam,
      ts: model.timestamp,
    );
    if (ret == null) return null;

    Rect drawRect = nextTipsRect;
    final children = <TextSpan>[];
    final difTxt = formatNumber(
      ret.dif.toDecimal(),
      precision: indicator.difTips.p,
      cutInvalidZero: true,
      prefix: indicator.difTips.label,
      suffix: ' ',
    );
    final deaTxt = formatNumber(
      ret.dea.toDecimal(),
      precision: indicator.deaTips.p,
      cutInvalidZero: true,
      prefix: indicator.deaTips.label,
      suffix: ' ',
    );
    final macdTxt = formatNumber(
      ret.macd.toDecimal(),
      precision: indicator.macdTips.p,
      cutInvalidZero: true,
      prefix: indicator.macdTips.label,
      suffix: ' ',
    );

    children.add(TextSpan(
      text: difTxt,
      style: indicator.difTips.style,
    ));

    children.add(TextSpan(
      text: deaTxt,
      style: indicator.deaTips.style,
    ));

    children.add(TextSpan(
      text: macdTxt,
      style: indicator.macdTips.style,
    ));

    return canvas.drawText(
      offset: drawRect.topLeft,
      textSpan: TextSpan(children: children),
      drawDirection: DrawDirection.ltr,
      drawableRect: drawRect,
      textAlign: TextAlign.left,
      padding: indicator.tipsPadding,
      maxLines: 1,
    );
  }
}
