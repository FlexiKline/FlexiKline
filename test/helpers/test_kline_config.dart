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
import 'package:flutter/material.dart' hide Overlay;

class TestFlexiKlineTheme implements IFlexiKlineTheme {
  @override
  Color get longColor => const Color(0xFF33BD65);

  @override
  Color get shortColor => const Color(0xFFE84E74);

  @override
  Color get chartBg => const Color(0xFFFFFFFF);

  @override
  Color get tooltipBg => const Color(0xFFF2F2F2);

  @override
  Color get countDownBg => const Color(0xFFBDBDBD);

  @override
  Color get crossTextBg => const Color(0xFF111111);

  @override
  Color get lastPriceBg => Colors.black54;

  @override
  Color get gridLineColor => const Color(0xffE9EDF0);

  @override
  Color get crosshairColor => const Color(0xFF000000);

  @override
  Color get drawToolColor => Colors.blueAccent;

  @override
  Color get markLineColor => Colors.blue;

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
  Color get latestPriceBg => throw UnimplementedError();

  @override
  Color get dragBg => throw UnimplementedError();

  @override
  Color get lineChartColor => throw UnimplementedError();
}

class TestFlexiKlineConfiguration with FlexiKlineThemeConfigurationMixin {
  @override
  IFlexiKlineTheme get theme => TestFlexiKlineTheme();

  @override
  Map<IDrawType, DrawObjectBuilder<Overlay, DrawObject<Overlay>>> get drawObjectBuilders {
    return {};
  }

  @override
  MainPaintObjectIndicator<Indicator> genMainIndicator(
    MainPaintObjectIndicator<Indicator>? mainIndicator,
  ) {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic>? getConfig(String key) {
    throw UnimplementedError();
  }

  @override
  Future<bool> setConfig(String key, Map<String, dynamic> value) {
    throw UnimplementedError();
  }

  @override
  String get configKey => 'test';
}
