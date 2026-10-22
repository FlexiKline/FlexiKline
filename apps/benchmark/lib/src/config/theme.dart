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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';

/// 固定配色: 两个版本、所有设备画同样的东西。
class BenchTheme implements IFlexiKlineTheme {
  const BenchTheme();

  @override
  Color get longColor => const Color(0xFF33BD65);
  @override
  Color get shortColor => const Color(0xFFE84E74);
  @override
  Color get chartBg => const Color(0xFFFFFFFF);
  @override
  Color get tooltipBg => const Color(0xFFF2F2F2);
  @override
  Color get countdownBg => const Color(0xFFBDBDBD);
  @override
  Color get crossTextBg => const Color(0xFF111111);
  @override
  Color get lastPriceBg => const Color(0x8A000000);
  @override
  Color get gridLineColor => const Color(0xffE9EDF0);
  @override
  Color get crosshairColor => const Color(0xFF000000);
  @override
  Color get drawToolColor => const Color(0xFF448AFF);
  @override
  Color get markLineColor => const Color(0xFF2196F3);
  @override
  Color get textColor => const Color(0xFF000000);
  @override
  Color get ticksTextColor => const Color(0xFF949494);
  @override
  Color get lastPriceColor => const Color(0xFF5F5F5F);
  @override
  Color get crossTextColor => const Color(0xFFFFFFFF);
  @override
  Color get tooltipTextColor => const Color(0xFF949494);
  @override
  Color get latestPriceBg => const Color(0xFF000000);
  @override
  Color get dragBg => const Color(0x33000000);
  @override
  Color get lineChartColor => const Color(0xFF0066FF);
}
