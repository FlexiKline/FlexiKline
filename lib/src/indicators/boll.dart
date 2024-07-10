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
import '../model/export.dart';
import '../utils/export.dart';
import '../framework/export.dart';

part 'boll.g.dart';

@CopyWith()
@FlexiIndicatorSerializable
class BOLLIndicator extends SinglePaintObjectIndicator
    implements IPrecomputable {
  BOLLIndicator({
    required super.key,
    super.name = 'BOLL',
    super.zIndex = 0,
    required super.height,
    super.padding = defaultMainIndicatorPadding,

    /// BOLL计算参数
    this.calcParam = const BOLLParam(n: 20, std: 2),

    /// 绘制相关参数
    required this.mbTips,
    required this.upTips,
    required this.dnTips,
    required this.tipsPadding,
    required this.lineWidth,

    /// 填充配置
    this.isFillBetweenUpAndDn = true,
    Color? fillColor,

    /// YAxis刻度数量(注: 仅在key为subBollKey时有用)
    this.tickCount = defaultSubTickCount,
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

  /// YAxis刻度数量(注: 仅在key为subBollKey时有用)
  final int tickCount;

  @override
  dynamic getCalcParam() => calcParam;

  @override
  BOLLPaintObject createPaintObject(KlineBindingBase controller) {
    return BOLLPaintObject(controller: controller, indicator: this);
  }

  factory BOLLIndicator.fromJson(Map<String, dynamic> json) =>
      _$BOLLIndicatorFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$BOLLIndicatorToJson(this);
}

class BOLLPaintObject<T extends BOLLIndicator> extends SinglePaintObjectBox<T>
    with
        PaintYAxisScaleMixin,
        PaintYAxisMarkOnCrossMixin,
        PaintSimpleCandleMixin {
  BOLLPaintObject({
    required super.controller,
    required super.indicator,
  });

  bool? _isInsub;
  bool get isInSub => _isInsub ??= indicator.key == subBollKey;

  @override
  MinMax? initState({required int start, required int end}) {
    if (!klineData.canPaintChart) return null;

    MinMax? bollMinmax = klineData.calcuBollMinmax(
      param: indicator.calcParam,
      start: start,
      end: end,
    );
    if (isInSub) {
      MinMax? candleMinmax = klineData.calculateMinmax(start: start, end: end);
      if (candleMinmax != null) return candleMinmax..updateMinMax(bollMinmax);
      if (bollMinmax != null) return bollMinmax..updateMinMax(candleMinmax);
      return null;
    } else {
      return bollMinmax;
    }
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    /// 绘制BOLL图
    paintBollChart(canvas, size);

    if (isInSub && settingConfig.showYAxisTick) {
      paintYAxisScale(
        canvas,
        size,
        tickCount: indicator.tickCount,
        precision: klineData.precision,
      );
    }
  }

  /// 重写[paintYAxisScale]中的格式化刻度值.
  @override
  String fromatTickValue(BagNum value, {required int precision}) {
    return formatPrice(
      value.toDecimal(),
      precision: precision,
      cutInvalidZero: false,
      showThousands: true,
    );
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    /// onCross时, 绘制Y轴上的标记值(注: 仅对indicator.key为subBollKey时有效)
    if (isInSub) {
      paintYAxisMarkOnCross(
        canvas,
        offset,
        precision: klineData.precision,
      );
    }
  }

  /// 在onCross时, 重写[paintYAxisMarkOnCross]中的格式化刻度值
  @override
  String formatMarkValueOnCross(BagNum value, {required int precision}) {
    return formatPrice(
      value.toDecimal(),
      precision: precision,
      cutInvalidZero: false,
      showThousands: true,
    );
  }

  /// 绘制BOLL线
  void paintBollChart(Canvas canvas, Size size) {
    if (!klineData.canPaintChart) return;
    final list = klineData.list;
    final len = list.length;
    if (!indicator.calcParam.isValid(len)) return;
    int start = klineData.start;
    int end = (klineData.end + 1).clamp(start, len); // 多绘制一根蜡烛

    if (isInSub) {
      // 绘制简易蜡烛
      paintSimpleCandleChart(canvas, size);
    }

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
