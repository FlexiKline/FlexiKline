import 'dart:math';

import 'package:flutter/material.dart';

import 'binding_base.dart';

mixin SettingBinding on KlineBindingBase {
  @override
  void initBinding() {
    super.initBinding();
    logd("setting init");
  }

  /// 主绘制区域(蜡烛图)
  Rect _mainRect = Rect.zero;
  Rect get mainRect => _mainRect;
  // 设置主绘制区域(蜡烛图)
  void setMainSize(Size size) {
    _mainRect = Rect.fromLTRB(
      0,
      0,
      size.width,
      size.height,
    );
  }

  /// 绘制区域真实宽高.
  double get canvasWidth => mainRect.width;
  double get canvasHeight => mainRect.height;

  /// 最大蜡烛宽度
  // double maxCandleWidth = 20;

  /// 单根蜡烛宽度
  double _candleWidth = 7.0;
  double get candleWidth => _candleWidth;
  set candleWidth(double width) {
    // 限制蜡烛宽度范围[1, 20]
    _candleWidth = width.clamp(1.0, 20.0);
  }

  /// 蜡烛间距
  double get margin => candleWidth / 7;

  /// 单根蜡烛所占据实际宽度
  double get candleActualWidth => candleWidth + margin;

  /// 绘制区域宽度内, 可绘制的蜡烛数
  int get maxCandleNums => (canvasWidth / candleActualWidth).ceil();
}
