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
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart' as tools;
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

/// 不落盘的配置: 每次启动都从默认配置开始, 采集之间互不影响。
///
/// 只用 `v2.5.6-monorepo` 上也存在的 API; 两版差异只允许在本文件与 `bench_indicators.dart` 里适配。
/// [draw] 为 true 时开启绘图并注册 flexi_kline_draw_tools 的全部工具, 只给 draw 场景用。
class BenchConfiguration with FlexiKlineConfigurationMixin {
  BenchConfiguration({this.draw = false});

  final bool draw;

  @override
  IFlexiKlineTheme get theme => const BenchTheme();

  @override
  Map<IDrawType, DrawObjectBuilder<Overlay, DrawObject<Overlay>>> get drawObjectBuilders =>
      draw ? tools.drawObjectBuilders : const {};

  @override
  DrawConfig genDrawConfig([DrawConfig? draw]) {
    final base = super.genDrawConfig(draw);
    return this.draw ? base.copyWith(enable: true) : base;
  }

  @override
  MainPaintObjectIndicator<Indicator> genMainIndicator(MainPaintObjectIndicator<Indicator>? mainIndicator) {
    return MainPaintObjectIndicator(
      size: mainIndicator?.size ?? const Size(0, 360),
      padding: mainIndicator?.padding ?? const EdgeInsets.only(top: 16, bottom: 4),
    );
  }

  @override
  SettingConfig genSettingConfig([SettingConfig? setting]) {
    // 倒计时每秒重绘一次, 会给静止场景混入与被测操作无关的帧。
    return (setting ?? const SettingConfig()).copyWith(
      autoStartLastPriceCountDownTimer: false,
      autoLoadMoreData: false,
    );
  }

  @override
  Map<String, dynamic>? getConfig(String key) => null;

  @override
  Future<bool> setConfig(String key, Map<String, dynamic> value) async => true;
}
