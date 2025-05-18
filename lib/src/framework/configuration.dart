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

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../constant.dart';
import '../config/export.dart';
import 'chart/indicator.dart';
import 'draw/overlay.dart';
import 'serializers.dart';

const flexiKlineConfigKey = 'flexi_kline_config';
const drawOverlayListConfigKey = 'draw_overlay_list_config';
const drawOverlayListKey = 'list';
const drawToolbarPositionKey = 'draw_toolbar_position';

/// FlexiKline主题接口.
///
/// 定义FlexiKline中通用颜色
abstract interface class IFlexiKlineTheme {
  /// 实际尺寸与UI设计的比例
  double get scale;

  /// 一个物理像素的值
  double get pixel;

  ///根据宽度或高度中的较小值进行适配
  /// - [size] UI设计上的尺寸大小, 单位dp.
  double setDp(num size);

  //字体大小适配方法
  ///- [fontSize] UI设计上字体的大小,单位dp.
  double setSp(num fontSize);

  /// 涨跌颜色
  Color get long;
  Color get short;

  Color get transparent;

  /// 背景色
  // 拖拽区域背景色
  Color get dragBg;
  Color get chartBg;
  Color get tooltipBg;
  Color get crossTextBg;
  Color get latestPriceTextBg;
  Color get lastPriceTextBg;
  Color get countDownTextBg;

  /// 线
  Color get gridLine; // grid网格线颜色
  Color get crossColor; // 十字线颜色
  Color get drawColor; // 绘制工具线颜色(十字线)
  Color get markLineColor; // 指示线颜色(最高,最低, 最新价, 拖拽底色)
  Color get lineChartColor; // line图默认颜色

  /// 主题色
  Color get themeColor;

  /// 文本颜色配置
  Color get textColor;
  // 刻度文本颜色
  Color get ticksTextColor;
  // 最后价文本颜色
  Color get lastPriceTextColor;
  // corssing时文本颜色
  Color get crossTextColor;
  // Tips 文本默认颜色
  Color get tooltipTextColor;
}

mixin FlexiKlineThemeTextStyle implements IFlexiKlineTheme {
  TextStyle getTextStyle(
    Color color, {
    double? fontSize,
    FontWeight? fontWeight,
    TextOverflow? overflow,
    double height = defaultTextHeight,
    TextBaseline textBaseline = TextBaseline.alphabetic,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize ?? defaulTextSize * scale,
      fontWeight: fontWeight,
      overflow: overflow,
      height: height,
      textBaseline: textBaseline,
    );
  }

  TextStyle get normalTextyStyle => TextStyle(
        color: textColor,
        fontSize: setSp(defaulTextSize),
        fontWeight: FontWeight.normal,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      );

  TextStyle get ticksTextStyle => TextStyle(
        color: ticksTextColor,
        fontSize: setSp(defaulTextSize),
        fontWeight: FontWeight.normal,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      );

  TextStyle get lastPriceTextStyle => TextStyle(
        color: lastPriceTextColor,
        fontSize: setSp(defaulTextSize),
        fontWeight: FontWeight.normal,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      );

  TextStyle get crossTextStyle => TextStyle(
        color: crossTextColor,
        fontSize: setSp(defaulTextSize),
        fontWeight: FontWeight.normal,
        height: defaultTextHeight,
      );

  TextStyle get tooltipTextStyle => TextStyle(
        color: tooltipTextColor,
        fontSize: setSp(defaulTextSize),
        overflow: TextOverflow.ellipsis,
        height: defaultMultiTextHeight,
      );

  TextStyle getTipsTextStyle(Color tipsColor) => TextStyle(
        color: tipsColor,
        fontSize: setSp(defaulTextSize),
        overflow: TextOverflow.ellipsis,
        height: defaultTipsTextHeight,
      );
}

abstract interface class IStorage {
  Map<String, dynamic>? getConfig(String key);

  Future<bool> setConfig(String key, Map<String, dynamic> value);
}

/// FlexiKline配置接口
abstract interface class IConfiguration implements IStorage {
  /// 当前配置主题
  IFlexiKlineTheme get theme;

  String get configKey;

  /// 生成FlexiKline配置
  /// 调用场景:
  /// 1. 首次加载(无缓存)情况下, 生成默认的FlexiKlineConfig
  /// 2. 从缓存中反序列化实现时调用, [origin]即是原始缓存配置, 这可能出现在后续追加/删除/修改配置时, 原有配置无法反序列化.
  FlexiKlineConfig generateFlexiKlineConfig([Map<String, dynamic>? origin]);

