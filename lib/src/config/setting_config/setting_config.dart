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
  const SettingConfig({
    required this.pixel,

    /// Long/Short 浅色不透明度 [longTintColor] 和 [shortTintColor]
    this.opacity = 0.5,

    /// 内置LoadingView样式配置
    required this.loading,

    ///  如果不指定默认为设置为20*20的逻辑像素区域.
    this.mainMinSize = const Size(120, 80),
    this.subMinHeight = 30,

    /// 蜡烛图绘制配置
    this.minPaintBlankRate = 0.5,
    this.alwaysCalculateScreenOfCandlesIfEnough = false,
    required this.candleMaxWidth,
    required this.candleWidth,
    this.candleFixedSpacing,
    this.candleSpacingParts = 7,
    required this.candleHollowBarBorderWidth,
    required this.candleLineWidth,
    required this.firstCandleInitOffset,

    /// 是否展示Y轴刻度.
    this.showYAxisTick = true,

    /// 全局默认的刻度值配置.
    required this.ticksText,

    /// 副图配置
    // 副区的指标图最大数量
    this.subChartMaxCount = defaultSubChartMaxCount,
  });

  /// 单个像素值
  final double pixel;

  /// Long/Short 浅色不透明度 [longTintColor] 和 [shortTintColor]
  final double opacity;

  // TODO: 待适配主题管理
  /// 内置LoadingView样式配置
  final LoadingConfig loading;

  // 主区指标图的最小大小限制
  final Size mainMinSize;
  // 副区指标图的最小高度
  final double subMinHeight;

  /// 绘制区域最少留白比例
  /// 例如: 当蜡烛数量不足以绘制一屏, 向右移动到末尾时, 绘制区域左边最少留白区域占可绘制区域(canvasWidth)的比例
  final double minPaintBlankRate;

  /// 如果足够总是计算一屏的蜡烛.
  /// 当滑动或初始化时会存在(minPaintBlankRate)的空白, 此时, 计算按一屏的蜡烛数量向后计算.
  final bool alwaysCalculateScreenOfCandlesIfEnough;

  /// 蜡烛配置
  // 最大蜡烛宽度[1, 50]
  final double candleMaxWidth;
  // 单根蜡烛柱的宽度
  final double candleWidth;
  // 蜡烛间的固定间距
  final double? candleFixedSpacing;
  // 蜡烛间的间距按蜡烛宽度平分[candleSpacingParts]份
  final int candleSpacingParts;
  // 蜡烛空心柱的边框宽度
  final double candleHollowBarBorderWidth;
  // 蜡烛高低线宽(high, low)
  final double candleLineWidth;
  // Candle 第一根Candle相对于mainRect右边的偏移
  final double firstCandleInitOffset;

  /// 是否展示Y轴刻度.
  final bool showYAxisTick;

  /// 全局默认的刻度值文本配置.
  final TextAreaConfig ticksText;

  // 副区的指标图最大数量
  final int subChartMaxCount;

  bool get isFixedCandleSpacing {
    return candleFixedSpacing != null && candleFixedSpacing! > pixel;
  }

  int get spacingCandleParts {
    return candleSpacingParts.clamp(1, candleWidth.toInt());
  }

  // /// 蜡烛间距 [candleFixedSpacing] 优先于 [candleSpacingParts]
  // double? _candleSpacing;
  // double get candleSpacing {
  //   _candleSpacing = candleFixedSpacing ?? candleWidth / candleSpacingParts;
  //   _candleSpacing = _candleSpacing! < pixel ? pixel : _candleSpacing;
  //   return _candleSpacing!;
  // }

  factory SettingConfig.fromJson(Map<String, dynamic> json) =>
      _$SettingConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SettingConfigToJson(this);
}
