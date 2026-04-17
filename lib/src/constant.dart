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
import 'package:flutter/painting.dart';

import 'model/time_interval.dart';
import 'types.dart';

/// 透明色
const Color transparent = Color(0x00000000);

/// 白色
const Color white = Color(0xFFFFFFFF);

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
const double defaultTextSize = 10;

// 默认文本区域Padding
const EdgeInsets defaultTextPadding = EdgeInsets.all(2);

// 默认文本高度
const double defaultTextHeight = 1;

// 默认文本高度多行模式
const double defaultMultiTextHeight = 1.4;

// 默认Tips文本高度
const double defaultTipsTextHeight = 1.2;

// 默认Tips文本区域的Padding: 左边缩进8个单位
const EdgeInsets defaultTipsPadding = EdgeInsets.only(left: 8);

/// 配置默认 BorderSide 哨兵值
///
/// 与 Flutter `BorderSide.none` 的区别：
/// 后者 `color` 默认为 `0xFF000000`（黑），会被误判为"用户设置了黑色"；
/// 这里显式使用 `transparent`，配合"颜色透明视为未设置"的配置色原则，
/// 使渲染端能正确回退到主题色。
const BorderSide defaultBorderSide = BorderSide(
  color: transparent,
  width: 0,
  style: BorderStyle.none,
);

const invalidInterval = FlexiTimeInterval(0, TimeUnit.millisecond);

/// 内置: 时间周期
const interval1s = FlexiTimeInterval(1, TimeUnit.second);
const interval1m = FlexiTimeInterval(1, TimeUnit.minute);
const interval5m = FlexiTimeInterval(5, TimeUnit.minute);
const interval15m = FlexiTimeInterval(15, TimeUnit.minute);
const interval1H = FlexiTimeInterval(1, TimeUnit.hour);
const interval4H = FlexiTimeInterval(4, TimeUnit.hour);
const interval1D = FlexiTimeInterval(1, TimeUnit.day);
const interval1W = FlexiTimeInterval(1, TimeUnit.week);

/// 内置TooltipLabel默认文本
const Map<TooltipLabel, String> defaultTooltipLabels = {
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
