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

import '../core/export.dart';
import '../data/export.dart';
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../utils/export.dart';

/// EMA 平滑移动平均线
/// 公式：
/// 1）快速平滑移动平均线（EMA）是12日的，计算公式为：
///   EMA(12)=2*今收盘价/(12+1)+11*昨日EMA(12)/(12+1)
/// 2）慢速平滑移动平均线（EMA）是26日的，计算公式为：
///   EMA(26)=2*今收盘价/(26+1)+25*昨日EMA(26)/(26+1)
class EMAIndicator extends SinglePaintObjectIndicator {
  EMAIndicator({
    super.key = const ValueKey(IndicatorType.ema),
    required super.height,
    super.tipsHeight,
    super.padding,
    required this.calcParams,
  });

  final List<EMAParam> calcParams;

  @override
  SinglePaintObjectBox createPaintObject(KlineBindingBase controller) {
    return EMAPaintObject(controller: controller, indicator: this);
  }
}

class EMAPaintObject extends SinglePaintObjectBox<EMAIndicator> {
  EMAPaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initData({
    required List<CandleModel> list,
    required int start,
    required int end,
  }) {
    if (list.isEmpty || start < 0 || end >= list.length) return null;
    MinMax? minMax;
    for (var param in indicator.calcParams) {
      final ret = klineData.calculateAndCacheEMA(
        list,
        param.count,
        start: start,
        end: end,
      );
      minMax ??= ret;
      minMax?.updateMinMax(ret);
    }
    return minMax;
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    paintEMALine(canvas, size);

    // if (!cross.isCrossing) {
    //   paintTips(canvas, model: state.curKlineData.latest);
    // }
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    if (indicator.tipsHeight <= 0) return;

    // paintTips(canvas, offset: offset);
  }

  /// 绘制EMA线
  void paintEMALine(Canvas canvas, Size size) {
    final data = klineData;
    if (data.list.isEmpty) return;
    int start = data.start;
    int end = data.end;

    try {
      /// 保存画布状态
      canvas.save();

      /// 裁剪绘制范围
      canvas.clipRect(setting.mainDrawRect);

      for (var param in indicator.calcParams) {
        final emaMap = klineData.getCountEmaMap(param.count);
        if (emaMap.isEmpty) continue;

        final offset = startCandleDx - candleWidthHalf;
        CandleModel m;
        final List<Offset> points = [];
        for (int i = start; i < end; i++) {
          m = data.list[i];
          final dx = offset - (i - start) * candleActualWidth;
          final emaData = emaMap[m.timestamp];
          if (emaData == null) continue;
          final dy = valueToDy(emaData.val, correct: false);
          points.add(Offset(dx, dy));
        }

        canvas.drawPath(
          Path()..addPolygon(points, false),
          Paint()
            ..color = param.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = setting.maLineStrokeWidth,
        );
      }
    } finally {
      /// 恢复画布状态
      canvas.restore();
    }
  }

  /// EMA 绘制tips区域
  @override
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    model ??= offsetToCandle(offset);
    if (model == null) return null;

    Rect drawRect = nextTipsRect;

    final children = <TextSpan>[];
    for (var param in indicator.calcParams) {
      final emaMap = klineData.getCountEmaMap(param.count);
      if (emaMap.isEmpty) continue;

      final emaData = emaMap.getItem(model.timestamp);
      if (emaData != null) {
        final text = formatNumber(
          emaData.val,
          precision: state.curKlineData.req.precision,
          cutInvalidZero: true,
          prefix: '${param.label}: ',
          suffix: '  ',
        );
        children.add(TextSpan(
          text: text,
          style: TextStyle(
            fontSize: setting.maTipsFontSize,
            color: param.color,
            height: drawRect.height / setting.maTipsFontSize,
            // height: 1.2,
          ),
        ));
      }
    }
    if (children.isNotEmpty) {
      return canvas.drawText(
        offset: drawRect.topLeft,
        textSpan: TextSpan(children: children),
        drawDirection: DrawDirection.ltr,
        drawableRect: drawRect,
        textAlign: TextAlign.left,
        padding: setting.maTipsRectPadding,
        maxLines: 1,
      );
    }
    return null;
  }
}
