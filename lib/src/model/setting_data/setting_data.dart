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
import 'package:json_annotation/json_annotation.dart';

import '../../constant.dart';
import '../../framework/serializers.dart';

part 'setting_data.g.dart';

@FlexiModelSerializable
class SettingData {
  SettingData({
    /// Long/Short颜色配置
    Color textColor = Colors.black,
    Color longColor = const Color(0xFF33BD65),
    Color shortColor = const Color(0xFFE84E74),
    this.opacity = 0.5,

    /// 内置LoadingView样式配置
    this.loadingProgressSize = 24,
    this.loadingProgressStrokeWidth = 4,
    this.loadingProgressBackgroundColor = const Color(0xFFECECEC),
    this.loadingProgressValueColor = Colors.black,

    /// 主/副图区域大小配置
    this.mainRect = Rect.zero,
    this.mainTipsHeight = 12,
    this.mainPadding = const EdgeInsets.only(bottom: 15),

    /// 主/副图绘制参数
    this.minPaintBlankRate = 0.5,
    this.alwaysCalculateScreenOfCandlesIfEnough = false,
    this.candleMaxWidth = 40.0,
    this.candleWidth = 7.0,
    this.candleSpacing = 1.0,
    this.candleLineWidth = 1.0,
    this.firstCandleInitOffset = 80,
    this.indicatorLineWidth = 1.0,

    /// Grid Axis conifg
    this.gridCount = 5,
    this.gridLineColor = const Color(0xffE9EDF0),
    this.gridLineWidth = 0.5,

    /// 全局默认文本配置: TextStyle / Background / Border
    TextStyle defaultTextStyle = const TextStyle(
      fontSize: 10,
      color: Colors.black,
      overflow: TextOverflow.ellipsis,
      height: 1,
    ),
    this.defaultPadding = const EdgeInsets.all(2),
    this.defaultBackground = Colors.white,
    this.defaultRadius = const BorderRadius.all(Radius.circular(2)),
    this.defaultBorder = const BorderSide(color: Colors.black, width: 0.5),
    TextStyle? longTextStyle,
    TextStyle? shortTextStyle,
    TextStyle? tipsTextStyle,
    this.tipsPadding = const EdgeInsets.only(left: 8),

    /// 全局默认的刻度值配置.
    // 刻度文本区域距离边框
    this.tickRectMargin = 1,
    TextStyle? tickTextStyle,
    this.tickPadding = const EdgeInsets.all(2),

    /// 标记线配置
    this.markLineWidth = 0.5,
    Color? markLineColor,

    /// Cross 通用配置
    this.crosshairLineWidth = 0.5,
    this.crosshairLineColor = Colors.black,
    this.crosshairLineDashes = const [3, 3],
    this.corssPointColor = Colors.black,
    this.crossPointRadius = 2,
    this.crossPointWidth = 6,
    // onCross时, 刻度配置 (价钱/数量/时间...)
    this.crossTickTextStyle = const TextStyle(
      fontSize: 10,
      color: Colors.white,
      overflow: TextOverflow.ellipsis,
      height: 1,
    ),
    this.crossTickBackground = Colors.black,
    this.crossTickPadding = const EdgeInsets.all(2),
    this.crossTickBorder = BorderSide.none,
    this.crossTickRadius = const BorderRadius.all(
      Radius.circular(2),
    ),

    /// 副图配置
    // 副区的指标图最大数量
    this.subChartMaxCount = defaultSubChartMaxCount,
    // 副图的指标图的右侧右侧刻度数量
    this.subIndicatorTickCount = 3, // 高中低=>top, middle, bottom
    // 副图指标图默认高度
    this.subIndicatorDefaultHeight = defaultSubIndicatorHeight,
    // 副图指标图默认Tips高度
    this.subIndicatorDefaultTipsHeight = defaultIndicatorTipsHeight,
    // 副图指标图默认Pading
    this.subIndicatorDefaultPadding = defaultIndicatorPadding,
  })  : textColor = textColor,
        longColor = longColor,
        shortColor = shortColor,
        markLineColor = markLineColor ?? textColor,
        defaultTextStyle = defaultTextStyle,
        longTextStyle =
            longTextStyle ?? defaultTextStyle.copyWith(color: longColor),
        shortTextStyle =
            shortTextStyle ?? defaultTextStyle.copyWith(color: shortColor),
        tipsTextStyle = tipsTextStyle ?? defaultTextStyle.copyWith(height: 1.2),
        tickTextStyle = tickTextStyle ?? defaultTextStyle;

  /// Long/Short颜色配置
  @JsonKey()
  final Color textColor;
  @JsonKey()
  final Color longColor;
  @JsonKey()
  final Color shortColor;
  @JsonKey()
  final double opacity;

  /// 内置LoadingView样式配置
  @JsonKey()
  final double loadingProgressSize;
  @JsonKey()
  final double loadingProgressStrokeWidth;
  @JsonKey()
  final Color loadingProgressBackgroundColor;
  @JsonKey()
  final Color loadingProgressValueColor;

  /// 主/副图区域大小配置
  @JsonKey()
  Rect mainRect;
  @JsonKey()
  double mainTipsHeight;
  @JsonKey()
  EdgeInsets mainPadding;

