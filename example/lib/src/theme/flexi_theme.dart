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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'theme.dart';
import 'theme_manager.dart';

final themeProvider = StateProvider<FKTheme>((ref) {
  return ref.watch(themeModeProvider) != ThemeMode.dark
      ? fkLightTheme
      : fkDarkTheme;
});

final fkLightTheme = LightFKTheme();
final fkDarkTheme = DarkFKTheme();

abstract class FKTheme {
  Brightness get brightness;
  ThemeData get themeData;

  Color get transparent => Colors.transparent;
  Color get brand => Colors.black;
  Color get long => const Color(0xFF33BD65);
  Color get short => const Color(0xFFE84E74);
  Color get white => Colors.white;
  Color get error => short;

  late Color pageBg;
  late Color lightBg;
  late Color translucentBg;
  late Color cardBg;
  late Color markBg;
  late Color gridLine;

  late Color dividerLine;
  late Color borderLine;
  late Color borderLight;
  late Color disable;

  late Color t1;
  late Color t2;
  late Color t3;
  late Color themeColor;

  double? _pixel;
  double get pixel {
    if (_pixel != null) return _pixel!;
    double? ratio = ScreenUtil().pixelRatio;
    ratio ??= PlatformDispatcher.instance.displays.first.devicePixelRatio;
    _pixel = 1 / ratio;
    return _pixel!;
  }
}

class LightFKTheme extends FKTheme {
  @override
  Brightness get brightness => Brightness.light;
  @override
  ThemeData get themeData => lightTheme;

  @override
  Color get pageBg => const Color(0xFFFFFFFF);
  @override
  Color get lightBg => const Color(0xFF111111);
  @override
  Color get translucentBg => markBg.withOpacity(0.7);
  @override
  Color get cardBg => const Color(0xFFF2F2F2);
  @override
  Color get markBg => const Color(0xFFECECEC);
  @override
  Color get gridLine => const Color(0xFFE9E9E9);

  @override
  Color get dividerLine => const Color(0xffE9EDF0);
  @override
  Color get borderLine => const Color(0xFFE3E6E9);
  @override
  Color get borderLight => const Color(0xFF000000);
  @override
  Color get disable => const Color(0xFF505050);

  @override
  Color get t1 => const Color(0xFF000000);
  @override
  Color get t2 => const Color(0xFF949494);
  @override
  Color get t3 => const Color(0xFF5F5F5F);
  @override
  Color get themeColor => const Color(0xFFFFFFFF);
}

class DarkFKTheme extends FKTheme {
  @override
  Brightness get brightness => Brightness.dark;
  @override
  ThemeData get themeData => darkTheme;

  @override
  Color get pageBg => const Color(0xFF111111);
  @override
  Color get lightBg => const Color(0xFFFFFFFF);
  @override
  Color get translucentBg => pageBg.withOpacity(0.7);
  @override
  Color get cardBg => const Color(0xFF1A1A1A);
  @override
  Color get markBg => const Color(0xFF2F2F2F);
  @override
  Color get gridLine => const Color(0xFF333333);

  @override
  Color get dividerLine => const Color(0xFF242424);
  @override
  Color get borderLine => const Color(0xFF2F2F2F);
  @override
  Color get borderLight => const Color(0xFFFFFFFF);
  @override
  Color get disable => const Color(0xFF505050);

  @override
  Color get t1 => const Color(0xFFFFFFFF);
  @override
  Color get t2 => const Color(0xFF909090);
  @override
  Color get t3 => const Color(0xFF606060);
  @override
  Color get themeColor => const Color(0xFF000000);
}

extension TextStyleFKTheme on FKTheme {
  /// Text long
  TextStyle get tls10w400 =>
      TextStyle(color: long, fontSize: 10.sp, fontWeight: FontWeight.w400);
  TextStyle get tls12w400 =>
      TextStyle(color: long, fontSize: 12.sp, fontWeight: FontWeight.w400);

