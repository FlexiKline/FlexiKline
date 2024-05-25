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

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';

import '../../framework/export.dart';
import '../../framework/serializers.dart';
import '../cross_config/cross_config.dart';
import '../grid_config/grid_config.dart';
import '../indicators_config/indicators_config.dart';
import '../setting_config/setting_config.dart';
import '../tooltip_config/tooltip_config.dart';

part 'flexi_kline_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class FlexiKlineConfig {
  FlexiKlineConfig({
    required this.grid,
    required this.setting,
    required this.cross,
    required this.tooltip,
    required this.indicators,
    required this.main,
    required this.sub,
  });

  GridConfig grid;
  SettingConfig setting;
  CrossConfig cross;
  TooltipConfig tooltip;
  IndicatorsConfig indicators;
  Set<ValueKey> main;
  Set<ValueKey> sub;

  factory FlexiKlineConfig.fromJson(Map<String, dynamic> json) =>
      _$FlexiKlineConfigFromJson(json);

  Map<String, dynamic> toJson() => _$FlexiKlineConfigToJson(this);
}
