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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../constant.dart';
import '../core/export.dart';
import '../extension/export.dart';
import '../model/export.dart';
import '../render/export.dart';
import '../utils/export.dart';
import '../framework/export.dart';

class CandleIndicator extends MultiPaintObjectIndicator {
  CandleIndicator({
    required super.key,
    required super.height,
    super.tipsHeight,
    super.padding,
    super.children,
  });

  @override
  MultiPaintObjectBox createPaintObject(
    KlineBindingBase controller,
  ) {
    return CandlePaintObject(controller: controller, indicator: this);
  }
}

class CandlePaintObject extends MultiPaintObjectBox<CandleIndicator> {
  CandlePaintObject({
    required super.controller,
    required super.indicator,
  });

  Decimal _max = Decimal.zero;
  Decimal _min = Decimal.zero;

  Decimal? _maxHigh, _minLow;

  @override
  void initData(List<CandleModel> list, {int start = 0, int end = 0}) {
    if (list.isEmpty || start < 0 || end > list.length) return;
    CandleModel m = list[start];
    _max = m.high;
    _min = m.low;
    for (var i = start + 1; i < end; i++) {
      m = list[i];
      _max = m.high > _max ? m.high : _max;
      _min = m.low < _min ? m.low : _min;
    }
    _maxHigh = _max;
    _minLow = _min;
    // 增加vol区域的margin为高度的1/10
    final volH = _max == _min ? Decimal.one : _max - _min;
    final margin = volH * twentieth;
    _max += margin;
    _min -= margin;

    super.initData(list, start: start, end: end);
  }

  @override
  Decimal get maxVal => _max;
  @override
  Decimal get minVal => _min;

  @override
  void paintChart(Canvas canvas, Size size) {
    /// 绘制蜡烛图
    paintCandleChart(canvas, size);

    /// 绘制X轴时间刻度数据. 在paintCandleChart调用
    // paintXAxisTimeTick(canvas);

    /// 绘制Y轴价钱刻度数据
    paintAxisTickMark(canvas, size);

    /// 绘制最新价刻度线与价钱标记
    paintLastPriceMark(canvas, size);

    super.paintChart(canvas, size);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    /// 绘制Cross Y轴价钱刻度
    paintCrossYAxisPriceMark(canvas, offset);

    if (setting.showCrossXAxisTickMark) {
      /// 绘制Cross X轴时间刻度
      paintCrossXAxisTimeMark(canvas, offset);
    }

    if (setting.showPopupCandleCard) {
      /// 绘制Cross 命中的蜡烛数据弹窗
      paintPopupCandleCard(canvas, offset);
    }
    super.onCross(canvas, offset);
  }

  /// 绘制蜡烛图
  void paintCandleChart(Canvas canvas, Size size) {
    final data = klineData;
    int start = data.start;
    int end = data.end;
    if (data.list.isEmpty || !data.list.checkIndex(start)) {
      logw('paintCandleChart Data.list is empty or Index is out of bounds');
      return;
    }

    final offset = startCandleDx - candleWidthHalf;
    final bar = data.timerBar;
    Offset? maxHihgOffset, minLowOffset;
    bool hasEnough = paintDxOffset > 0;
    Decimal maxHigh = data.list[start].high;
    Decimal minLow = data.list[start].low;
    for (var i = start; i < end; i++) {
      final model = data.list[i];
      final dx = offset - (i - start) * candleActualWidth;
      final isLong = model.close >= model.open;

      final highOff = Offset(dx, valueToDy(model.high));
      final lowOff = Offset(dx, valueToDy(model.low));
      canvas.drawLine(
        highOff,
        lowOff,
        isLong ? setting.candleLineLongPaint : setting.candleLineShortPaint,
      );

      final openOff = Offset(dx, valueToDy(model.open));
      final closeOff = Offset(dx, valueToDy(model.close));
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
          model: model,
          offset: Offset(dx, chartRect.bottom),
        );
      }

