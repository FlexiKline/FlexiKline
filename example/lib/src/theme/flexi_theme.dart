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
  Color get long => const Color(0xFF02C19A);
  Color get short => const Color(0xFFDD5B58);

  late Color pageBg;
  late Color cardBg;
  late Color markBg;
  late Color disable;

  late Color dividerLine;
  late Color borderLine;

  late Color t1;
  late Color t2;
  late Color t3;
  late Color white = Colors.white;
}

class LightFKTheme extends FKTheme {
  @override
  Brightness get brightness => Brightness.light;
  @override
  ThemeData get themeData => lightTheme;

  @override
  Color get pageBg => const Color(0xffF5F6FA);
  @override
  Color get cardBg => const Color(0xffF8F9FB);
  @override
  Color get markBg => const Color(0xffE4ECFF);
  @override
  Color get disable => const Color(0xffB3B3B3);

  @override
  Color get dividerLine => const Color(0xffE9EDF0);
  @override
  Color get borderLine => const Color(0xFFE3E6E9);

  @override
  Color get t1 => const Color(0xff282828);
  @override
  Color get t2 => const Color(0xff6C6C6C);
  @override
  Color get t3 => const Color(0xff8F8F8F);
  @override
  Color get white => Colors.black;
}

class DarkFKTheme extends FKTheme {
  @override
  Brightness get brightness => Brightness.dark;
  @override
  ThemeData get themeData => darkTheme;

  @override
  Color get pageBg => const Color(0xFF121212);
  @override
  Color get cardBg => const Color(0xFF202020);
  @override
  Color get markBg => const Color(0xFF040404);
  @override
  Color get disable => const Color(0xFF353535);

  @override
  Color get dividerLine => const Color(0xFF242424);
  @override
  Color get borderLine => const Color(0xFF2F2F2F);
  @override
  Color get t1 => const Color(0xFFFFFFFF);
  @override
  Color get t2 => const Color(0xFF939393);
  @override
  Color get t3 => const Color(0xFF606060);
  @override
  Color get white => Colors.white;
}

extension TextStyleFKTheme on FKTheme {
// T1
  TextStyle get t1s10w400 =>
      TextStyle(color: t1, fontSize: 10.sp, fontWeight: FontWeight.w400);
  TextStyle get t1s12w400 =>
      TextStyle(color: t1, fontSize: 12.sp, fontWeight: FontWeight.w400);
  TextStyle get t1s14w400 =>
      TextStyle(color: t2, fontSize: 14.sp, fontWeight: FontWeight.w400);
  TextStyle get t1s14w500 =>
      TextStyle(color: t2, fontSize: 14.sp, fontWeight: FontWeight.w500);
  TextStyle get t1s14w700 =>
      TextStyle(color: t2, fontSize: 14.sp, fontWeight: FontWeight.w700);
  TextStyle get t1s16w400 =>
      TextStyle(color: t2, fontSize: 16.sp, fontWeight: FontWeight.w400);
  TextStyle get t1s16w500 =>
      TextStyle(color: t2, fontSize: 16.sp, fontWeight: FontWeight.w500);
  TextStyle get t1s18w500 =>
      TextStyle(color: t2, fontSize: 16.sp, fontWeight: FontWeight.w500);
  TextStyle get t1s18w600 =>
      TextStyle(color: t2, fontSize: 16.sp, fontWeight: FontWeight.w600);
  // T2
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
  // T3
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

final lightTheme = ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    background: fkLightTheme.pageBg,
    onBackground: fkLightTheme.white,
    primary: fkLightTheme.pageBg,
    onPrimary: fkLightTheme.white,
    secondary: fkLightTheme.cardBg,
    onSecondary: fkLightTheme.t1,
    tertiary: fkLightTheme.disable,
    onTertiary: fkLightTheme.t2,
    surface: fkLightTheme.markBg,
    onSurface: fkLightTheme.t3,
    error: fkLightTheme.short,
    onError: fkLightTheme.white,
  ),
  useMaterial3: true,
  scaffoldBackgroundColor: fkLightTheme.pageBg,
  tabBarTheme: TabBarTheme(
    dividerColor: Colors.transparent,
    indicatorColor: fkLightTheme.t1,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: fkLightTheme.cardBg,
    indicatorColor: Colors.black,
  ),
);

final darkTheme = ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    background: fkDarkTheme.pageBg,
    onBackground: fkDarkTheme.white,
    primary: fkDarkTheme.pageBg,
    onPrimary: fkDarkTheme.white,
    secondary: fkDarkTheme.cardBg,
    onSecondary: fkDarkTheme.t1,
    tertiary: fkDarkTheme.disable,
    onTertiary: fkDarkTheme.t2,
    surface: fkDarkTheme.markBg,
    onSurface: fkDarkTheme.t3,
    error: fkDarkTheme.short,
    onError: fkDarkTheme.white,
  ),
  useMaterial3: true,
  scaffoldBackgroundColor: fkDarkTheme.pageBg,
  tabBarTheme: TabBarTheme(
    dividerColor: Colors.transparent,
    indicatorColor: fkDarkTheme.t1,
  ),
);

// const materialTheme = MaterialTheme(TextTheme());

// final lightTheme = materialTheme.light();
// final darkTheme = materialTheme.dark();
