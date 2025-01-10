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

import 'dart:math' as math;
import 'dart:ui';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart' hide Overlay;

class TestFlexiKlineTheme implements IFlexiKlineTheme {
  @override
  String key = 'flexi_kline_config_key_test';

  double? _scale;
  @override
  double get scale {
    if (_scale != null) return _scale!;
    final mediaQuery = MediaQueryData.fromView(window);
    _scale = math.min(mediaQuery.size.width, mediaQuery.size.height) / 393;
    return _scale!;
  }

  double? _pixel;
  @override
  double get pixel {
    if (_pixel != null) return _pixel!;
    final mediaQuery = MediaQueryData.fromView(window);
    _pixel = 1.0 / mediaQuery.devicePixelRatio;
    return _pixel!;
  }

  @override
  double setDp(num size) => size * scale;

  @override
  double setSp(num fontSize) => fontSize * scale;

  @override
  Color long = const Color(0xFF33BD65);

  @override
  Color short = const Color(0xFFE84E74);

  @override
  Color chartBg = const Color(0xFFFFFFFF);

  @override
  Color tooltipBg = const Color(0xFFF2F2F2);

  @override
  Color countDownTextBg = const Color(0xFFBDBDBD);

  @override
  Color crossTextBg = const Color(0xFF111111);

  @override
  Color drawTextBg = Colors.blue;

  @override
  Color transparent = Colors.transparent;

  @override
  Color lastPriceTextBg = Colors.black54;

  @override
  Color gridLine = const Color(0xffE9EDF0);

  @override
  Color crossColor = const Color(0xFF000000);

  @override
  Color get drawColor => Colors.blueAccent;

  @override
  Color markLine = const Color(0xFF000000);

  @override
  Color get themeColor => Colors.white;

  @override
  Color textColor = const Color(0xFF000000);

  @override
  Color ticksTextColor = const Color(0xFF949494);

  @override
  Color lastPriceTextColor = const Color(0xFF5F5F5F);

  @override
  Color crossTextColor = const Color(0xFFFFFFFF);

  @override
  Color tooltipTextColor = const Color(0xFF949494);

  @override
  // TODO: implement latestPriceTextBg
  Color get latestPriceTextBg => throw UnimplementedError();
}

class TestFlexiKlineConfiguration with FlexiKlineThemeConfigurationMixin {
  @override
  FlexiKlineConfig getFlexiKlineConfig() {
    return genFlexiKlineConfig();
  }

  @override
  void saveFlexiKlineConfig(FlexiKlineConfig config) {}

  @override
  IFlexiKlineTheme get theme => TestFlexiKlineTheme();

  @override
  Map<IDrawType, DrawObjectBuilder<Overlay, DrawObject<Overlay>>>
      get drawObjectBuilders {
    return {};
  }

  @override
  MainPaintObjectIndicator<PaintObjectIndicator> genMainIndicator() {
    // TODO: implement genMainIndicator
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic>? getConfig(String key) {
    // TODO: implement getConfig
    throw UnimplementedError();
  }

  @override
  Future<bool> setConfig(String key, Map<String, dynamic> value) {
    // TODO: implement setConfig
    throw UnimplementedError();
  }
}
