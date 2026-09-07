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

part of 'core.dart';

/// 绘制环境：主题与基础配置。
abstract interface class PaintEnvironment {
  /// 当前主题。
  IFlexiKlineTheme get theme;

  /// 通用图表设置。
  SettingConfig get settingConfig;

  /// 网格层设置。
  GridConfig get gridConfig;

  /// 十字线设置。
  CrossConfig get crossConfig;

  /// 手势与缩放设置。
  GestureConfig get gestureConfig;
}

/// 绘制数据：K 线数据、数据 listenable 与 computed 指标数据槽。
abstract interface class PaintDataScope {
  /// 当前绘制使用的 K 线数据。
  KlineData get klineData;

  /// 当前 K 线规格变化 listenable。
  ValueListenable<KlineSpec> get klineSpecListenable;

  /// 当前 K 线加载状态 listenable。
  ValueListenable<KlineLoadingState> get loadingStateListenable;

  /// 获取 [key] 对应的 computed data index。
  int? getComputedDataIndex(ComputedIndicatorKey key);

  /// 已分配的 computed data slot 容量（高水位，只增不减）。
  int get computedDataCapacity;
}

/// 绘制几何：区域、蜡烛尺寸、坐标换算与 pane 布局。
abstract interface class PaintGeometryScope {
  /// 整个画布区域。
  Rect get canvasRect;

  /// 主图绘制区域。
  Rect get mainRect;

  /// 副图绘制区域。
  Rect get subRect;

  /// 时间轴绘制区域。
  Rect get timeRect;

  /// 蜡烛宽度。
  double get candleWidth;

  /// 蜡烛间距。
  double get candleSpacing;

  /// 单根蜡烛占用的实际宽度。
  double get candleActualWidth;

  /// 蜡烛宽度的一半。
  double get candleWidthHalf;

  /// 当前画布内第一根蜡烛的绘制偏移。
  double get startCandleDx;

  /// 当前绘制区域相对 startIndex 右侧的偏移。
  double get paintDxOffset;

  /// 计算 [paneIndex] 对应副区的 top。
  double calculatePaneTop(int paneIndex);

  /// 将蜡烛值转换为主图 Y 坐标。
  double candleValueToDy(FlexiNum value, {bool correct = false});

  /// 将主图 Y 坐标转换为蜡烛值。
  FlexiNum? dyToCandleValue(double dy, {bool check = false});
}

/// 绘制运行态：布局写回、cross、chart zoom 与调度。
abstract interface class PaintRuntimeScope {
  /// 是否允许指标写回布局高度。
  bool get canUpdateLayoutHeight;

  /// 指标图是否正在缩放。
  bool get isChartZooming;

  /// 是否正在绘制 cross。
  bool get isCrossing;

  /// 当前 cross 坐标。
  Offset? get crossOffset;

  /// 指标图缩放滑竿区域。
  ///
  /// **只读。** 热区由编排层在主区绘制完成后从绘制树上拉取(见
  /// `CandleBasePaintObject.zoomSlideBarRect`); [PaintContext] 是所有 PaintObject 共享的
  /// 同一个实例, 挂上写方法就等于允许任何副区指标改这块只该由主区蜡烛决定的热区。
  Rect get chartZoomSlideBarRect;

  /// 本帧主区竖线的 dx 序列, canvas 坐标; 空表示主区未产出竖线。
  ///
  /// 副区指标画竖线时把它交给 `PaintGridTicksMixin.paintVerticalGridLines` 即与主区对齐,
  /// 不必依赖「两处配一样」的约定。读取时机由编排保证: 主区的网格线那一趟在所有副区之前
  /// 跑完(见 `ChartBinding.paintChart`)。
  ///
  /// **只读。** [PaintContext] 是所有 PaintObject 共享的同一个实例, 挂上写方法就等于允许
  /// 任何副区指标改主区的竖线位置; dx 只经 `IPaintObject.paintGridLines` 的返回值上行, 由
  /// 框架内部的 `MainPaintObject` 持有。
  ///
  /// 横线没有对应物: 主区是价格轴, 副区是各自的值轴, 两者不可通用。
  List<double> get gridVerticalDxs;

  /// 请求重绘 chart 图层。
  void requestRepaint();

  /// 请求取消当前 cross。
  void requestCancelCross();

  /// 请求移动到初始位置。
  void requestMoveToInitialPosition();

  /// 请求框架释放对 [object] 的持有（当前是拖动归属，后续可能是 hover、焦点等）。
  ///
  /// PaintObject 与框架的通用沟通通道，两个时机共用、无需区分：
  /// - 退出绘制树：框架在 `PaintObject.onExitTree` 内自动调用；
  /// - 仍在树内但要主动中止进行中的交互（如被拖动的业务目标已从数据中消失）：
  ///   不调用则框架会继续把 [PaintObject.handleDragUpdate] 发给它，并把抬手当成一次提交。
  ///
  /// 各 Binding 的实现带对象身份守卫，传入非当前持有对象时为空操作，因此对象在
  /// 任意时机调用都是安全的。
  void requestReleasePaintObject(PaintObject object);
}

/// PaintObject 对外可见的绘制上下文。
abstract interface class PaintContext
    implements PaintEnvironment, PaintDataScope, PaintGeometryScope, PaintRuntimeScope, IStorage, ILogger {}
