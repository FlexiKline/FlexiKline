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

part 'candle.g.dart';

@FlexiIndicatorSerializable
class CandleIndicator extends SinglePaintObjectIndicator {
  CandleIndicator({
    super.key = candleKey,
    super.name = 'Candle',
    required super.height,
    super.tipsHeight,
    super.padding,
    this.latestPriceRectBackgroundColor,
  });

  final Color? latestPriceRectBackgroundColor;

  @override
  CandlePaintObject createPaintObject(
    KlineBindingBase controller,
  ) {
    return CandlePaintObject(controller: controller, indicator: this);
  }

  factory CandleIndicator.fromJson(Map<String, dynamic> json) =>
      _$CandleIndicatorFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$CandleIndicatorToJson(this);
}

class CandlePaintObject<T extends CandleIndicator>
    extends SinglePaintObjectBox<T> with PaintYAxisMarkOnCrossMixin {
  CandlePaintObject({
    required super.controller,
    required super.indicator,
  });

  BagNum? _maxHigh, _minLow;

  @override
  MinMax? initState({required int start, required int end}) {
    if (!klineData.canPaintChart) return null;

    MinMax? minmax = klineData.calculateMinmax(start: start, end: end);
    _maxHigh = minmax?.max;
    _minLow = minmax?.min;
    return minmax;
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    /// 绘制蜡烛图
    paintCandleChart(canvas, size);

    /// 绘制X轴时间刻度数据. 在paintCandleChart调用
    // paintXAxisTimeTick(canvas);

    /// 绘制Y轴价钱刻度数据
    paintYAxisPriceTick(canvas, size);
  }

  @override
  void paintExtraAfterPaintChart(Canvas canvas, Size size) {
    /// 绘制最新价刻度线与价钱标记
    paintLatestPriceMark(canvas, size);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    /// 绘制Cross Y轴价钱刻度
    paintYAxisMarkOnCross(canvas, offset);

    /// 绘制Cross X轴时间刻度
    paintXAxisMarkOnCross(canvas, offset);

    // /// 绘制Cross 命中的蜡烛数据弹窗
    // paintTips(canvas, offset: offset);
  }

  // onCross时, 格式化Y轴上的标记值.
  @override
  String formatYAxisMarkValueOnCross(BagNum value) {
    return setting.formatPrice(
      value.toDecimal(),
      instId: klineData.req.instId,
      precision: klineData.req.precision,
      cutInvalidZero: false,
    );
  }

  /// 绘制蜡烛图
  void paintCandleChart(Canvas canvas, Size size) {
    if (!klineData.canPaintChart) {
      logw('paintCandleChart Data.list is empty or Index is out of bounds');
      return;
    }

    final list = klineData.list;
    int start = klineData.start;
    int end = klineData.end;

    final offset = startCandleDx - candleWidthHalf;
    final bar = klineData.timerBar;
    Offset? maxHihgOffset, minLowOffset;
    bool hasEnough = paintDxOffset > 0;
    BagNum maxHigh = list[start].high;
    BagNum minLow = list[start].low;
    CandleModel m;
    for (var i = start; i < end; i++) {
      m = list[i];
      final dx = offset - (i - start) * candleActualWidth;
      final isLong = m.close >= m.open;

      final highOff = Offset(dx, valueToDy(m.high));
      final lowOff = Offset(dx, valueToDy(m.low));
      canvas.drawLine(
        highOff,
        lowOff,
        isLong ? setting.candleLineLongPaint : setting.candleLineShortPaint,
      );

      final openOff = Offset(dx, valueToDy(m.open));
      final closeOff = Offset(dx, valueToDy(m.close));
      canvas.drawLine(
        openOff,
        closeOff,
        isLong ? setting.candleBarLongPaint : setting.candleBarShortPaint,
      );

      if (bar != null && i % setting.timeTickIntervalCandleCounts == 0) {
        // 绘制X轴时间刻度.
        paintXAxisTimeTick(
          canvas,
          bar: bar,
          model: m,
          offset: Offset(dx, chartRect.bottom),
        );
      }

      if (setting.isDrawPriceMark) {
        if (hasEnough) {
          // 满足一屏, 根据initData中的最大最小值来记录最大最小偏移量.
          if (m.high == _maxHigh) {
            maxHihgOffset = highOff;
            maxHigh = _maxHigh!;
          }
          if (m.low == _minLow) {
            minLowOffset = lowOff;
            minLow = _minLow!;
          }
        } else if (dx > 0) {
          // 如果当前绘制不足一屏, 最大最小绘制仅限可见区域.
          if (m.high >= maxHigh) {
            maxHihgOffset = highOff;
            maxHigh = m.high;
          }
          if (m.low <= minLow) {
            minLowOffset = lowOff;
            minLow = m.low;
          }
        }
      }
    }

    // 最后绘制在蜡烛图中的最大最小价钱标记
    if (setting.isDrawPriceMark &&
        (maxHihgOffset != null && maxHigh > BagNum.zero) &&
        (minLowOffset != null && minLow > BagNum.zero)) {
      paintPriceMark(canvas, maxHihgOffset, maxHigh);
      paintPriceMark(canvas, minLowOffset, minLow);
    }
  }

  /// 绘制蜡烛图上最大最小值价钱标记.
  void paintPriceMark(
    Canvas canvas,
    Offset offset,
    BagNum val,
  ) {
    final flag = offset.dx > chartRectWidthHalf ? -1 : 1;
    Offset endOffset = Offset(
      offset.dx + setting.priceMarkLineLength * flag,
      offset.dy,
    );
    canvas.drawLine(
      offset,
      endOffset,
      setting.priceMarkLinePaint,
    );
    endOffset = Offset(
      endOffset.dx + flag * setting.priceMarkMargin,
      endOffset.dy - setting.priceMarkFontSize / 2,
    );

    final text = setting.formatPrice(
      val.toDecimal(),
      instId: klineData.req.instId,
      precision: klineData.req.precision,
    );
    canvas.drawText(
      offset: endOffset,
      drawDirection: flag < 0 ? DrawDirection.rtl : DrawDirection.ltr,
      text: text,
      style: setting.priceMarkTextStyle,
      maxLines: 1,
    );
  }

  void paintXAxisTimeTick(
    Canvas canvas, {
    required TimeBar bar,
    required CandleModel model,
    required Offset offset,
  }) {
    // final data = curKlineData;
    // if (data.list.isEmpty) return;
    // int start = data.start;
    // int end = data.end;

    // final offset = startCandleDx - candleWidthHalf;
    // final bar = data.timerBar;
    // for (var i = start; i < end; i++) {
    //   final model = data.list[i];
    //   final dx = offset - (i - start) * candleActualWidth;
    //   if (bar != null && i % timeTickIntervalCandleCounts == 0) {
    //     Offset(dx, mainDrawBottom);
    // 绘制X轴时间刻度.
    canvas.drawText(
      offset: offset,
      drawDirection: DrawDirection.center,
      text: model.formatDateTimeByTimeBar(bar),
      style: setting.timeTickStyle,
      textAlign: TextAlign.center,
      textWidth: setting.timeTickRectWidth,
    );
    //   }
    // }
  }

  void paintYAxisPriceTick(Canvas canvas, Size size) {
    final yAxisStep = chartRect.bottom / setting.gridCount;
    final dx = chartRect.right;
    double dy = 0;
    for (int i = 1; i <= setting.gridCount; i++) {
      dy = i * yAxisStep;
      final price = dyToValue(dy);
      if (price == null) continue;

      final text = setting.formatPrice(
        price.toDecimal(),
        instId: klineData.req.instId,
        precision: klineData.req.precision,
      );

      canvas.drawText(
        offset: Offset(
          dx,
          dy - setting.yAxisTickRectHeight,
        ),
        drawDirection: DrawDirection.rtl,
        drawableRect: drawBounding,
        text: text,
        style: setting.yAxisTickTextStyle,
        // textWidth: tickTextWidth,
        textAlign: TextAlign.end,
        padding: setting.yAxisTickRectPadding,
        maxLines: 1,
      );
    }
  }

  /// 绘制最新价刻度线与价钱标记
  /// 1. 价钱标记始终展示在画板最右边.
  /// 2. 最新价向右移出屏幕后, 刻度线横穿整屏.
  ///    且展示在指定价钱区间内, 如超出边界, 则停靠在最高最低线上.
  /// 3. 最新价向左移动后, 刻度线根据最新价蜡烛线平行移动.
  void paintLatestPriceMark(Canvas canvas, Size size) {
    if (!setting.isDrawLatestPriceMark) return;
    final data = klineData;
    final model = data.latest;
    if (model == null) {
      logd('paintLatestPriceMark > on data!');
      return;
    }

    bool showLastPriceUpdateTime = setting.showLatestPriceUpdateTime;
    double dx = chartRect.right;
    double firstCandleDx = startCandleDx;
    double rightMargin = setting.latestPriceRectRightMinMargin;
    double ldx = 0; // 计算最新价刻度线lineTo参数X轴的dx值. 默认0: 代表橫穿整个Canvas.
    double dy;
    if (model.close >= minMax.max) {
      dy = chartRect.top; // 画板顶部展示.
    } else if (model.close <= minMax.min) {
      dy = chartRect.bottom; // 画板底部展示.
    } else {
      dy = clampDyInChart(valueToDy(model.close));
    }
    // 计算最新价在当前画板中的X轴位置.
    if (firstCandleDx < dx) {
      ldx = firstCandleDx;
    } else {
      if (setting.showLatestPriceXAxisLineWhenMoveOffDrawArea) {
        ldx = 0;
        rightMargin += setting.latestPriceRectRightMaxMargin;
        showLastPriceUpdateTime = false;
      } else {
        ldx = dx - rightMargin;
      }
    }

    // 画最新价在画板中的刻度线.
    final path = Path();
    path.moveTo(dx, dy);
    path.lineTo(ldx, dy);
    canvas.drawDashPath(
      path,
      setting.latestPriceMarkLinePaint,
      dashes: setting.latestPriceMarkLineDashes,
    );

    // 画最新价文本区域.
    double textHeight =
        setting.latestPriceRectPadding.vertical + setting.latestPriceFontSize;
    String text = setting.formatPrice(
      model.close.toDecimal(),
      instId: klineData.req.instId,
      precision: klineData.req.precision,
      cutInvalidZero: false,
    );
    if (showLastPriceUpdateTime) {
      final nextUpdateDateTime = model.nextUpdateDateTime(klineData.req.bar);
      // logd(
      //   'paintLastPriceMark lastModelTime:${model.dateTime}, nextUpdateDateTime:$nextUpdateDateTime',
      // );
      if (nextUpdateDateTime != null) {
        final timeDiff = formatTimeDiff(nextUpdateDateTime);
        if (timeDiff != null) {
          text += "\n$timeDiff";
          textHeight += setting.latestPriceFontSize;
        }
      }
    }

    canvas.drawText(
      offset: Offset(
        dx - rightMargin,
        dy - textHeight / 2, // 计算最新价文本区域相对于刻度线的位置
      ),
      drawDirection: DrawDirection.rtl,
      drawableRect: drawBounding,
      text: text,
      style: setting.latestPriceTextStyle,
      textAlign: TextAlign.end,
      textWidthBasis: TextWidthBasis.longestLine,
      padding: setting.latestPriceRectPadding,
      backgroundColor: indicator.latestPriceRectBackgroundColor ??
          setting.latestPriceRectBackgroundColor,
      radius: setting.latestPriceRectBorderRadius,
      borderWidth: setting.latestPriceRectBorderWidth,
      borderColor: setting.latestPriceRectBorderColor,
    );
  }

  /// 绘制Cross X轴时间刻度
  @protected
  void paintXAxisMarkOnCross(Canvas canvas, Offset offset) {
    final index = dxToIndex(offset.dx);
    final model = klineData.getCandle(index);
    final timeBar = klineData.timerBar;
    if (model == null || timeBar == null) return;

    // final time = model.formatDateTimeByTimeBar(timeBar);
    final time = setting.formatDateTime(model.dateTime);

    final dyCenterOffset =
        (paintPadding.bottom - setting.crossXTickRectHeight) / 2;
    canvas.drawText(
      offset: Offset(
        offset.dx,
        chartRect.bottom + dyCenterOffset,
      ),
      drawDirection: DrawDirection.center,
      text: time,
      style: setting.crossXTickTextStyle,
      textAlign: TextAlign.center,
      textWidthBasis: TextWidthBasis.longestLine,
      padding: setting.crossXTickRectPadding,
      backgroundColor: setting.crossXTickRectBackgroundColor,
      radius: setting.crossXTickRectBorderRadius,
      borderWidth: setting.crossXTickRectBorderWidth,
      borderColor: setting.crossXTickRectBorderColor,
    );
  }

  /// 绘制Cross 命中的蜡烛数据弹窗
  @override
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    if (!setting.showPopupCandleCard) return null;

    if (offset == null) return null;
    model ??= offsetToCandle(offset);
    final timeBar = klineData.timerBar;
    if (model == null || timeBar == null) return null;

    /// 1. 准备数据
    // ['Time', 'Open', 'High', 'Low', 'Close', 'Chg', '%Chg', 'Amount']
    final keys = setting.i18nCandleCardKeys;
    final keySpanList = <TextSpan>[];
    for (var i = 0; i < keys.length; i++) {
      final text = i < keys.length - 1 ? '${keys[i]}\n' : keys[i];
      keySpanList.add(TextSpan(
        text: text,
        style: setting.candleCardTitleStyle,
      ));
    }

    final instId = klineData.instId;
    final p = klineData.precision;
    TextStyle changeStyle = setting.candleCardTitleStyle;
    final chgrate = model.changeRate;
    if (chgrate > 0) {
      changeStyle = setting.candleCardLongStyle;
    } else if (chgrate < 0) {
      changeStyle = setting.candleCardShortStyle;
    }
    final valueSpan = <TextSpan>[
      TextSpan(
        text: '${model.formatDateTimeByTimeBar(timeBar)}\n',
        style: setting.candleCardTitleStyle,
      ),
      TextSpan(
        text:
            '${setting.formatPrice(model.open.toDecimal(), instId: instId, precision: p)}\n',
        style: setting.candleCardTitleStyle,
      ),
      TextSpan(
        text:
            '${setting.formatPrice(model.high.toDecimal(), instId: instId, precision: p)}\n',
        style: setting.candleCardTitleStyle,
      ),
      TextSpan(
        text:
            '${setting.formatPrice(model.low.toDecimal(), instId: instId, precision: p)}\n',
        style: setting.candleCardTitleStyle,
      ),
      TextSpan(
        text:
            '${setting.formatPrice(model.close.toDecimal(), instId: instId, precision: p)}\n',
        style: setting.candleCardTitleStyle,
      ),
      TextSpan(
        text:
            '${setting.formatPrice(model.change.toDecimal(), instId: instId, precision: p)}\n',
        style: changeStyle,
      ),
      TextSpan(
        text: '${formatPercentage(model.changeRate)}\n',
        style: changeStyle,
      ),
      TextSpan(
        text: formatNumber(
          model.vol.toDecimal(),
          precision: 2,
          cutInvalidZero: true,
          showCompact: true,
        ),
        style: setting.candleCardTitleStyle,
        // recognizer: _tapGestureRecognizer..onTap = () => ... // 点击事件处理?
      ),
    ];

    /// 2. 开始绘制.
    if (offset.dx > chartRectWidthHalf) {
      // 点击区域在右边; 绘制在左边
      Offset drawOffset = Offset(
        chartRect.left + setting.candleCardRectMargin.left,
        chartRect.top + setting.candleCardRectMargin.top,
      );

      final size = canvas.drawText(
        offset: drawOffset,
        drawDirection: DrawDirection.ltr,
        drawableRect: chartRect,
        textSpan: TextSpan(
          children: keySpanList,
          style: setting.candleCardTitleStyle,
        ),
        style: setting.candleCardTitleStyle,
        textAlign: TextAlign.start,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: setting.candleCardRectPadding,
        backgroundColor: setting.candleCardRectBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(setting.candleCardRectBorderRadius),
          bottomLeft: Radius.circular(setting.candleCardRectBorderRadius),
        ),
      );

      canvas.drawText(
        offset: Offset(
          drawOffset.dx + size.width - 1,
          drawOffset.dy,
        ),
        drawDirection: DrawDirection.ltr,
        drawableRect: chartRect,
        textSpan: TextSpan(
          children: valueSpan,
          style: setting.candleCardValueStyle,
        ),
        style: setting.candleCardValueStyle,
        textAlign: TextAlign.end,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: setting.candleCardRectPadding,
        backgroundColor: setting.candleCardRectBackgroundColor,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(setting.candleCardRectBorderRadius),
          bottomRight: Radius.circular(setting.candleCardRectBorderRadius),
        ),
      );
    } else {
      // 点击区域在左边; 绘制在右边
      Offset drawOffset = Offset(
        chartRect.right - setting.candleCardRectMargin.right,
        chartRect.top + setting.candleCardRectMargin.top,
      );

      final size = canvas.drawText(
        offset: drawOffset,
        drawDirection: DrawDirection.rtl,
        drawableRect: chartRect,
        textSpan: TextSpan(
          children: valueSpan,
          style: setting.candleCardValueStyle,
        ),
        style: setting.candleCardValueStyle,
        textAlign: TextAlign.end,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: setting.candleCardRectPadding,
        backgroundColor: setting.candleCardRectBackgroundColor,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(setting.candleCardRectBorderRadius),
          bottomRight: Radius.circular(setting.candleCardRectBorderRadius),
        ),
      );

      canvas.drawText(
        offset: Offset(
          drawOffset.dx - size.width + 1,
          drawOffset.dy,
        ),
        drawDirection: DrawDirection.rtl,
        drawableRect: chartRect,
        textSpan: TextSpan(
          children: keySpanList,
          style: setting.candleCardTitleStyle,
        ),
        style: setting.candleCardTitleStyle,
        textAlign: TextAlign.start,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: setting.candleCardRectPadding,
        backgroundColor: setting.candleCardRectBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(setting.candleCardRectBorderRadius),
          bottomLeft: Radius.circular(setting.candleCardRectBorderRadius),
        ),
      );
    }
    return null;
  }
}
