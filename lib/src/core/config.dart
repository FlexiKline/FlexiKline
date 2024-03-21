import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'binding_base.dart';
import 'setting.dart';

mixin ConfigBinding on KlineBindingBase, SettingBinding {
  @override
  void initBinding() {
    super.initBinding();
    logd("config init");
  }

  Color background = Colors.red;

  void updateBackground() {
    logd("config updateBackground");
  }

  Paint get riseLinePaint => Paint()
    ..color = Colors.green
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  Paint get downLinePaint => Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  Paint get riseBoldPaint => Paint()
    ..color = Colors.green
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7;

  Paint get downBoldPaint => Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7;

  Paint get gridXAxisLinePaint => Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke
    ..strokeWidth = pixel;

  Paint get gridYAxisLinePaint => Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke
    ..strokeWidth = pixel;

  double get pixel {
    final mediaQuery = MediaQueryData.fromView(ui.window);
    return 1.0 / mediaQuery.devicePixelRatio;
  }

  double tickTextFontSize = 10;
  double tickTextWidth = 100;
  Color tickTextColor = Colors.black;
  double get tickTextHeight => tickTextFontSize;
  TextStyle get tickTextStyle => TextStyle(
        fontSize: tickTextFontSize,
        color: tickTextColor,
        overflow: TextOverflow.ellipsis,
      );
}
