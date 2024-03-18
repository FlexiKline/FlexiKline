import 'dart:io';
import 'package:flutter/foundation.dart';

bool kIsDesktop = kIsWeb ||
    Platform.isWindows ||
    Platform.isLinux ||
    Platform.isMacOS ||
    Platform.isFuchsia;
bool kIsApp = !kIsDesktop;

/// 枚举顺序都不能变，只能加不能减，缓存是按照枚举index来保存的
enum GestureMode {
  none,
  crossMode,
  paintMode,
  paintEditMode,
  panMode,
  scaleMode,
}

enum KlineType {
  candle,
  hollowCandle,
  bar,
  heikenAshi,
}

enum KLineMarkPrice {
  high,
  low,
  close,
}

enum MainChartType {
  ma,
  boll,
  mark,
  ema,
  @Deprecated('MainChartType.candle移动到KlineChartType')
  candle,
  sar,
  ene,
  dc,
  alligator,
  kc,
}

enum SubChartType {
  macd,
  kdj,
  rsi,
  wr,
  volume,
  obv,
  trix,
  roc,
  atr,
}

enum KLineScalePosition {
  left,
  center,
  right,
}

enum KLineScaleStyle {
  line,
  candle,
}

enum KLinePriceStyle {
  high,
  low,
  close,
  open,
}

enum TimeParamsType {
  time,
  minute,
  hour,
  day,
  week,
  month,
}

enum PriceType {
  open,
  close,
  high,
  low,
  avg,
  volume,
}

enum DrawType {
  none,
  trend, // 趋势线
  trendAngle, // 趋势线角度
  hLine, // 水平线
  vLine, // 垂直线
  hLineRay, // 水平射线
  pebonacci, // 佩波那契回撤
  parallel, // 平行通道
  trendFibExtend, // 佩波那契扩展
  cross, // 十字线
  trendArrow, // 箭头
  ray, // 射线
}
