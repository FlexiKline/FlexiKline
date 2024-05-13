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
import 'ma.dart';

part 'vol_ma.g.dart';

/// VolMa 移动平均指标线
@FlexiIndicatorSerializable
class VolMaIndicator extends SinglePaintObjectIndicator {
  VolMaIndicator({
    super.key = volMaKey,
    super.name = 'VOLMA',
    required super.height,
    super.tipsHeight,
    super.padding,
    this.calcParams = const [
      MaParam(label: 'MA5', count: 5, color: Colors.orange),
      MaParam(label: 'MA10', count: 10, color: Colors.blue)
    ],
  });

  final List<MaParam> calcParams;

  @override
  VolMaPaintObject createPaintObject(KlineBindingBase controller) {
    return VolMaPaintObject(controller: controller, indicator: this);
  }

  factory VolMaIndicator.fromJson(Map<String, dynamic> json) =>
      _$VolMaIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$VolMaIndicatorToJson(this);
}

class VolMaPaintObject<T extends VolMaIndicator>
    extends SinglePaintObjectBox<T> {
  VolMaPaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initState({required int start, required int end}) {
    if (!klineData.canPaintChart) return null;

    MinMax? minmax;
    for (var param in indicator.calcParams) {
      final ret = klineData.calculateMavolMinmax(
        param.count,
        start: start,
        end: end,
      );
      minmax ??= ret;
      minmax?.updateMinMax(ret);
    }
    return minmax;
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    paintVolMALine(canvas, size);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    ///
  }

  /// 绘制MA指标线
  void paintVolMALine(Canvas canvas, Size size) {
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
      final maVolMap = klineData.getVolmaMap(param.count);
      if (maVolMap.isEmpty) continue;

      final offset = startCandleDx - candleWidthHalf;
      CandleModel m;
      MaResult? maRet;
      final List<Offset> points = [];
      for (int i = start; i < end; i++) {
        m = data.list[i];
        final dx = offset - (i - start) * candleActualWidth;
        maRet = maVolMap[m.timestamp];
        maRet ??= klineData.calculateVolma(i, param.count);
        if (maRet == null) continue;
        final dy = valueToDy(maRet.val, correct: false);
        points.add(Offset(dx, dy));
      }

      canvas.drawPath(
        Path()..addPolygon(points, false),
        Paint()
          ..color = param.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = setting.defPaintLineWidth,
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
    if (indicator.tipsHeight <= 0) return null;
    model ??= offsetToCandle(offset);
    if (model == null) return null;

    Rect drawRect = nextTipsRect;

    final children = <TextSpan>[];
    for (var param in indicator.calcParams) {
      final ret = klineData.getVolmaResult(
        count: param.count,
        ts: model.timestamp,
      );
      if (ret == null) continue;

      final text = formatNumber(
        ret.val.toDecimal(),
        precision: state.curKlineData.req.precision,
        cutInvalidZero: true,
        prefix: '${param.label}: ',
        suffix: '  ',
      );
      children.add(TextSpan(
        text: text,
        style: TextStyle(
          fontSize: setting.tipsDefaultTextSize,
          color: param.color,
          height: setting.tipsDefaultTextHeight,
        ),
      ));
    }

    if (children.isNotEmpty) {
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
    return null;
  }
}
