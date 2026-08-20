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

import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../constant.dart';
import '../framework/export.dart';
import 'cross_config/cross_config.dart';
import 'draw_config/draw_config.dart';
import 'flexi_kline_config/flexi_kline_config.dart';
import 'gesture_config/gesture_config.dart';
import 'grid_config/grid_config.dart';
import 'setting_config/setting_config.dart';

mixin FlexiKlineConfigurationMixin implements IConfiguration {
  /// 每次调用都从 [IStorage] 反序列化并交由 [generateFlexiKlineConfig] 兜底，
  /// 返回**新实例**。
  ///
  /// 覆写为返回同一缓存实例，即可让共享本 [IConfiguration] 的多个 Controller
  /// 共用同一份运行时配置；此时 [generateFlexiKlineConfig] 只在首次调用时执行一次。
  @override
  FlexiKlineConfig getFlexiKlineConfig() {
    FlexiKlineConfig? origin;
    try {
      final json = getConfig(flexiKlineConfigKey);
      if (json != null && json.isNotEmpty) {
        origin = FlexiKlineConfig.fromJson(json);
      }
    } catch (error, stack) {
      debugPrintStack(stackTrace: stack, label: 'getFlexiKlineConfig$error');
    }
    return generateFlexiKlineConfig(origin);
  }

  @override
  void saveFlexiKlineConfig(FlexiKlineConfig config) {
    setConfig(flexiKlineConfigKey, config.toJson());
  }

  /// 生成 FlexiKline 配置。
  ///
  /// 不再是 [IConfiguration] 契约，仅本 mixin 的定制入口。调用场景:
  /// 1. 首次加载(无缓存)情况下, 生成默认的FlexiKlineConfig
  /// 2. 从缓存中反序列化实现时调用, [origin]即是原始缓存配置, 这可能出现在后续追加/删除/修改配置时, 原有配置无法反序列化.
  FlexiKlineConfig generateFlexiKlineConfig([FlexiKlineConfig? origin]) {
    return FlexiKlineConfig(
      grid: genGridConfig(origin?.grid),
      setting: genSettingConfig(origin?.setting),
      gesture: genGestureConfig(origin?.gesture),
      cross: genCrossConfig(origin?.cross),
      draw: genDrawConfig(origin?.draw),
      mainIndicator: genMainIndicator(origin?.mainIndicator),
      sub: genSubIndicators(origin?.sub),
    );
  }

  MainPaintObjectIndicator genMainIndicator(MainPaintObjectIndicator<Indicator>? mainIndicator) {
    return mainIndicator ??
        MainPaintObjectIndicator(
          size: const Size(0, defaultMainIndicatorHeight),
          padding: defaultMainIndicatorPadding,
        );
  }

  Set<IIndicatorKey> genSubIndicators([Set<IIndicatorKey>? sub]) {
    return sub ?? {};
  }

  GridConfig genGridConfig([GridConfig? grid]) {
    return grid ?? const GridConfig();
  }

  GestureConfig genGestureConfig([GestureConfig? gesture]) {
    return gesture ?? GestureConfig();
  }

  SettingConfig genSettingConfig([SettingConfig? setting]) {
    return setting ?? const SettingConfig();
  }

  CrossConfig genCrossConfig([CrossConfig? cross]) {
    return cross ?? const CrossConfig();
  }

  DrawConfig genDrawConfig([DrawConfig? draw]) {
    return draw ?? const DrawConfig();
  }

  @override
  Map<IDrawType, DrawObjectBuilder> get drawObjectBuilders => {};
}
