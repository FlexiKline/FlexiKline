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

import '../../extension/export.dart' show FlexiKlineNumExt;
import '../../framework/serializers.dart';

part 'gradient_config.g.dart';

/// 渐变配置
///
/// 用于配置动态渐变效果，支持基于基础颜色动态生成渐变。
///
/// 与直接使用 [LinearGradient] 不同，此配置允许：
/// - 颜色基于运行时的实际颜色动态生成
/// - 配置透明度、方向、stops 等参数
/// - 支持完全自定义颜色列表
///
/// 使用场景：
/// 1. 基于动态颜色的渐变（如折线图区域填充）
/// 2. 主题切换时渐变自动适应
/// 3. 需要保持渐变与线条颜色一致性的场景
@CopyWith()
@FlexiConfigSerializable
class GradientConfig {
  const GradientConfig({
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
    this.stops,
    this.tileMode = TileMode.decal,
    this.startAlpha = 0.5,
    this.endAlpha = 0.0,
    this.colors,
  });

  /// 渐变起始位置
  ///
  /// 默认: [Alignment.topCenter]
  final Alignment begin;

  /// 渐变结束位置
  ///
  /// 默认: [Alignment.bottomCenter]
  final Alignment end;

  /// 颜色停止点
  ///
  /// 如果为 null，颜色将均匀分布。
  /// 如果提供，长度必须与颜色数量相同。
  final List<double>? stops;

  /// 平铺模式
  ///
  /// 默认: [TileMode.decal]
  final TileMode tileMode;

  /// 起始颜色的透明度 (0.0 - 1.0)
  ///
  /// 当 [colors] 为 null 时使用，用于基于基础颜色生成渐变。
  /// 0.0 = 完全透明, 1.0 = 完全不透明
  ///
  /// 默认: 0.5
  final double startAlpha;

  /// 结束颜色的透明度 (0.0 - 1.0)
  ///
  /// 当 [colors] 为 null 时使用，用于基于基础颜色生成渐变。
  /// 0.0 = 完全透明, 1.0 = 完全不透明
  ///
  /// 默认: 0.0
  final double endAlpha;

  /// 自定义颜色列表
  ///
  /// 如果提供，将忽略 [startAlpha] 和 [endAlpha]，直接使用这些颜色。
  /// 如果为 null，将基于基础颜色和透明度动态生成。
  final List<Color>? colors;

  /// 创建 LinearGradient
  ///
  /// [baseColor] 基础颜色，当 [colors] 为 null 时使用
  LinearGradient createGradient({
    required Color baseColor,
  }) {
    final gradientColors = colors ??
        [
          baseColor.withAlpha(startAlpha.alpha),
          baseColor.withAlpha(endAlpha.alpha),
        ];

    return LinearGradient(
      begin: begin,
      end: end,
      colors: gradientColors,
      stops: stops,
      tileMode: tileMode,
    );
  }

  /// 是否为动态渐变（基于颜色生成）
  bool get isDynamic => colors == null;

  /// 是否为静态渐变（使用固定颜色）
  bool get isStatic => colors != null;

  factory GradientConfig.fromJson(Map<String, dynamic> json) => _$GradientConfigFromJson(json);

  Map<String, dynamic> toJson() => _$GradientConfigToJson(this);
}

/// 预设的渐变配置
class GradientPresets {
  GradientPresets._();

  /// 默认折线图渐变（从上到下，50% -> 0%）
  static const lineChart = GradientConfig(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    startAlpha: 0.5,
    endAlpha: 0.0,
    stops: [0.0, 1.0],
    tileMode: TileMode.decal,
  );

  /// 上涨渐变（从上到下，50% -> 0%）
  /// 用于涨跌线图的上涨区域
  static const long = GradientConfig(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    startAlpha: 0.5,
    endAlpha: 0.0,
    stops: [0.0, 1.0],
    tileMode: TileMode.decal,
  );

  /// 下跌渐变（从下到上，50% -> 0%）
  /// 用于涨跌线图的下跌区域
  static const short = GradientConfig(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    startAlpha: 0.5,
    endAlpha: 0.0,
    stops: [0.0, 1.0],
    tileMode: TileMode.decal,
  );

  /// 强渐变（从上到下，80% -> 0%）
  static const strong = GradientConfig(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    startAlpha: 0.8,
    endAlpha: 0.0,
    stops: [0.0, 1.0],
    tileMode: TileMode.decal,
  );

  /// 强渐变反向（从下到上，80% -> 0%）
  static const strongReverse = GradientConfig(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    startAlpha: 0.8,
    endAlpha: 0.0,
    stops: [0.0, 1.0],
    tileMode: TileMode.decal,
  );

  /// 弱渐变（从上到下，30% -> 0%）
  static const weak = GradientConfig(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    startAlpha: 0.3,
    endAlpha: 0.0,
    tileMode: TileMode.decal,
  );

  /// 弱渐变反向（从下到上，30% -> 0%）
  static const weakReverse = GradientConfig(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    startAlpha: 0.3,
    endAlpha: 0.0,
    stops: [0.0, 1.0],
    tileMode: TileMode.decal,
  );

  /// 双向渐变（中间 80% -> 两端 0%）
  static const bidirectional = GradientConfig(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    startAlpha: 0.0,
    endAlpha: 0.0,
    stops: [0.0, 0.5, 1.0],
    tileMode: TileMode.decal,
  );

  /// 水平渐变（从左到右）
  static const horizontal = GradientConfig(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    startAlpha: 0.5,
    endAlpha: 0.0,
    stops: [0.0, 1.0],
    tileMode: TileMode.decal,
  );

  /// 倒序渐变（从下到上，50% -> 0%）
  static const reverse = GradientConfig(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    startAlpha: 0.5,
    endAlpha: 0.0,
    stops: [0.0, 1.0],
    tileMode: TileMode.decal,
  );
}
