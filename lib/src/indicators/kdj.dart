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

part 'kdj.g.dart';

///
/// KDJ (9, 3, 3)
/// 当日K值=2/3×前一日K值+1/3×当日RSV
/// 当日D值=2/3×前一日D值+1/3×当日K值
/// 若无前一日K 值与D值，则可分别用50来代替。
/// J值=3*当日K值-2*当日D值
@CopyWith()
@FlexiIndicatorSerializable
class KDJIndicator extends SinglePaintObjectIndicator
    implements IPrecomputable {
  KDJIndicator({
    super.key = const ValueKey(IndicatorType.kdj),
    super.name = 'KDJ',
    super.zIndex = 0,
    super.height = defaultSubIndicatorHeight,
    super.padding = defaultSubIndicatorPadding,

    /// KDJ计算参数
    this.calcParam = const KDJParam(n: 9, m1: 3, m2: 3),

    /// 绘制相关参数
    required this.ktips,
    required this.dtips,
    required this.jtips,
    required this.tipsPadding,
    this.tickCount = defaultSubTickCount,
    required this.lineWidth,
    this.precision = 2,
  });

  /// KDJ计算参数
  final KDJParam calcParam;

  /// 绘制相关参数
  final TipsConfig ktips;
  final TipsConfig dtips;
  final TipsConfig jtips;
  final EdgeInsets tipsPadding;
  final int tickCount;
  final double lineWidth;
  // 默认精度
  final int precision;

  @override
  dynamic getCalcParam() => calcParam;

  @override
  KDJPaintObject createPaintObject(KlineBindingBase controller) {
    return KDJPaintObject(controller: controller, indicator: this);
  }

  factory KDJIndicator.fromJson(Map<String, dynamic> json) =>
      _$KDJIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$KDJIndicatorToJson(this);
}

class KDJPaintObject<T extends KDJIndicator> extends SinglePaintObjectBox<T>
    with PaintYAxisScaleMixin, PaintYAxisMarkOnCrossMixin {
  KDJPaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initState({required int start, required int end}) {
    if (!klineData.canPaintChart) return null;

    return klineData.calcuKdjMinmax(
      param: indicator.calcParam,
      start: start,
      end: end,
    );
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    /// 绘制KDJ线
    paintKDJLine(canvas, size);

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

  void paintKDJLine(Canvas canvas, Size size) {
    if (!klineData.canPaintChart) return;
    final list = klineData.list;
    final len = list.length;
    if (!indicator.calcParam.isValid(len)) return;
    int start = klineData.start;
    int end = (klineData.end + 1).clamp(start, len); // 多绘制一根蜡烛

    final List<Offset> kPoints = [];
    final List<Offset> dPoints = [];
    final List<Offset> jPoints = [];
    final offset = startCandleDx - candleWidthHalf;

    CandleModel m;
    for (int i = start; i < end; i++) {
      m = list[i];
      if (!m.isValidKdjData) continue;
      final dx = offset - (i - start) * candleActualWidth;
      kPoints.add(Offset(dx, valueToDy(m.k!, correct: false)));
      dPoints.add(Offset(dx, valueToDy(m.d!, correct: false)));
      jPoints.add(Offset(dx, valueToDy(m.j!, correct: false)));
    }

    canvas.drawPath(
      Path()..addPolygon(kPoints, false),
      Paint()
        ..color = indicator.ktips.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = indicator.lineWidth,
    );

    canvas.drawPath(
      Path()..addPolygon(dPoints, false),
      Paint()
        ..color = indicator.dtips.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = indicator.lineWidth,
    );

    canvas.drawPath(
      Path()..addPolygon(jPoints, false),
      Paint()
        ..color = indicator.jtips.color
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
    if (model == null || !model.isValidKdjData) return null;

    final precision = indicator.precision;
    final children = <TextSpan>[];

    children.add(TextSpan(
      text: formatNumber(
        model.k?.toDecimal(),
        precision: indicator.ktips.getP(precision),
        cutInvalidZero: true,
        prefix: indicator.ktips.label,
        suffix: ' ',
      ),
      style: indicator.ktips.style,
    ));

    children.add(TextSpan(
      text: formatNumber(
        model.d?.toDecimal(),
        precision: indicator.dtips.getP(precision),
        cutInvalidZero: true,
        prefix: indicator.dtips.label,
        suffix: ' ',
      ),
      style: indicator.dtips.style,
    ));

    children.add(TextSpan(
      text: formatNumber(
        model.j?.toDecimal(),
        precision: indicator.jtips.getP(precision),
        cutInvalidZero: true,
        prefix: indicator.jtips.label,
        suffix: ' ',
      ),
      style: indicator.jtips.style,
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
