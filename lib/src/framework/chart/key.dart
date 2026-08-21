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

part of 'indicator.dart';

/// 指标 Key 基类（sealed，仅允许三种子类型）
///
/// - [DirectIndicatorKey]：基础/系统指标（Candle、Time、Main 等），不占 slot。
/// - [ComputedIndicatorKey]：数据指标（KDJ、MACD 等），占 slot，需要 precompute。
/// - [ExternalIndicatorKey]：业务指标（Trade 等），不占 slot，由业务数据驱动。
sealed class IIndicatorKey {
  const IIndicatorKey(
    this.id, {
    String? label,
  }) : label = label ?? id;

  final String id;
  final String label;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other.runtimeType == runtimeType && other is IIndicatorKey && id == other.id;
  }

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode;

  @override
  String toString() {
    return '$runtimeType:$id:$label';
  }
}

/// 基础/系统指标 Key
///
/// 用于 Candle、Time、Main 等框架内置指标，不参与 slot 分配。
final class DirectIndicatorKey extends IIndicatorKey {
  const DirectIndicatorKey(super.id, {super.label});
}

/// 数据指标 Key
///
/// 用于 KDJ、MACD、MA 等需要 precompute 并写入 FlexiCandleModel.slots 的指标。
/// 注册时会分配 dataIndex，对应 ComputedIndicator / ComputedPaintObject。
final class ComputedIndicatorKey extends IIndicatorKey {
  const ComputedIndicatorKey(super.id, {super.label});
}

/// 业务指标 Key
///
/// 用于 Trade 等由业务数据或用户操作驱动的指标，不占 slot。
/// 对应 ExternalIndicator / ExternalPaintObject。
final class ExternalIndicatorKey extends IIndicatorKey {
  const ExternalIndicatorKey(super.id, {super.label});
}

const unknownIndicatorKey = DirectIndicatorKey('unknown');

typedef IndicatorBuilder<T extends Indicator<IIndicatorKey>> = T Function(
  Map<String, dynamic>,
);

const mainIndicatorKey = DirectIndicatorKey('main', label: 'Main');
const candleIndicatorKey = DirectIndicatorKey('candle', label: 'Candle');
const timeIndicatorKey = DirectIndicatorKey('time', label: 'Time');

const mainPaneIndex = -1;

/// Indicator绘制模式
///
/// 注: PaintMode仅当Indicator加入MultiPaintObjectIndicator后起作用,
/// 代表当前Indicator的绘制是否是独立绘制的, 还是依赖于MultiPaintObjectIndicator
enum PaintMode {
  /// 组合模式, Indicator会联合其他子Indicator一起绘制, 坐标系共享.
  combine,

  /// 独立模式下, Indicator会按自己height和minmax独立绘制.
  alone;

  bool get isCombine => this == PaintMode.combine;
}

/// 绘制位置
///
/// 主要是指定TimeIndicator的绘制位置
enum DrawPosition {
  // top, // 不支持
  middle,
  bottom,
}

/// 缩放位置
///
/// 将绘制区域宽度三等分, [auto] 会根据当前缩放开始时的焦点位置, 自行决定缩放位置.
enum ScalePosition {
  auto,
  left,
  middle,
  right,
}

/// [PaintObject.handleTap] 的处理结果, 决定框架的后续动作.
///
/// 三值而非 bool: bool 表达不了「消费了点击但不需要选中态」这一态, 而它是
/// 真实存在的(如 crossing 中的下单按钮、蜡烛图的越界价格标记).
enum PaintTapResult {
  /// 未命中本对象: 框架继续询问后续绘制对象.
  ignored,

  /// 已消费本次点击, 但不需要选中态.
  ///
  /// 框架停止询问后续对象, 并清除当前选中态(若有):
  /// 用户点了另一个可交互元素, 说明注意力已从原选中目标转移.
  handled,

  /// 已消费本次点击, 并请求成为选中对象.
  ///
  /// 框架停止询问后续对象, 授予选中态并取消 cross.
  /// 这是获得选中态的唯一途径.
  selected;

  /// 是否消费了本次点击(不再询问后续对象, 也不启动 cross).
  bool get isConsumed => this != PaintTapResult.ignored;
}