      if (setting.isDrawPriceMark) {
        if (hasEnough) {
          // 满足一屏, 根据initData中的最大最小值来记录最大最小偏移量.
          if (model.high == _maxHigh) {
            maxHihgOffset = highOff;
            maxHigh = _maxHigh!;
          }
          if (model.low == _minLow) {
            minLowOffset = lowOff;
            minLow = _minLow!;
          }
        } else if (dx > 0) {
          // 如果当前绘制不足一屏, 最大最小绘制仅限可见区域.
          if (model.high >= maxHigh) {
            maxHihgOffset = highOff;
            maxHigh = model.high;
          }
          if (model.low <= minLow) {
            minLowOffset = lowOff;
            minLow = model.low;
          }
        }
      }
    }

    // 最后绘制在蜡烛图中的最大最小价钱标记
    if (setting.isDrawPriceMark &&
        (maxHihgOffset != null && maxHigh > Decimal.zero) &&
        (minLowOffset != null && minLow > Decimal.zero)) {
      paintPriceMark(canvas, maxHihgOffset, maxHigh);
      paintPriceMark(canvas, minLowOffset, minLow);
    }
  }

  /// 绘制蜡烛图上最大最小值价钱标记.
  void paintPriceMark(
    Canvas canvas,
    Offset offset,
    Decimal val,
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
      val,
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

  void paintAxisTickMark(Canvas canvas, Size size) {
    final yAxisStep = chartRect.bottom / setting.gridCount;
    final dx = chartRect.right;
    double dy = 0;
    for (int i = 1; i <= setting.gridCount; i++) {
      dy = i * yAxisStep;
      final price = dyToValue(dy);
      if (price == null) continue;

      final text = setting.formatPrice(
        price,
        instId: klineData.req.instId,
        precision: klineData.req.precision,
      );

      canvas.drawText(
        offset: Offset(dx, dy - setting.priceTickRectHeight),
        drawDirection: DrawDirection.rtl,
        drawableRect: drawBounding,
        text: text,
        style: setting.priceTickStyle,
        // textWidth: tickTextWidth,
        textAlign: TextAlign.end,
        padding: setting.priceTickRectPadding,
        maxLines: 1,
      );
    }
  }

  /// 绘制最新价刻度线与价钱标记
  /// 1. 价钱标记始终展示在画板最右边.
  /// 2. 最新价向右移出屏幕后, 刻度线横穿整屏.
  ///    且展示在指定价钱区间内, 如超出边界, 则停靠在最高最低线上.
  /// 3. 最新价向左移动后, 刻度线根据最新价蜡烛线平行移动.
  void paintLastPriceMark(Canvas canvas, Size size) {
    if (!setting.isDrawLastPriceMark) return;
    final data = klineData;
    final model = data.latest;
    if (model == null) {
      logd('paintLastPriceMark > on data!');
      return;
    }

    double dx = chartRect.right;
    double ldx = 0; // 计算最新价刻度线lineTo参数X轴的dx值. 默认0: 代表橫穿整个Canvas.
    double dy;
    double flag = -1; // 计算右边最新价钱文本时, dy增减的方向
    if (model.close >= maxVal) {
      dy = chartRect.top; // 画板顶部展示.
    } else if (model.close <= minVal) {
      dy = chartRect.bottom; // 画板底部展示.
      flag = 1;
    } else {
      // 计算最新价在当前画板中的X轴位置.
      ldx = clampDxInChart(startCandleDx);
      dy = clampDyInChart(valueToDy(model.close));
    }

    // 画最新价在画板中的刻度线.
    final path = Path();
    path.moveTo(dx, dy);
    path.lineTo(ldx, dy);
    canvas.drawDashPath(
      path,
      setting.lastPriceMarkLinePaint,
      dashes: setting.lastPriceMarkLineDashes,
    );

    // 画最新价文本区域.
    double textHeight =
        setting.lastPriceRectPadding.vertical + setting.lastPriceFontSize;
    String text = setting.formatPrice(
      model.close,
      instId: klineData.req.instId,
      precision: klineData.req.precision,
      cutInvalidZero: false,
    );
    if (setting.showLastPriceUpdateTime) {
      final nextUpdateDateTime = model.nextUpdateDateTime(klineData.req.bar);
      // logd(
      //   'paintLastPriceMark lastModelTime:${model.dateTime}, nextUpdateDateTime:$nextUpdateDateTime',
      // );
      if (nextUpdateDateTime != null) {
        final timeDiff = formatTimeDiff(nextUpdateDateTime);
        if (timeDiff != null) {
          text += "\n$timeDiff";
          textHeight += setting.lastPriceFontSize;
        }
      }
    }
    canvas.drawText(
      offset: Offset(
        dx - setting.lastPriceRectRightMargin,
        dy + flag * textHeight / 2, // 计算最新价文本区域相对于刻度线的位置
      ),
      drawDirection: DrawDirection.rtl,
      drawableRect: drawBounding,
      text: text,
      style: setting.lastPriceTextStyle,
      textAlign: TextAlign.end,
      textWidthBasis: TextWidthBasis.longestLine,
      padding: setting.lastPriceRectPadding,
      backgroundColor: setting.lastPriceRectBackgroundColor,
      radius: setting.lastPriceRectBorderRadius,
      borderWidth: setting.lastPriceRectBorderWidth,
      borderColor: setting.lastPriceRectBorderColor,
    );
  }

  /// TODO: 待考虑.
  void paintCrossTips(Canvas canvas, Offset offset) {
    // TODO: implement paintCrossTips
  }

  /// 绘制Cross Y轴价钱刻度
  @protected
  void paintCrossYAxisPriceMark(Canvas canvas, Offset offset) {
    final price = dyToValue(offset.dy);
    if (price == null) return;

    final text = setting.formatPrice(
      price,
      instId: klineData.req.instId,
      precision: klineData.req.precision,
      cutInvalidZero: false,
    );
    canvas.drawText(
      offset: Offset(
        chartRect.right - setting.crossYTickRectRigthMargin,
        offset.dy - setting.crossYTickRectHeight / 2,
      ),
      drawDirection: DrawDirection.rtl,
      // drawableSize: drawBounding.size,
      drawableRect: drawBounding,
      text: text,
      style: setting.crossYTickTextStyle,
      textAlign: TextAlign.end,
      textWidthBasis: TextWidthBasis.longestLine,
      padding: setting.crossYTickRectPadding,
      backgroundColor: setting.crossYTickRectBackgroundColor,
      radius: setting.crossYTickRectBorderRadius,
      borderWidth: setting.crossYTickRectBorderWidth,
      borderColor: setting.crossYTickRectBorderColor,
    );
  }

  /// 绘制Cross X轴时间刻度
  @protected
  void paintCrossXAxisTimeMark(Canvas canvas, Offset offset) {
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
  @protected
  void paintPopupCandleCard(Canvas canvas, Offset offset) {
    final model = dxToCandle(offset.dx);
    final timeBar = klineData.timerBar;
    if (model == null || timeBar == null) return;

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
            '${setting.formatPrice(model.open, instId: instId, precision: p)}\n',
        style: setting.candleCardTitleStyle,
      ),
      TextSpan(
        text:
            '${setting.formatPrice(model.high, instId: instId, precision: p)}\n',
        style: setting.candleCardTitleStyle,
      ),
      TextSpan(
        text:
            '${setting.formatPrice(model.low, instId: instId, precision: p)}\n',
        style: setting.candleCardTitleStyle,
      ),
      TextSpan(
        text:
            '${setting.formatPrice(model.close, instId: instId, precision: p)}\n',
        style: setting.candleCardTitleStyle,
      ),
      TextSpan(
        text:
            '${setting.formatPrice(model.change, instId: instId, precision: p)}\n',
        style: changeStyle,
      ),
      TextSpan(
        text: '${formatPercentage(model.changeRate)}\n',
        style: changeStyle,
      ),
      TextSpan(
        text: formatNumber(
          model.vol,
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
  }
}
