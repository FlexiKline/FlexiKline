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

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';

import '../../constant.dart';
import '../../framework/serializers.dart';
import '../loading_config/loading_config.dart';
import '../text_area_config/text_area_config.dart';
import '../tolerance_config/tolerance_config.dart';

part 'setting_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class SettingConfig {
  SettingConfig({
    /// Long/Short颜色配置
    required this.textColor,
    required this.longColor,
    required this.shortColor,
    this.opacity = 0.5,

    /// 内置LoadingView样式配置
    required this.loading,

    /// 主/副图区域大小配置
    this.mainRect = Rect.zero,
    required this.mainMinSize,
    required this.mainPadding,
    this.mainDrawBelowTipsArea = true,

    /// 主/副图绘制参数
    this.minPaintBlankRate = 0.5,
    this.alwaysCalculateScreenOfCandlesIfEnough = false,
    required this.candleMaxWidth,
    required this.candleWidth,
    required this.candleSpacing,
    required this.candleLineWidth,
    required this.firstCandleInitOffset,

    /// 全局默认的刻度值配置.
    required this.tickText,

    /// 副图配置
    // 副区的指标图最大数量
    this.subChartMaxCount = defaultSubChartMaxCount,

    /// 手势平移限制参数
    ToleranceConfig? panTolerance,
  }) : panTolerance = panTolerance ?? ToleranceConfig();

  /// Long/Short颜色配置
  final Color textColor;
  final Color longColor;
  final Color shortColor;
  final double opacity;

  /// 内置LoadingView样式配置
  final LoadingConfig loading;

  /// 主区
  // 主区域大小配置
  Rect mainRect;
  // 主区域最小大小限制
  Size mainMinSize;
  // 主区域Padding
  EdgeInsets mainPadding;
  // 主区图表的绘制是否在Tips区域下
  bool mainDrawBelowTipsArea;

  /// 绘制区域最少留白比例
  /// 例如: 当蜡烛数量不足以绘制一屏, 向右移动到末尾时, 绘制区域左边最少留白区域占可绘制区域(canvasWidth)的比例
  double minPaintBlankRate;

  /// 如果足够总是计算一屏的蜡烛.
  /// 当滑动或初始化时会存在(minPaintBlankRate)的空白, 此时, 计算按一屏的蜡烛数量向后计算.
  bool alwaysCalculateScreenOfCandlesIfEnough;

  /// 蜡烛配置
  // 最大蜡烛宽度[1, 50]
  double candleMaxWidth;
  // 单根蜡烛宽度
  double candleWidth;
  // 蜡烛间距
  double candleSpacing;
  // 蜡烛线宽(high, low)
  double candleLineWidth;
  // Candle 第一根Candle相对于mainRect右边的偏移
  double firstCandleInitOffset;

  /// 全局默认的刻度值配置.
  final TextAreaConfig tickText;

  // 副区的指标图最大数量
  final int subChartMaxCount;

  /// 手势平移限制参数
  final ToleranceConfig panTolerance;

  void setMainRect(Size size) {
    if (size.isEmpty) {
      throw Exception('setMainRect($size) is invalid!!!');
    }
    mainRect = Rect.fromLTRB(
      0,
      0,
      size.width,
      size.height,
    );
  }

  // 确保最小Size必须小于MainSize.
  void checkAndFixMinSize() {
    final mainSize = mainRect.size;
    if (mainMinSize.width > mainSize.width) {
      mainMinSize = Size(mainSize.width, mainMinSize.height);
    }
    if (mainMinSize.height > mainSize.height) {
      mainMinSize = Size(mainMinSize.width, mainSize.height);
    }
  }

  void update(SettingConfig config) {
    mainRect = config.mainRect;
    mainMinSize = config.mainMinSize;
    mainPadding = config.mainPadding;
    mainDrawBelowTipsArea = config.mainDrawBelowTipsArea;
    minPaintBlankRate = config.minPaintBlankRate;
    alwaysCalculateScreenOfCandlesIfEnough =
        config.alwaysCalculateScreenOfCandlesIfEnough;
    candleMaxWidth = config.candleMaxWidth;
    candleWidth = config.candleWidth;
    candleSpacing = config.candleSpacing;
    candleLineWidth = config.candleLineWidth;
    firstCandleInitOffset = config.firstCandleInitOffset;
  }

  factory SettingConfig.fromJson(Map<String, dynamic> json) =>
      _$SettingConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SettingConfigToJson(this);
}

extension SettingDataExt on SettingConfig {
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
}
