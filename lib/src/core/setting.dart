import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'binding_base.dart';

mixin SettingBinding on KlineBindingBase {
  @override
  void initBinding() {
    super.initBinding();
    logd("init setting");
  }

  @override
  void dispose() {
    super.dispose();
    logd("dispose setting");
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

  ///  Canvas 布局参数图
  ///                      mainRectWidth
  ///   |------------------mainRect.top-----------------------|
  ///   |------------------mainPadding.top--------------------|
  ///   |mainPadding.left---+----------------mainPadding.right|
  ///   |   |---------------+canvasWidth------------------|   |
  ///   |-------------------+------------------canvasRight|   |
  ///   |mainRectHeight     |canvasHeight                     |
  ///   |                   |                                 |
  ///   |canvasBottom------mainPadding.bottom-----------------|
  ///   |------------------mainRect.bottom--------------------|
  /// 主绘制区域宽高
  double get mainRectWidth => mainRect.width;
  double get mainRectHeight => mainRect.height;

  /// 主绘制区域的大小
  Size get drawableSize => Size(mainRectWidth, mainRectHeight);

  /// 主图上下padding
  EdgeInsets mainPadding = const EdgeInsets.only(
    top: 20,
    bottom: 10,
    // right: 20,
  );

  /// X轴绘制区域真实宽.
  double get canvasWidth => mainRectWidth - mainPadding.horizontal;

  /// X轴上绘制区域半值.
  double get canvasWidthHalf => canvasWidth / 2;

  /// Y轴绘制区域真实高.
  double get canvasHeight => mainRectHeight - mainPadding.vertical;

  /// X轴主绘制区域的左边界值
  double get canvasLeft => mainPadding.left;

  /// X轴主绘制区域右边界值
  double get canvasRight => mainRectWidth - mainPadding.right;

  /// Y轴主绘制区域上边界值
  double get canvasTop => mainPadding.top;

  /// Y轴主绘制区域下边界值
  double get canvasBottom => mainRectHeight - mainPadding.bottom;

  /// 绘制区域左边最少空白比例
  /// 当蜡烛数量不足以绘制一屏, 向右移动到末尾时, 绘制区域左边最少留白区域占可绘制区域(canvasWidth)的比例
  double minPaintRate = 0.5;
  double get minPaintWidthInCanvas => canvasWidth * minPaintRate;

  /// 幅图上下padding
  EdgeInsets subPadding = const EdgeInsets.all(10);

  /// 最大蜡烛宽度
  double _candleMaxWidth = 40.0;
  double get candleMaxWidth => _candleMaxWidth;
  set candleMaxWidth(double width) {
    _candleMaxWidth = width.clamp(1.0, 100.0);
  }

  /// 单根蜡烛宽度
  double _candleWidth = 7.0;
  double get candleWidth => _candleWidth;
  set candleWidth(double width) {
    // 限制蜡烛宽度范围[1, candleMaxWidth]
    _candleWidth = width.clamp(1.0, candleMaxWidth);
  }

  /// 蜡烛间距
  double get candleMargin => candleWidth / 7;

  /// 单根蜡烛所占据实际宽度
  double get candleActualWidth => candleWidth + candleMargin;

  /// 单根蜡烛的一半
  double get candleWidthHalf => candleActualWidth / 2;

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
    ..strokeWidth = candleWidth;

  /// CandleBar下跌配置
  Paint get downLinePaint => Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  Paint get downBoldPaint => Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;

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
  Color tickTextColor = Colors.blue;
  double get tickTextHeight => tickTextFontSize;
  TextStyle get tickTextStyle => TextStyle(
        fontSize: tickTextFontSize,
        color: tickTextColor,
        overflow: TextOverflow.ellipsis,
      );

  /// 最大最小价钱刻度线与价钱标记.
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

  /// 最新价文本区域配置
  bool isDrawLastPriceMark = true;
  double lastPriceFontSize = 10;
  double lastPriceTextWidth = 100;
  Color lastPriceColor = Colors.black;
  TextStyle get lastPriceTextStyle => TextStyle(
        fontSize: lastPriceFontSize,
        color: lastPriceColor,
        overflow: TextOverflow.ellipsis,
        textBaseline: TextBaseline.alphabetic,
      );

  /// 是否在最新价下面展示下次更新时间.
  bool showLastPriceUpdateTime = true;

  /// 最新价文本区域的背景相关配置.
  Color lastPriceRectBackgroundColor = Colors.white;
  double lastPriceRectBorderRadius = 2;
  double lastPriceRectBorderWidth = 0.5;
  Color lastPriceRectBorderColor = Colors.black;
  EdgeInsets lastPriceRectMargin = const EdgeInsets.symmetric(
    horizontal: 1,
    // vertical: 1,
  );
  EdgeInsets lastPriceRectPadding = const EdgeInsets.symmetric(
    horizontal: 2,
    vertical: 1,
  );

  /// 最新价刻度线配置
  Color lastPriceMarkLineColor = Colors.black;
  double lastPriceMarkLineWidth = 1;
  Paint get lastPriceMarkLinePaint => Paint()
    ..color = lastPriceMarkLineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = lastPriceMarkLineWidth;
  List<double> lastPriceMarkLineDashes = const [3, 3];

  /// 价钱格式化函数
  String Function(String instId, Decimal val, {int? precision})? priceFormat;

  /// 价钱格式化函数
  /// TODO: 待数据格式化.
  String formatPrice(Decimal val, {int? precision, required String instId}) {
    int p = precision ?? 6; // TODO: 待优化
    if (priceFormat != null) {
      return priceFormat!.call(
        instId,
        val,
        precision: p,
      );
    }
    return val.toStringAsFixed(p);
  }
}
