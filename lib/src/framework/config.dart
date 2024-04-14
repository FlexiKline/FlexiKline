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

import '../core/export.dart';
import '../indicators/export.dart';
import 'indicator.dart';

abstract interface class IndicatorGenerator {
  Indicator createIndicator(KlineBindingBase controller);
}

sealed class IndicatorConfig implements IndicatorGenerator {
  IndicatorConfig({
    required this.name,
    required this.key,
    this.drawInMain = false,
  });

  final String name;
  final ValueKey key;
  final bool drawInMain;
}

class CandleConfig extends IndicatorConfig {
  CandleConfig({String? name})
      : super(
          name: name ?? 'Candle',
          key: const ValueKey('Candle'),
          drawInMain: true,
        );

  @override
  Indicator createIndicator(KlineBindingBase controller) {
    final setting = controller as SettingBinding;
    return CandleIndicator(
      key: key,
      height: setting.mainRect.height,
      tipsHeight: setting.mainTipsHeight,
      padding: setting.mainPadding,
    );
  }
}

class VolumeConfig extends IndicatorConfig {
  VolumeConfig({String? name})
      : super(
          name: name ?? 'Vol',
          key: const ValueKey('Volume'),
          drawInMain: false,
        );

  @override
  Indicator createIndicator(KlineBindingBase controller) {
    final setting = controller as SettingBinding;
    return VolumeIndicator(
      key: key,
      height: setting.subIndicatorDefaultHeight,
      tipsHeight: setting.subIndicatorDefaultTipsHeight,
      padding: setting.subIndicatorDefaultPadding,
    );
  }
}

final List<IndicatorConfig> supportMainIndicators = [
  CandleConfig(),
];
final List<IndicatorConfig> supportSubIndicators = [
  VolumeConfig(),
];
