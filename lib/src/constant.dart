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

// ignore_for_file: constant_identifier_names

import 'package:flexi_formatter/date_time.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'extension/basic_type_ext.dart';

/// double类型的计算精度误差
const double precisionError = 0.000001;

/// 默认数据格式化精度
const int defaultPrecision = 4;

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

// 默认副图指标最大数量
const int defaultSubIndicatorMaxCount = 4;

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
  // time('1m', 1, TimeUnit.minute), // 1分钟线图
  s1('1s', 1, TimeUnit.second),
  m1('1m', 1, TimeUnit.minute),
  m3('3m', 3, TimeUnit.minute),
  m5('5m', 5, TimeUnit.minute),
  m15('15m', 15, TimeUnit.minute),
  m30('30m', 30, TimeUnit.minute),
  H1('1H', 1, TimeUnit.hour),
  H2('2H', 2, TimeUnit.hour),
  H4('4H', 4, TimeUnit.hour),
  H6('6H', 6, TimeUnit.hour),
  H12('12H', 12, TimeUnit.hour),
  D1('1D', 1, TimeUnit.day),
  D2('2D', 2, TimeUnit.day),
  D3('3D', 3, TimeUnit.day),
  W1('1W', 7, TimeUnit.week),
  M1('1M', 1, TimeUnit.month),
  M3('3M', 3, TimeUnit.month),
  utc6H('6Hutc', 6, TimeUnit.hour),
  utc12H('12Hutc', 12, TimeUnit.hour),
  utc1D('1Dutc', 1, TimeUnit.day),
  utc2D('2Dutc', 2, TimeUnit.day),
  utc3D('3Dutc', 3, TimeUnit.day),
  utc1W('1Wutc', 7, TimeUnit.week),
  utc1M('1Mutc', 1, TimeUnit.month),
  utc3M('3Mutc', 3, TimeUnit.month);

  const TimeBar(this.bar, this.multiplier, this.unit);

  final String bar;
  final int multiplier;
  final TimeUnit unit;

  int get milliseconds => unit.microseconds ~/ 1000 * multiplier;

  bool get isUtc {
    return name.contains('utc') || bar.contains('utc');
  }

  @override
  String toString() => bar;

  static TimeBar? convert(String bar) {
    try {
      return TimeBar.values.firstWhere(
        (e) => e.bar.equalsIgnoreCase(bar) || e.name.equalsIgnoreCase(bar),
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
