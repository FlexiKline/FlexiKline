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

/// 绘制位置
/// 主要是指定TimeIndicator的绘制位置
enum DrawPosition {
  // top, // 不支持
  middle,
  bottom,
}

/// 缩放位置
/// [auto] 会根据当前绽放开始时, 所有焦点位置, 将绘制区域宽度三等分, 从而自动决定缩放位置.
enum ScalePosition {
  auto,
  left,
  middle,
  right,
}

enum IndicatorType {
  main('MAIN'),
  time('Time'),
  candle('CANDLE'),
  ma('MA'),
  ema('EMA'),
  boll('BOLL'),
  sar('SAR'),
  volMa('VOLMA'),
  volume('VOL'),
  maVol('MAVOL'),
  macd('MACD'),
  kdj('KDJ'),
  rsi('RSI'),
  stochRsi('StochRSI');

  const IndicatorType(this.label);

  final String label;

  @override
  String toString() {
    return label;
  }
}

const mainChartKey = ValueKey<dynamic>(IndicatorType.main);
const timeKey = ValueKey<dynamic>(IndicatorType.time);

/// 指标
const candleKey = ValueKey<dynamic>(IndicatorType.candle);
const maKey = ValueKey<dynamic>(IndicatorType.ma);
const emaKey = ValueKey<dynamic>(IndicatorType.ema);
const bollKey = ValueKey<dynamic>(IndicatorType.boll);
const sarKey = ValueKey<dynamic>(IndicatorType.sar);
const volMaKey = ValueKey<dynamic>(IndicatorType.volMa);
const volumeKey = ValueKey<dynamic>(IndicatorType.volume);
const maVolKey = ValueKey<dynamic>(IndicatorType.maVol);
const macdKey = ValueKey<dynamic>(IndicatorType.macd);
const kdjKey = ValueKey<dynamic>(IndicatorType.kdj);
const rsiKey = ValueKey<dynamic>(IndicatorType.rsi);
const stochRsiKey = ValueKey<dynamic>(IndicatorType.stochRsi);

/// 可预计算接口
/// 实现 [IPrecomputable] 接口, 即代表当前对象是可以进行预计算.
/// [getCalcParam] 返回预计算的参数. 可以为空
abstract interface class IPrecomputable {
  dynamic getCalcParam();
}
