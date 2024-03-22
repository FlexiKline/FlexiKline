import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'binding_base.dart';
import 'config.dart';
import 'data_mgr.dart';
import 'setting.dart';
import '../extension/export.dart';
import '../render/draw_text.dart';

abstract interface class ICandlePinter {
  void paintCandle(Canvas canvas, Size size);
}

mixin CandleBinding
    on KlineBindingBase, SettingBinding, ConfigBinding, DataMgrBinding
    implements ICandlePinter {
  @override
  void initBinding() {
    super.initBinding();
    logd('candle init');
    // _instance = this;
  }

  double get dyFactor {
    return canvasHeight / curCandleData.dataHeight.toDouble();
  }

  @override
  void paintCandle(Canvas canvas, Size size) {
    /// 绘制Grid
    paintGrid(canvas, size);

    /// 绘制蜡烛线
    paintCandleLine(canvas, size);

    /// 绘制X轴刻度数据
    printXAisTickData(canvas, size);

    /// 绘制最新价与刻度线
    paintLastPriceMark(canvas, size);
  }

  /// 绘制蜡烛线
  void paintCandleLine(Canvas canvas, Size size) {
    final data = curCandleData;
    int start = data.start;
    int end = data.end;

    final offset =
        canvasRight - data.offset - candleMargin + (candleActualWidth / 2);

    Offset? maxHihgOffset, minLowOffset;
    for (var i = start; i < end; i++) {
      final model = data.list[i];
      final dx = offset - (i - start) * candleActualWidth;
      final isRise = model.close >= model.open;
      final highOff = Offset(
        dx,
        canvasBottom - (model.high - data.min).toDouble() * dyFactor,
      );
      final lowOff = Offset(
        dx,
        canvasBottom - (model.low - data.min).toDouble() * dyFactor,
      );
      canvas.drawLine(
        highOff,
        lowOff,
        isRise ? riseLinePaint : downLinePaint,
      );
      final openOff = Offset(
        dx,
        canvasBottom - (model.open - data.min).toDouble() * dyFactor,
      );
      final closeOff = Offset(
        dx,
        canvasBottom - (model.close - data.min).toDouble() * dyFactor,
      );
      canvas.drawLine(
        openOff,
        closeOff,
        isRise ? riseBoldPaint : downBoldPaint,
      );

      if (isDrawPriceMark) {
        // 记录最大最小偏移量.
        if (model.high == data.max) {
          maxHihgOffset = highOff;
          // paintPriceMark(canvas, highOff, model.high);
        }
        if (model.low == data.min) {
          minLowOffset = lowOff;
          // paintPriceMark(canvas, lowOff, model.low);
        }
      }
    }

    //最后绘制在蜡烛图中的最大最小价钱标记
    if (isDrawPriceMark && maxHihgOffset != null && minLowOffset != null) {
      paintPriceMark(canvas, maxHihgOffset, data.max);
      paintPriceMark(canvas, minLowOffset, data.min);
    }
  }

  /// 绘制蜡烛图上最大最小值价钱标记.
  void paintPriceMark(
    Canvas canvas,
    Offset offset,
    Decimal val,
  ) {
    final flag = offset.dx > canvasWidthHalf ? -1 : 1;
    Offset endOffset = Offset(
      offset.dx + priceMarkLineWidth * flag,
      offset.dy,
    );
    canvas.drawLine(
      offset,
      endOffset,
      priceMarkLinePaint,
    );
    endOffset = Offset(
      endOffset.dx + flag * priceMarkMargin,
      endOffset.dy - priceMarkFontSize / 2,
    );

    final text = formatPrice(val);
    canvas.drawText(
      offset: endOffset,
      drawDirection: flag < 0 ? DrawDirection.rtl : DrawDirection.ltr,
      // canvasWidth: canvasRight,
      text: text,
      style: priceMarkTextStyle,
      maxLines: 1,
    );
  }

  /// 绘制最新价刻度线与价钱标记
  /// 1. 价钱标记始终展示在画板最右边.
  /// 2. 最新价向右移出屏幕后, 刻度线横穿整屏.
  ///    且展示在指定价钱区间内, 如超出边界, 则停靠在最高最低线上.
  /// 3. 最新价向左移动后, 刻度线根据最新价蜡烛线平行移动.
  void paintLastPriceMark(Canvas canvas, Size size) {
    final data = curCandleData;
    final model = data.latest;
    if (model == null) {
      logd('paintLastPriceMark > on data!');
      return;
    }

    if (data.start == 0) {
      // 最新价存在当前画板上
      final dxOffset =
          canvasRight - data.offset - candleMargin + (candleActualWidth / 2);
      final closeOff = Offset(
        dxOffset,
        canvasBottom - (model.close - data.min).toDouble() * dyFactor,
      );

      final text = formatPrice(model.close);
      canvas.drawText(
        offset: closeOff,
        drawDirection: DrawDirection.ltr,
        drawMargin: lastPriceMarkRectMargin,
        canvasWidth: canvasRight,
        text: text,
        style: lastPriceMarkTextStyle,
        textAlign: TextAlign.end,
        // textWidthBasis: TextWidthBasis.longestLine,
        padding: lastPriceMarkRectPadding,
        backgroundColor: lastPriceMarkRectBackgroundColor,
        borderRadius: lastPriceMarkRectBorderRadius,
        borderWidth: lastPriceMarkRectBorderWidth,
        borderColor: lastPriceMarkRectBorderColor,
      );
    } else {
      // 最新价已移出画板
    }
  }

  /// 绘制X轴刻度数据
  void printXAisTickData(Canvas canvas, Size size) {
    final data = curCandleData;
    final min = data.min;
    final yAxisStep = mainRectHeight / gridCount;
    final dx = mainRectWidth - tickTextWidth - tickTextPadding.horizontal;
    double dy = 0;
    for (int i = 1; i <= gridCount; i++) {
      dy = i * yAxisStep - tickTextFontSize;

      // final val = min.toDouble() + (i * yAxisStep - mainRect.top) / canvasHeight * data.dataHeight.toDouble();
      final val = min + ((i * yAxisStep - mainRect.top) / dyFactor).d;
      final text = formatPrice(val);

      canvas.drawText(
        offset: Offset(dx, dy),
        canvasWidth: canvasRight,
        text: text,
        style: tickTextStyle,
        textWidth: tickTextWidth,
        textAlign: TextAlign.end,
        padding: tickTextPadding,
        maxLines: 1,
      );
    }
  }

  /// 绘制Grid
  void paintGrid(Canvas canvas, Size size) {
    final yAxisStep = mainRectWidth / gridCount;
    final xAxisStep = mainRectHeight / gridCount;
    final paintX = gridXAxisLinePaint;
    final paintY = gridYAxisLinePaint;
    double dx = 0;
    double dy = 0;
    canvas.drawLine(
      Offset(0, dy),
      Offset(mainRectWidth, dy),
      paintX,
    );
    for (int i = 1; i < gridCount; i++) {
      dx = i * yAxisStep;
      dy = i * xAxisStep;
      // 绘制xAsix线
      canvas.drawLine(
        Offset(0, dy),
        Offset(mainRectWidth, dy),
        paintX,
      );
      // 绘制YAsix线
      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx, mainRectHeight),
        paintY,
      );
    }
    canvas.drawLine(
      Offset(0, mainRectHeight),
      Offset(mainRectWidth, mainRectHeight),
      paintX,
    );
  }
}
