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

/// 用户交互事件类型。
///
/// 每项都对应框架内一个已有的操作收口方法，在那里直接上报，不改动任何功能逻辑。
/// 新增事件只需在此追加枚举值，[FlexiKlineObserver] 接口不变。
enum FlexiKlineEventType {
  // —— 图表手势 ——
  /// 平移结束。
  pan,

  /// X 轴缩放结束（蜡烛宽度变化）。
  scale,

  /// Y 轴缩放结束（价格区间由用户接管）。
  zoomY,

  /// 十字线进入 / 退出。`active` 区分。
  cross,

  /// 拖拽调整指标高度结束。
  gridResize,

  /// 指标绘制对象拖动结束。
  paintObjectDrag,

  // —— 数据 ——
  /// 触发加载历史数据。
  loadMoreHistory,

  /// 切换 K 线数据（交易对 / 周期）。
  switchKlineData,

  /// 定位到指定日期。
  moveToDate,

  /// 回到最新位置。
  moveToLatest,

  // —— 指标 ——
  /// 显示 / 隐藏指标。`visible` 区分。
  indicatorToggle,

  // —— 绘图 ——
  /// 选用绘图工具开始绘制。
  drawStart,

  /// 完成一个绘制对象。
  drawComplete,

  /// 选中一个绘制对象。
  drawSelect,

  /// 拖动绘制对象结束。
  drawMove,

  /// 删除绘制对象。`all` 标识是否清空。
  drawDelete,
}

/// 一次用户交互事件：只承载事实快照，不含业务解释。
///
/// [data] 是发射点就近可得的扁平载荷，key 由各发射点保证；埋点方通常直接
/// `track(type.name, data)`。聚合、时间窗与上报格式全在业务侧决定。
final class FlexiKlineEvent {
  const FlexiKlineEvent(this.type, this.timestamp, this.data);

  final FlexiKlineEventType type;

  /// 事件发生时刻（epoch ms）。
  final int timestamp;

  /// 事实载荷；无附加信息时为空 Map。
  final Map<String, Object?> data;

  @override
  String toString() => 'FlexiKlineEvent(${type.name}, ts:$timestamp, data:$data)';
}

/// 用户交互观测者。
///
/// 业务侧继承后 override [onEvent]，按 [FlexiKlineEvent.type] 分流做埋点上报，
/// 经 `FlexiKlineController.addObserver` / `removeObserver` 注册与注销。
///
/// 这是一条旁路只读通道：回调内不应回写框架状态或做重活，也不应假设执行时序。
/// 用抽象类而非接口，后续演进可以 no-op 方式新增方法而不破坏已有实现。
abstract class FlexiKlineObserver {
  const FlexiKlineObserver();

  /// 收到一次用户交互事件。默认 no-op。
  void onEvent(FlexiKlineEvent event) {}
}
