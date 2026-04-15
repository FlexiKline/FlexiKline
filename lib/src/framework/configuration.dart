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

import '../config/export.dart';
import 'chart/indicator.dart';
import 'draw/overlay.dart';
import 'serializers.dart';

const flexiKlineConfigKey = 'flexi_kline_config';
const drawOverlayListConfigKey = 'draw_overlay_list_config';
const drawOverlayListKey = 'list';
const drawToolbarPositionKey = 'draw_toolbar_position';

/// 获取FlexiKline主题的函数类型
typedef FlexiKlineThemeGetter<T extends IFlexiKlineTheme> = T Function();

/// FlexiKline 主题接口。
abstract interface class IFlexiKlineTheme {
  // ─── 涨跌色 ───────────────────────────────────────────
  Color get longColor; // 蜡烛上涨色、Tooltip 涨值文本色
  Color get shortColor; // 蜡烛下跌色、Tooltip 跌值文本色

  // ─── 背景色 ───────────────────────────────────────────
  Color get chartBg; // K 线组件默认背景色，支持独立主题
  Color get tooltipBg; // Tooltip 背景色、Loading 背景色
  Color get crossTextBg; // 十字线刻度文本背景色
  Color get latestPriceBg; // 最新价标签背景色（最新蜡烛在视口内时）
  Color get lastPriceBg; // 最后价标签背景色（最新蜡烛滚出视口时）
  Color get countDownBg; // 倒计时标签背景色
  Color get dragBg; // 拖拽指标高度时的区域背景色

  // ─── 线色 ─────────────────────────────────────────────
  Color get gridLineColor; // 网格线颜色
  Color get crosshairColor; // 十字线颜色
  Color get drawToolColor; // 绘制工具（趋势线、标尺等）颜色
  Color get markLineColor; // 标记线（最高、最低、最新价、最后价、倒计时边框、拖拽线）颜色
  Color get lineChartColor; // 折线图默认颜色

  // ─── 文本色 ───────────────────────────────────────────
  Color get textColor; // 主文本色、Loading 文本色
  Color get ticksTextColor; // Y 轴/时间轴刻度文本色
  Color get lastPriceColor; // 最后价标签文本色
  Color get crossTextColor; // 十字线刻度文本色
  Color get tooltipTextColor; // Tooltip 文本色
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
  FlexiKlineConfig generateFlexiKlineConfig([FlexiKlineConfig? origin]);

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
    FlexiKlineConfig? config;
    try {
      final json = getConfig(flexiKlineConfigKey);
      if (json is Map<String, dynamic>) {
        config = FlexiKlineConfig.fromJson(json);
      }
    } catch (error, stack) {
      debugPrintStack(stackTrace: stack, label: 'getFlexiKlineConfig$error');
    }

    return generateFlexiKlineConfig(config);
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
    setConfig('$instId-$drawOverlayListConfigKey', {
      drawOverlayListKey: list.map((e) => e.toJson()).toList(),
    });
  }

  /// 从缓存中删除[instId]指定的所有绘制实例数据
  void delDrawOverlayList(String instId) {
    setConfig('$instId-$drawOverlayListConfigKey', {});
  }

  /// 从缓存中删除单个绘制实例数据
  // void delDrawOverlay(String instId, Overlay overlay) {
  //   var list = getDrawOverlayList(instId);
  //   if (list.isNotEmpty) {
  //     list = list.where((e) => e.id != overlay.id);
  //   }
  //   saveDrawOverlayList(instId, list);
  // }

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
