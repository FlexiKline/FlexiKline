import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';
import '../extension/export.dart';
import '../render/export.dart';

/// 绘制蜡烛图以及相关指标数据
///   Canvas 布局参数图
///                      mainRectWidth
///   |------------------mainRect.top-----------------------|
///   |------------------mainPadding.top--------------------|
///   |mainPadding.left---+----------------mainPadding.right|
///   |   |---------------+canvasWidth------------------|   |
///   |-------------------+------------------canvasRight|   |
///   |mainRectHeight     |canvasHeight                     |
///   |   |---------------+---------------|-->startDx<--|---+-->paintDx<--...|
///   |canvasBottom------mainPadding.bottom-----------------|
///   |------------------mainRect.bottom--------------------|
mixin CandleBinding
    on KlineBindingBase, SettingBinding
    implements ICandlePainter, IDataSource {
  @override
  void initBinding() {
    super.initBinding();
    logd('init candle');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose candle');
  }

  /// 触发重绘蜡烛线.
  @override
  void markRepaintCandle() => repaintCandle.value++;
  ValueNotifier<int> repaintCandle = ValueNotifier(0);

  DateTime? _lastPaintTime;
  int get diffTime {
    // 计算两次绘制时间差
    return _lastPaintTime
            ?.difference(_lastPaintTime = DateTime.now())
            .inMilliseconds
            .abs() ??
        0;
  }

  @override
  void paintCandle(Canvas canvas, Size size) {
    logd('$diffTime paintCandle >>>>');

    calculateCandleIndexAndOffset();

    /// 绘制蜡烛图
    paintCandleChart(canvas, size);

    /// 绘制Y轴刻度数据
    printYAisTickData(canvas, size);
  }

  /// 绘制蜡烛图
  void paintCandleChart(Canvas canvas, Size size) {
    final data = curCandleData;
    if (data.list.isEmpty) return;
    int start = data.start;
    int end = data.end;

    final offset = startCandleDx;

    Offset? maxHihgOffset, minLowOffset;
    for (var i = start; i <= end; i++) {
      final model = data.list[i];
      final dx = offset - (i - start + 1) * candleActualWidth;
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
        isRise ? candleLineLongPaint : candleLineShortPaint,
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
        isRise ? candleBarLongPaint : candleBarShortPaint,
      );

      if (isDrawPriceMark) {
        // 记录最大最小偏移量.
        if (model.high == data.max) {
          maxHihgOffset = highOff;
        }
        if (model.low == data.min) {
          minLowOffset = lowOff;
        }
      }
    }

    // 最后绘制在蜡烛图中的最大最小价钱标记
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
      offset.dx + priceMarkLineLength * flag,
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

    final text = formatPrice(
      val,
      instId: curCandleData.req.instId,
      precision: curCandleData.req.precision,
    );
    canvas.drawText(
      offset: endOffset,
      drawDirection: flag < 0 ? DrawDirection.rtl : DrawDirection.ltr,
      text: text,
      style: priceMarkTextStyle,
      maxLines: 1,
    );
  }

  /// 绘制X轴刻度数据
  void printYAisTickData(Canvas canvas, Size size) {
    final data = curCandleData;
    final max = data.max;
    final yAxisStep = mainRectHeight / gridCount;
    final dx = mainRectWidth - tickTextWidth - tickTextPadding.horizontal;
    double dy = 0;
    for (int i = 1; i <= gridCount; i++) {
      dy = i * yAxisStep - tickTextFontSize;

      final val = max - ((i * yAxisStep - mainPadding.top) / dyFactor).d;
      final text = formatPrice(
        val,
        instId: curCandleData.req.instId,
        precision: curCandleData.req.precision,
      );

      canvas.drawText(
        offset: Offset(dx, dy),
        drawableSize: drawableSize,
        text: text,
        style: tickTextStyle,
        textWidth: tickTextWidth,
        textAlign: TextAlign.end,
        padding: tickTextPadding,
        maxLines: 1,
      );
    }
  }
}
