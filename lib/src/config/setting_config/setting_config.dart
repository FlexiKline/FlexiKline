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

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/painting.dart';

import '../../framework/serializers.dart';
import '../loading_config/loading_config.dart';

part 'setting_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class SettingConfig {
  const SettingConfig({
    /// Long/Short 浅色不透明度 [longTintColor] 和 [shortTintColor]
    this.opacity = 0.5,

    /// 内置LoadingView样式配置
    this.loading = const LoadingConfig(
      size: 26,
      strokeWidth: 4,
    ),

    ///  如果不指定默认为设置为20*20的逻辑像素区域.
    this.mainMinSize = const Size(120, 80),
    this.subMinHeight = 30,

    /// 蜡烛图绘制配置
    this.minPaintBlankRate = 0.5,
    this.alwaysCalculateScreenOfCandlesIfEnough = false,
    this.candleMinWidth = 1,
    this.candleMaxWidth = 40,
    this.candleWidth = 7,
    this.candleFixedSpacing = 1,
    this.candleSpacingParts = 7,
    this.candleHollowBarBorderWidth = 1,
    this.candleLineWidth = 1,
    this.firstCandleInitOffset = 80,

    /// overlay 是否允许绘制在主图 rect 之外
    this.allowOverlayOutsideMainRect = true,

    /// 是否展示Y轴刻度.
    this.showYAxisTick = true,

    /// 是否自动启动最后一根蜡烛的价格倒计时定时器.
    this.autoStartLastPriceCountDownTimer = true,

    /// 是否自动加载更多数据
    this.autoLoadMoreData = true,
    this.expandRatiosOfSameMinmax = const [0.1, 0.05],

    /// Y 轴缩放可达跨度倍率
    this.minZoomSpanRatio = 0.05,
    this.maxZoomSpanRatio = 20,
  });

  /// Long/Short 浅色不透明度 [longTintColor] 和 [shortTintColor]
  final double opacity;

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
  /// 最小蜡烛宽度, 小于 1 会被夹到 1(否则蜡烛宽度可精确归零, 蜡烛数量的推算不再收敛)
  final double candleMinWidth;
  // 最大蜡烛宽度, 小于 [candleMinWidth] 时取后者; 不设上界
  final double candleMaxWidth;
  // 单根蜡烛柱的宽度
  final double candleWidth;
  // 蜡烛间的固定间距
  final double? candleFixedSpacing;
  // 蜡烛间的间距按蜡烛宽度平分[candleSpacingParts]份
  final int candleSpacingParts;
  // 蜡烛空心柱的边框宽度
  final double candleHollowBarBorderWidth;
  // 蜡烛空心线宽; 高低线宽(high, low)
  final double candleLineWidth;
  // Candle 第一根Candle相对于mainRect右边的偏移
  final double firstCandleInitOffset;

  /// overlay 是否允许绘制在主图 rect 之外
  final bool allowOverlayOutsideMainRect;

  /// 是否展示Y轴刻度.
  final bool showYAxisTick;

  /// 是否自动启动最后一根蜡烛的价格倒计时定时器.
  final bool autoStartLastPriceCountDownTimer;

  /// 是否自动加载更多数据
  final bool autoLoadMoreData;

  /// 当前绘制区域内如果行情无波动时, 用于增加的绘制区域宽度.
  /// 取值范围: >=0;
  /// first: 最高价增加(1+first)倍.
  /// second: 最低价减少(1-second)倍.
  /// 如果为0或null, 则不增加最高价或最低价
  final List<double> expandRatiosOfSameMinmax;

  /// Y 轴缩放能把可见价格跨度压到的下限, 单位是「用户接管 Y 轴那一刻的自动跨度」的倍数。
  /// 取值 (0, 1], 默认 0.05 即最多把内容放大 20 倍。触摸与非触摸共用同一个界。
  ///
  /// 与 `GestureConfig.maxZoomPerGesture` 是两件事: 后者是单轮手势的上界, 抬手重抓即重新
  /// 计量; 本字段是全局可达范围, 分几轮都不会越过。
  ///
  /// 与 [maxZoomSpanRatio] 不取倒数对: 放大方向有纵向平移做补偿, 用户能移到想看的价格切片,
  /// 压到很小仍是有效视图; 缩小方向没有补偿, 跨度一大数据就成一条发丝。
  final double minZoomSpanRatio;

  /// Y 轴缩放能把可见价格跨度放到的上限, 单位同 [minZoomSpanRatio]。
  /// 取值 [1, ∞), 默认 20 即最多把内容缩小 20 倍。
  final double maxZoomSpanRatio;

  bool get isFixedCandleSpacing {
    return candleFixedSpacing != null && candleFixedSpacing! > candleMinWidth;
  }

  int get spacingCandleParts {
    return candleSpacingParts.clamp(1, math.max(1, candleWidth.toInt()));
  }

  factory SettingConfig.fromJson(Map<String, dynamic> json) => _$SettingConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SettingConfigToJson(this);
}
