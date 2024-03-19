import 'package:flutter/material.dart';

import 'binding_base.dart';

mixin ConfigBinding on KlineBindingBase {
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
}
