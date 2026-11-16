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
import 'package:json_annotation/json_annotation.dart';

import '../../framework/serializers.dart';

part 'reveal_config.g.dart';

/// 展开的触发策略。
@JsonEnum()
enum RevealTrigger {
  /// 控制器生命周期内, 首次出现可绘制数据时展开一次。
  controllerFirst,

  /// 某个 spec.key 首次未命中缓存、数据可绘制时展开; 缓存命中的切换不展开。
  specFirstLoad,
}

/// 数据显示时的展开动画配置。
///
/// 框架决定何时展开; 绘制由指标在 `paintReveal` 中完成。默认关闭。
@CopyWith()
@FlexiSerializable
class RevealConfig {
  const RevealConfig({
    this.enabled = false,
    this.trigger = RevealTrigger.controllerFirst,
    this.duration = 600,
    this.curve = 'easeInOut',
  });

  /// 总开关。为 false 时不展开, 所有内容直接显示终态。
  final bool enabled;

  /// 展开的触发策略, 见 [RevealTrigger]。
  final RevealTrigger trigger;

  /// 展开时长, 单位毫秒。
  final int duration;

  /// 曲线名, 经 `parseCurve` 解析, 无法识别时为 `Curves.easeInOut`。
  final String curve;

  factory RevealConfig.fromJson(Map<String, dynamic> json) => _$RevealConfigFromJson(json);

  Map<String, dynamic> toJson() => _$RevealConfigToJson(this);
}
