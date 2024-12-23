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

import 'package:flutter/painting.dart';

import '../constant.dart';
import '../config/export.dart';
import 'chart/indicator.dart';
import 'draw/overlay.dart';

/// FlexiKline主题接口.
///
/// 定义FlexiKline中通用颜色
abstract interface class IFlexiKlineTheme {
  /// 缓存Key
  String get key;

  /// 实际尺寸与UI设计的比例
  double get scale;

  /// 一个物理像素的值
  double get pixel;

  ///根据宽度或高度中的较小值进行适配
  /// - [size] UI设计上的尺寸大小, 单位dp.
  double setDp(num size);

  //字体大小适配方法
  ///- [fontSize] UI设计上字体的大小,单位dp.
  double setSp(num fontSize);

  /// 涨跌颜色
  Color get long;
  Color get short;

  // 背景色
  Color get chartBg;
  Color get tooltipBg;
  Color get countDownTextBg;
  Color get crossTextBg;
  Color get drawTextBg;
  Color get transparent;
  Color get lastPriceTextBg;

  /// 分隔线
  Color get gridLine;
  Color get crossColor;
  Color get drawColor;
  Color get markLine;

  /// 主题色
  Color get themeColor;

  /// 文本颜色配置
  Color get textColor;
  Color get ticksTextColor;
  Color get lastPriceTextColor;
  Color get crossTextColor;
  Color get tooltipTextColor;
}

mixin FlexiKlineThemeTextStyle implements IFlexiKlineTheme {
  TextStyle getTextStyle(
    Color color, {
    double? fontSize,
    FontWeight? fontWeight,
    TextOverflow? overflow,
    double height = defaultTextHeight,
    TextBaseline textBaseline = TextBaseline.alphabetic,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize ?? defaulTextSize * scale,
      fontWeight: fontWeight,
      overflow: overflow,
      height: height,
      textBaseline: textBaseline,
    );
  }

  TextStyle get normalTextyStyle => TextStyle(
        color: textColor,
        fontSize: setSp(defaulTextSize),
        fontWeight: FontWeight.normal,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      );

  TextStyle get ticksTextStyle => TextStyle(
        color: ticksTextColor,
        fontSize: setSp(defaulTextSize),
        fontWeight: FontWeight.normal,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      );

  TextStyle get lastPriceTextStyle => TextStyle(
        color: lastPriceTextColor,
        fontSize: setSp(defaulTextSize),
        fontWeight: FontWeight.normal,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      );

  TextStyle get crossTextStyle => TextStyle(
        color: crossTextColor,
        fontSize: setSp(defaulTextSize),
        fontWeight: FontWeight.normal,
        height: defaultTextHeight,
      );

  TextStyle get tooltipTextStyle => TextStyle(
        color: tooltipTextColor,
        fontSize: setSp(defaulTextSize),
        overflow: TextOverflow.ellipsis,
        height: defaultMultiTextHeight,
      );

  TextStyle getTipsTextStyle(Color tipsColor) => TextStyle(
        color: tipsColor,
        fontSize: setSp(defaulTextSize),
        overflow: TextOverflow.ellipsis,
        height: defaultTipsTextHeight,
      );
}

/// FlexiKline配置接口
abstract interface class IConfiguration {
  /// 当前配置主题
  IFlexiKlineTheme get theme;

  /// 获取FlexiKline配置
  /// 1. 如果本地有缓存, 则从缓存中获取.
  /// 2. 如果本地没有缓存, 根据当前主题生成一套FlexiKline配置.
  FlexiKlineConfig getFlexiKlineConfig();

  /// 保存[config]配置信息到本地.
  void saveFlexiKlineConfig(FlexiKlineConfig config);

  /// 蜡烛指标配置构造器(主区)
  IndicatorBuilder<CandleBaseIndicator> get candleIndicatorBuilder;

  /// 时间指标配置构造器(副区)
  IndicatorBuilder<TimeBaseIndicator> get timeIndicatorBuilder;

  /// 主区指标配置定制
  Map<IIndicatorKey, IndicatorBuilder> mainIndicatorBuilders();

  /// 副区指标配置定制
  Map<IIndicatorKey, IndicatorBuilder> subIndicatorBuilders();

  /// 绘制工具定制
  Map<IDrawType, DrawObjectBuilder> drawObjectBuilders();

  /// 从本地获取[instId]对应的绘制实例数据列表.
  Iterable<Overlay> getDrawOverlayList(String instId);

  /// 以[instId]为key, 持久化绘制实例列表[list]到本地中.
  void saveDrawOverlayList(String instId, Iterable<Overlay> list);
}
