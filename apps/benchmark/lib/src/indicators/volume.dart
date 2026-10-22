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

import 'package:flexi_formatter/flexi_formatter.dart' show RoundMode, formatAmount;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';

/// 主区成交量: `PaintMode.alone` 贴在主区底部的半透明涨跌量柱, 不含计算。
///
/// 绘制对标 `flexi_kline_indicators` 的 `VolumeIndicator`, 配置最小化: 只保留高度、边距、精度与透明度, 不做序列化与 copyWith。
class BenchVolumeIndicator extends DirectIndicator {
  BenchVolumeIndicator({
    super.height = defaultSubIndicatorHeight,
    super.padding = defaultSubIndicatorPadding,
    this.precision = 4,
    this.opacity = 0.5,
  }) : super(
         key: const DirectIndicatorKey('bench_volume'),
         zIndex: -2,
         paintMode: PaintMode.alone,
       );

  final int precision;
  final double opacity;

  @override
  DirectPaintObject<DirectIndicator> createPaintObject() => _BenchVolumePaintObject();
}

class _BenchVolumePaintObject extends DirectPaintObject<BenchVolumeIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    if (!klineData.checkStartAndEnd(start, end)) return null;

    FlexiCandleModel m = klineData.list[end - 1];
    FlexiNum minVol = m.vol;
    FlexiNum maxVol = m.vol;
    for (int i = end - 2; i >= start; i--) {
      m = klineData.list[i];
      maxVol = m.vol > maxVol ? m.vol : maxVol;
      minVol = m.vol < minVol ? m.vol : minVol;
    }
    return MinMax(max: maxVol, min: minVol)..minToZero();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final list = klineData.list;
    final int start = klineData.start;
    final int end = klineData.end;

    final offset = startCandleDx - candleWidthHalf;
    final dyBottom = chartRect.bottom;

    final longPaint = defLongBarPaint..color = longColor.withAlpha(indicator.opacity.alpha);
    final shortPaint = defShortBarPaint..color = shortColor.withAlpha(indicator.opacity.alpha);

    for (var i = start; i < end; i++) {
      final model = list[i];
      final dx = offset - (i - start) * candleActualWidth;
      final dy = valueToDy(model.vol);
      final isLong = model.close >= model.open;

      canvas.drawLine(Offset(dx, dy), Offset(dx, dyBottom), isLong ? longPaint : shortPaint);
    }
  }

  @override
  void paintCross(Canvas canvas, Offset offset, {FlexiCandleModel? model}) {}

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) {
    model ??= offsetToCandle(offset);
    if (model == null) return null;

    final text = formatAmount(
      model.vol.toDecimal(),
      precision: indicator.precision,
      roundMode: RoundMode.truncate,
      prefix: 'Vol:$nbsp',
    );

    tipsRect ??= drawableRect;
    return canvas.drawText(
      offset: tipsRect.topLeft,
      text: text,
      style: TextStyle(
        fontSize: defaultTextSize,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
        color: theme.ticksTextColor,
      ),
      drawDirection: DrawDirection.ltr,
      drawableRect: tipsRect,
      textAlign: TextAlign.start,
      padding: defaultTipsPadding,
    );
  }
}
