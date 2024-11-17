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

part of 'indicator.dart';

/// Indicator绘制模式
///
/// 注: PaintMode仅当Indicator加入MultiPaintObjectIndicator后起作用,
/// 代表当前Indicator的绘制是否是独立绘制的, 还是依赖于MultiPaintObjectIndicator
enum PaintMode {
  /// 组合模式, Indicator会联合其他子Indicator一起绘制, 坐标系共享.
  combine,

  /// 独立模式下, Indicator会按自己height和minmax独立绘制.
  alone;

  bool get isCombine => this == PaintMode.combine;
}

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

abstract interface class IIndicatorKey {
  String get id;
  String get label;
}

final class FlexiIndicatorKey implements IIndicatorKey {
  const FlexiIndicatorKey(
    this.id, {
    String? label,
  }) : label = label ?? id;

  @override
  final String id;

  @override
  final String label;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlexiIndicatorKey &&
        runtimeType == other.runtimeType &&
        id == other.id;
  }

  @override
  int get hashCode {
    return runtimeType.hashCode ^ id.hashCode;
  }
}

const unknownIndicatorKey = FlexiIndicatorKey('unknown');

/// 内置IndciatorKey
enum IndicatorType implements IIndicatorKey {
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

  @override
  String get id => name;

  @override
  final String label;

  @override
  String toString() {
    return label;
  }
}

// /// 指标
// /// 主区
// const mainChartKey = ValueKey<dynamic>(IndicatorType.main);
// const candleKey = ValueKey<dynamic>(IndicatorType.candle);
// const maKey = ValueKey<dynamic>(IndicatorType.ma);
// const emaKey = ValueKey<dynamic>(IndicatorType.ema);
// const bollKey = ValueKey<dynamic>(IndicatorType.boll);
// const sarKey = ValueKey<dynamic>(IndicatorType.sar);
// const volumeKey = ValueKey<dynamic>(IndicatorType.volume);

// /// 副区
// const volMaKey = ValueKey<dynamic>(IndicatorType.volMa);
// const subVolKey = ValueKey<dynamic>(IndicatorType.subVol);
// const maVolKey = ValueKey<dynamic>(IndicatorType.maVol);
// const macdKey = ValueKey<dynamic>(IndicatorType.macd);
// const kdjKey = ValueKey<dynamic>(IndicatorType.kdj);
// const subBollKey = ValueKey<dynamic>(IndicatorType.subBoll);
// const subSarKey = ValueKey<dynamic>(IndicatorType.subSar);
// const rsiKey = ValueKey<dynamic>(IndicatorType.rsi);
// const stochRsiKey = ValueKey<dynamic>(IndicatorType.stochRsi);
// const timeKey = ValueKey<dynamic>(IndicatorType.time);

/// 可预计算接口
/// 实现 [IPrecomputable] 接口, 即代表当前对象是可以进行预计算.
/// [getCalcParam] 返回预计算的参数. 可以为空
abstract interface class IPrecomputable {
  dynamic getCalcParam();
}