  /// 蜡烛指标配置构造器(主区)
  IndicatorBuilder<CandleBaseIndicator> get candleIndicatorBuilder;

  /// 时间指标配置构造器(副区)
  IndicatorBuilder<TimeBaseIndicator> get timeIndicatorBuilder;

  /// 主区指标配置定制
  Map<IIndicatorKey, IndicatorBuilder> get mainIndicatorBuilders;

  /// 副区指标配置定制
  Map<IIndicatorKey, IndicatorBuilder> get subIndicatorBuilders;

  /// 绘制工具定制
  Map<IDrawType, DrawObjectBuilder> get drawObjectBuilders;
}

typedef FromJson<T> = T Function(Map<String, dynamic>);

extension FromJsonExt<T> on FromJson<T> {
  /// 将[json]数据转换为类型[T]的实例
  T? toInstance(Map<String, dynamic>? json) {
    return jsonToInstance(json, this);
  }
}

/// 通过[fromJson]函数将[json]数据转换为类型[T]的实例
T? jsonToInstance<T>(Map<String, dynamic>? json, FromJson<T> fromJson) {
  if (json == null || json.isEmpty) return null;
  try {
    return fromJson(json);
  } catch (error, stack) {
    debugPrintStack(stackTrace: stack, label: error.toString());
  }
  return null;
}

extension IConfigurationExt on IConfiguration {
  FlexiKlineConfig getFlexiKlineConfig() {
    Map<String, dynamic>? json;
    try {
      json = getConfig(flexiKlineConfigKey);
      if (json is Map<String, dynamic>) {
        return FlexiKlineConfig.fromJson(json);
      }
    } catch (error, stack) {
      debugPrintStack(stackTrace: stack, label: 'getFlexiKlineConfig$error');
    }

    return generateFlexiKlineConfig(json);
  }

  void saveFlexiKlineConfig(FlexiKlineConfig config) {
    setConfig(flexiKlineConfigKey, config.toJson());
  }

  /// 从本地获取加载[key]指定的指标配置, 并转换成[Indicator]实例.
  /// 如果指定[builder], 则不会从配置中查找.
  T? getIndicator<T extends Indicator>(
    IIndicatorKey key, {
    IndicatorBuilder? builder,
  }) {
    try {
      final json = getConfig(key.id);
      builder ??= mainIndicatorBuilders[key];
      builder ??= subIndicatorBuilders[key];
      if (builder == null) return null;
      final indicator = builder.call(json);
      if (indicator is T) return indicator;
    } catch (error, stack) {
      debugPrintStack(stackTrace: stack, label: 'getIndicator$error');
    }
    return null;
  }

  /// 保存[indicator]配置到本地.
  bool saveIndicator<T extends Indicator>(T indicator) {
    final json = indicator.toJson();
    if (json.isEmpty) return false;
    setConfig(indicator.key.id, json);
    return true;
  }

  void delIndicator(IIndicatorKey key) {
    setConfig(key.id, {});
  }

  /// 从本地获取[instId]对应的绘制实例数据列表.
  Iterable<Overlay> getDrawOverlayList(String instId) {
    final json = getConfig('$instId-$drawOverlayListConfigKey');
    if (json == null || json.isEmpty) return [];
    final data = json[drawOverlayListKey];
    if (data is List<dynamic>) {
      return data.map((e) => Overlay.fromJson(e)).toList();
    }
    return [];
  }

  /// 以[instId]为key, 持久化绘制实例列表[list]到本地中.
  void saveDrawOverlayList(String instId, Iterable<Overlay> list) {
    if (list.isEmpty) return;
    setConfig('$instId-$drawOverlayListConfigKey', {
      drawOverlayListKey: list.map((e) => e.toJson()).toList(),
    });
  }

  /// 获取DrawToolbar上次缓存的位置
  Offset getDrawToolbarPosition() {
    final json = getConfig(drawToolbarPositionKey);
    if (json == null || json.isEmpty) return Offset.infinite;
    return const OffsetConverter(defaultOffset: Offset.infinite).fromJson(json);
  }

  /// 保存DrawToolbar位置[position]
  void saveDrawToolbarPosition(Offset position) {
    final json = const OffsetConverter().toJson(position);
    setConfig(drawToolbarPositionKey, json);
  }
}
