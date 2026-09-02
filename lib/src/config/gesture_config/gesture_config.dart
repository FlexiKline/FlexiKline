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
    double maxZoomPerGesture = 6,
    this.useCustomZoomRect = false,
    double panClaimRatio = 2,
    double dragClaimSlopFactor = 0.5,
    double scaleClaimSlopFactor = 1,
  })  : tolerance = tolerance ?? ToleranceConfig(),
        scaleSpeed = scaleSpeed.clamp(1, 30),
        maxZoomPerGesture = maxZoomPerGesture.clamp(1.2, 20),
        panClaimRatio = panClaimRatio.clamp(1, 10),
        dragClaimSlopFactor = dragClaimSlopFactor.clamp(0.1, 0.9),
        scaleClaimSlopFactor = scaleClaimSlopFactor.clamp(0.5, 4);

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

  /// 单次价格轴拖动最多能把可见价格区间放大或压缩的倍数。
  ///
  /// 是上界而非实际生效值：一轮手势的缩放系数随手指位置在 `[1 / maxZoomPerGesture,
  /// maxZoomPerGesture]` 内连续变化，两端互为倒数，且与主图区高度无关。**每轮手势独立**，
  /// 抬手重抓即重新计量（每次按下都取新的区间快照），所以多次手势可以叠加到任意总倍数。
  ///
  /// 取值 [1.2, 20]：越大越灵敏，同样位移产生更大的跨度变化，代价是手指贴近主图区边界时
  /// 最后一段行程更陡；取 1.2 已相当迟钝（单次最多 1.2 倍）。默认 6 对齐 TradingView
  /// price scale 的软化项（主图区高度的 0.2 倍，等价 `1 + 1 / 0.2 = 6`）。
  ///
  /// 内部换算成软化项 `s = 主图区高度 / (maxZoomPerGesture - 1)`，加在缩放系数的分子与分母
  /// 两侧。手指永远到不了「虚拟底边」，比值因此不会在贴边时爆炸；而两侧同加保住了「手指
  /// 回到起点即系数为 1」这个不动点——只加分母会让「拖回起点即还原」失效。
  ///
  /// 这一个参数就是缩放灵敏度的全部自由度：行程固定为主图区高度，所以中性点灵敏度
  /// `1 / (按下距底距离 + s)` 与全局倍数上界由同一个 `s` 决定，不存在第二个可独立调节的量。
  final double maxZoomPerGesture;

  /// 缩放滑竿区域是否由宿主自行指定。
  ///
  /// false（默认）：由蜡烛指标在绘制 Y 轴刻度时按最宽刻度文本自动上报——贴主区右缘、宽度
  /// 等于最宽刻度文本、高度取主区全高。true：框架不再自动上报，区域完全来自宿主调用
  /// [FlexiKlineController.setChartZoomSlideBarRect]。
  ///
  /// 只决定这个矩形从哪来，不改变任何命中判定：落点归属、滚轮缩放、光标提示与
  /// `onChartZoomStart` 四处都无条件读 `chartZoomSlideBarRect`。是否启用缩放由
  /// [enableZoom] 决定，与本项无关。
  ///
  /// 置 true 时宿主必须传 canvas 坐标（与手势位置同一坐标系，主区 topLeft 恒为原点）。
  /// 框架不做坐标转换——四个判定点必须读同一个坐标系，任何单点补偿都救不回来。
  final bool useCustomZoomRect;

  /// 图表整体平移抢占手势竞技场所需的横向占优比例，判据为 `|dx| > |dy| × panClaimRatio`。
  ///
  /// 落点没有业务归属时，手势按意图在「平移图表」与「让外层滚动」之间二选一：位移方向落在
  /// 与水平轴夹角小于 `atan(1 / panClaimRatio)` 的锥内才判为平移。普通平移只消费 dx，纵向
  /// 位移对它毫无意义，所以让给外层是语义正确而非妥协。
  ///
  /// 取值 [1, 10]：1 相当于 45° 锥，任何横向占优都算平移；越大锥越窄，越不容易把斜拖误判
  /// 成平移。默认 2，即约 26.57°。
  final double panClaimRatio;

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

  /// 图表缩放抢占手势竞技场所需的指间距变化，相对外层 hitSlop 的比例，判据为
  /// `指间距变化 > hitSlop × scaleClaimSlopFactor`。
  ///
  /// 与外层同量纲比较：外层 `VerticalDragGestureRecognizer` 看「一指移动了多远」，这里看
  /// 「两指相对移动了多远」。默认 1，即取外层的同一个阈值——对称捏合每指走 hitSlop 的四分之
  /// 一即抢到，一指锚定另一指移动时与外层同点，同点由图表胜出（`Listener` 在命中路径中深于
  /// `Scrollable`，同一 move 事件里先判定、先抢占）。
  ///
  /// 取值 [0.5, 4]：调大更保守，代价是外层更容易先接管；调小会把自然滚动时手指的轻微开合
  /// 误判成缩放。
  ///
  /// 与族内 chartPan → chartScale 的切换阈值语义不同，不要合并：抢占要跟外层赛跑、必须
  /// 灵敏，族内切换要稳，过敏会让平移中途乱缩放。
  final double scaleClaimSlopFactor;

  factory GestureConfig.fromJson(Map<String, dynamic> json) => _$GestureConfigFromJson(json);

  Map<String, dynamic> toJson() => _$GestureConfigToJson(this);
}
