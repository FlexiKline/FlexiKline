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
import '../data/export.dart';
import '../extension/export.dart';
import '../model/export.dart';
import '../utils/export.dart';
import '../framework/export.dart';

class BOLLIndicator extends SinglePaintObjectIndicator {
  BOLLIndicator({
    super.key = const ValueKey(IndicatorType.boll),
    required super.height,
    super.tipsHeight = defaultIndicatorTipsHeight,
    super.padding,
    this.mid = 20,
    this.std = 2,
    this.mbColor = const Color(0xFF886787),
    this.upColor = const Color(0xFFF0B527),
    this.dnColor = const Color(0xFFD85BE0),
    this.mbLabel = 'BOLL(20):',
    this.upLabel = 'UB:',
    this.dnLabel = 'LB:',
    this.precision,
    this.isFillBetweenUpAndDn = true,
    Color? fillColor,
  }) : fillColor = fillColor ?? mbColor.withOpacity(0.1);

  // BOLL相关参数
  final int mid;
  final int std;
  final Color mbColor;
  final Color upColor;
  final Color dnColor;
  final String mbLabel;
  final String upLabel;
  final String dnLabel;

  /// 绘制相关参数
  // 精度, 如果未提供, 使用当前币种精度
  final int? precision;
  // 是否将up和dn之间填充半透明色
  final bool isFillBetweenUpAndDn;
  // 默认是mbColor的0.1不透明度.
  final Color fillColor;

  @override
  BOLLPaintObject createPaintObject(KlineBindingBase controller) {
    return BOLLPaintObject(controller: controller, indicator: this);
  }
}

class BOLLPaintObject extends SinglePaintObjectBox<BOLLIndicator> {
  BOLLPaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initData({
    required List<CandleModel> list,
    required int start,
    required int end,
  }) {
    final minmax = klineData.calculateAndCacheBOLL(
      n: indicator.mid,
      std: indicator.std,
    );
    return minmax;
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
    final data = klineData;
    if (data.list.isEmpty) return;
    int start = data.start;
    int end = (data.end + 1).clamp(start, data.list.length); // 多绘制一根蜡烛
    BOLLResult? ret;
    final List<Offset> mbPoints = [];
    final List<Offset> upPoints = [];
    final List<Offset> dnPoints = [];
    final offset = startCandleDx - candleWidthHalf;
    for (int i = start; i < end; i++) {
      ret = klineData.getBollResult(data.list[i].timestamp);
      if (ret == null) continue;
      final dx = offset - (i - start) * candleActualWidth;
      mbPoints.add(Offset(dx, valueToDy(ret.mb, correct: false)));
      upPoints.add(Offset(dx, valueToDy(ret.up, correct: false)));
      dnPoints.add(Offset(dx, valueToDy(ret.dn, correct: false)));
    }

    canvas.drawPath(
      Path()..addPolygon(mbPoints, false),
      Paint()
        ..color = indicator.mbColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = setting.paintLineStrokeDefaultWidth,
    );

    canvas.drawPath(
      Path()..addPolygon(upPoints, false),
      Paint()
        ..color = indicator.upColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = setting.paintLineStrokeDefaultWidth,
    );

    canvas.drawPath(
      Path()..addPolygon(dnPoints, false),
      Paint()
        ..color = indicator.dnColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = setting.paintLineStrokeDefaultWidth,
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
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    if (indicator.tipsHeight <= 0) return null;
    model ??= offsetToCandle(offset);
    if (model == null) return null;

    final ret = klineData.getBollResult(model.timestamp);
    if (ret == null) return null;

    final precision = indicator.precision ?? klineData.precision;
    Rect drawRect = nextTipsRect;
    final children = <TextSpan>[];

    final mbTxt = formatNumber(
      ret.mb,
      precision: precision,
      cutInvalidZero: true,
      prefix: indicator.mbLabel,
      suffix: ' ',
    );
    final upTxt = formatNumber(
      ret.up,
      precision: precision,
      cutInvalidZero: true,
      prefix: indicator.upLabel,
      suffix: ' ',
    );
    final dnTxt = formatNumber(
      ret.dn,
      precision: precision,
      cutInvalidZero: true,
      prefix: indicator.dnLabel,
      suffix: ' ',
    );

    children.add(TextSpan(
      text: mbTxt,
      style: TextStyle(
        fontSize: setting.tipsDefaultTextSize,
        color: indicator.mbColor,
        height: setting.tipsDefaultTextHeight,
      ),
    ));

    children.add(TextSpan(
      text: upTxt,
      style: TextStyle(
        fontSize: setting.tipsDefaultTextSize,
        color: indicator.upColor,
        height: setting.tipsDefaultTextHeight,
      ),
    ));

    children.add(TextSpan(
      text: dnTxt,
      style: TextStyle(
        fontSize: setting.tipsDefaultTextSize,
        color: indicator.dnColor,
        height: setting.tipsDefaultTextHeight,
      ),
    ));

    return canvas.drawText(
      offset: drawRect.topLeft,
      textSpan: TextSpan(children: children),
      drawDirection: DrawDirection.ltr,
      drawableRect: drawRect,
      textAlign: TextAlign.left,
      padding: setting.tipsRectDefaultPadding,
      maxLines: 1,
    );
  }
}
