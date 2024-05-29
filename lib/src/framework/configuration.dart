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

import 'package:flutter/material.dart';

import '../config/export.dart';

abstract interface class IFlexiKlineTheme {
  /// 缓存Key
  String get key;

  /// 实际尺寸与UI设计的比例
  double get scale;

  /// 一个像素的值
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
  Color get transparent;
  Color get lastPriceTextBg;

  /// 分隔线
  Color get gridLine;
  Color get crosshair;
  Color get priceMarkLine;

  /// 文本颜色配置
  Color get textColor;
  Color get tickTextColor;
  Color get lastPriceTextColor;
  Color get crossTextColor;
  Color get tooltipTextColor;
}

abstract class FlexiKlineTheme implements IFlexiKlineTheme {
  FlexiKlineTheme({
    required this.long,
    required this.short,
    required this.chartBg,
    required this.tooltipBg,
    required this.countDownTextBg,
    required this.crossTextBg,
    this.transparent = Colors.transparent,
    required this.lastPriceTextBg,
    required this.gridLine,
    required this.crosshair,
    required this.priceMarkLine,
    required this.textColor,
    required this.tickTextColor,
    required this.lastPriceTextColor,
    required this.crossTextColor,
    required this.tooltipTextColor,
  });

  FlexiKlineTheme.simple({
    required this.long,
    required this.short,
    required this.chartBg,
    required Color markBg,
    required this.crossTextBg,
    this.transparent = Colors.transparent,
    required this.lastPriceTextBg,
    required Color color,
    required this.gridLine,
    required this.tickTextColor,
    required this.crossTextColor,
  })  : tooltipBg = markBg,
        countDownTextBg = markBg,
        crosshair = color,
        priceMarkLine = color,
        textColor = color,
        lastPriceTextColor = color,
        tooltipTextColor = color;

  @override
  late Color long;
  @override
  late Color short;

  /// 背景色
  @override
  late Color chartBg;
  @override
  late Color tooltipBg;
  @override
  late Color countDownTextBg;
  @override
  late Color crossTextBg;
  @override
  late Color transparent;
  @override
  late Color lastPriceTextBg;

  /// 分隔线
  @override
  late Color gridLine;
  @override
  late Color crosshair;
  @override
  late Color priceMarkLine;

  /// 文本颜色配置
  @override
  late Color textColor;
  @override
  late Color tickTextColor;
  @override
  late Color lastPriceTextColor;
  @override
  late Color crossTextColor;
  @override
  late Color tooltipTextColor;
}

abstract interface class IConfiguration {
  /// FlexiKline初始或默认的主区的宽高.
  Size get initialMainSize;

  /// 获取FlexiKline配置
  /// 1. 如果本地有缓存, 则从缓存中获取.
  /// 2. 如果本地没有缓存, 根据当前主题生成一套FlexiKline配置.
  FlexiKlineConfig getFlexiKlineConfig();

  /// 保存[config]配置信息到本地; 通过FlexiKlineController调用.
  void saveFlexiKlineConfig(FlexiKlineConfig config);
}
