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
/// - [NormalIndicatorKey]：基础/系统指标（Candle、Time、Main 等），不占 slot。
/// - [DataIndicatorKey]：数据指标（KDJ、MACD 等），占 slot，需要 precompute。
/// - [BusinessIndicatorKey]：业务指标（Trade 等），不占 slot，由业务数据驱动。
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
    return '${runtimeType.toString()}:$id:$label';
  }
}

/// 基础/系统指标 Key
///
/// 用于 Candle、Time、Main 等框架内置指标，不参与 slot 分配。
final class NormalIndicatorKey extends IIndicatorKey {
  const NormalIndicatorKey(super.id, {super.label});
}

/// 数据指标 Key
///
/// 用于 KDJ、MACD、MA 等需要 precompute 并写入 FlexiCandleModel.slots 的指标。
/// 注册时会分配 dataIndex，对应 DataIndicator / DataPaintObject。
final class DataIndicatorKey extends IIndicatorKey {
  const DataIndicatorKey(super.id, {super.label});
}

/// 业务指标 Key
///
/// 用于 Trade 等由业务数据或用户操作驱动的指标，不占 slot。
/// 对应 BusinessIndicator / BusinessPaintObject。
final class BusinessIndicatorKey extends IIndicatorKey {
  const BusinessIndicatorKey(super.id, {super.label});
}

const unknownIndicatorKey = NormalIndicatorKey('unknown');

typedef IndicatorBuilder<T extends Indicator<IIndicatorKey>> = T Function(
  Map<String, dynamic>?,
);

const mainIndicatorKey = NormalIndicatorKey('main', label: 'Main');
const candleIndicatorKey = NormalIndicatorKey('candle', label: 'Candle');
const timeIndicatorKey = NormalIndicatorKey('time', label: 'Time');

/// 可预计算接口
/// 实现 [IPrecomputable] 接口, 即代表当前对象是可以进行预计算.
abstract interface class IPrecomputable {
  dynamic get calcParam;
}

const mainIndicatorSlot = -1;

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
