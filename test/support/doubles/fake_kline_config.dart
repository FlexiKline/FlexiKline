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

/// 测试用 [IFlexiKlineTheme] 和 [IConfiguration] 假实现。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';

/// 测试用主题实现
class FakeFlexiKlineTheme implements IFlexiKlineTheme {
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

/// 测试用配置实现
class FakeFlexiKlineConfiguration with FlexiKlineConfigurationMixin {
  FakeFlexiKlineConfiguration({
    Set<IIndicatorKey>? mainChildren,
    Set<IIndicatorKey>? subKeys,
    this.mainIndicatorDefaultSize,
    this.shareConfigInstance = false,
  })  : _mainChildren = mainChildren,
        _subKeys = subKeys;

  final Set<IIndicatorKey>? _mainChildren;
  final Set<IIndicatorKey>? _subKeys;
  final Size? mainIndicatorDefaultSize;

  /// 是否让 [getFlexiKlineConfig] 返回同一缓存实例，用于模拟多 Controller 共享配置。
  final bool shareConfigInstance;
  FlexiKlineConfig? _sharedConfig;

  /// [saveFlexiKlineConfig] 收到的配置，按调用顺序记录，供落盘时机断言。
  final List<FlexiKlineConfig> savedConfigs = [];

  @override
  FlexiKlineConfig getFlexiKlineConfig() {
    if (!shareConfigInstance) return super.getFlexiKlineConfig();
    return _sharedConfig ??= super.getFlexiKlineConfig();
  }

  @override
  void saveFlexiKlineConfig(FlexiKlineConfig config) {
    savedConfigs.add(config);
    super.saveFlexiKlineConfig(config);
  }

  @override
  IFlexiKlineTheme get theme => FakeFlexiKlineTheme();

  @override
  Map<IDrawType, DrawObjectBuilder<Overlay, DrawObject<Overlay>>> get drawObjectBuilders => {};

  @override
  MainPaintObjectIndicator<Indicator> genMainIndicator(
    MainPaintObjectIndicator<Indicator>? mainIndicator,
  ) {
    return MainPaintObjectIndicator(
      size: mainIndicator?.size ?? mainIndicatorDefaultSize ?? const Size(0, 300),
      padding: mainIndicator?.padding ?? EdgeInsets.zero,
      children: _mainChildren,
    );
  }

  @override
  SettingConfig genSettingConfig([SettingConfig? setting]) {
    final base = setting ?? const SettingConfig();
    return base.copyWith(
      autoStartLastPriceCountDownTimer: false,
      autoLoadMoreData: false,
    );
  }

  @override
  Set<IIndicatorKey> genSubIndicators([Set<IIndicatorKey>? sub]) {
    return _subKeys ?? sub ?? {};
  }

  @override
  Map<String, dynamic>? getConfig(String key) => null;

  @override
  Future<bool> setConfig(String key, Map<String, dynamic> value) async => true;
}
