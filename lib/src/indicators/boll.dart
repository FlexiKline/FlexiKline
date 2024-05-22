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

import '../config/export.dart';
import '../constant.dart';
import '../core/export.dart';
import '../data/export.dart';
import '../extension/export.dart';
import '../model/export.dart';
import '../utils/export.dart';
import '../framework/export.dart';

part 'boll.g.dart';

@FlexiIndicatorSerializable
class BOLLIndicator extends SinglePaintObjectIndicator {
  BOLLIndicator({
    super.key = bollKey,
    super.name = 'BOLL',
    required super.height,
    super.padding = defaultMainIndicatorPadding,

    /// BOLL计算参数
    this.calcParam = const BOLLParam(n: 20, std: 2),

    /// 绘制相关参数
    this.mbTips = const TipsConfig(
      label: 'BOLL(20): ',
      // precision: 2,
      style: TextStyle(
        fontSize: defaulTextSize,
        color: Color(0xFF886787),
        overflow: TextOverflow.ellipsis,
        height: defaultTipsTextHeight,
      ),
    ),
    this.upTips = const TipsConfig(
      label: 'UB: ',
      // precision: 2,
      style: TextStyle(
        fontSize: defaulTextSize,
        color: Color(0xFFF0B527),
        overflow: TextOverflow.ellipsis,
        height: defaultTipsTextHeight,
      ),
    ),
    this.dnTips = const TipsConfig(
      label: 'LB: ',
      // precision: 2,
      style: TextStyle(
        fontSize: defaulTextSize,
        color: Color(0xFFD85BE0),
        overflow: TextOverflow.ellipsis,
        height: defaultTipsTextHeight,
      ),
    ),
    this.tipsPadding = defaultTipsPadding,
    this.lineWidth = defaultIndicatorLineWidth,

    /// 填充配置
    this.isFillBetweenUpAndDn = true,
    Color? fillColor,
  }) : fillColor = fillColor ?? mbTips.color.withOpacity(0.1);

  /// BOLL计算参数
  final BOLLParam calcParam;

  /// 绘制相关参数
  final TipsConfig mbTips;
  final TipsConfig upTips;
  final TipsConfig dnTips;
  final EdgeInsets tipsPadding;
  final double lineWidth;

  /// 填充配置
  // 是否将up和dn之间填充半透明色
  final bool isFillBetweenUpAndDn;
  // 默认是mbColor的0.1不透明度.
  final Color fillColor;

  @override
  BOLLPaintObject createPaintObject(KlineBindingBase controller) {
    return BOLLPaintObject(controller: controller, indicator: this);
  }

  factory BOLLIndicator.fromJson(Map<String, dynamic> json) =>
      _$BOLLIndicatorFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$BOLLIndicatorToJson(this);
}

class BOLLPaintObject<T extends BOLLIndicator> extends SinglePaintObjectBox<T> {
  BOLLPaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initState({required int start, required int end}) {
    if (!klineData.canPaintChart) return null;

    return klineData.calcuBollMinmax(
      param: indicator.calcParam,
      start: start,
      end: end,
    );
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    /// 绘制BOLL线
    paintBollLine(canvas, size);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    ///
  }

  /// 绘制BOLL线
  void paintBollLine(Canvas canvas, Size size) {
    if (!klineData.canPaintChart) return;
    if (!indicator.calcParam.isValid) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = (klineData.end + 1).clamp(start, list.length); // 多绘制一根蜡烛

    final List<Offset> mbPoints = [];
    final List<Offset> upPoints = [];
    final List<Offset> dnPoints = [];
    final offset = startCandleDx - candleWidthHalf;

    CandleModel m;
    for (int i = start; i < end; i++) {
      m = list[i];
      if (!m.isValidBollData) continue;
      final dx = offset - (i - start) * candleActualWidth;
      mbPoints.add(Offset(dx, valueToDy(m.mb!, correct: false)));
      upPoints.add(Offset(dx, valueToDy(m.up!, correct: false)));
      dnPoints.add(Offset(dx, valueToDy(m.dn!, correct: false)));
    }

    canvas.drawPath(
      Path()..addPolygon(mbPoints, false),
      Paint()
        ..color = indicator.mbTips.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = indicator.lineWidth,
    );

    canvas.drawPath(
      Path()..addPolygon(upPoints, false),
      Paint()
        ..color = indicator.upTips.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = indicator.lineWidth,
    );

    canvas.drawPath(
      Path()..addPolygon(dnPoints, false),
      Paint()
        ..color = indicator.dnTips.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = indicator.lineWidth,
    );

    if (indicator.isFillBetweenUpAndDn) {
      canvas.drawPath(
        Path()..addPolygon([...upPoints, ...dnPoints.reversed], false),
        Paint()
          ..color = indicator.fillColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    model ??= offsetToCandle(offset);
    if (model == null || !model.isValidBollData) return null;

    final precision = klineData.precision;
    final children = <TextSpan>[];

    children.add(TextSpan(
      text: formatNumber(
        model.mb?.toDecimal(),
        precision: indicator.mbTips.getP(precision),
        cutInvalidZero: true,
        prefix: indicator.mbTips.label,
        suffix: ' ',
      ),
      style: indicator.mbTips.style,
    ));

    children.add(TextSpan(
      text: formatNumber(
        model.up?.toDecimal(),
        precision: indicator.upTips.getP(precision),
        cutInvalidZero: true,
        prefix: indicator.upTips.label,
        suffix: ' ',
      ),
      style: indicator.upTips.style,
    ));

    children.add(TextSpan(
      text: formatNumber(
        model.dn?.toDecimal(),
        precision: indicator.dnTips.getP(precision),
        cutInvalidZero: true,
        prefix: indicator.dnTips.label,
        suffix: ' ',
      ),
      style: indicator.dnTips.style,
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
