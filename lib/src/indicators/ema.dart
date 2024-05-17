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

part 'ema.g.dart';

/// EMA 平滑移动平均线
/// 公式：
/// 1）快速平滑移动平均线（EMA）是12日的，计算公式为：
///   EMA(12)=2*今收盘价/(12+1)+11*昨日EMA(12)/(12+1)
/// 2）慢速平滑移动平均线（EMA）是26日的，计算公式为：
///   EMA(26)=2*今收盘价/(26+1)+25*昨日EMA(26)/(26+1)
@FlexiIndicatorSerializable
class EMAIndicator extends SinglePaintObjectIndicator {
  EMAIndicator({
    super.key = emaKey,
    super.name = 'EMA',
    required super.height,
    super.padding = defaultMainIndicatorPadding,
    this.calcParams = const [
      MaParam(
        count: 5,
        tips: TipsConfig(
          label: 'EMA5: ',
          // precision: 2,
          style: TextStyle(
            fontSize: defaulTextSize,
            color: Color(0xFF806180),
            overflow: TextOverflow.ellipsis,
            height: defaultTipsTextHeight,
          ),
        ),
      ),
      MaParam(
        count: 10,
        tips: TipsConfig(
          label: 'EMA10: ',
          // precision: 2,
          style: TextStyle(
            fontSize: defaulTextSize,
            color: Color(0xFFEBB736),
            overflow: TextOverflow.ellipsis,
            height: defaultTipsTextHeight,
          ),
        ),
      ),
      MaParam(
        count: 20,
        tips: TipsConfig(
          label: 'EMA20: ',
          // precision: 2,
          style: TextStyle(
            fontSize: defaulTextSize,
            color: Color(0xFFD672D5),
            overflow: TextOverflow.ellipsis,
            height: defaultTipsTextHeight,
          ),
        ),
      ),
      MaParam(
        count: 60,
        tips: TipsConfig(
          label: 'EMA60: ',
          // precision: 2,
          style: TextStyle(
            fontSize: defaulTextSize,
            color: Color(0xFF788FD5),
            overflow: TextOverflow.ellipsis,
            height: defaultTipsTextHeight,
          ),
        ),
      ),
    ],
    this.tipsPadding = defaultTipsPadding,
    this.lineWidth = defaultIndicatorLineWidth,
  });

  final List<MaParam> calcParams;
  final EdgeInsets tipsPadding;
  final double lineWidth;

  @override
  SinglePaintObjectBox createPaintObject(KlineBindingBase controller) {
    return EMAPaintObject(controller: controller, indicator: this);
  }

  factory EMAIndicator.fromJson(Map<String, dynamic> json) =>
      _$EMAIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$EMAIndicatorToJson(this);
}

class EMAPaintObject<T extends EMAIndicator> extends SinglePaintObjectBox<T> {
  EMAPaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initState({required int start, required int end}) {
    if (!klineData.canPaintChart) return null;

    MinMax? minmax;
    for (var param in indicator.calcParams) {
      final ret = klineData.calculateEmaMinmax(
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
    paintEMALine(canvas, size);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    ///
  }

  /// 绘制EMA线
  void paintEMALine(Canvas canvas, Size size) {
    if (!klineData.canPaintChart) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = (klineData.end + 1).clamp(start, list.length); // 多绘制一根蜡烛

    // try {
    //   /// 保存画布状态
    //   canvas.save();
    //   /// 裁剪绘制范围
    //   canvas.clipRect(setting.mainDrawRect);

    for (var param in indicator.calcParams) {
      final emaMap = klineData.getEmaMap(param.count);
      if (emaMap.isEmpty) continue;

      final offset = startCandleDx - candleWidthHalf;
      CandleModel m;
      MaResult? ret;
      final List<Offset> points = [];
      for (int i = start; i < end; i++) {
        m = list[i];
        final dx = offset - (i - start) * candleActualWidth;
        ret = emaMap[m.timestamp];
        if (ret == null) continue;
        final dy = valueToDy(ret.val, correct: false);
        points.add(Offset(dx, dy));
      }

      canvas.drawPath(
        Path()..addPolygon(points, false),
        Paint()
          ..color = param.tips.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = indicator.lineWidth,
      );
    }
    // } finally {
    //   /// 恢复画布状态
    //   canvas.restore();
    // }
  }

  /// EMA 绘制tips区域
  @override
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    model ??= offsetToCandle(offset);
    if (model == null) return null;

    final children = <TextSpan>[];
    for (var param in indicator.calcParams) {
      final ret = klineData.getEmaResult(
        count: param.count,
        ts: model.timestamp,
      );
      if (ret == null) continue;

      final text = formatNumber(
        ret.val.toDecimal(),
        precision: param.tips.getP(klineData.precision),
        cutInvalidZero: true,
        prefix: param.tips.label,
        suffix: '  ',
      );
      children.add(TextSpan(
        text: text,
        style: param.tips.style,
      ));
    }
    if (children.isNotEmpty) {
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
    return null;
  }
}
