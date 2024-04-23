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
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../render/export.dart';
import '../utils/export.dart';

/// MA 移动平均指标线
class MAIndicator extends SinglePaintObjectIndicator {
  MAIndicator({
    super.key = const ValueKey(IndicatorType.ma),
    required super.height,
    super.tipsHeight,
    super.padding,
    required this.calcParams,
  });

  final List<MaParam> calcParams;

  @override
  SinglePaintObjectBox createPaintObject(KlineBindingBase controller) {
    return MAPaintObject(controller: controller, indicator: this);
  }
}

class MAPaintObject extends SinglePaintObjectBox<MAIndicator> {
  MAPaintObject({
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
      final ret = calcuMgr.calculateAndCacheMA(
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
    paintMALine(canvas, size);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    // if (indicator.tipsHeight <= 0) return;
  }

  /// 绘制MA指标线
  void paintMALine(Canvas canvas, Size size) {
    final data = klineData;
    if (data.list.isEmpty) return;
    int start = data.start;
    int end = (data.end + 1).clamp(start, data.list.length); // 多绘制一根蜡烛

    // try {
    //   // 保存画布状态
    //   canvas.save();
    //   // 裁剪绘制范围
    //   canvas.clipRect(setting.mainDrawRect);
    for (var param in indicator.calcParams) {
      final countMaMap = calcuMgr.getCountMaMap(param.count);
      if (countMaMap.isEmpty) continue;

      final offset = startCandleDx - candleWidthHalf;
      CandleModel m;
      final List<Offset> points = [];
      for (int i = start; i < end; i++) {
        m = data.list[i];
        final dx = offset - (i - start) * candleActualWidth;
        CalcuData? maData = countMaMap[m.timestamp];
        maData ??= calcuMgr.calculateMA(data.list, i, param.count);
        final dy = valueToDy(maData.val, correct: false);
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
    // } finally {
    //   // 恢复画布状态
    //   canvas.restore();
    // }
  }

  /// MA 绘制tips区域
  @override
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    model ??= offsetToCandle(offset);
    if (model == null) return null;

    Rect drawRect = nextTipsRect;

    final children = <TextSpan>[];
    for (var param in indicator.calcParams) {
      final countMaMap = calcuMgr.getCountMaMap(param.count);
      if (countMaMap.isEmpty) continue;

      final maVal = countMaMap.getItem(model.timestamp);
      if (maVal != null) {
        final text = formatNumber(
          maVal.val,
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
