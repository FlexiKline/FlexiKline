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

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:example/generated/l10n.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config.dart';
import '../indicators/avl_indicator.dart';
import '../theme/export.dart';
import '../utils/cache_util.dart';

Map<TooltipLabel, String> tooltipLables() {
  return {
    TooltipLabel.time: S.current.tooltipTime,
    TooltipLabel.open: S.current.tooltipOpen,
    TooltipLabel.high: S.current.tooltipHigh,
    TooltipLabel.low: S.current.tooltipLow,
    TooltipLabel.close: S.current.tooltipClose,
    TooltipLabel.chg: S.current.tooltipChg,
    TooltipLabel.chgRate: S.current.tooltipChgRate,
    TooltipLabel.range: S.current.tooltipRange,
    TooltipLabel.amount: S.current.tooltipAmount,
    TooltipLabel.turnover: S.current.tooltipTurnover,
  };
}

class DefaultFlexiKlineTheme extends BaseFlexiKlineTheme
    with FlexiKlineThemeTextStyle {
  final FKTheme theme;

  DefaultFlexiKlineTheme({
    required this.theme,
  }) : super(
          long: theme.long,
          short: theme.short,
          chartBg: theme.pageBg,
          tooltipBg: theme.markBg,
          countDownTextBg: theme.markBg,
          crossTextBg: theme.lightBg,
          transparent: theme.transparent,
          lastPriceTextBg: theme.translucentBg,
          gridLine: theme.gridLine,
          crosshair: theme.t1,
          priceMarkLine: theme.t1,
          textColor: theme.t1,
          tickTextColor: theme.t2,
          lastPriceTextColor: theme.t1,
          crossTextColor: theme.tlight,
          tooltipTextColor: theme.t1,
        );

  DefaultFlexiKlineTheme.simple({
    required this.theme,
  }) : super.simple(
          long: theme.long,
          short: theme.short,
          chartBg: theme.pageBg,
          markBg: theme.markBg,
          crossTextBg: theme.lightBg,
          lastPriceTextBg: theme.translucentBg,
          color: theme.t1,
          gridLine: theme.gridLine,
          tickTextColor: theme.t2,
          crossTextColor: theme.tlight,
        );

  @override
  String get key {
    return 'flexi_kline_config_key-${theme.brightness.name}';
  }

  double? _scale;
  @override
  double get scale => _scale ??= math.min(
        ScreenUtil().scaleWidth,
        ScreenUtil().scaleHeight,
      );

  double? _pixel;
  @override
  double get pixel {
    if (_pixel != null) return _pixel!;
    double? ratio = ScreenUtil().pixelRatio;
    ratio ??= PlatformDispatcher.instance.displays.first.devicePixelRatio;
    _pixel = 1 / ratio;
    return _pixel!;
  }

  @override
  double setDp(num size) => ScreenUtil().radius(size);

  @override
  double setSp(num fontSize) => ScreenUtil().setSp(fontSize);
}

final defaultKlineThemeProvider = StateProvider<DefaultFlexiKlineTheme>((ref) {
  return ref.watch(
    themeProvider.select((theme) => DefaultFlexiKlineTheme(theme: theme)),
  );
});

class DefaultFlexiKlineConfiguration with FlexiKlineThemeConfigurationMixin {
  final WidgetRef ref;

  DefaultFlexiKlineConfiguration({required this.ref});

  @override
  Size get initialMainSize {
    return Size(ScreenUtil().screenWidth, 300.r);
  }

  @override
  FlexiKlineConfig getFlexiKlineConfig([DefaultFlexiKlineTheme? theme]) {
    theme ??= ref.read(defaultKlineThemeProvider);
    try {
      final String? jsonStr = CacheUtil().get(theme!.key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final json = jsonDecode(jsonStr);
        if (json is Map<String, dynamic>) {
          //return FlexiKlineConfig.fromJson(json);
        }
      }
    } catch (err, stack) {
      defLogger.e('getFlexiKlineConfig error:$err', stackTrace: stack);
    }

    return genFlexiKlineConfig(theme!);
  }

  @override
  void saveFlexiKlineConfig(FlexiKlineConfig config) {
    final jsonSrc = jsonEncode(config);
    CacheUtil().setString(config.key, jsonSrc);
  }

  @override
  CandleIndicator genCandleIndicator(covariant IFlexiKlineTheme theme) {
    return super.genCandleIndicator(theme).copyWith(
          useCandleColorAsLatestBg: false, // 不使用蜡烛色做背景
          latest: MarkConfig(
            show: true,
            spacing: 1.r,
            line: LineConfig(
              type: LineType.dashed,
              color: theme.priceMarkLine,
              width: 0.5.r,
              dashes: [3, 3],
            ),
            text: TextAreaConfig(
              style: TextStyle(
                fontSize: theme.normalTextSize,
                color: theme.textColor,
                overflow: TextOverflow.ellipsis,
                height: defaultTextHeight,
              ),
              background: theme.chartBg,
              minWidth: 45.r,
              textAlign: TextAlign.center,
              padding: theme.textPading,
              border: BorderSide(color: theme.textColor, width: 0.5.r),
              borderRadius: BorderRadius.all(Radius.circular(2 * theme.scale)),
            ),
          ),
          countDown: TextAreaConfig(
            style: TextStyle(
              fontSize: theme.normalTextSize,
              color: theme.textColor,
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight,
            ),
            textAlign: TextAlign.center,
            background: theme.countDownTextBg,
            padding: theme.textPading,
            border: BorderSide(color: theme.textColor, width: 0.5.r),
            borderRadius: BorderRadius.all(Radius.circular(2 * theme.scale)),
          ),
        );
  }

  @override
  List<SinglePaintObjectIndicator> customMainIndicators() {
    final theme = ref.read(defaultKlineThemeProvider);
    return [
      AVLIndicator(
        height: theme.mainIndicatorHeight,
        padding: theme.mainIndicatorPadding,
        line: LineConfig(
          width: 1.r,
          color: Colors.deepOrange,
          type: LineType.solid,
        ),
        tips: TipsConfig(
          label: 'AVL',
          style: TextStyle(
            color: Colors.deepOrange,
            fontSize: theme.normalTextSize,
            height: defaultTextHeight,
          ),
        ),
        tipsPadding: theme.tipsPadding,
      ),
    ];
  }
}
