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

const jsonKeyTooltip = 'tooptip';
const jsonKeyCross = 'cross';
const jsonKeyGrid = 'grid';
const jsonKeySetting = 'setting';
const jsonKeySupportMainIndicators = 'supportMainIndicators';
const jsonKeySupportSubIndicators = 'supportSubIndicators';
const jsonKeyMain = 'main';
const jsonKeySub = 'sub';
const jsonKeyChildren = 'children';
// const mainChartKey = ValueKey<dynamic>(jsonKeyMain);

enum IndicatorType {
  main('MAIN'),
  time('Time'),
  candle('CANDLE'),
  ma('MA'),
  ema('EMA'),
  boll('BOLL'),
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
const volMaKey = ValueKey<dynamic>(IndicatorType.volMa);
const volumeKey = ValueKey<dynamic>(IndicatorType.volume);
const maVolKey = ValueKey<dynamic>(IndicatorType.maVol);
const macdKey = ValueKey<dynamic>(IndicatorType.macd);
const kdjKey = ValueKey<dynamic>(IndicatorType.kdj);
const rsiKey = ValueKey<dynamic>(IndicatorType.rsi);
const stochRsiKey = ValueKey<dynamic>(IndicatorType.stochRsi);
