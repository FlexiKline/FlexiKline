import 'package:flutter/material.dart';
import 'package:kline/src/render/draw_text.dart';
import 'binding_base.dart';
import 'config.dart';
import 'data_mgr.dart';
import 'setting.dart';

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
  }

  /// 绘制蜡烛线
  void paintCandleLine(Canvas canvas, Size size) {
    final data = curCandleData;
    int start = data.start;
    int end = data.end;

    double offset =
        canvasRight - data.offset - candleMargin + (candleActualWidth / 2);
    // offset ? + (candleActualWidth / 2)

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

  /// 绘制X轴刻度数据
  void printXAisTickData(Canvas canvas, Size size) {
    final data = curCandleData;
    final min = data.min;
    // final tickStep = data.dataHeight.toDouble() / gridCount;
    final yAxisStep = mainRectHeight / gridCount;
    final dx = mainRectWidth - tickTextWidth;
    double dy = 0;
    for (int i = 1; i <= gridCount; i++) {
      dy = i * yAxisStep - tickTextFontSize;

      // final val = min.toDouble() + (i * yAxisStep - mainRect.top) / canvasHeight * data.dataHeight.toDouble();
      final val = min.toDouble() + (i * yAxisStep - mainRect.top) / dyFactor;

      final text = val.toStringAsFixed(6); // TODO: 待数据格式化.
      canvas.drawText(
        offset: Offset(dx, dy),
        text: text,
        style: tickTextStyle,
        textWidth: 100,
        textAlign: TextAlign.end,
        // padding: EdgeInsets.only(right: 10),
        maxLines: 1,
      );
    }
  }
}
