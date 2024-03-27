import 'dart:ui' as ui;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../constant.dart';
import '../utils/export.dart';
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

  Color longColor = Colors.green;
  Color shortColor = Colors.red;

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

  bool checkOffsetInCanvas(Offset offset) {
    return offset.dx > canvasLeft &&
        offset.dx < canvasRight &&
        offset.dy > canvasTop &&
        offset.dy < canvasBottom;
  }

  double clampDxInCanvas(double dx) => dx.clamp(canvasLeft, canvasRight);
  double clampDyInCanvas(double dy) => dy.clamp(canvasTop, canvasBottom);

  /// 绘制区域最少留白比例
  /// 例如: 当蜡烛数量不足以绘制一屏, 向右移动到末尾时, 绘制区域左边最少留白区域占可绘制区域(canvasWidth)的比例
  double _minPaintBlankRate = 0.5;
  double get minPaintBlankRate => _minPaintBlankRate;
  set minPaintBlankRate(double val) {
    _minPaintBlankRate = val.clamp(0, 0.9);
  }

  /// 绘制区域最少留白宽度.
  double get minPaintBlankWidth => canvasWidth * minPaintBlankRate;

  /// 留白按宽度minPaintBlankWidth来计算
  bool minPaintBlandUseWidth = true;

  /// 绘制区域最少留白可绘制蜡烛数.
  int get minPaintBlankCandleCount {
    return (minPaintBlankWidth / candleActualWidth).ceil();
  }

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

  /// CandleBar配置
  // Candle Line
  double candleLineWidth = 1;
  Paint get candleLineLongPaint => Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleLineWidth;
  Paint get candleLineShortPaint => Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleLineWidth;
  // Candle Bar
  Paint get candleBarLongPaint => Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;
  Paint get candleBarShortPaint => Paint()
    ..color = shortColor
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
  Color tickTextColor = Colors.black;
  double get tickTextHeight => tickTextFontSize;
  TextStyle get tickTextStyle => TextStyle(
        fontSize: tickTextFontSize,
        color: tickTextColor,
        overflow: TextOverflow.ellipsis,
        height: 1,
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
        height: 1,
      );
  double priceMarkMargin = 1; // 价钱与线之前的间距
  double priceMarkLineLength = 20; // 价钱指示线的长度
  double? priceMarkLineWidth; // 价钱指示线的绘制宽度
  // 价钱指示线的Paint
  Paint get priceMarkLinePaint => Paint()
    ..color = priceMarkColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = priceMarkLineWidth ?? pixel;

  /// 最新价文本区域配置
  bool isDrawLastPriceMark = true;
  double lastPriceFontSize = 10;
  double lastPriceTextWidth = 100; // TODO 暂无用
  Color lastPriceColor = Colors.black;
  TextStyle get lastPriceTextStyle => TextStyle(
        fontSize: lastPriceFontSize,
        color: lastPriceColor,
        overflow: TextOverflow.ellipsis,
        height: 1,
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
    vertical: 2,
  );

  /// 最新价刻度线配置
  Color lastPriceMarkLineColor = Colors.black;
  double? lastPriceMarkLineWidth; // 最新价X轴标志线的绘制宽度.
  Paint get lastPriceMarkLinePaint => Paint()
    ..color = lastPriceMarkLineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = lastPriceMarkLineWidth ?? pixel;
  List<double> lastPriceMarkLineDashes = const [3, 3];

  /// Cross 配置 ///
  // cross line
  Color crossLineColor = Colors.black;
  double crossLineWidth = 0.5;
  List<double> crossLineDashes = const [3, 3];
  Paint get crossLinePaint => Paint()
    ..color = crossLineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = crossLineWidth;
  // cross point
  Color corssPointColor = Colors.black;
  double crossPointRadius = 2;
  double crossPointWidth = 6;
  Paint get crossPointPaint => Paint()
    ..color = corssPointColor
    ..strokeWidth = crossPointWidth
    ..style = PaintingStyle.fill;
  // cross Y轴价钱文本配置
  // 是否展示Cross Y轴上的价钱标记.
  bool showCrossYAxisPriceMark = true;
  double crossPriceFontSize = 10;
  double crossPriceTextWidth = 100; // TODO 暂无用
  Color crossPriceColor = Colors.white;
  TextStyle get crossPriceTextStyle => TextStyle(
        fontSize: crossPriceFontSize,
        color: crossPriceColor,
        overflow: TextOverflow.ellipsis,
        height: 1,
        textBaseline: TextBaseline.alphabetic,
      );
  // cross Y轴最右边文本区域的背景相关配置.
  Color crossPriceRectBackgroundColor = Colors.black;
  double crossPriceRectBorderRadius = 2;
  double crossPriceRectBorderWidth = 0.0;
  Color crossPriceRectBorderColor = Colors.transparent;
  EdgeInsets crossPriceRectMargin = const EdgeInsets.symmetric(
    horizontal: 1,
    // vertical: 1,
  );
  EdgeInsets crossPriceRectPadding = const EdgeInsets.symmetric(
    horizontal: 2,
    vertical: 2,
  );
  // cross 价钱区域总高度.
  double get crossPriceRectHeight {
    return crossPriceFontSize +
        crossPriceRectPadding.vertical +
        crossPriceRectMargin.vertical;
  }

  // cross popup candle info 配置
  bool showPopupCrossCandleInfo = true;
  // Cross popup background config.
  Color crossCandleRectBackgroundColor = Colors.grey;
  double crossCandleRectBorderRadius = 2;
  double crossCandleRectBorderWidth = 0.0;
  Color crossCandleRectBorderColor = Colors.transparent;
  EdgeInsets crossCandleRectMargin = const EdgeInsets.symmetric(
    horizontal: 1,
  );
  EdgeInsets crossCandleRectPadding = const EdgeInsets.symmetric(
    horizontal: 2,
    vertical: 2,
  );

  double crossCandleFontSize = 10;
  double crossCandleTextHeight = 1.2; // 文本跨度的高度，为字体大小的倍数
  TextStyle get crossCandleTextStyle => TextStyle(
        fontSize: crossCandleFontSize,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
        height: crossCandleTextHeight,
        textBaseline: TextBaseline.alphabetic,
      );

  // Cross Candle Title Style
  TextStyle? _crossCandleTitleStyle;
  TextStyle get crossCandleTitleStyle =>
      _crossCandleTitleStyle ?? crossCandleTextStyle;
  set crossCandleTitleStyle(TextStyle style) => _crossCandleTitleStyle = style;

  // Cross Candle Value Style
  TextStyle? _crossCandleValueStyle;
  TextStyle get crossCandleValueStyle =>
      _crossCandleValueStyle ?? crossCandleTextStyle;
  set crossCandleValueStyle(TextStyle style) => _crossCandleValueStyle = style;

  // Cross Candle Long Style
  TextStyle? _crossCandleLongStyle;
  TextStyle get crossCandleLongStyle =>
      _crossCandleLongStyle ??
      crossCandleTextStyle.copyWith(
        color: longColor,
      );
  set crossCandleLongStyle(TextStyle style) => _crossCandleLongStyle = style;

  // Cross Candle Short Style
  TextStyle? _crossCandleShortStyle;
  TextStyle get crossCandleShortStyle =>
      _crossCandleShortStyle ??
      crossCandleTextStyle.copyWith(
        color: shortColor,
      );
  set crossCandleShortStyle(TextStyle style) => _crossCandleShortStyle = style;

  // Candle信息多语言配置.
  List<String> _i18nCandleKeys = i18nCandleEnKeys;
  List<String> get i18nCandleKeys => _i18nCandleKeys;
  set i18nCandleKeys(List<String> keys) {
    if (keys.isNotEmpty && keys.length == i18nCandleEnKeys.length) {
      _i18nCandleKeys = keys;
    }
  }

  //////////////////////////////////////

  /// 价钱格式化函数
  String Function(String instId, Decimal val, {int? precision})? priceFormat;

  /// 价钱格式化函数
  /// TODO: 待数据格式化.
  String formatPrice(Decimal val, {int? precision, required String instId}) {
    int p = precision ?? defaultPrecision; // TODO: 待优化
    if (priceFormat != null) {
      return priceFormat!.call(
        instId,
        val,
        precision: p,
      );
    }
    return val.toStringAsFixed(p);
  }

  /// 时间格式化函数
  String Function(DateTime dateTime)? dateTimeFormat;
  String formatDateTime(DateTime dateTime) {
    if (dateTimeFormat != null) {
      return dateTimeFormat!.call(dateTime);
    }
    return formatyyMMddHHMMss(dateTime);
  }
}