  /// Text short
  TextStyle get tss10w400 =>
      TextStyle(color: short, fontSize: 10.sp, fontWeight: FontWeight.w400);
  TextStyle get tss12w400 =>
      TextStyle(color: short, fontSize: 12.sp, fontWeight: FontWeight.w400);

  /// T1
  TextStyle get t1s10w400 =>
      TextStyle(color: t1, fontSize: 10.sp, fontWeight: FontWeight.w400);
  TextStyle get t1s12w400 =>
      TextStyle(color: t1, fontSize: 12.sp, fontWeight: FontWeight.w400);
  TextStyle get t1s12w500 =>
      TextStyle(color: t1, fontSize: 12.sp, fontWeight: FontWeight.w500);
  TextStyle get t1s14w400 =>
      TextStyle(color: t1, fontSize: 14.sp, fontWeight: FontWeight.w400);
  TextStyle get t1s14w500 =>
      TextStyle(color: t1, fontSize: 14.sp, fontWeight: FontWeight.w500);
  TextStyle get t1s14w700 =>
      TextStyle(color: t1, fontSize: 14.sp, fontWeight: FontWeight.w700);
  TextStyle get t1s16w400 =>
      TextStyle(color: t1, fontSize: 16.sp, fontWeight: FontWeight.w400);
  TextStyle get t1s16w500 =>
      TextStyle(color: t1, fontSize: 16.sp, fontWeight: FontWeight.w500);
  TextStyle get t1s16w700 =>
      TextStyle(color: t1, fontSize: 16.sp, fontWeight: FontWeight.w700);
  TextStyle get t1s18w500 =>
      TextStyle(color: t1, fontSize: 16.sp, fontWeight: FontWeight.w500);
  TextStyle get t1s18w600 =>
      TextStyle(color: t1, fontSize: 16.sp, fontWeight: FontWeight.w600);
  TextStyle get t1s18w700 =>
      TextStyle(color: t1, fontSize: 18.sp, fontWeight: FontWeight.w700);
  TextStyle get t1s20w700 =>
      TextStyle(color: t1, fontSize: 20.sp, fontWeight: FontWeight.w700);

  /// T2
  TextStyle get t2s10w400 =>
      TextStyle(color: t2, fontSize: 10.sp, fontWeight: FontWeight.w400);
  TextStyle get t2s12w400 =>
      TextStyle(color: t2, fontSize: 12.sp, fontWeight: FontWeight.w400);
  TextStyle get t2s14w400 =>
      TextStyle(color: t2, fontSize: 14.sp, fontWeight: FontWeight.w400);
  TextStyle get t2s14w500 =>
      TextStyle(color: t2, fontSize: 14.sp, fontWeight: FontWeight.w500);
  TextStyle get t2s16w400 =>
      TextStyle(color: t2, fontSize: 16.sp, fontWeight: FontWeight.w400);
  TextStyle get t2s16w500 =>
      TextStyle(color: t2, fontSize: 16.sp, fontWeight: FontWeight.w500);
  TextStyle get t2s18w500 =>
      TextStyle(color: t2, fontSize: 16.sp, fontWeight: FontWeight.w500);
  TextStyle get t2s18w600 =>
      TextStyle(color: t2, fontSize: 16.sp, fontWeight: FontWeight.w600);

  /// T3
  TextStyle get t3s10w400 =>
      TextStyle(color: t3, fontSize: 10.sp, fontWeight: FontWeight.w400);
  TextStyle get t3s12w400 =>
      TextStyle(color: t3, fontSize: 12.sp, fontWeight: FontWeight.w400);
  TextStyle get t3s14w400 =>
      TextStyle(color: t3, fontSize: 14.sp, fontWeight: FontWeight.w400);
  TextStyle get t3s14w500 =>
      TextStyle(color: t3, fontSize: 14.sp, fontWeight: FontWeight.w500);
  TextStyle get t3s16w400 =>
      TextStyle(color: t3, fontSize: 16.sp, fontWeight: FontWeight.w400);
  TextStyle get t3s16w500 =>
      TextStyle(color: t3, fontSize: 16.sp, fontWeight: FontWeight.w500);
  TextStyle get t3s18w500 =>
      TextStyle(color: t3, fontSize: 16.sp, fontWeight: FontWeight.w500);
  TextStyle get t3s18w600 =>
      TextStyle(color: t3, fontSize: 16.sp, fontWeight: FontWeight.w600);
}

