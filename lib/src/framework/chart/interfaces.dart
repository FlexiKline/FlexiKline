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

/// 指标图的绘制边界接口
abstract interface class IPaintBounding {
  void resetPaintBounding({int? paneIndex});

  /// 当前指标图画笔可以绘制的范围
  Rect get drawableRect;

  /// 当前指标图绘制区域
  Rect get chartRect;

  /// 当前指标图顶部绘制区域
  Rect get topRect;

  /// 当前指标图底部绘制区域
  Rect get bottomRect;
}

/// 指标图的绘制状态接口
///
/// 定义绘制对象的状态管理能力，包括 minMax、坐标转换等。
/// 所有类型的 PaintObject 都需要此接口。
abstract interface class IPaintState {
  /// 最大值/最小值范围
  MinMax get minMax;

  /// 设置最大值/最小值范围
  void setMinMax(MinMax val);

  /// 当前指标图的 dyFactor
  double get dyFactor;

  /// 计算指标需要的数据, 并返回 [start ~ end) 之间的 MinMax
  ///
  /// 此方法在绘制前调用，用于计算当前绘制范围的数据范围。
  /// 返回 null 表示使用当前 minMax。
  ///
  /// 入口保证 `0 <= start < end <= klineData.length`(见 [BaseData.canPaintChart]),
  /// 实现无需再校验区间或数据是否为空; 但派生下标(如 `end - period`)可能为负, 在遍历
  /// 之外索引蜡烛时须自行确认。
  MinMax? computeVisibleMinMax(int start, int end);
}

/// 指标图的绘制接口
///
/// 定义绘制对象的核心绘制能力，包括图表绘制、Cross 事件处理等。
abstract interface class IPaintObject {
  /// 指标 Key
  IIndicatorKey get key;

  /// 绘制本对象负责的网格线: 先竖线、后横线, 位置由各方向自己的 mode 决定。
  ///
  /// 它是**指标层的编排入口**, 不是单条线的绘制方法: 实现者内部各方向自己取位置
  /// (`PaintGridTicksMixin.resolveXxx`)再落笔(`paintXxx`), 框架只负责在正确的时机调它一次。
  ///
  /// 框架在**本 pane 的可见区间就绪之后、本 pane 的指标图之前**调用, 所以 [IPaintState.minMax]
  /// 与 [IPaintBounding] 的几何都已生效: 位置由值换算的横线可以直接按本帧区间取整, 而网格线
  /// 一定落在本 pane 所有指标之下 —— 后者与各指标的 zIndex 无关, 只由这个调用时机保证。
  ///
  /// > [!warning]
  /// > **数据未就绪(`canPaintChart` 为 false)那一帧是唯一的例外。** 那时框架只走这一趟就返回,
  /// > [IPaintState.minMax] 读到的是上一帧的值, 副区的 `paneIndex` 也还没分配 —— 副区的
  /// > [IPaintBounding.drawableRect] 因此读到的是主区区域。所以那一帧的位置只能依赖几何:
  /// > 内置实现在那里让 `nice` 退化为 `count`(见 `PaintGridTicksMixin.resolveHorizontalDys`),
  /// > 副区实现者要么显式传 `bounds`, 要么接受那一帧不画。
  ///
  /// 返回本帧**解析出**的两个方向的位置, 与画不画无关 —— `line` 为 null 只表示本对象自己不画,
  /// 位置照样要返回。它是这些位置离开本对象的唯一通道, 宿主覆写本方法后框架拿到的因此仍是宿主
  /// 实际用的位置: dx 经 [PaintContext.gridVerticalDxs] 供其它 pane 对齐, dy 交给本对象的刻度
  /// 文本那一趟(隔着整个子对象遍历)。不产出时给空列表。
  ///
  /// 两个方向都返回, 而不按消费方裁剪: 框架当前只读主区那一趟的返回值(副区无处对齐、值轴各自
  /// 独立), 但「交出你解析的位置」是一条与实现者身份无关的契约; 按消费方裁剪会让主区的需要长进
  /// 公共接口, 且横线一旦不经返回值上行, 就只能靠帧内字段或重算一遍跨过子对象遍历。
  ({List<double> dxs, List<double> dys}) paintGridLines(Canvas canvas, Size size);

  /// 绘制指标图
  ///
  /// [canvas] 画布
  /// [size] 绘制区域大小
  void paint(Canvas canvas, Size size);

  /// 在所有指标图绘制结束后额外的绘制
  ///
  /// 用于绘制一些需要覆盖在其他指标图之上的内容。
  void paintOverlay(Canvas canvas, Size size);

  /// 绘制 Cross 状态下的指标附加内容。
  ///
  /// 当用户进行 Cross 操作时，由 Cross 图层调用。
  /// [canvas] 画布
  /// [offset] Cross 位置
  void paintCross(Canvas canvas, Offset offset, {FlexiCandleModel? model});

  /// 绘制顶部 Tips 信息条
  ///
  /// [canvas] 画布
  /// [model] 当前选中的蜡烛数据
  /// [offset] Cross 位置（如果有）
  /// [tipsRect] Tips 绘制区域
  ///
  /// 返回绘制的 Tips 高度，用于布局计算
  Size? paintTips(
    Canvas canvas, {
    FlexiCandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  });
}

/// PaintObject 统一生命周期能力（参照 Flutter State 设计）。
///
/// 三种类型的 PaintObject 共享同一套生命周期词汇；存活差异由 [keepAlive] 决定。
abstract interface class IPaintLifecycle {
  /// mount 之后一次性初始化（几何尚未生效）。
  void initState();

  /// K 线依赖（spec.key）变化回调。
  void didChangeDependencies(KlineSpec oldSpec);

  /// 进入绘制树（几何首次有效）。
  void didAttach();

  /// 离开绘制树。
  void didDetach();

  /// 出树是否保活（不 dispose）。
  bool get keepAlive;
}

/// 业务指标绘制接口
///
/// 用于由业务数据或用户操作驱动的指标（Trade 等），不占 slot。
/// 这些指标的数据由业务逻辑提供，而非通过预计算获得。
abstract interface class IExternalPainter extends IPaintObject {
  /// 业务数据加载便捷入口。
  ///
  /// [initState] 默认调用它；复杂指标应优先 override 明确生命周期方法。
  void loadBusinessData();
}
