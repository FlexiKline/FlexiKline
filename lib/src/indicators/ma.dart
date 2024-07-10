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
import '../data/export.dart';
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../utils/export.dart';

part 'ma.g.dart';

/// MA 移动平均指标线
@CopyWith()
@FlexiIndicatorSerializable
class MAIndicator extends SinglePaintObjectIndicator implements IPrecomputable {
  MAIndicator({
    super.key = maKey,
    super.name = 'MA',
    super.zIndex = 0,
    required super.height,
    super.padding = defaultMainIndicatorPadding,
    required this.calcParams,
    required this.tipsPadding,
    required this.lineWidth,
  });

  final List<MaParam> calcParams;
  final EdgeInsets tipsPadding;
  final double lineWidth;

  @override
  dynamic getCalcParam() => calcParams;

  @override
  SinglePaintObjectBox createPaintObject(KlineBindingBase controller) {
    return MAPaintObject(controller: controller, indicator: this);
  }

  factory MAIndicator.fromJson(Map<String, dynamic> json) =>
      _$MAIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MAIndicatorToJson(this);
}

class MAPaintObject<T extends MAIndicator> extends SinglePaintObjectBox<T> {
  MAPaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initState({required int start, required int end}) {
    if (!klineData.canPaintChart) return null;

    return klineData.calcuMaMinmax(
      indicator.calcParams,
      start: start,
      end: end,
    );
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    paintMALine(canvas, size);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    ///
  }

  /// 绘制MA指标线
  void paintMALine(Canvas canvas, Size size) {
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
        val = list[i].maList?.getItem(j);
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
    if (model == null || !model.isValidMaList) return null;

    final children = <TextSpan>[];
    BagNum? val;
    for (int i = 0; i < model.maList!.length; i++) {
      val = model.maList?.getItem(i);
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
