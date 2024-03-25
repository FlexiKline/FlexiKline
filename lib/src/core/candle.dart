import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'binding_base.dart';
import 'data_source.dart';
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
    on KlineBindingBase, SettingBinding, DataSourceBinding
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

    curCandleData.calculateIndex(
      paintDxOffset,
      candleActualWidth,
    );
    curCandleData.calculateMaxmin();

    /// 绘制蜡烛图
    paintCandleChart(canvas, size);

    /// 绘制X轴刻度数据
    printXAisTickData(canvas, size);
  }

  /// 绘制蜡烛图
  void paintCandleChart(Canvas canvas, Size size) {
    final data = curCandleData;
    int start = data.start;
    int end = data.end;

    final offset = canvasRight - data.offset - candleMargin + candleWidthHalf;

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

    final text = formatPrice(val, instId: curCandleData.req.instId);
    canvas.drawText(
      offset: endOffset,
      drawDirection: flag < 0 ? DrawDirection.rtl : DrawDirection.ltr,
      // canvasWidth: canvasRight,
      text: text,
      style: priceMarkTextStyle,
      maxLines: 1,
    );
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
      final text = formatPrice(val, instId: curCandleData.req.instId);

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
