// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../constant.dart';
import '../model/export.dart';
import '../utils/export.dart';
import 'binding_base.dart';
import 'interface.dart';

mixin SettingBinding on KlineBindingBase implements IConfig {
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

  VoidCallback? onSizeChange;

  Color longColor = Colors.green;
  Color shortColor = Colors.red;

  /// 一个像素的值.
  double get pixel {
    final mediaQuery = MediaQueryData.fromView(ui.window);
    return 1.0 / mediaQuery.devicePixelRatio;
  }

  /// 整个画布区域大小 = 由主图区域 + 副图区域
  Rect get canvasRect => Rect.fromLTRB(
        mainRect.left,
        mainRect.top,
        math.max(mainRectSize.width, subRectSize.width),
        mainRectSize.height + subRectSize.height,
      );
  double get canvasWidth => canvasRect.width;
  double get canvasHeight => canvasRect.height;

  /// 主图区域大小
  Rect _mainRect = Rect.zero;
  Rect get mainRect => _mainRect;
  Size get mainRectSize => Size(mainRect.width, mainRect.height);
  void setMainSize(Size size) {
    _mainRect = Rect.fromLTRB(
      0,
      0,
      size.width,
      size.height,
    );
    onSizeChange?.call();
  }

  /// 主图总宽度
  double get mainRectWidth => mainRect.width;

  /// 主图总高度
  double get mainRectHeight => mainRect.height;

  /// 主图区域的tips高度
  double mainTipsHeight = 20;

  /// 主图上下padding
  EdgeInsets mainPadding = const EdgeInsets.only(
    bottom: 15,
  );

  Rect get mainDrawRect => Rect.fromLTRB(
        mainRect.left + mainPadding.left,
        mainRect.top + mainPadding.top,
        mainRect.right - mainPadding.right,
        mainRect.bottom - mainPadding.bottom,
      );

  /// X轴主绘制区域真实宽.
  double get mainDrawWidth => mainRectWidth - mainPadding.horizontal;

  /// Y轴主绘制区域真实高.
  double get mainDrawHeight => mainRectHeight - mainPadding.vertical;

  /// X轴上主绘制区域宽度的半值.
  double get mainDrawWidthHalf => mainDrawWidth / 2;

  /// X轴主绘制区域的左边界值
  double get mainDrawLeft => mainPadding.left;

  /// X轴主绘制区域右边界值
  double get mainDrawRight => mainRectWidth - mainPadding.right;

  /// Y轴主绘制区域上边界值
  double get mainDrawTop => mainPadding.top;

  /// Y轴主绘制区域下边界值
  double get mainDrawBottom => mainRectHeight - mainPadding.bottom;

  bool checkOffsetInMainRect(Offset offset) {
    return mainRect.contains(offset);
  }

  double clampDxInMain(double dx) => dx.clamp(mainDrawLeft, mainDrawRight);
  double clampDyInMain(double dy) => dy.clamp(mainDrawTop, mainDrawBottom);

  /// 绘制区域最少留白比例
  /// 例如: 当蜡烛数量不足以绘制一屏, 向右移动到末尾时, 绘制区域左边最少留白区域占可绘制区域(canvasWidth)的比例
  double _minPaintBlankRate = 0.5;
  double get minPaintBlankRate => _minPaintBlankRate;
  set minPaintBlankRate(double val) {
    _minPaintBlankRate = val.clamp(0, 0.9);
  }

  /// 绘制区域最少留白宽度.
  double get minPaintBlankWidth => mainDrawWidth * minPaintBlankRate;

  // Gesture Pan
  // 平移结束后, candle惯性平移, 持续的最长时间.
  int panMaxDurationWhenPanEnd = 1000;
  // 平移结束后, candle惯性平移, 此时每一帧移动的最大偏移量. 值越大, 移动的会越远.
  double panMaxOffsetPreFrameWhenPanEnd = 30.0;

  /// 最大蜡烛宽度[1, 50]
  double _candleMaxWidth = 40.0;
  double get candleMaxWidth => _candleMaxWidth;
  set candleMaxWidth(double width) {
    _candleMaxWidth = width.clamp(1.0, 50.0);
  }

  /// 单根蜡烛宽度
  double _candleWidth = 8.0;
  double get candleWidth => _candleWidth;
  set candleWidth(double width) {
    // 限制蜡烛宽度范围[1, candleMaxWidth]
    _candleWidth = width.clamp(1.0, candleMaxWidth);
  }

  /// 蜡烛间距
  double get candleMargin => candleWidth / 8;

  /// 单根蜡烛所占据实际宽度
  double get candleActualWidth => candleWidth + candleMargin;

  /// 单根蜡烛的一半
  double get candleWidthHalf => candleActualWidth / 2;

  /// 绘制区域宽度内, 可绘制的蜡烛数
  int get maxCandleCount => (mainDrawWidth / candleActualWidth).ceil();

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

  // Candle 第一根Candle相对于mainRect右边的偏移
  double firstCandleInitOffset = 80;

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

  /// Y轴上价钱刻度线配置
  double priceTickFontSize = 10;
  EdgeInsets priceTickRectPadding = const EdgeInsets.only(
    right: 2,
  );
  Color priceTickColor = Colors.black;
  double get priceTickRectHeight {
    final textHeight = priceTickFontSize * (priceTickStyle.height ?? 1);
    return textHeight + priceTickRectPadding.vertical;
  }

  TextStyle get priceTickStyle => TextStyle(
        fontSize: priceTickFontSize,
        color: priceTickColor,
        overflow: TextOverflow.ellipsis,
        height: 1,
      );

  /// X轴上时间刻度线配置
  double timeTickFontSize = 10;
  double timeTickRectWidth = 70;
  double timeTickSpacing = 10;
  int get timeTickIntervalCandleCounts {
    return ((timeTickRectWidth + timeTickSpacing) / candleActualWidth).round();
  }

  Color timeTickColor = Colors.black;
  TextStyle get timeTickStyle => TextStyle(
        fontSize: timeTickFontSize,
        color: timeTickColor,
        overflow: TextOverflow.ellipsis,
        height: mainPadding.bottom / timeTickFontSize,
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
  double lastPriceRectRightMargin = 1;
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

  // 是否展示Cross Y轴上的价钱标记.
  // bool showCrossYAxisTickMark = true;
  // cross Y轴对应刻度文本区域配置 (价钱, Volume ...)
  double crossYTickFontSize = 10;
  double crossYTickTextWidth = 100; // TODO 暂无用
  Color crossYTickColor = Colors.white;
  TextStyle get crossYTickTextStyle => TextStyle(
        fontSize: crossYTickFontSize,
        color: crossYTickColor,
        overflow: TextOverflow.ellipsis,
        height: 1,
        textBaseline: TextBaseline.alphabetic,
      );
  // cross Y轴对应刻度文本区域配置
  Color crossYTickRectBackgroundColor = Colors.black;
  double crossYTickRectBorderRadius = 2;
  double crossYTickRectBorderWidth = 0.0;
  Color crossYTickRectBorderColor = Colors.transparent;
  double crossYTickRectRigthMargin = 1;
  EdgeInsets crossYTickRectPadding = const EdgeInsets.symmetric(
    horizontal: 2,
    vertical: 2,
  );
  // cross YAxis Tick Rect总高度.
  double get crossYTickRectHeight {
    final textHeight = crossYTickFontSize * (crossYTickTextStyle.height ?? 1);
    return textHeight + crossYTickRectPadding.vertical;
  }

  /// Cross X轴对应刻度文本配置(时间)
  bool showCrossXAxisTickMark = true;
  double crossXTickFontSize = 10;
  double crossXTickTextWidth = 100; // TODO 暂无用
  Color crossXTickColor = Colors.white;
  TextStyle get crossXTickTextStyle => TextStyle(
        fontSize: crossXTickFontSize,
        color: crossXTickColor,
        overflow: TextOverflow.ellipsis,
        height: 1,
        textBaseline: TextBaseline.alphabetic,
      );
  // cross X轴对应刻度文本区域的配置
  Color crossXTickRectBackgroundColor = Colors.black;
  double crossXTickRectBorderRadius = 2;
  double crossXTickRectBorderWidth = 0.0;
  Color crossXTickRectBorderColor = Colors.transparent;
  EdgeInsets crossXTickRectPadding = const EdgeInsets.symmetric(
    horizontal: 2,
    vertical: 2,
  );
  double get crossXTickRectHeight {
    final textHeight = crossXTickFontSize * (crossXTickTextStyle.height ?? 1);
    return textHeight + crossXTickRectPadding.vertical;
  }

  // candle Card 配置
  bool showPopupCandleCard = true;

  // candle Card background config.
  Color candleCardRectBackgroundColor = const Color(0xFFF2F2F2);
  double candleCardRectBorderRadius = 4;
  EdgeInsets candleCardRectMargin = const EdgeInsets.only(
    left: 15,
    right: 65,
    top: 4,
  );
  EdgeInsets candleCardRectPadding = const EdgeInsets.symmetric(
    horizontal: 4,
    vertical: 4,
  );

  double candleCardFontSize = 10;
  double candleCardTextHeight = 1.5; // 文本跨度的高度，为字体大小的倍数
  TextStyle get candleCardTextStyle => TextStyle(
        fontSize: candleCardFontSize,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
        height: candleCardTextHeight,
        textBaseline: TextBaseline.alphabetic,
      );

  // candle Card Title Style
  TextStyle? _candleCardTitleStyle;
  TextStyle get candleCardTitleStyle =>
      _candleCardTitleStyle ?? candleCardTextStyle;
  set candleCardTitleStyle(TextStyle style) => _candleCardTitleStyle = style;

  // candle Card Value Style
  TextStyle? _candleCardValueStyle;
  TextStyle get candleCardValueStyle =>
      _candleCardValueStyle ?? candleCardTextStyle;
  set candleCardValueStyle(TextStyle style) => _candleCardValueStyle = style;

  // Cross Candle Long Style
  TextStyle? _candleCardLongStyle;
  TextStyle get candleCardLongStyle =>
      _candleCardLongStyle ??
      candleCardTextStyle.copyWith(
        color: longColor,
      );
  set candleCardLongStyle(TextStyle style) => _candleCardLongStyle = style;

  // candle Card Short Style
  TextStyle? _candleCardShortStyle;
  TextStyle get candleCardShortStyle =>
      _candleCardShortStyle ??
      candleCardTextStyle.copyWith(
        color: shortColor,
      );
  set candleCardShortStyle(TextStyle style) => _candleCardShortStyle = style;

  // candle Card信息多语言配置.
  List<String> _i18nCandleCardKeys = i18nCandleCardEn;
  List<String> get i18nCandleCardKeys => _i18nCandleCardKeys;
  set i18nCandleCardKeys(List<String> keys) {
    if (keys.isNotEmpty && keys.length == i18nCandleCardEn.length) {
      _i18nCandleCardKeys = keys;
    }
  }

  //////////////////////////////////////

  /// 价钱格式化函数
  String Function(String instId, Decimal val,
      {int? precision, bool? cutInvalidZero})? priceFormat;

  /// 价钱格式化函数
  /// TODO: 待优化
  String formatPrice(
    Decimal val, {
    int? precision,
    required String instId,
    bool cutInvalidZero = true,
  }) {
    int p = precision ?? defaultPrecision;
    if (priceFormat != null) {
      return priceFormat!.call(
        instId,
        val,
        precision: p,
        cutInvalidZero: cutInvalidZero,
      );
    }
    return formatNumber(
      val,
      precision: p,
      cutInvalidZero: cutInvalidZero,
      // showThousands: true,
    );
  }

  /// 时间格式化函数
  String Function(DateTime dateTime)? dateTimeFormat;
  String formatDateTime(DateTime dateTime) {
    if (dateTimeFormat != null) {
      return dateTimeFormat!.call(dateTime);
    }
    return formatyyMMddHHMMss(dateTime);
  }

  /// 定制展示Candle Card info.
  List<CardInfo> Function(CandleModel model)? customCandleCardInfo;

  ///////////////////////////////////////////
  /// 以下是副图的绘制配置 /////////////////////
  //////////////////////////////////////////
  /// 副图区域大小
  Rect get subRect => Rect.fromLTRB(
        mainRect.left,
        mainRect.bottom,
        mainRect.right,
        mainRect.bottom + subRectHeight,
      );

  /// 副区的单个指标图高度
  double subIndicatorChartHeight = 80;

  /// 副区的指标图最大数量
  int subIndicatorChartMaxCount = 4;

  Size get subRectSize => Size(subRect.width, subRect.height);

  /// Volume Bar
  Paint get volBarLongPaint => Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;
  Paint get volBarShortPaint => Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;
  // Volume Bar Y轴刻度数量
  int volBarYAxisTickCount = 3; // 高中低=>top, middle, bottom
  double volBarTickFontSize = 10;
  Color volBarTickColor = Colors.black;
  TextStyle get volBarTickStyle => TextStyle(
        fontSize: volBarTickFontSize,
        color: volBarTickColor,
        overflow: TextOverflow.ellipsis,
        height: 1,
      );
  EdgeInsets volBarTickRectPadding = const EdgeInsets.only(
    right: 2,
  );
  double get volBarTickRectHeight {
    final textHeight = volBarTickFontSize * (volBarTickStyle.height ?? 1);
    return textHeight + volBarTickRectPadding.vertical;
  }

  /// Volume Tooltip 区域配置
  double volTipFontSize = 10;
  Color volTipColor = Colors.black;
  TextStyle get volTipStyle => TextStyle(
        fontSize: volTipFontSize,
        color: volTipColor,
        overflow: TextOverflow.ellipsis,
        height: 1,
      );
  EdgeInsets volTipRectPadding = const EdgeInsets.only(
    left: 8,
  );
}
