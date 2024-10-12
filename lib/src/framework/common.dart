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

import 'package:flutter/foundation.dart';

import 'overlay.dart';

/// 绘制位置
///
/// 主要是指定TimeIndicator的绘制位置
enum DrawPosition {
  // top, // 不支持
  middle,
  bottom,
}

/// 缩放位置
///
/// [auto] 会根据当前绽放开始时, 所有焦点位置, 将绘制区域宽度三等分, 从而自动决定缩放位置.
enum ScalePosition {
  auto,
  left,
  middle,
  right,
}

enum IndicatorType {
  /// 主区
  main('MAIN'),
  candle('CANDLE'),
  ma('MA'),
  ema('EMA'),
  boll('BOLL'),
  sar('SAR'),
  volume('VOL'),

  /// 副区
  time('Time'),
  volMa('VOLMA'),
  subVol('VOL'),
  maVol('MAVOL'),
  macd('MACD'),
  kdj('KDJ'),
  subBoll('BOLL'),
  subSar('SAR'),
  rsi('RSI'),
  stochRsi('StochRSI');

  const IndicatorType(this.label);

  final String label;

  @override
  String toString() {
    return label;
  }
}

/// 指标
/// 主区
const mainChartKey = ValueKey<dynamic>(IndicatorType.main);
const candleKey = ValueKey<dynamic>(IndicatorType.candle);
const maKey = ValueKey<dynamic>(IndicatorType.ma);
const emaKey = ValueKey<dynamic>(IndicatorType.ema);
const bollKey = ValueKey<dynamic>(IndicatorType.boll);
const sarKey = ValueKey<dynamic>(IndicatorType.sar);
const volumeKey = ValueKey<dynamic>(IndicatorType.volume);

/// 副区
const volMaKey = ValueKey<dynamic>(IndicatorType.volMa);
const subVolKey = ValueKey<dynamic>(IndicatorType.subVol);
const maVolKey = ValueKey<dynamic>(IndicatorType.maVol);
const macdKey = ValueKey<dynamic>(IndicatorType.macd);
const kdjKey = ValueKey<dynamic>(IndicatorType.kdj);
const subBollKey = ValueKey<dynamic>(IndicatorType.subBoll);
const subSarKey = ValueKey<dynamic>(IndicatorType.subSar);
const rsiKey = ValueKey<dynamic>(IndicatorType.rsi);
const stochRsiKey = ValueKey<dynamic>(IndicatorType.stochRsi);
const timeKey = ValueKey<dynamic>(IndicatorType.time);

/// 可预计算接口
/// 实现 [IPrecomputable] 接口, 即代表当前对象是可以进行预计算.
/// [getCalcParam] 返回预计算的参数. 可以为空
abstract interface class IPrecomputable {
  dynamic getCalcParam();
}

typedef DrawObjectBuilder<T extends Overlay> = DrawObject Function(T overlay);

abstract interface class IDrawType {
  int get steps;
  String get id;
}

enum DrawType implements IDrawType {
  // 单线
  trendLine(2), // 趋势线
  arrowLine(2), // 箭头
  extendedTrendLine(2), // 延长趋势线
  trendAngle(2), // 趋势线角度
  rayLine(2), // 射线
  horizontalTrendLine(2), // 水平趋势线
  horizontalRayLine(2), // 水平射线
  horizontalLine(1), // 水平线
  verticalLine(1), // 垂直线
  crossLine(1), // 十字线
  priceLine(1), // 价钱线
  // 多线
  rectangle(2), // 长方形
  parallelChannel(3), // 平行通道
  // parallelLines, // 平行直线
  fibRetracement(2), // 斐波那契回撤
  // fibExpansion(3), // 斐波那契扩展
  fibFans(2); // 斐波那契扇形

  const DrawType(this.steps);

  @override
  final int steps;

  @override
  String get id => name;
}

enum MagnetMode {
  normal,
  weakMagnet,
  strongMagnet;
}
