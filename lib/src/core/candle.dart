import 'package:flutter/material.dart';
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
    return -canvasHeight / curCandleData.height.toDouble();
  }

  @override
  void paintCandle(Canvas canvas, Size size) {
    /// 绘制Grid
    paintGrid(canvas, size);

    /// 绘制X轴刻度线
    printXAisTickLine(canvas, size);

    /// 绘制蜡烛线
    paintCandleLine(canvas, size);
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
        canvasBottom + (model.high - data.min).toDouble() * dyFactor,
      );
      final lowOff = Offset(
        dx,
        canvasBottom + (model.low - data.min).toDouble() * dyFactor,
      );
      canvas.drawLine(
        highOff,
        lowOff,
        isRise ? riseLinePaint : downLinePaint,
      );
      final openOff = Offset(
        dx,
        canvasBottom + (model.open - data.min).toDouble() * dyFactor,
      );
      final closeOff = Offset(
        dx,
        canvasBottom + (model.close - data.min).toDouble() * dyFactor,
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
    final yAxisItem = mainRectWidth / gridCount;
    final xAxisItem = mainRectHeight / gridCount;
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
      dx = i * yAxisItem;
      dy = i * xAxisItem;
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

  /// 绘制X轴刻度线
  void printXAisTickLine(Canvas canvas, Size size) {
    final data = curCandleData;
    final xAxisItem = mainRectHeight / gridCount;
    double dx = 0;
    // for (int i = 1; i < gridCount; i++) {
    //   dx = i * yAxisItem;
    //   dy = i * xAxisItem;
    //   // 绘制xAsix刻度

    // }
  }
}
