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
import 'package:flutter/animation.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../framework/serializers.dart';
import '../../utils/convert_util.dart';

part 'tolerance_config.g.dart';

/// 平移结束后的惯性动画限制参数
/// [maxDuration] 惯性平移允许的最大时长(单位ms)
/// [distanceFactor] 惯性平移的距离因子 = [velocity] * inertiaFactor; 值越大, 惯性平移距离越长.
/// [curvestr] 惯性平移动画的响应曲线. 参考: https://api.flutter.dev/flutter/animation/Curves-class.html
@CopyWith()
@FlexiConfigSerializable
class ToleranceConfig {
  factory ToleranceConfig({
    int maxDuration = 3000,
    double distanceFactor = 0.8,
    String curvestr = 'easeOutCubic',
    double panSmoothFactor = 0.15,
    double convergenceRatio = 0.85,
  }) {
    return ToleranceConfig._(
      maxDuration: maxDuration,
      distanceFactor: distanceFactor,
      curvestr: curvestr,
      curve: parseCurve(curvestr),
      panSmoothFactor: panSmoothFactor.clamp(0.1, 1.0),
      convergenceRatio: convergenceRatio.clamp(0.0, 1.0),
    );
  }

  const ToleranceConfig._({
    this.maxDuration = 3000,
    this.distanceFactor = 0.8,
    required this.curve,
    required this.curvestr,
    this.panSmoothFactor = 0.15,
    this.convergenceRatio = 0.85,
  });

  final int maxDuration;
  final double distanceFactor;
  final String curvestr;

  /// 平移过程中 Y 轴平滑插值因子 (值越小越平滑, 建议 0.1~0.25)
  final double panSmoothFactor;

  /// 惯性动画尾部开始将 smoothFactor 收敛到 1.0 的动画进度比 (0~1)
  final double convergenceRatio;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final Curve curve;

  @override
  String toString() {
    return 'Tolerance($maxDuration, $distanceFactor, $curvestr, $panSmoothFactor, $convergenceRatio)';
  }

  factory ToleranceConfig.fromJson(Map<String, dynamic> json) => _$ToleranceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ToleranceConfigToJson(this);
}
