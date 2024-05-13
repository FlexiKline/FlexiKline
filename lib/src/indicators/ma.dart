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
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../utils/export.dart';

part 'ma.g.dart';

@FlexiParamSerializable
final class MaParam {
  final String label;
  final int count;
  final Color color;

  const MaParam({
    required this.label,
    required this.count,
    required this.color,
  });

  factory MaParam.fromJson(Map<String, dynamic> json) =>
      _$MaParamFromJson(json);
  Map<String, dynamic> toJson() => _$MaParamToJson(this);
}

/// MA 移动平均指标线
@FlexiIndicatorSerializable
class MAIndicator extends SinglePaintObjectIndicator {
  MAIndicator({
    super.key = maKey,
    super.name = 'MA',
    required super.height,
    super.tipsHeight = defaultIndicatorTipsHeight,
    super.padding,
    this.calcParams = const [
      MaParam(label: 'MA7', count: 7, color: Color(0xFF946F9A)),
      MaParam(label: 'MA30', count: 30, color: Color(0xFFF1BF32))
    ],
  });

  final List<MaParam> calcParams;

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

    MinMax? minmax = klineData.calcuMaMinmax(
      indicator.calcParams,
      start: start,
      end: end,
    );
    return minmax;
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

    for (int j = 0; j < indicator.calcParams.length; j++) {
      final offset = startCandleDx - candleWidthHalf;
      BagNum? val;
      final List<Offset> points = [];
      for (int i = start; i < end; i++) {
        val = list[i].maRets?.getItem(j);
        if (val == null) continue;
        points.add(Offset(
          offset - (i - start) * candleActualWidth,
          valueToDy(val, correct: false),
        ));
      }

      canvas.drawPath(
        Path()..addPolygon(points, false),
        Paint()
          ..color = indicator.calcParams[j].color
          ..style = PaintingStyle.stroke
          ..strokeWidth = setting.indicatorLineWidth,
      );
    }
  }

  /// MA 绘制tips区域
  @override
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    if (indicator.tipsHeight <= 0) return null;
    model ??= offsetToCandle(offset);
    if (model == null || !model.isValidMaRets) return null;

    Rect drawRect = nextTipsRect;

    final children = <TextSpan>[];
    BagNum? val;
    for (int i = 0; i < model.maRets!.length; i++) {
      val = model.maRets![i];
      if (val == null) continue;
      final param = indicator.calcParams.getItem(i);
      if (param == null) continue;

      final text = formatNumber(
        val.toDecimal(),
        precision: state.curKlineData.req.precision,
        cutInvalidZero: true,
        prefix: '${param.label}: ',
        suffix: '  ',
      );
      children.add(TextSpan(
        text: text,
        style: setting.tipsTextStyle.copyWith(color: param.color),
      ));
    }
    if (children.isNotEmpty) {
      return canvas.drawText(
        offset: drawRect.topLeft,
        textSpan: TextSpan(children: children),
        drawDirection: DrawDirection.ltr,
        drawableRect: drawRect,
        textAlign: TextAlign.left,
        padding: setting.tipsPadding,
        maxLines: 1,
      );
    }
    return null;
  }
}

// class MAPaintObject2<T extends MAIndicator> extends SinglePaintObjectBox<T> {
//   MAPaintObject2({
//     required super.controller,
//     required super.indicator,
//   });

//   @override
//   MinMax? initData({int? start, int? end}) {
//     if (!klineData.canPaintChart) return null;

//     MinMax? minmax;
//     for (var param in indicator.calcParams) {
//       final ret = klineData.calculateMaMinmax(param.count);
//       minmax ??= ret;
//       minmax?.updateMinMax(ret);
//     }
//     return minmax;
//   }

//   @override
//   void paintChart(Canvas canvas, Size size) {
//     paintMALine(canvas, size);
//   }

//   @override
//   void onCross(Canvas canvas, Offset offset) {
//     ///
//   }

//   /// 绘制MA指标线
//   void paintMALine(Canvas canvas, Size size) {
//     if (!klineData.canPaintChart) return;
//     final list = klineData.list;
//     int start = klineData.start;
//     int end = (klineData.end + 1).clamp(start, list.length); // 多绘制一根蜡烛

//     // try {
//     //   // 保存画布状态
//     //   canvas.save();
//     //   // 裁剪绘制范围
//     //   canvas.clipRect(setting.mainDrawRect);

//     for (var param in indicator.calcParams) {
//       final maMap = klineData.getMaMap(param.count);
//       if (maMap.isEmpty) continue;

//       final offset = startCandleDx - candleWidthHalf;
//       CandleModel m;
//       MaResult? ret;
//       final List<Offset> points = [];
//       for (int i = start; i < end; i++) {
//         m = list[i];
//         final dx = offset - (i - start) * candleActualWidth;
//         ret = maMap[m.timestamp];
//         ret ??= klineData.calculateMa(i, param.count);
//         if (ret == null) continue;
//         final dy = valueToDy(ret.val, correct: false);
//         points.add(Offset(dx, dy));
//       }

//       canvas.drawPath(
//         Path()..addPolygon(points, false),
//         Paint()
//           ..color = param.color
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = setting.paintLineStrokeDefaultWidth,
//       );
//     }
//     // } finally {
//     //   // 恢复画布状态
//     //   canvas.restore();
//     // }
//   }

//   /// MA 绘制tips区域
//   @override
//   Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
//     if (indicator.tipsHeight <= 0) return null;
//     model ??= offsetToCandle(offset);
//     if (model == null) return null;

//     Rect drawRect = nextTipsRect;

//     final children = <TextSpan>[];
//     for (var param in indicator.calcParams) {
//       final ret = klineData.getMaResult(
//         count: param.count,
//         ts: model.timestamp,
//       );
//       if (ret == null) continue;

//       final text = formatNumber(
//         ret.val,
//         precision: state.curKlineData.req.precision,
//         cutInvalidZero: true,
//         prefix: '${param.label}: ',
//         suffix: '  ',
//       );
//       children.add(TextSpan(
//         text: text,
//         style: TextStyle(
//           fontSize: setting.tipsDefaultTextSize,
//           color: param.color,
//           height: setting.tipsDefaultTextHeight,
//         ),
//       ));
//     }

//     if (children.isNotEmpty) {
//       return canvas.drawText(
//         offset: drawRect.topLeft,
//         textSpan: TextSpan(children: children),
//         drawDirection: DrawDirection.ltr,
//         drawableRect: drawRect,
//         textAlign: TextAlign.left,
//         padding: setting.tipsRectDefaultPadding,
//         maxLines: 1,
//       );
//     }
//     return null;
//   }
// }
