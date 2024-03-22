import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'binding_base.dart';

mixin SettingBinding on KlineBindingBase {
  @override
  void initBinding() {
    super.initBinding();
    logd("setting init");
  }

  /// 一个像素的值.
  double get pixel {
    final mediaQuery = MediaQueryData.fromView(ui.window);
    return 1.0 / mediaQuery.devicePixelRatio;
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
  ///   |-------------mainRect.top----------------------------|
  ///   |------------------mainPadding.top--------------------|
  ///   |mainPadding.left---+----------------mainPadding.right|
  ///   |   |---------------+canvasWidth------------------|   |
  ///   |-------------------+------------------canvasRight|   |
  ///   |mainRectHeight     |canvasHeight                     |
  ///   |                   |                                 |
  ///   |canvasBottom------mainPadding.bottom-----------------|
  ///   |-------------mainRect.bottom-------------------------|
  /// 主绘制区域宽高
  double get mainRectWidth => mainRect.width;
  double get mainRectHeight => mainRect.height;

  /// 绘制区域真实宽.
  double get canvasWidth {
    return mainRectWidth - mainPadding.left - mainPadding.right;
  }

  double get canvasWidthHalf => canvasWidth / 2;

  /// 绘制区域真实高.
  double get canvasHeight {
    return mainRectHeight - mainPadding.top - mainPadding.bottom;
  }

  /// 绘制区域右边界值
  double get canvasRight => mainRectWidth - mainPadding.right;

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

  /// 单根蜡烛宽度
  double _candleWidth = 7.0;
  double candleMaxWidth = 20.0; // 最大蜡烛宽度
  double get candleWidth => _candleWidth;
  set candleWidth(double width) {
    // 限制蜡烛宽度范围[1, candleMaxWidth]
    _candleWidth = width.clamp(1.0, math.max(7, candleMaxWidth));
  }

  /// 蜡烛间距
  double get candleMargin => candleWidth / 7;

  /// 单根蜡烛所占据实际宽度
  double get candleActualWidth => candleWidth + candleMargin;

  /// 绘制区域宽度内, 可绘制的蜡烛数
  int get maxCandleCount => (canvasWidth / candleActualWidth).ceil();

  /// CandleBar上涨配置
  Paint get riseLinePaint => Paint()
    ..color = Colors.green
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  Paint get riseBoldPaint => Paint()
    ..color = Colors.green
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7;

  /// CandleBar下跌配置
  Paint get downLinePaint => Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  Paint get downBoldPaint => Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7;

  /// Grid Axis config
  // Grid Axis Count
  int gridCount = 5;
  int get gridXAxisCount => gridCount + 1; // 平分5份: 上下边线都展示
  int get gridYAxisCount => gridCount - 1; // 平分5份: 左右边线不展示
  Paint get gridXAxisLinePaint => Paint()
    ..color = Colors.grey.withOpacity(0.2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = pixel;
  Paint get gridYAxisLinePaint => Paint()
    ..color = Colors.grey.withOpacity(0.2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = pixel;

  /// X轴上的刻度线配置
  double tickTextFontSize = 10;
  double tickTextWidth = 100;
  EdgeInsets tickTextPadding = const EdgeInsets.only(
    right: 2,
  );
  Color tickTextColor = Colors.grey;
  double get tickTextHeight => tickTextFontSize;
  TextStyle get tickTextStyle => TextStyle(
        fontSize: tickTextFontSize,
        color: tickTextColor,
        overflow: TextOverflow.ellipsis,
      );

  /// 蜡烛图上最大最小价钱刻度线与价钱标记.
  bool isDrawPriceMark = true;
  double priceMarkFontSize = 10;
  double priceMarkTextWidth = 100;
  Color priceMarkColor = Colors.black;
  TextStyle get priceMarkTextStyle => TextStyle(
        fontSize: priceMarkFontSize,
        color: priceMarkColor,
        overflow: TextOverflow.ellipsis,
      );
  double priceMarkMargin = 1; // 价钱与线之前的间距
  double priceMarkLineWidth = 20; // 价钱指示线的长度
  // 价钱指示线的Paint
  Paint get priceMarkLinePaint => Paint()
    ..color = priceMarkColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  /// 蜡烛图上的当前价刻度线与价钱标记
  bool isDrawLastPriceMark = true;
  double lastPriceMarkFontSize = 10;
  double lastPriceMarkTextWidth = 100;
  Color lastPriceMarkColor = Colors.black;
  TextStyle get lastPriceMarkTextStyle => TextStyle(
        fontSize: lastPriceMarkFontSize,
        color: lastPriceMarkColor,
        overflow: TextOverflow.ellipsis,
        textBaseline: TextBaseline.alphabetic,
      );
  Paint get lastPriceMarkLinePaint => Paint()
    ..color = lastPriceMarkColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  // 最新价文本区域的背景相关配置.
  Color lastPriceMarkRectBackgroundColor = Colors.white;
  double lastPriceMarkRectBorderRadius = 3;
  double lastPriceMarkRectBorderWidth = 0.5;
  double lastPriceMarkRectMargin = 1;
  Color lastPriceMarkRectBorderColor = Colors.black;
  EdgeInsets lastPriceMarkRectPadding = const EdgeInsets.symmetric(
    horizontal: 2,
    vertical: 1,
  );
  bool isShowLastPriceUpdateTime = true; // 是否在最新价下面展示下次更新时间.

  /// 价钱格式化函数
  String Function(String instId, Decimal val, {int? precision})? priceFormat;
}
