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

import '../../framework/export.dart';
import '../cross_config/cross_config.dart';
import '../draw_config/draw_config.dart';
import '../gesture_config/gesture_config.dart';
import '../grid_config/grid_config.dart';
import '../setting_config/setting_config.dart';
import '../tooltip_config/tooltip_config.dart';

part 'flexi_kline_config.g.dart';

@FlexiConfigSerializable
class FlexiKlineConfig {
  FlexiKlineConfig({
    required this.key,
    required this.grid,
    required this.setting,
    required this.gesture,
    required this.cross,
    required this.draw,
    required this.tooltip,
    // required this.indicators,
    this.main = const <IIndicatorKey>{},
    this.sub = const <IIndicatorKey>{},
  });

  final String key;
  GridConfig grid;
  SettingConfig setting;
  GestureConfig gesture;
  CrossConfig cross;
  DrawConfig draw;
  TooltipConfig tooltip;
  Set<IIndicatorKey> main;
  Set<IIndicatorKey> sub;

  FlexiKlineConfig clone() {
    try {
      return FlexiKlineConfig.fromJson(toJson());
    } catch (e) {
      debugPrint('FlexiKlineConfig clone failed!!!');
    }
    return this;
  }

  void update(FlexiKlineConfig config) {
    main = config.main;
    sub = config.sub;
    setting.update(config.setting);
  }

  factory FlexiKlineConfig.fromJson(Map<String, dynamic> json) =>
      _$FlexiKlineConfigFromJson(json);

  Map<String, dynamic> toJson() {
    // main = mainIndicator.children.map((e) => e.key).toSet();
    // sub = subRectIndicatorQueue.map((e) => e.key).toSet();
    return _$FlexiKlineConfigToJson(this);
  }
}
