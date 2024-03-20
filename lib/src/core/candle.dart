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
    final data = curCandleData;
    int start = data.start;
    int end = data.end;
    double offset = canvasWidth - data.offset + (candleActualWidth / 2);

    for (var i = start; i < end; i++) {
      final model = data.list[i];
      final dx = offset - ((i - start) * candleActualWidth);
      final isRise = model.close >= model.open;
      final highOff = Offset(
        dx,
        canvasHeight + (model.high - data.min).toDouble() * dyFactor,
      );
      final lowOff = Offset(
        dx,
        canvasHeight + (model.low - data.min).toDouble() * dyFactor,
      );
      canvas.drawLine(
        highOff,
        lowOff,
        isRise ? riseLinePaint : downLinePaint,
      );
      final openOff = Offset(
        dx,
        canvasHeight + (model.open - data.min).toDouble() * dyFactor,
      );
      final closeOff = Offset(
        dx,
        canvasHeight + (model.close - data.min).toDouble() * dyFactor,
      );
      canvas.drawLine(
        openOff,
        closeOff,
        isRise ? riseBoldPaint : downBoldPaint,
      );
    }
  }
}
