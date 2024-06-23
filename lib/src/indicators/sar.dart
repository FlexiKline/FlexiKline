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
import 'package:flexi_kline/src/extension/export.dart';
import 'package:flutter/material.dart';

import '../config/export.dart';
import '../constant.dart';
import '../core/export.dart';
import '../data/kline_data.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../utils/export.dart';

part 'sar.g.dart';

/// SAR 抛物线指标
/// SAR 的计算需要参考每一日的最高价与最低价：
/// SAR(今日)：SAR (昨日) + AF (动能趋势指标) x [ (区间极值(波段内最极值) – SAR(昨日)]
@CopyWith()
@FlexiIndicatorSerializable
class SARIndicator extends SinglePaintObjectIndicator
    implements IPrecomputable {
  SARIndicator({
    super.key = sarKey,
    super.name = 'SAR',
    required super.height,
    super.padding = defaultMainIndicatorPadding,
    super.zIndex = 3,
    this.calcParam = const SARParam(startAf: 0.02, step: 0.02, maxAf: 0.2),
    this.radius,
    required this.paint,
    required this.tipsPadding,
    required this.tipsStyle,
  });

  final SARParam calcParam;

  // 圆的半径.
  final double? radius;

  /// 绘制SAR的画笔.
  /// 注: 如果paint.color为空, 自动根据sarFlag去确定使用[settingConfig]中的[longColor]或[shortColor].
  final PaintConfig paint;
  final EdgeInsets tipsPadding;
  final TextStyle tipsStyle;

  @override
  dynamic getCalcParam() => calcParam;

  @override
  SARPaintObject createPaintObject(covariant KlineBindingBase controller) {
    return SARPaintObject(controller: controller, indicator: this);
  }

  factory SARIndicator.fromJson(Map<String, dynamic> json) =>
      _$SARIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SARIndicatorToJson(this);
}

class SARPaintObject<T extends SARIndicator> extends SinglePaintObjectBox<T> {
  SARPaintObject({required super.controller, required super.indicator});

  @override
  MinMax? initState({required int start, required int end}) {
    if (!klineData.canPaintChart) return null;

    return klineData.calcuSarMinmax(
      param: indicator.calcParam,
      start: start,
      end: end,
    );
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    if (!klineData.canPaintChart) return;
    final list = klineData.list;
    final len = list.length;
    if (!indicator.calcParam.isValid(len)) return;
    int start = klineData.start;
    int end = (klineData.end + 1).clamp(start, len); // 多绘制一根蜡烛

    Paint paint = Paint()..style = indicator.paint.style;

    if (indicator.paint.strokeWidth != null) {
      paint.strokeWidth = indicator.paint.strokeWidth!;
    }
    if (indicator.paint.color != null) {
      paint.color = indicator.paint.color!;
    }
    final radius = indicator.radius ?? setting.candleWidth / 3;

    final offset = startCandleDx - candleWidthHalf;
    CandleModel m;
    for (int i = start; i < end; i++) {
      m = list[i];
      if (!m.isValidSarData) continue;
      final dx = offset - (i - start) * candleActualWidth;
      if (indicator.paint.color == null) {
        if (m.sarFlag! > 0) {
          paint.color = settingConfig.longColor;
        } else if (m.sarFlag! < 0) {
          paint.color = settingConfig.shortColor;
        } else {
          paint.color = settingConfig.textColor;
        }
      }
      canvas.drawCircle(
        Offset(dx, valueToDy(m.sar!, correct: false)),
        radius,
        paint,
      );
    }
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    ///
  }

  @override
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    model ??= offsetToCandle(offset);
    if (model == null || !model.isValidSarData) return null;

    final text = formatNumber(
      model.sar?.toDecimal(),
      precision: klineData.precision,
      showThousands: true,
      cutInvalidZero: true,
      prefix: '${indicator.name}: ',
    );

    tipsRect ??= drawableRect;
    return canvas.drawText(
      offset: tipsRect.topLeft,
      text: text,
      style: indicator.tipsStyle,
      drawDirection: DrawDirection.ltr,
      drawableRect: tipsRect,
      textAlign: TextAlign.left,
      padding: indicator.tipsPadding,
      maxLines: 1,
    );
  }
}
