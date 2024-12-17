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
import 'package:flutter/painting.dart';

import '../../constant.dart';
import '../../framework/serializers.dart';
import '../loading_config/loading_config.dart';
import '../text_area_config/text_area_config.dart';

part 'setting_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class SettingConfig {
  SettingConfig({
    required this.pixel,

    /// Long/Short颜色配置
    required this.textColor,
    required this.longColor,
    required this.shortColor,
    this.opacity = 0.5,

    /// 内置LoadingView样式配置
    required this.loading,

    /// 主/副图区域大小配置
    // this.mainRect = Rect.zero,

    ///  如果不指定默认为设置为20*20的逻辑像素区域.
    Size? mainMinSize,
    // required this.mainPadding,
    // this.mainDrawBelowTipsArea = true,

    /// 主/副图绘制参数
    this.minPaintBlankRate = 0.5,
    this.alwaysCalculateScreenOfCandlesIfEnough = false,
    required this.candleMaxWidth,
    required this.candleWidth,
    this.candleFixedSpacing,
    this.candleSpacingParts = 7,
    required this.candleLineWidth,
    required this.firstCandleInitOffset,

    /// 是否展示Y轴刻度.
    this.showYAxisTick = true,

    /// 全局默认的刻度值配置.
    required this.ticksText,

    /// 副图配置
    // 副区的指标图最大数量
    this.subChartMaxCount = defaultSubChartMaxCount,
  }) : mainMinSize = mainMinSize ?? Size(20 * pixel, 20 * pixel);

  /// 单个像素值
  final double pixel;

  /// Long/Short颜色配置
  final Color textColor;
  final Color longColor;
  final Color shortColor;
  final double opacity;

  /// 内置LoadingView样式配置
  final LoadingConfig loading;

  /// 主区
  // 主区域大小配置
  // Rect mainRect; // TODO: 后续由MainPaintObject管理
  // 主区域最小大小限制,
  final Size mainMinSize;
  // // 主区域Padding
  // final EdgeInsets mainPadding;
  // // 主区图表的绘制是否在Tips区域下
  // final bool mainDrawBelowTipsArea;

  /// 绘制区域最少留白比例
  /// 例如: 当蜡烛数量不足以绘制一屏, 向右移动到末尾时, 绘制区域左边最少留白区域占可绘制区域(canvasWidth)的比例
  final double minPaintBlankRate;

  /// 如果足够总是计算一屏的蜡烛.
  /// 当滑动或初始化时会存在(minPaintBlankRate)的空白, 此时, 计算按一屏的蜡烛数量向后计算.
  final bool alwaysCalculateScreenOfCandlesIfEnough;

  /// 蜡烛配置
  // 最大蜡烛宽度[1, 50]
  final double candleMaxWidth;
  // 单根蜡烛宽度
  double candleWidth;
  // 固定蜡烛间距
  final double? candleFixedSpacing;
  // 蜡烛间距按蜡烛宽度平分[candleSpacingParts]份
  final int candleSpacingParts;
  // 蜡烛线宽(high, low)
  final double candleLineWidth;
  // Candle 第一根Candle相对于mainRect右边的偏移
  final double firstCandleInitOffset;

  /// 是否展示Y轴刻度.
  final bool showYAxisTick;

  /// 全局默认的刻度值配置.
  final TextAreaConfig ticksText;

  // 副区的指标图最大数量
  final int subChartMaxCount;

  /// 蜡烛间距 [candleFixedSpacing] 优先于 [candleSpacingParts]
  double? _candleSpacing;
  double get candleSpacing {
    _candleSpacing = candleFixedSpacing ?? candleWidth / candleSpacingParts;
    _candleSpacing = _candleSpacing! < pixel ? pixel : _candleSpacing;
    return _candleSpacing!;
  }

  // void setMainRect(Size size) {
  //   if (size >= mainMinSize) {
  //     mainRect = Rect.fromLTRB(
  //       0,
  //       0,
  //       size.width,
  //       size.height,
  //     );
  //   }
  // }

  // 确保最小Size必须小于MainSize.
  // void checkAndFixMinSize() {
  //   final mainSize = mainRect.size;
  //   if (mainMinSize.width > mainSize.width) {
  //     mainMinSize = Size(mainSize.width, mainMinSize.height);
  //   }
  //   if (mainMinSize.height > mainSize.height) {
  //     mainMinSize = Size(mainMinSize.width, mainSize.height);
  //   }
  // }

  // void update(SettingConfig config) {
  //   mainRect = config.mainRect;
  //   // mainMinSize = config.mainMinSize;
  //   candleWidth = config.candleWidth;
  // }

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