  /// 主/副图绘制参数
  // 绘制区域最少留白比例
  // 例如: 当蜡烛数量不足以绘制一屏, 向右移动到末尾时, 绘制区域左边最少留白区域占可绘制区域(canvasWidth)的比例
  @JsonKey()
  double minPaintBlankRate;
  // 如果足够总是计算一屏的蜡烛.
  // 当滑动或初始化时会存在(minPaintBlankRate)的空白, 此时, 计算按一屏的蜡烛数量向后计算.
  @JsonKey()
  bool alwaysCalculateScreenOfCandlesIfEnough;
  // 最大蜡烛宽度[1, 50]
  @JsonKey()
  double candleMaxWidth;
  // 单根蜡烛宽度
  @JsonKey()
  double candleWidth;
  // 蜡烛间距
  @JsonKey()
  double candleSpacing;
  // 蜡烛线宽(high, low)
  @JsonKey()
  double candleLineWidth;
  // Candle 第一根Candle相对于mainRect右边的偏移
  @JsonKey()
  double firstCandleInitOffset;
  // 指标线图的默认线宽
  @JsonKey()
  double indicatorLineWidth;

  /// 主/副图 Grid Axis conifg
  // 主图区域grid的数量
  @JsonKey()
  final int gridCount;
  @JsonKey()
  final Color gridLineColor;
  @JsonKey()
  final double gridLineWidth;

  /// 全局默认文本配置: TextStyle / Background / Border
  @JsonKey()
  final TextStyle defaultTextStyle;
  @JsonKey()
  final EdgeInsets defaultPadding;
  @JsonKey()
  final Color defaultBackground;
  @JsonKey()
  final BorderSide defaultBorder;
  @JsonKey()
  final BorderRadius defaultRadius;
  @JsonKey()
  final TextStyle longTextStyle;
  @JsonKey()
  final TextStyle shortTextStyle;
  // Tips文本样式
  @JsonKey()
  final TextStyle tipsTextStyle;
  // Tips文本的通用Padding
  @JsonKey()
  final EdgeInsets tipsPadding;

  /// 全局默认的刻度值配置.
  // 刻度文本区域距离边框
  @JsonKey()
  final double tickRectMargin;
  @JsonKey()
  final TextStyle tickTextStyle;
  @JsonKey()
  final EdgeInsets tickPadding;

  /// 标记线配置
  @JsonKey()
  final double markLineWidth;
  @JsonKey()
  final Color markLineColor;

  /// Cross 通用配置
  @JsonKey()
  final double crosshairLineWidth;
  @JsonKey()
  final Color crosshairLineColor;
  @JsonKey()
  final List<double> crosshairLineDashes;
  @JsonKey()
  final Color corssPointColor;
  @JsonKey()
  final double crossPointRadius;
  @JsonKey()
  final double crossPointWidth;
  // onCross时, 刻度配置 (价钱/数量/时间...)
  @JsonKey()
  final TextStyle crossTickTextStyle;
  @JsonKey()
  final Color crossTickBackground;
  @JsonKey()
  final EdgeInsets crossTickPadding;
  @JsonKey()
  final BorderSide crossTickBorder;
  @JsonKey()
  final BorderRadius crossTickRadius;

  /// 副图配置
  // 副区的指标图最大数量
  @JsonKey()
  int subChartMaxCount;
  // 副图的指标图的右侧右侧刻度数量
  @JsonKey()
  final int subIndicatorTickCount;
  // 副图指标图默认高度
  @JsonKey()
  final double subIndicatorDefaultHeight;
  // 副图指标图默认Tips高度
  @JsonKey()
  final double subIndicatorDefaultTipsHeight;
  // 副图指标图默认Pading
  @JsonKey()
  final EdgeInsets subIndicatorDefaultPadding;

  factory SettingData.fromJson(Map<String, dynamic> json) =>
      _$SettingDataFromJson(json);
  Map<String, dynamic> toJson() => _$SettingDataToJson(this);
}

extension SettingDataExt on SettingData {
  /// 指标图 涨跌 bar/line 配置
  Color get longTintColor => longColor.withOpacity(opacity);
  Color get shortTintColor => shortColor.withOpacity(opacity);
  // 实心
  Paint get defLongBarPaint => Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;
  Paint get defShortBarPaint => Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;
  // 实心, 浅色
  Paint get defLongTintBarPaint => Paint()
    ..color = longTintColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;
  Paint get defShortTintBarPaint => Paint()
    ..color = shortTintColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;
  // 空心
  Paint get defLongHollowBarPaint => Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  Paint get defShortHollowBarPaint => Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  // 线
  Paint get defLongLinePaint => Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleLineWidth;
  Paint get defShortLinePaint => Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleLineWidth;

  /// Cross 配置 ///
  Paint get crossLinePaint => Paint()
    ..color = crosshairLineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = crosshairLineWidth;
  // cross point
  Paint get crossPointPaint => Paint()
    ..color = corssPointColor
    ..strokeWidth = crossPointWidth
    ..style = PaintingStyle.fill;
}
