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

import '../../utils/vector_util.dart';
import '../../framework/serializers.dart';
import '../text_area_config/text_area_config.dart';

part 'draw_params.g.dart';

@CopyWith()
@FlexiConfigSerializable
class DrawParams {
  const DrawParams({
    // 箭头(ArrowLine)
    this.arrowsRadians = pi30,
    this.arrowsLen = 16.0,
    // 价值线(priceLine)
    this.priceText,
    this.priceTextMargin = EdgeInsets.zero,
    // 趋势线角度(TrendAngle)
    this.angleText,
    this.angleBaseLineMinLen = 80,
    this.angleRadSize = const Size(50, 50),
    // 平行通道
    this.paralleBgOpacity = 0.1,
    // 矩形
    this.rectangleBgOpacity = 0.1,
    // 斐波那契回撤
    this.fibRetracementRates = const [
      0,
      0.236,
      0.382,
      0.5,
      0.618,
      0.786,
      1.0,
      1.382,
      1.5,
      1.618,
      2,
    ],
    this.fibColors = const [
      Color(0xFFFF1744),
      Color(0xFFFF9100),
      Color(0xFFFFEA00),
      Color(0xFF00E676),
      Color(0xFF18FFFF),
      Color(0xFF2979FF),
      Color(0xFF651FFF),
    ],
    this.fibBgOpacity = 0.1,
    this.fibRateText = const TextAreaConfig(),
  });

  /// 箭头(ArrowLine)相对于基线的弧度
  final double arrowsRadians;

  /// 箭头(ArrowLine)长度
  final double arrowsLen;

  /// 价值线(priceLine)的文本配置, 如果不指定, 使用DrawConfig的tickText.
  final TextAreaConfig? priceText;

  /// 价值线(priceLine)的文本区域相对于价值线的margin
  final EdgeInsets priceTextMargin;

  /// 趋势线角度(TrendAngle)的文本配置, 如果不指定, 使用DrawConfig的tickText.
  final TextAreaConfig? angleText;

  /// 趋势线角度(TrendAngle)的基线长度
  final double angleBaseLineMinLen;

  /// 趋势线角度(TrendAngle)的圆弧大小
  final Size angleRadSize;

  /// 平行通道背景填充透明度
  final double paralleBgOpacity;

  /// 矩形背景填充不透明度
  final double rectangleBgOpacity;

  /// 斐波那契回撤比率
  final List<double> fibRetracementRates;

  /// 斐波那契颜色列表
  /// 如果为空使用画笔颜色.
  final List<Color> fibColors;

  /// 斐波那契两条比率线间的背景不透明度
  /// 注: 如果设置为0表示不填充背景
  final double fibBgOpacity;

  /// 斐波那契文本配置
  final TextAreaConfig fibRateText;

  factory DrawParams.fromJson(Map<String, dynamic> json) =>
      _$DrawParamsFromJson(json);

  Map<String, dynamic> toJson() => _$DrawParamsToJson(this);
}
