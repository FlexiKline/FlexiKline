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

part 'boll.g.dart';

@FlexiParamSerializable
final class BOLLParam {
  final int n;
  final int std;

  const BOLLParam({required this.n, required this.std});

  bool get isValid => n > 0 && std > 0;

  @override
  int get hashCode => n.hashCode ^ std.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BOLLParam &&
          runtimeType == other.runtimeType &&
          n == other.n &&
          std == other.std;

  @override
  String toString() {
    return 'BOLLParam{n:$n, std:$std}';
  }

  factory BOLLParam.fromJson(Map<String, dynamic> json) =>
      _$BOLLParamFromJson(json);
  Map<String, dynamic> toJson() => _$BOLLParamToJson(this);
}

@FlexiIndicatorSerializable
class BOLLIndicator extends SinglePaintObjectIndicator {
  BOLLIndicator({
    super.key = bollKey,
    super.name = 'BOLL',
    required super.height,
    super.tipsHeight = defaultIndicatorTipsHeight,
    super.padding,
    this.calcParam = const BOLLParam(n: 20, std: 2),
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
  final BOLLParam calcParam;
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
  MinMax? initData({int? start, int? end}) {
    if (!klineData.canPaintChart) return null;

    return klineData.calculateBollMinmax(
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
    final bollMap = klineData.getBollMap(indicator.calcParam);
    if (bollMap.isEmpty || !klineData.canPaintChart) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = (klineData.end + 1).clamp(start, list.length); // 多绘制一根蜡烛

    BollResult? ret;
    final List<Offset> mbPoints = [];
    final List<Offset> upPoints = [];
    final List<Offset> dnPoints = [];
    final offset = startCandleDx - candleWidthHalf;
    for (int i = start; i < end; i++) {
      ret = bollMap[list[i].timestamp];
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

    final ret = klineData.getBollResult(
      param: indicator.calcParam,
      ts: model.timestamp,
    );
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
