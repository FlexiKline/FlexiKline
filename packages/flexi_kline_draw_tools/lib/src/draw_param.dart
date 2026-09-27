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
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';

part 'draw_param.g.dart';

/// 箭头(ArrowLine)绘制参数
@CopyWith()
// @FlexiOverlaySerializable
class ArrowLineDrawParam {
  const ArrowLineDrawParam({
    this.arrowsRadians = pi30,
    this.arrowsLen = 16.0,
  });

  /// 箭头(ArrowLine)相对于基线的弧度
  final double arrowsRadians;

  /// 箭头(ArrowLine)长度
  final double arrowsLen;
}

/// 价值线绘制参数
@CopyWith()
class PriceLineDrawParam {
  const PriceLineDrawParam({
    this.priceText,
    this.priceTextMargin = const EdgeInsets.only(
      left: 12,
      bottom: 2,
    ),
  });

  /// 价值线(priceLine)的文本配置, 如果不指定, 使用DrawConfig的ticksText.
  final TextAreaConfig? priceText;

  /// 价值线(priceLine)的文本区域相对于价值线的margin
  final EdgeInsets priceTextMargin;
}

/// 趋势线角度(TrendAngle)绘制参数
@CopyWith()
class TrendAngleDrawParam {
  const TrendAngleDrawParam({
    this.angleBaseLineMinLen = 80,
    this.angleRadSize = const Size.square(50),
    this.angleText,
  });

  /// 趋势线角度(TrendAngle)的基线长度
  final double angleBaseLineMinLen;

  /// 趋势线角度(TrendAngle)的圆弧大小
  final Size angleRadSize;

  /// 趋势线角度(TrendAngle)的文本配置, 如果不指定, 使用DrawConfig的ticksText.
  final TextAreaConfig? angleText;
}

/// 平行通道绘制参数
@CopyWith()
class ParallelChannelDrawParam {
  const ParallelChannelDrawParam({this.parallelBgOpacity = 0.1});

  /// 平行通道背景填充透明度
  final double parallelBgOpacity;
}

/// 矩形绘制参数
@CopyWith()
class RectangleDrawParam {
  const RectangleDrawParam({this.rectangleBgOpacity = 0.1});

  /// 矩形背景填充不透明度
  final double rectangleBgOpacity;
}

/// 平行四边形绘制参数
@CopyWith()
class ParallelogramDrawParam {
  const ParallelogramDrawParam({this.bgOpacity = 0.1});

  /// 背景填充不透明度
  final double bgOpacity;
}

/// 斐波那契回撤/扩展绘制参数
@CopyWith()
class FibonacciDrawParam {
  const FibonacciDrawParam({
    this.fibRates = const [
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
    this.fibText = const TextAreaConfig(
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.normal,
        height: defaultTextHeight,
      ),
      padding: EdgeInsets.all(2),
    ),
  });

  /// 斐波那契回撤/扩展比率
  final List<double> fibRates;

  /// 斐波那契回撤/扩展颜色列表
  /// 如果为空使用指针画笔颜色.
  final List<Color> fibColors;

  /// 斐波那契回撤/扩展两条比率线间的背景不透明度
  /// 注: 如果设置为0表示不填充背景
  final double fibBgOpacity;

  /// 斐波那契回撤/扩展/扇形文本配置
  /// 配置中TextStyle颜色配置使用规则:
  /// 1. 如果配置颜色且不是透明的, 则优先使用.
  /// 2. 否则根据当前[fibRates]的遍历顺序取用[fibColors]中配置的颜色
  final TextAreaConfig fibText;
}

/// 斐波那契扇形绘制参数
@CopyWith()
class FibFansDrawParam {
  const FibFansDrawParam({
    this.fibFansParams = const [0, 0.25, 0.382, 0.5, 0.618, 0.75, 1],
    this.fibFansColors = const [
      Color(0xFF651FFF),
      Color(0xFF2979FF),
      Color(0xFF18FFFF),
      Color(0xFF00E676),
      Color(0xFFFFEA00),
      Color(0xFFFF9100),
      Color(0xFFFF1744),
    ],
    this.fibFansGridColor = const Color(0x20000000),
    this.fibText = const TextAreaConfig(
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.normal,
        height: defaultTextHeight,
      ),
      padding: EdgeInsets.all(2),
    ),
  });

  /// 斐波那契扇形关键数值
  final List<double> fibFansParams;

  /// 斐波那契扇形颜色列表
  /// 如果为空使用指针画笔颜色.
  final List<Color> fibFansColors;

  /// 斐波那契扇形网格线颜色
  /// 如果为空不绘制扇形网格
  final Color? fibFansGridColor;

  /// 斐波那契回撤/扩展/扇形文本配置
  /// 配置中TextStyle颜色配置使用规则:
  /// 1. 如果配置颜色且不是透明的, 则优先使用.
  /// 2. 否则根据当前[fibFansParams]的遍历顺序取用[fibFansColors]中配置的颜色
  final TextAreaConfig fibText;
}
