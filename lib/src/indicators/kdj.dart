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
import '../framework/export.dart';
import '../model/export.dart';
import '../utils/export.dart';

part 'kdj.g.dart';

@FlexiParamSerializable
final class KDJParam {
  final int n;
  final int m1;
  final int m2;

  const KDJParam({required this.n, required this.m1, required this.m2});

  bool get isValid => n > 0 && m1 > 0 && m2 > 0;

  @override
  int get hashCode => n.hashCode ^ m1.hashCode ^ m2.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KDJParam &&
          runtimeType == other.runtimeType &&
          n == other.n &&
          m1 == other.m1 &&
          m2 == other.m2;

  @override
  String toString() {
    return 'KDJParam{n:$n, m1:$m1, m2:$m2}';
  }

  factory KDJParam.fromJson(Map<String, dynamic> json) =>
      _$KDJParamFromJson(json);
  Map<String, dynamic> toJson() => _$KDJParamToJson(this);
}

///
/// KDJ (9, 3, 3)
/// 当日K值=2/3×前一日K值+1/3×当日RSV
/// 当日D值=2/3×前一日D值+1/3×当日K值
/// 若无前一日K 值与D值，则可分别用50来代替。
/// J值=3*当日K值-2*当日D值
@FlexiIndicatorSerializable
class KDJIndicator extends SinglePaintObjectIndicator {
  KDJIndicator({
    super.key = const ValueKey(IndicatorType.kdj),
    super.name = 'KDJ',
    required super.height,
    super.tipsHeight = defaultIndicatorTipsHeight,
    super.padding,
    this.calcParam = const KDJParam(n: 9, m1: 3, m2: 3),
    this.kColor = const Color(0xFF7A5C79),
    this.dColor = const Color(0xFFFABD3F),
    this.jColor = const Color(0xFFBB72CA),
    this.tickCount,
    this.precision = 2,
  });

  final KDJParam calcParam;
  final Color kColor;
  final Color dColor;
  final Color jColor;

  /// 绘制相关参数
  final int? tickCount;
  final int precision;

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
    with PaintYAxisTickMixin, PaintYAxisMarkOnCrossMixin {
  KDJPaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initData({int? start, int? end}) {
    if (!klineData.canPaintChart) return null;

    return klineData.calculateKdjMinmax(
      param: indicator.calcParam,
    );
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    /// 绘制Y轴刻度值
    paintYAxisTick(
      canvas,
      size,
      tickCount: indicator.tickCount ?? setting.subChartYAxisTickCount,
    );

    /// 绘制KDJ线
    paintKDJLine(canvas, size);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    /// onCross时, 绘制Y轴上的标记值
    paintYAxisMarkOnCross(canvas, offset);
  }

  void paintKDJLine(Canvas canvas, Size size) {
    final kdjMap = klineData.getKdjMap(indicator.calcParam);
    if (kdjMap.isEmpty || !klineData.canPaintChart) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = (klineData.end + 1).clamp(start, list.length); // 多绘制一根蜡烛

    KdjReset? ret;
    final List<Offset> kPoints = [];
    final List<Offset> dPoints = [];
    final List<Offset> jPoints = [];
    final offset = startCandleDx - candleWidthHalf;
    for (int i = start; i < end; i++) {
      ret = kdjMap[list[i].timestamp];
      if (ret == null) continue;
      final dx = offset - (i - start) * candleActualWidth;
      kPoints.add(Offset(dx, valueToDy(ret.k, correct: false)));
      dPoints.add(Offset(dx, valueToDy(ret.d, correct: false)));
      jPoints.add(Offset(dx, valueToDy(ret.j, correct: false)));
    }

    canvas.drawPath(
      Path()..addPolygon(kPoints, false),
      Paint()
        ..color = indicator.kColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = setting.paintLineStrokeDefaultWidth,
    );

    canvas.drawPath(
      Path()..addPolygon(dPoints, false),
      Paint()
        ..color = indicator.dColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = setting.paintLineStrokeDefaultWidth,
    );

    canvas.drawPath(
      Path()..addPolygon(jPoints, false),
      Paint()
        ..color = indicator.jColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = setting.paintLineStrokeDefaultWidth,
    );
  }

  @override
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    if (indicator.tipsHeight <= 0) return null;
    model ??= offsetToCandle(offset);
    if (model == null) return null;

    final ret = klineData.getKdjResult(
      param: indicator.calcParam,
      ts: model.timestamp,
    );
    if (ret == null) return null;

    Rect drawRect = nextTipsRect;
    final children = <TextSpan>[];

    final kTxt = formatNumber(
      ret.k,
      precision: indicator.precision,
      cutInvalidZero: true,
      prefix: 'K: ',
      suffix: ' ',
    );
    final dTxt = formatNumber(
      ret.d,
      precision: indicator.precision,
      cutInvalidZero: true,
      prefix: 'D: ',
      suffix: ' ',
    );
    final jTxt = formatNumber(
      ret.j,
      precision: indicator.precision,
      cutInvalidZero: true,
      prefix: 'J: ',
      suffix: ' ',
    );

    children.add(TextSpan(
      text: kTxt,
      style: TextStyle(
        fontSize: setting.tipsDefaultTextSize,
        color: indicator.kColor,
        height: setting.tipsDefaultTextHeight,
      ),
    ));

    children.add(TextSpan(
      text: dTxt,
      style: TextStyle(
        fontSize: setting.tipsDefaultTextSize,
        color: indicator.dColor,
        height: setting.tipsDefaultTextHeight,
      ),
    ));

    children.add(TextSpan(
      text: jTxt,
      style: TextStyle(
        fontSize: setting.tipsDefaultTextSize,
        color: indicator.jColor,
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
