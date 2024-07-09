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

/// 默认数据格式化精度
const int defaultPrecision = 4;

// 默认Decimal除法精度
const int defaultScaleOnInfinitePrecision = 17;

// 默认主区指标高度
const double defaultMainIndicatorHeight = 300;

// 默认时间指标高度
const double defaultTimeIndicatorHeight = 15;

// 默认副图指标高度
const double defaultSubIndicatorHeight = 60;

// 默认指标图Padding
const EdgeInsets defaultSubIndicatorPadding = EdgeInsets.only(top: 12);

// 默认主图区域Padding
const EdgeInsets defaultMainIndicatorPadding = EdgeInsets.only(
  top: 5, // 顶部留白
  bottom: 5, // 底部留白, 5: 最低价字体高度的一半, 保证最低价文本不会绘制到边线上.
);

// 默认主图区域最小Size
const Size defaultMainRectMinSize = Size(20, 20);
const Rect defaultCanvasRectMinRect = Rect.fromLTWH(0, 0, 20, 20);

// 默认副图指标最大数量
const int defaultSubChartMaxCount = 4;

// 默认副图指标刻度数量: 高中低=>top, middle, bottom
const int defaultSubTickCount = 3;

// 默认指标线图的宽度
const double defaultIndicatorLineWidth = 1;

// 默认文本配置
const double defaulTextSize = 10;

// 默认文本区域Padding
const EdgeInsets defaultTextPading = EdgeInsets.all(2);

// 默认文本高度
const double defaultTextHeight = 1;

// 默认文本高度多行模式
const double defaultMultiTextHeight = 1.4;

// 默认Tips文本高度
const double defaultTipsTextHeight = 1.2;

// 默认指标图TipsHeight
// const double defaultIndicatorTipsHeight = 15;

// 默认Tips文本区域的Padding: 左边缩进8个单位
const EdgeInsets defaultTipsPadding = EdgeInsets.only(left: 8);

/// 计算模式
/// [fast] 使用(IEEE 754 二进制浮点数算术标准)计算指标数据. (用double类型计算)
/// [accurate] 使用Decimal基于十进制算术的精确计算指标数据. (用Decimal类型计算)
enum ComputeMode {
  fast,
  accurate,
}

/// 时间粒度，默认值1m
/// 如 [1m/3m/5m/15m/30m/1H/2H/4H]
/// 香港时间开盘价k线：[6H/12H/1D/2D/3D/1W/1M/3M]
/// UTC时间开盘价k线：[/6Hutc/12Hutc/1Dutc/2Dutc/3Dutc/1Wutc/1Mutc/3Mutc]
enum TimeBar {
  // time(1000, 'time'), // 暂不支持; v0.8.0支持
  s1(1000, '1s'),
  m1(Duration.millisecondsPerMinute, '1m'),
  m3(3 * Duration.millisecondsPerMinute, '3m'),
  m5(5 * Duration.millisecondsPerMinute, '5m'),
  m15(15 * Duration.millisecondsPerMinute, '15m'),
  m30(30 * Duration.millisecondsPerMinute, '30m'),
  H1(Duration.millisecondsPerHour, '1H'),
  H2(2 * Duration.millisecondsPerHour, '2H'),
  H4(4 * Duration.millisecondsPerHour, '4H'),
  H6(6 * Duration.millisecondsPerHour, '6H'),
  H12(12 * Duration.millisecondsPerHour, '12H'),
  D1(Duration.millisecondsPerDay, '1D'),
  D2(2 * Duration.millisecondsPerDay, '2D'),
  D3(3 * Duration.millisecondsPerDay, '3D'),
  W1(7 * Duration.millisecondsPerDay, '1W'),
  M1(30 * Duration.millisecondsPerDay, '1M'), // ?
  M3(90 * Duration.millisecondsPerDay, '3M'), // ?
  utc6H(6 * Duration.millisecondsPerHour, '6Hutc'),
  utc12H(12 * Duration.millisecondsPerHour, '12Hutc'),
  utc1D(Duration.millisecondsPerDay, '1Dutc'),
  utc2D(2 * Duration.millisecondsPerDay, '2Dutc'),
  utc3D(3 * Duration.millisecondsPerDay, '3Dutc'),
  utc1W(7 * Duration.millisecondsPerDay, '1Wutc'),
  utc1M(30 * Duration.millisecondsPerDay, '1Mutc'),
  utc3M(90 * Duration.millisecondsPerDay, '3Mutc');

  const TimeBar(this.milliseconds, this.bar);

  final int milliseconds;
  final String bar;

  bool get isUtc {
    return name.contains('utc') || bar.contains('utc');
  }

  @override
  String toString() => bar;

  static TimeBar? convert(String bar) {
    try {
      return TimeBar.values.firstWhere(
        (e) => e.bar == bar || e.name == bar,
      );
    } on Error catch (error) {
      debugPrintStack(stackTrace: error.stackTrace);
      return null;
    }
  }
}

/// 内置TooltipLabel
enum TooltipLabel {
  time,
  open,
  high,
  low,
  close,
  chg,
  chgRate,
  range,
  amount,
  turnover;
}

const Map<TooltipLabel, String> defaultTooltipLables = {
  TooltipLabel.time: 'Time',
  TooltipLabel.open: 'Open',
  TooltipLabel.high: 'High',
  TooltipLabel.low: 'Low',
  TooltipLabel.close: 'Close',
  TooltipLabel.chg: 'Chg',
  TooltipLabel.chgRate: '%Chg',
  TooltipLabel.range: 'Range',
  TooltipLabel.amount: 'Amount',
  TooltipLabel.turnover: 'Turnover',
};

enum ThousandUnit {
  /// trillion
  trillion('T'),

  /// billion
  billion('B'),

  /// million
  million('M'),

  /// thousand
  thousand('K'),

  /// less than thousand
  less('');

  final String value;
  const ThousandUnit(this.value);
}

enum RoundMode {
  round,
  floor,
  ceil,
  truncate,
}
