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

import 'package:example/src/theme/flexi_theme.dart';
import 'package:example/src/utils/cache_util.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config.dart';

class BitFlexiKlineConfiguration extends IConfiguration {
  static const flexKlineConfigKey = 'flexi_kline_config_key_bit';

  @override
  Size get initialMainSize => Size(ScreenUtil().screenWidth, 300.r);

  @override
  FlexiKlineConfig getFlexiKlineConfig() {
    try {
      final String? jsonStr = CacheUtil().get(flexKlineConfigKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final json = jsonDecode(jsonStr);
        if (json is Map<String, dynamic>) {
          return FlexiKlineConfig.fromJson(json);
        }
      }
    } catch (err, stack) {
      defLogger.e('getFlexiKlineConfig error:$err', stackTrace: stack);
    }
    return defaultFlexiKlineConfig;
  }

  @override
  void saveFlexiKlineConfig(FlexiKlineConfig config) {
    final jsonSrc = jsonEncode(config);
    CacheUtil().setString(flexKlineConfigKey, jsonSrc);
  }

  FlexiKlineConfig genFlexiKlineConfigObject(FKTheme theme) {
    return FlexiKlineConfig(
      main: {candleKey},
      sub: {timeKey},
      grid: GridConfig(
        show: true,
        horizontal: GridAxis(
          show: true,
          width: 0.5.r,
          color: theme.dividerLine,
          type: LineType.solid,
          dashes: const [2, 2],
        ),
        vertical: GridAxis(
          show: true,
          width: 0.5.r,
          color: theme.dividerLine,
          type: LineType.solid,
          dashes: const [2, 2],
        ),
      ),
      setting: SettingConfig(),
      cross: CrossConfig(
        enable: true,
        crosshair: LineConfig(
          width: 0.5.r,
          color: theme.t1,
          type: LineType.dashed,
          dashes: const [3, 3],
        ),
        point: CrossPointConfig(
          radius: 2.r,
          width: 6.r,
          color: theme.t1,
        ),
        tickText: TextAreaConfig(
          style: TextStyle(
            color: theme.t1,
            fontSize: theme.klineTextSize,
            fontWeight: FontWeight.normal,
            height: theme.klineTextHeight,
          ),
          background: theme.lightBg,
          padding: EdgeInsets.all(2.r),
          border: BorderSide.none,
          borderRadius: BorderRadius.all(
            Radius.circular(2.r),
          ),
        ),
      ),
      tooltip: TooltipConfig(),
      indicators: genIndicatorsConfig(theme),
    );
  }

  IndicatorsConfig genIndicatorsConfig(FKTheme theme) {
    final mainHeight = 300.r;
    return IndicatorsConfig(
      candle: genCandleIndicator(theme, mainHeight),
    );
  }

  CandleIndicator genCandleIndicator(FKTheme theme, double mainHeight) {
    return CandleIndicator(
      height: mainHeight,
      padding: defaultMainIndicatorPadding,
      high: MarkConfig(
        spacing: 2,
        line: LineConfig(
          type: LineType.solid,
          color: theme.t1,
          length: 20.r,
          width: 0.5.r,
        ),
      ),
      low: MarkConfig(
        spacing: 2.r,
        line: LineConfig(
          type: LineType.solid,
          color: theme.t1,
          length: 20.r,
          width: 0.5.r,
        ),
      ),
      last: MarkConfig(
        show: true,
        spacing: 100.r,
        line: LineConfig(
          type: LineType.dashed,
          color: theme.t1,
          width: 0.5.r,
          dashes: [3, 3],
        ),
        text: TextAreaConfig(
          style: TextStyle(
            fontSize: theme.klineTextSize,
            color: theme.tlight,
            overflow: TextOverflow.ellipsis,
            height: theme.klineTextHeight,
            textBaseline: TextBaseline.alphabetic,
          ),
          background: theme.translucentBg,
          padding: EdgeInsets.symmetric(horizontal: 4.r, vertical: 2.r),
          border: BorderSide(color: theme.transparent),
          borderRadius: BorderRadius.all(Radius.circular(10.r)),
        ),
      ),
      latest: MarkConfig(
        show: true,
        spacing: 1.r,
        line: LineConfig(
          type: LineType.dashed,
          color: theme.t1,
          width: 0.5.r,
          dashes: [3, 3],
        ),
        text: TextAreaConfig(
          style: TextStyle(
            fontSize: theme.klineTextSize,
            color: Colors.white,
            overflow: TextOverflow.ellipsis,
            height: theme.klineTextHeight,
          ),
          minWidth: 45,
          textAlign: TextAlign.center,
          padding: defaultTextPading,
          borderRadius: BorderRadius.all(Radius.circular(2.r)),
        ),
      ),
      useCandleColorAsLatestBg: true,
      showCountDown: true,
      countDown: TextAreaConfig(
        style: TextStyle(
          fontSize: theme.klineTextSize,
          color: theme.t1,
          overflow: TextOverflow.ellipsis,
          height: theme.klineTextHeight,
        ),
        textAlign: TextAlign.center,
        background: theme.markBg,
        padding: defaultTextPading,
        borderRadius: BorderRadius.all(Radius.circular(2.r)),
      ),
    );
  }
}
