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
  ToleranceConfig({
    this.maxDuration = 1000,
    this.distanceFactor = 0.3,
    this.curvestr = 'decelerate',
  }) : _curve = parseCurve(curvestr);

  final int maxDuration;
  final double distanceFactor;
  final String curvestr;

  late final Curve _curve;
  Curve get curve => _curve;

  @override
  String toString() {
    return 'Tolerance($maxDuration, $distanceFactor, $curvestr)';
  }

  factory ToleranceConfig.fromJson(Map<String, dynamic> json) =>
      _$ToleranceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ToleranceConfigToJson(this);
}
