import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'binding_base.dart';
import 'setting.dart';

mixin GridBinding on KlineBindingBase, SettingBinding {
  @override
  void initBinding() {
    super.initBinding();
    logd('init grid');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose grid');
  }

  void markRepaintGrid() => repaintGridBg.value++;
  ValueNotifier<int> repaintGridBg = ValueNotifier(0);

  void paintGridBg(Canvas canvas, Size size) {
    final yAxisStep = mainRectWidth / gridCount;
    final xAxisStep = mainDrawBottom / gridCount;
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
        Offset(dx, mainDrawBottom),
        paintY,
      );
    }
    canvas.drawLine(
      Offset(0, mainDrawBottom),
      Offset(mainRectWidth, mainDrawBottom),
      paintX,
    );
  }
}
