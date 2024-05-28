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
import 'dart:convert';

import 'package:example/src/config.dart';
import 'package:example/src/router.dart';
import 'package:example/src/theme/export.dart';
import 'package:example/src/theme/flexi_theme.dart';
import 'package:example/src/utils/cache_util.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BitFlexiKlineLightTheme implements IFlexiKlineTheme {
  @override
  String key = 'flexi_kline_config_key_bit-light';

  double? _scale;
  @override
  double get scale => _scale ??= ScreenUtil().scaleWidth;

  double? _pixel;
  @override
  double get pixel {
    if (_pixel != null) return _pixel!;
    double? ratio = ScreenUtil().pixelRatio;
    ratio ??= MediaQueryData.fromWindow(window).devicePixelRatio;
    _pixel = 1 / ratio;
    return _pixel!;
  }

  @override
  double setPt(num size) => size * scale;

  @override
  double setSp(num fontSize) => fontSize * scale;

  @override
  Color long = const Color(0xFF33BD65);

  @override
  Color short = const Color(0xFFE84E74);

  @override
  Color markBg = const Color(0xFFECECEC);

  @override
  Color cardBg = const Color(0xFFF2F2F2);

  @override
  Color disable = const Color(0xFFBDBDBD);

  @override
  Color lightBg = const Color(0xFF111111);

  @override
  Color transparent = Colors.transparent;

  @override
  Color translucentBg = Colors.black54;

  @override
  Color dividerLine = const Color(0xffE9EDF0);

  @override
  Color t1 = const Color(0xFF000000);

  @override
  Color t2 = const Color(0xFF949494);

  @override
  Color t3 = const Color(0xFF5F5F5F);

  @override
  Color tlight = const Color(0xFFFFFFFF);
}

class BitFlexiKlineDarkTheme implements IFlexiKlineTheme {
  @override
  String key = 'flexi_kline_config_key_bit-dark';

  double? _scale;
  @override
  double get scale => _scale ??= ScreenUtil().scaleWidth;

  double? _pixel;
  @override
  double get pixel {
    if (_pixel != null) return _pixel!;
    double? ratio = ScreenUtil().pixelRatio;
    ratio ??= MediaQueryData.fromWindow(window).devicePixelRatio;
    _pixel = 1 / ratio;
    return _pixel!;
  }

  @override
  double setPt(num size) => size * scale;

  @override
  double setSp(num fontSize) => fontSize * scale;

  @override
  Color long = const Color(0xFF33BD65);

  @override
  Color short = const Color(0xFFE84E74);

  @override
  Color markBg = const Color(0xFFECECEC);

  @override
  Color cardBg = const Color(0xFFF2F2F2);

  @override
  Color disable = const Color(0xFFBDBDBD);

  @override
  Color lightBg = const Color(0xFF111111);

  @override
  Color transparent = Colors.transparent;

  @override
  Color translucentBg = Colors.black54;

  @override
  Color dividerLine = const Color(0xffE9EDF0);

  @override
  Color t1 = const Color(0xFF000000);

  @override
  Color t2 = const Color(0xFF949494);

  @override
  Color t3 = const Color(0xFF5F5F5F);

  @override
  Color tlight = const Color(0xFFFFFFFF);
}

final lightBitFlexiKlineTheme = BitFlexiKlineLightTheme();
final darkBitFlexiKlineTheme = BitFlexiKlineDarkTheme();

final bitFlexiKlineThemeProvider = StateProvider<IFlexiKlineTheme>((ref) {
  final brightness = ref.watch(
    themeProvider.select((theme) => theme.brightness),
  );
  if (brightness == Brightness.dark) {
    return darkBitFlexiKlineTheme;
  } else {
    return lightBitFlexiKlineTheme;
  }
});

class BitFlexiKlineConfiguration extends BaseFlexiKlineConfiguration {
  @override
  Size get initialMainSize {
    return Size(ScreenUtil().screenWidth, 300.r);
  }

  @override
  FlexiKlineConfig getInitialFlexiKlineConfig([String? key]) {
    final theme = globalNavigatorKey.ref.read(bitFlexiKlineThemeProvider);
    try {
      key ??= theme.key;
      final String? jsonStr = CacheUtil().get(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final json = jsonDecode(jsonStr);
        if (json is Map<String, dynamic>) {
          return FlexiKlineConfig.fromJson(json);
        }
      }
    } catch (err, stack) {
      defLogger.e('getFlexiKlineConfig error:$err', stackTrace: stack);
    }

    /// 取默认
    return genFlexiKlineConfig(theme);
  }

  @override
  void saveFlexiKlineConfig(FlexiKlineConfig config) {
    final jsonSrc = jsonEncode(config);
    CacheUtil().setString(config.key, jsonSrc);
  }
}
