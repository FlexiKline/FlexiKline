import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:kline/kline.dart';

import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

/// 绘制蜡烛图以及相关指标数据
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

    /// 绘制Y轴价钱刻度数据
    paintYAxisPriceTick(canvas, size);

    /// 绘制X轴时间刻度数据. 在paintCandleChart调用
    // paintXAxisTimeTick(canvas);
  }

  /// 绘制蜡烛图
  void paintCandleChart(Canvas canvas, Size size) {
    final data = curCandleData;
    if (data.list.isEmpty) return;
    int start = data.start;
    int end = data.end;

    final offset = startCandleDx;
    final bar = data.timerBar;
    Offset? maxHihgOffset, minLowOffset;
    for (var i = start; i <= end; i++) {
      final model = data.list[i];
      final dx = offset - (i - start + 1) * candleActualWidth;
      final isRise = model.close >= model.open;
      final highOff = Offset(
        dx,
        mainDrawBottom - (model.high - data.min).toDouble() * dyFactor,
      );
      final lowOff = Offset(
        dx,
        mainDrawBottom - (model.low - data.min).toDouble() * dyFactor,
      );
      canvas.drawLine(
        highOff,
        lowOff,
        isRise ? candleLineLongPaint : candleLineShortPaint,
      );
      final openOff = Offset(
        dx,
        mainDrawBottom - (model.open - data.min).toDouble() * dyFactor,
      );
      final closeOff = Offset(
        dx,
        mainDrawBottom - (model.close - data.min).toDouble() * dyFactor,
      );
      canvas.drawLine(
        openOff,
        closeOff,
        isRise ? candleBarLongPaint : candleBarShortPaint,
      );

      if (bar != null && i % timeTextOffsetCandleCounts == 0) {
        // 绘制X轴时间刻度.
        paintXAxisTimeTick(
          canvas,
          bar: bar,
          model: model,
          offset: Offset(
            dx + timeTextWidth / 2,
            mainDrawBottom,
          ),
        );
      }

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
    final flag = offset.dx > mainDrawWidthHalf ? -1 : 1;
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

  /// 绘制X轴时间刻度 (paintCandleChart遍历时触发)
  void paintXAxisTimeTick(
    Canvas canvas, {
    required TimeBar bar,
    required CandleModel model,
    required Offset offset,
  }) {
    // final data = curCandleData;
    // if (data.list.isEmpty) return;

    // int start = data.start;
    // int end = data.end;
    // final offset = startCandleDx;
    // final bar = data.timerBar;
    // for (var i = start; i <= end; i++) {
    //   final model = data.list[i];
    //   final dx = offset - (i - start + 1) * candleActualWidth;
    //   if (bar != null && i % timeTextOffsetCandleCounts == 0) {
    // 绘制X轴时间刻度.
    canvas.drawText(
      offset: offset,
      drawDirection: DrawDirection.rtl,
      text: model.formatDateTimeByTimeBar(bar),
      style: timeTextStyle,
      textWidth: timeTextWidth,
      textAlign: TextAlign.center,
    );
    //   }
    // }
  }

  /// 绘制Y轴价钱刻度数据
  void paintYAxisPriceTick(Canvas canvas, Size size) {
    final data = curCandleData;
    final max = data.max;
    final yAxisStep = mainDrawBottom / gridCount;
    final dx = mainRectWidth;
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
        drawDirection: DrawDirection.rtl,
        drawableSize: mainRectSize,
        text: text,
        style: tickTextStyle,
        // textWidth: tickTextWidth,
        textAlign: TextAlign.end,
        padding: tickTextPadding,
        maxLines: 1,
      );
    }
  }
}
