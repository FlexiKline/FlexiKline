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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

part 'avl_indicator.g.dart';

/// 主区 - 均价线
/// 均价线(AVL)AVL = 某日总成交金额/某日总成交股数其计算结果就是每股平均的成交价格。
/// AVL反映当日的真实股票价格情况，避免主力庄家的骗线图形。均价线是超级短线实战的一个重要研判工具。
@FlexiIndicatorSerializable
class AVLIndicator extends SinglePaintObjectIndicator {
  AVLIndicator({
    super.key = const ValueKey('AVL'),
    super.name = 'AVL',
    super.zIndex = 0,
    required super.height,
    required super.padding,
    required this.line,
    required this.tips,
    required this.tipsPadding,
  });

  final LineConfig line;
  final TipsConfig tips;
  final EdgeInsets tipsPadding;

  @override
  AVLPaintObject createPaintObject(covariant KlineBindingBase controller) {
    return AVLPaintObject(controller: controller, indicator: this);
  }

  factory AVLIndicator.fromJson(Map<String, dynamic> json) =>
      _$AVLIndicatorFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$AVLIndicatorToJson(this);
}

class AVLPaintObject extends SinglePaintObjectBox<AVLIndicator> {
  AVLPaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initState({required int start, required int end}) {
    return null;
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    return;
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    if (!klineData.canPaintChart) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = (klineData.end + 1).clamp(start, list.length);

    final List<Offset> points = [];

    CandleModel m;
    for (var i = start; i < end; i++) {
      m = list[i];
      if (m.volCcy != null && !m.vol.isZero) {
        points.add(Offset(
          indexToDx(i, check: false)!,
          valueToDy(m.volCcy!.div(m.vol)),
        ));
      }
    }

    canvas.drawLineType(
      indicator.line.type,
      Path()..addPolygon(points, false),
      indicator.line.linePaint,
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
    if (model == null || !model.isValidKdjData) return null;

    final precision = klineData.req.precision;
    if (model.volCcy != null && !model.vol.isZero) {
      final text = formatNumber(
        model.volCcy!.div(model.vol).toDecimal(),
        precision: indicator.tips.getP(precision),
        cutInvalidZero: true,
        prefix: indicator.tips.label,
      );
      tipsRect ??= drawableRect;
      return canvas.drawText(
        offset: tipsRect.topLeft,
        text: text,
        style: indicator.tips.style,
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
