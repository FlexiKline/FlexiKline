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

import '../preset.dart';
import 'theme.dart';

/// 不落盘的配置: 每次启动都从默认配置开始, 采集之间互不影响。
///
/// 只用 `v2.5.6-monorepo` 上也存在的 API; 两版差异只允许经 `compat.dart` 适配。
/// 默认关闭的交互由 [features] 按场景打开: 它们会改变常态下的绘制内容(如 resize 的可拖拽分隔线)。
/// 指标的激活走配置: [mainChildren] 是主区默认激活的指标, [subKeys] 是副区默认激活的指标。
class BenchConfiguration with FlexiKlineConfigurationMixin {
  BenchConfiguration({
    this.features = const {},
    this.mainChildren = const {},
    this.subKeys = const {},
  });

  final Set<BenchFeature> features;
  final Set<IIndicatorKey> mainChildren;
  final Set<IIndicatorKey> subKeys;

  bool get _draw => features.contains(BenchFeature.draw);

  @override
  IFlexiKlineTheme get theme => const BenchTheme();

  @override
  Map<IDrawType, DrawObjectBuilder<Overlay, DrawObject<Overlay>>> get drawObjectBuilders =>
      _draw ? tools.drawObjectBuilders : const {};

  @override
  DrawConfig genDrawConfig([DrawConfig? draw]) {
    final base = super.genDrawConfig(draw);
    return _draw ? base.copyWith(enable: true) : base;
  }

  @override
  GridConfig genGridConfig([GridConfig? grid]) {
    final base = super.genGridConfig(grid);
    return features.contains(BenchFeature.resize) ? base.copyWith(isAllowDragIndicatorHeight: true) : base;
  }

  @override
  GestureConfig genGestureConfig([GestureConfig? gesture]) {
    final base = super.genGestureConfig(gesture);
    return features.contains(BenchFeature.zoom) ? base.copyWith(enableZoom: true) : base;
  }

  @override
  MainPaintObjectIndicator<Indicator> genMainIndicator(MainPaintObjectIndicator<Indicator>? mainIndicator) {
    return MainPaintObjectIndicator(
      size: mainIndicator?.size ?? const Size(0, 360),
      padding: mainIndicator?.padding ?? const EdgeInsets.only(top: 16, bottom: 4),
      // 激活集合会在运行时被写入, 不能把构造时传入的集合直接交出去。
      children: {...mainChildren},
    );
  }

  @override
  Set<IIndicatorKey> genSubIndicators([Set<IIndicatorKey>? sub]) => sub ?? {...subKeys};

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