extension ButtonStyleFKTheme on FKTheme {
  ButtonStyle get roundBtnStyle {
    return TextButton.styleFrom(
      foregroundColor: t1,
      backgroundColor: markBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r)),
    );
  }

  ButtonStyle outlinedBtnStyle({
    bool showOutlined = false,
  }) {
    return TextButton.styleFrom(
      foregroundColor: t1,
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r)),
      side: showOutlined ? BorderSide(color: t1, width: 1.r) : null,
    );
  }

  ButtonStyle circleBtnStyle({Color? fg, Color? bg}) {
    return TextButton.styleFrom(
      foregroundColor: fg ?? t2,
      backgroundColor: bg ?? markBg,
      shape: const CircleBorder(),
    );
  }

  ShapeBorder get defaultShape => RoundedRectangleBorder(
        side: BorderSide(color: borderLight, width: 1.r),
        borderRadius: BorderRadius.circular(5.r),
      );
}

// final lightTheme = ThemeData(
//   colorScheme: ColorScheme(
//     brightness: Brightness.light,
//     background: fkLightTheme.pageBg,
//     onBackground: fkLightTheme.white,
//     primary: fkLightTheme.pageBg,
//     onPrimary: fkLightTheme.white,
//     secondary: fkLightTheme.cardBg,
//     onSecondary: fkLightTheme.t1,
//     tertiary: fkLightTheme.disable,
//     onTertiary: fkLightTheme.t2,
//     surface: fkLightTheme.markBg,
//     onSurface: fkLightTheme.t3,
//     error: fkLightTheme.short,
//     onError: fkLightTheme.white,
//   ),
//   useMaterial3: true,
//   scaffoldBackgroundColor: fkLightTheme.pageBg,
//   tabBarTheme: TabBarTheme(
//     dividerColor: Colors.transparent,
//     indicatorColor: fkLightTheme.t1,
//   ),
//   navigationBarTheme: NavigationBarThemeData(
//     backgroundColor: fkLightTheme.cardBg,
//     indicatorColor: Colors.black,
//   ),
// );

// final darkTheme = ThemeData(
//   colorScheme: ColorScheme(
//     brightness: Brightness.light,
//     background: fkDarkTheme.pageBg,
//     onBackground: fkDarkTheme.white,
//     primary: fkDarkTheme.pageBg,
//     onPrimary: fkDarkTheme.white,
//     secondary: fkDarkTheme.cardBg,
//     onSecondary: fkDarkTheme.t1,
//     tertiary: fkDarkTheme.disable,
//     onTertiary: fkDarkTheme.t2,
//     surface: fkDarkTheme.markBg,
//     onSurface: fkDarkTheme.t3,
//     error: fkDarkTheme.short,
//     onError: fkDarkTheme.white,
//   ),
//   useMaterial3: true,
//   scaffoldBackgroundColor: fkDarkTheme.pageBg,
//   tabBarTheme: TabBarTheme(
//     dividerColor: Colors.transparent,
//     indicatorColor: fkDarkTheme.t1,
//   ),
// );

const materialTheme = MaterialTheme(TextTheme());

final lightTheme = materialTheme.light().copyWith(
      tabBarTheme: TabBarTheme(
        dividerColor: Colors.transparent,
        indicatorColor: fkLightTheme.t1,
      ),
    );
final darkTheme = materialTheme.dark().copyWith(
      tabBarTheme: TabBarTheme(
        dividerColor: Colors.transparent,
        indicatorColor: fkDarkTheme.t1,
      ),
    );
