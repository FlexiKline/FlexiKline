import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../theme/my_app_theme.dart';

/// 当前明暗模式对应的 K 线色板。
MyKlineTheme get myKlineTheme =>
    myAppThemeMode.value == ThemeMode.dark ? const MyKlineDarkTheme() : const MyKlineLightTheme();

/// K 线图表主题：涨跌色等公共色在基类，明暗两套具象色板在子类。
abstract class MyKlineTheme implements IFlexiKlineTheme {
  const MyKlineTheme();

  @override
  Color get longColor => const Color(0xFF21B26D);

  @override
  Color get shortColor => const Color(0xFFEE4549);

  @override
  Color get crosshairColor => const Color(0xFFF6A701);

  @override
  Color get drawToolColor => Colors.blueAccent;
}

class MyKlineLightTheme extends MyKlineTheme {
  const MyKlineLightTheme();

  @override
  Color get chartBg => const Color(0xFFFBFDFF);

  @override
  Color get tooltipBg => const Color(0xCCFFFFFF);

  @override
  Color get countdownBg => const Color(0xFFF5F5F5);

  @override
  Color get crossTextBg => const Color(0xFF444444);

  @override
  Color get latestPriceBg => const Color(0xFFFBFDFF);

  @override
  Color get lastPriceBg => Colors.black54;

  @override
  Color get dragBg => textColor;

  @override
  Color get gridLineColor => const Color(0xFFE9E9E9);

  @override
  Color get markLineColor => textColor;

  @override
  Color get lineChartColor => Colors.lightBlue;

  @override
  Color get textColor => const Color(0xFF111111);

  @override
  Color get ticksTextColor => const Color(0xFF949494);

  @override
  Color get lastPriceColor => crossTextColor;

  @override
  Color get crossTextColor => const Color(0xFFF9F8F8);

  @override
  Color get tooltipTextColor => textColor;
}

class MyKlineDarkTheme extends MyKlineTheme {
  const MyKlineDarkTheme();

  @override
  Color get chartBg => const Color(0xFF111111);

  @override
  Color get tooltipBg => const Color(0xCC16181A);

  @override
  Color get countdownBg => const Color(0xFF333333);

  @override
  Color get crossTextBg => const Color(0xFF404040);

  @override
  Color get latestPriceBg => const Color(0xFF111111);

  @override
  Color get lastPriceBg => Colors.black54;

  @override
  Color get dragBg => const Color(0xFFA0A0A0);

  @override
  Color get gridLineColor => const Color(0xFF222222);

  @override
  Color get markLineColor => const Color(0xFFA0A0A0);

  @override
  Color get lineChartColor => Colors.lightBlue;

  @override
  Color get textColor => const Color(0xFFA0A0A0);

  @override
  Color get ticksTextColor => const Color(0xFF949494);

  @override
  Color get lastPriceColor => const Color(0xFFAFAFAF);

  @override
  Color get crossTextColor => const Color(0xFFFFFFFF);

  @override
  Color get tooltipTextColor => const Color(0xFF9D9DA1);
}
