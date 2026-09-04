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
