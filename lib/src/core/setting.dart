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

  ///
  ///  --------------------------- mainRect.top
  ///   |                 ---------- mainPadding.top
  ///   |                   |
  ///   |mainRectHeight     | canvasHeight
  ///   |                   |
  ///   |canvasBaseHeight ---------- mainPadding.bottom
  ///  --------------------------- mainRect.bottom
  /// 主绘制区域宽高
  double get mainRectWidth => mainRect.width;
  double get mainRectHeight => mainRect.height;

  /// 绘制区域真实宽.
  double get canvasWidth {
    return mainRectWidth - mainPadding.left - mainPadding.right;
  }

  /// 绘制区域真实高.
  double get canvasHeight {
    return mainRectHeight - mainPadding.top - mainPadding.bottom;
  }

  /// 绘制区域右边界值
  double get canvasRight => mainRectHeight - mainPadding.right;

  /// 绘制区域下边界值
  double get canvasBottom => mainRectHeight - mainPadding.bottom;

  /// 主图上下padding
  EdgeInsets mainPadding = const EdgeInsets.only(
    top: 20,
    bottom: 10,
    // right: 20,
  );

  /// 幅图上下padding
  EdgeInsets subPadding = const EdgeInsets.all(10);

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
  double get candleMargin => candleWidth / 7;

  /// 单根蜡烛所占据实际宽度
  double get candleActualWidth => candleWidth + candleMargin;

  /// 绘制区域宽度内, 可绘制的蜡烛数
  int get maxCandleCount => (canvasWidth / candleActualWidth).ceil();

  /// Grid xAxis Count
  int gridCount = 5;
  int get gridXAxisCount => gridCount + 1; // 平分5份: 上下边线都展示
  int get gridYAxisCount => gridCount - 1; // 平分5份: 左右边线不展示
}
