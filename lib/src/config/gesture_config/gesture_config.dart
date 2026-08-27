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

import '../../framework/chart/indicator.dart';
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
    this.enableLongPress = true,
    this.enableInertialPan = true,
    ToleranceConfig? tolerance,
    this.loadMoreWhenNoEnoughDistance,
    this.loadMoreWhenNoEnoughCandles = 60,
    this.enableScale = true,
    this.scalePosition = ScalePosition.auto,
    double scaleSpeed = 10,
    this.supportKeyboardShortcuts = true,
    this.enableZoom = false,
    this.zoomStartMinDistance = 5,
    this.zoomSpeed = 1,
    this.isManualSetZoomRect = false,
    double dragClaimSlopFactor = 0.5,
    double panClaimRatio = 2,
  })  : tolerance = tolerance ?? ToleranceConfig(),
        scaleSpeed = scaleSpeed.clamp(1, 30),
        dragClaimSlopFactor = dragClaimSlopFactor.clamp(0.1, 0.9),
        panClaimRatio = panClaimRatio.clamp(1, 10);

  /// 是否启用长按操作
  final bool enableLongPress;

  /// 是否进行惯性平移
  final bool enableInertialPan;

  /// 惯性平移限制参数
  final ToleranceConfig tolerance;

  /// 当没有足够平移的距离时, 加载更多.
  final double? loadMoreWhenNoEnoughDistance;

  /// 当没有足够平移的蜡烛时, 加载更多.
  final int loadMoreWhenNoEnoughCandles;

  /// 是否启用缩放操作
  final bool enableScale;

  /// 缩放操作位置
  final ScalePosition scalePosition;

  /// 按比例缩放蜡烛图速度. 取值范围[1~30], 建议10.
  final double scaleSpeed;

  /// 是否启用键盘操作
  final bool supportKeyboardShortcuts;

  /// 是否启用缩放操作
  final bool enableZoom;

  /// Zoom缩放操作启动最小距离. 默认5. 注: 仅支持触摸设备.
  final int zoomStartMinDistance;

  /// Zoom缩放速度主区图表速度. 默认1.
  final int zoomSpeed;

  /// 是否手动设置缩放区域
  final bool isManualSetZoomRect;

  /// 落点归属抢占手势竞技场的位移阈值，相对外层 Scrollable 实际 hitSlop 的比例。
  ///
  /// 图表嵌在可滚动容器内时，单指拖动的接受阈值恒为外层 Scrollable 的两倍，必须在到达
  /// 外层阈值之前显式抢占才拿得到手势。落点没有业务归属时不抢占，空白区拖动仍归外层
  /// 滚动。
  ///
  /// 取值 (0, 1)，构造时 clamp 到 [0.1, 0.9]：取 0 会把手柄上的点击也当成拖动抢走，
  /// 取 1 及以上则晚于外层的裁决，抢不到手势。默认 0.5。
  ///
  /// 存比例而非像素值，是因为外层 hitSlop 取自 `DeviceGestureSettings.touchSlop`，
  /// Android 平台值常小于 `kTouchSlop`(18)，写死的像素阈值会在部分设备上失效。
  final double dragClaimSlopFactor;

  /// 图表整体平移抢占手势竞技场所需的横向占优比例，判据为 `|dx| > |dy| × panClaimRatio`。
  ///
  /// 落点没有业务归属时，手势按意图在「平移图表」与「让外层滚动」之间二选一：位移方向落在
  /// 与水平轴夹角小于 `atan(1 / panClaimRatio)` 的锥内才判为平移。普通平移只消费 dx，纵向
  /// 位移对它毫无意义，所以让给外层是语义正确而非妥协。
  ///
  /// 取值 [1, 10]：1 相当于 45° 锥，任何横向占优都算平移；越大锥越窄，越不容易把斜拖误判
  /// 成平移。默认 2，即约 26.57°。
  final double panClaimRatio;

  factory GestureConfig.fromJson(Map<String, dynamic> json) => _$GestureConfigFromJson(json);

  Map<String, dynamic> toJson() => _$GestureConfigToJson(this);
}
