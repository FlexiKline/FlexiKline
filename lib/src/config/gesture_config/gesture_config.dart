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

import '../../framework/common.dart';
import '../../framework/serializers.dart';
import '../tolerance_config/tolerance_config.dart';

part 'gesture_config.g.dart';

/// GestureConfig 手势平移相关配置
/// [tolerance] 代表手势平移惯性动画的容忍参数
/// [loadMoreWhenNoEnoughDistance] :
///   当滑动时, 还剩此距离时, 触发提前LoadMore蜡烛数据, 其优先于[loadMoreWhenNoEnoughCandles].
/// [loadMoreWhenNoEnoughCandles] :
///   默认值60: 按单根蜡烛宽度默认值计算, 在触摸设备上, 代表还剩一屏半时, 触发LoadMore.
///   非触摸设备上, 根据窗口宽度自行计算设定, 或直接使用[loadMoreWhenNoEnoughDistance]更好.
@CopyWith()
@FlexiConfigSerializable
class GestureConfig {
  GestureConfig({
    this.supportLongPressOnTouchDevice = true,
    this.isInertialPan = true,
    ToleranceConfig? tolerance,
    this.loadMoreWhenNoEnoughDistance,
    this.loadMoreWhenNoEnoughCandles = 60,
    this.scalePosition = ScalePosition.auto,
    double scaleSpeed = 10,
  })  : tolerance = tolerance ?? ToleranceConfig(),
        scaleSpeed = scaleSpeed.clamp(1, 30);

  /// 在触摸设备上是否支持长按操作
  final bool supportLongPressOnTouchDevice;

  /// 是否进行惯性平移
  final bool isInertialPan;

  /// 惯性平移限制参数
  final ToleranceConfig tolerance;

  /// 当没有足够平移的距离时, 加载更多.
  final double? loadMoreWhenNoEnoughDistance;

  /// 当没有足够平移的蜡烛时, 加载更多.
  final int loadMoreWhenNoEnoughCandles;

  /// 缩放操作位置
  final ScalePosition scalePosition;

  /// 缩放速度. 取值范围[1~30], 建议10.
  final double scaleSpeed;

  factory GestureConfig.fromJson(Map<String, dynamic> json) =>
      _$GestureConfigFromJson(json);

  Map<String, dynamic> toJson() => _$GestureConfigToJson(this);
}
