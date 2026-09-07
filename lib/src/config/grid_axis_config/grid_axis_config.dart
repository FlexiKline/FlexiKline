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

import '../../framework/grid_tick_mode.dart';
import '../../framework/serializers.dart';
import '../line_config/line_config.dart';

part 'grid_axis_config.g.dart';

/// 指标侧单个方向的网格线配置。
///
/// 横竖两个方向共用本类型: 内容完全相同(取位方式 + 线样式), 方向由持有它的字段名表达
/// (如 `CandleBaseIndicator.horizontalGrid` / `verticalGrid`)。
///
/// 显隐由 [line] 是否为 null 表达, 不另设 `show` —— grid 层的 `GridBorder` 用 `show` 是为了
/// 保住旧持久化配置的键, 这里是新面, 没有那条约束。
@CopyWith()
@FlexiConfigSerializable
class GridAxisConfig {
  const GridAxisConfig({
    this.mode = GridTickMode.fallback,
    this.line,
  });

  /// 网格线的取位方式。
  final GridTickMode mode;

  /// 线样式; null 则不画线。
  ///
  /// 不画线仍会产出位置: 横向的位置要供刻度文本使用, 纵向的要供副区指标对齐。
  ///
  /// **默认 null 是唯一能精确往返的默认值**: 可空字段一旦带非空默认值, json_serializable
  /// 生成的 `?? 默认值` 就会把宿主显式关掉的线在反序列化时复活。要画线的一方显式给出即可,
  /// 如 `CandleBaseIndicator.defaultHorizontalGrid`。
  final LineConfig? line;

  factory GridAxisConfig.fromJson(Map<String, dynamic> json) => _$GridAxisConfigFromJson(json);

  Map<String, dynamic> toJson() => _$GridAxisConfigToJson(this);
}
