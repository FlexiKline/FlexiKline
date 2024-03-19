import 'package:flutter/material.dart';
import '../extension/export.dart';
import 'binding_base.dart';
import 'config.dart';
import 'data.dart';
import 'setting.dart';

abstract interface class ICandlePinter {
  void paintCandle(Canvas canvas, Size size);
}

mixin CandleBinding
    on KlineBindingBase, SettingBinding, ConfigBinding, DataBinding
    implements ICandlePinter {
  @override
  void initBinding() {
    super.initBinding();
    logd('candle init');
    // _instance = this;
  }

  double get dyFactor {
    return ((mainRect.top - mainRect.bottom).d / curCandleData.height)
        .toDouble();
  }

  @override
  void paintCandle(Canvas canvas, Size size) {
    final data = curCandleData;

    for (var i = 0; i < data.list.length; i++) {
      final model = data.list[i];
      final dx = mainRect.right - (i * 8 + 7 / 2);
      final isRise = model.close >= model.open;
      final highOff = Offset(
        dx,
        mainRect.bottom + (model.high - data.min).toDouble() * dyFactor,
      );
      final lowOff = Offset(
        dx,
        mainRect.bottom + (model.low - data.min).toDouble() * dyFactor,
      );

      canvas.drawLine(
        highOff,
        lowOff,
        isRise ? riseLinePaint : downLinePaint,
      );
      final openOff = Offset(
        dx,
        mainRect.bottom + (model.open - data.min).toDouble() * dyFactor,
      );
      final closeOff = Offset(
        dx,
        mainRect.bottom + (model.close - data.min).toDouble() * dyFactor,
      );
      canvas.drawLine(
        openOff,
        closeOff,
        isRise ? riseBoldPaint : downBoldPaint,
      );
    }
  }
}
