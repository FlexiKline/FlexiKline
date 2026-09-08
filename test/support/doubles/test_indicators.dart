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

/// 测试用 Indicator / PaintObject 子类（v2.2.0 三类型体系）
///
/// 提供 [CandleBaseIndicator]、[TimeBaseIndicator]、[DirectIndicator]、
/// [ComputedIndicator]、[ExternalIndicator] 的最小化实现，
/// 用于 [IndicatorPaintObjectManager] 的单元测试和属性测试。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';

// ---------------------------------------------------------------------------
// Candle
// ---------------------------------------------------------------------------

/// 测试用 [CandleBaseIndicator] 子类，支持自定义 height
class TestCandleIndicator extends CandleBaseIndicator {
  TestCandleIndicator({
    super.height = 300,
    super.horizontalGrid,
    super.verticalGrid,
    this.chartType = FlexiChartType.barSolid,
    this.hideMainIndicatorsInLineChartMode = false,
    this.visibleMinMaxFromData = false,
    this.paintMarker = false,
  }) : super(padding: EdgeInsets.zero);

  /// [CandleBasePaintObject.resolveChartType] 的返回值
  final FlexiChartType chartType;

  /// 线图模式下是否隐藏其余主区指标（内置 CandleIndicator 默认为 true）
  final bool hideMainIndicatorsInLineChartMode;

  /// [computeVisibleMinMax] 是否按内置蜡烛的口径从数据算可见区间。
  ///
  /// 默认 false（返回 null）：多数用例不关心 Y 轴映射，让区间保持 [MinMax.zero] 更省事。
  /// 需要断言价格→像素映射（如 Y 轴缩放）的用例置 true。
  final bool visibleMinMaxFromData;

  /// [PaintObject.paint] 是否落一笔可识别的记号（[TestCandlePaintObject.markerPath]）。
  ///
  /// 默认 false：蜡烛不画任何东西，按绘制产物断言的用例不必过滤它。断言 z 序的用例置 true，
  /// 「网格线在蜡烛之下」才有可观测的先后。
  final bool paintMarker;

  /// 最近一次创建的绘制对象
  TestCandlePaintObject? object;

  @override
  CandleBasePaintObject<CandleBaseIndicator> createPaintObject() {
    return object = TestCandlePaintObject();
  }
}

/// 可切换图表类型的蜡烛绘制对象，用于验证线图模式下的隐藏行为。
class TestCandlePaintObject extends CandleBasePaintObject<TestCandleIndicator> {
  /// [TestCandleIndicator.paintMarker] 开启时 [paint] 落下的记号。
  ///
  /// 取正方形而不是线段：网格线的包围盒一维为 0，用有面积的形状才能在绘制记录里一眼分开。
  static final Path markerPath = Path()..addRect(const Rect.fromLTWH(10, 10, 20, 20));

  /// 覆盖 indicator 的配置；为 null 时取 `indicator.chartType`。
  FlexiChartType? chartTypeOverride;

  /// [formatTicksValue] 每次收到的刻度值，按绘制顺序。
  ///
  /// 这是观测 `paintYAxisTicks` 内部 `dyToValue(check: false)` 产物的唯一途径：文本一旦交给
  /// `Paragraph` 就读不回来了，而钩子拿到的正是即将被格式化的那个值。
  final List<FlexiNum> formattedTickValues = [];

  @override
  FlexiChartType resolveChartType() => chartTypeOverride ?? indicator.chartType;
  @override
  bool get hideMainIndicatorsInLineChartMode => indicator.hideMainIndicatorsInLineChartMode;
  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    if (!indicator.visibleMinMaxFromData) return null;
    if (!klineData.canPaintChart) return null;
    return klineData.calculateMinmax(start, end);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (indicator.paintMarker) canvas.drawPath(markerPath, Paint());
  }

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;

  @override
  String formatTicksValue(FlexiNum value, {required int precision}) {
    formattedTickValues.add(value);
    return super.formatTicksValue(value, precision: precision);
  }

  // ---- PaintGridTicksMixin 的算位置能力对用例开放 ----
  //
  // mixin 里三个 resolve 都是 @protected: 它们服务实现者, 不是公开 API。用例要直接断言位置,
  // 只能经子类转发 —— 从 canvas 记录读回来的坐标是 float32, 带 1e-6 相对噪声, 做不了
  // 「反算值与算法原值逐位相同」这类断言。

  List<double> horizontalDysOf(GridTickMode mode, {Rect? bounds}) {
    return resolveHorizontalDys(mode, bounds: bounds);
  }

  List<double> verticalDxsOf(GridTickMode mode, {Rect? bounds}) {
    return resolveVerticalDxs(mode, bounds: bounds);
  }
}

// ---------------------------------------------------------------------------
// Time
// ---------------------------------------------------------------------------

/// 测试用 [TimeBaseIndicator] 子类，支持自定义 height
class TestTimeIndicator extends TimeBaseIndicator {
  TestTimeIndicator({
    super.height = 20,
  }) : super(padding: EdgeInsets.zero, position: DrawPosition.middle);

  @override
  TimeBasePaintObject<TimeBaseIndicator> createPaintObject() => _TestTimePaintObject();
}

class _TestTimePaintObject extends TimeBasePaintObject<TestTimeIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

// ---------------------------------------------------------------------------
// Direct
// ---------------------------------------------------------------------------

/// 测试用 [DirectIndicator] 子类，支持自定义 key 和 height
class TestDirectIndicator extends DirectIndicator {
  TestDirectIndicator({
    required super.key,
    super.height = 100,
    super.autoActivate = false,
    this.tipsHeight = 0,
  }) : super(padding: EdgeInsets.zero);

  /// [PaintObject.paintTips] 返回的 tips 行高；0 表示不绘制 tips（返回 null）。
  ///
  /// 取固定值，便于对主区 tips 撑高后的 padding 断言精确值。
  final double tipsHeight;

  @override
  DirectPaintObject<DirectIndicator> createPaintObject() => _TestDirectPaintObject();
}

class _TestDirectPaintObject extends DirectPaintObject<TestDirectIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) {
    final height = indicator.tipsHeight;
    return height > 0 ? Size(tipsRect?.width ?? 0, height) : null;
  }
}

// ---------------------------------------------------------------------------
// Range（可观察 minMax）
// ---------------------------------------------------------------------------

/// 测试用主区子指标：返回随可见区间变化的 [MinMax]，并记录 [computeVisibleMinMax] 的调用。
///
/// 返回值由 `start` / `end` 派生，所以「自动跟随可见数据」与「被下发覆盖」在断言上可区分：
/// 前者随可见区间变化，后者恒等于下发值。用 [paintMode] 区分 combine 与 alone 两类子对象。
class TestRangeIndicator extends DirectIndicator {
  TestRangeIndicator({
    required super.key,
    super.height = 100,
    super.autoActivate = false,
    super.paintMode,
  }) : super(padding: EdgeInsets.zero);

  /// 最近一次创建的绘制对象
  TestRangePaintObject? object;

  @override
  DirectPaintObject<DirectIndicator> createPaintObject() => object = TestRangePaintObject();
}

/// [TestRangeIndicator] 的绘制对象：可见区间与调用次数都可断言。
class TestRangePaintObject extends DirectPaintObject<TestRangeIndicator> {
  /// [computeVisibleMinMax] 的调用次数。
  int computeCount = 0;

  /// 最近一次 [computeVisibleMinMax] 收到的可见区间。
  int? lastStart;
  int? lastEnd;

  /// 由 `start` / `end` 派生的区间：min 取 start，max 取 end * 10。
  static MinMax rangeOf(int start, int end) => MinMax(
        max: FlexiNum.fromNum(end * 10),
        min: FlexiNum.fromNum(start),
      );

  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    computeCount++;
    lastStart = start;
    lastEnd = end;
    return rangeOf(start, end);
  }

  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

// ---------------------------------------------------------------------------
// Computed
// ---------------------------------------------------------------------------

/// 测试用 [ComputedIndicator] 子类，支持自定义 key、height 和 param
class TestComputedIndicator extends ComputedIndicator {
  TestComputedIndicator({
    required super.key,
    super.height = 100,
    super.autoActivate = false,
    this.param,
  }) : super(padding: EdgeInsets.zero);

  /// 可选计算参数，暴露给 [calcParam] getter
  final dynamic param;

  @override
  dynamic get calcParam => param;

  @override
  ComputedPaintObject<ComputedIndicator> createPaintObject() => _TestComputedPaintObject();

  @override
  IndicatorCalculator createCalculator(int dataIndex) => _TestComputedCalculator(this, dataIndex);
}

class _TestComputedCalculator extends IndicatorCalculator<TestComputedIndicator> {
  _TestComputedCalculator(super.indicator, super.dataIndex);
  @override
  void compute(KlineData data, Range range, {bool reset = false}) {}
}

class _TestComputedPaintObject extends ComputedPaintObject<TestComputedIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

// ---------------------------------------------------------------------------
// External
// ---------------------------------------------------------------------------

/// 测试用 [ExternalIndicator] 子类，支持自定义 key 和 height
class TestExternalIndicator extends ExternalIndicator {
  TestExternalIndicator({
    required super.key,
    super.height = 80,
    super.autoActivate = true,
  }) : super(padding: EdgeInsets.zero);

  @override
  ExternalPaintObject<ExternalIndicator> createPaintObject() => _TestExternalPaintObject();
}

class _TestExternalPaintObject extends ExternalPaintObject<TestExternalIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

// ---------------------------------------------------------------------------
// Interactive（选中 / 拖动）
// ---------------------------------------------------------------------------

/// 测试用可交互 [ExternalIndicator]：驱动 selection 与 drag 的分发测试。
///
/// [createPaintObject] 会把创建出的对象记在 [object] 上，测试据此取到实例，
/// 无需为此在生产代码上开放访问器。
class TestInteractiveIndicator extends ExternalIndicator {
  TestInteractiveIndicator({
    required super.key,
    super.height = 80,
    super.zIndex,
    super.autoActivate = true,
    this.hitRect = const Rect.fromLTRB(0, 0, 100, 100),
  }) : super(padding: EdgeInsets.zero);

  /// [handleTap] / [handleDragStart] 的命中区域
  final Rect hitRect;

  /// 最近一次创建的绘制对象
  TestInteractivePaintObject? object;

  @override
  TestInteractivePaintObject createPaintObject() {
    return object = TestInteractivePaintObject();
  }
}

/// [TestInteractiveIndicator] 的绘制对象：记录回调序列供断言。
class TestInteractivePaintObject extends ExternalPaintObject<TestInteractiveIndicator> {
  /// 是否认领拖动；置 false 可模拟「按在选中对象上但不接受拖动」
  bool acceptDrag = true;

  /// 命中时是否消费点击。
  bool acceptTap = true;

  /// 按调用顺序记录的回调名
  final List<String> calls = [];

  /// 最近一次 [handleDragStart] 的命中位置
  Offset? lastDragStartPosition;

  /// 最近一次 [handleDragUpdate] 的参数
  Offset? lastDragPosition;
  Offset? lastDragDelta;

  /// 本轮拖动累计的 delta, 每次 [handleDragStart] 归零。
  ///
  /// 与 PointerMove 分几段派发无关, 用于校验手势识别前的位移没有丢。
  Offset totalDragDelta = Offset.zero;

  /// [hitTestDragStart] 被询问的次数。
  ///
  /// 刻意不进 [calls]: 该方法必须无副作用, 用独立计数器才能同时断言
  /// "被询问过"与"没有产生任何拖动回调"。
  int hitTestDragStartCount = 0;

  @override
  bool handleTap(Offset position) {
    if (!indicator.hitRect.contains(position)) return false;
    calls.add('tap');
    return acceptTap;
  }

  @override
  bool hitTestDragStart(Offset position) {
    hitTestDragStartCount++;
    // 判据与 [handleDragStart] 同源, 但不改任何状态。
    return acceptDrag && indicator.hitRect.contains(position);
  }

  @override
  bool handleDragStart(Offset position) {
    if (!acceptDrag || !indicator.hitRect.contains(position)) return false;
    calls.add('dragStart');
    lastDragStartPosition = position;
    totalDragDelta = Offset.zero;
    return true;
  }

  @override
  void handleDragUpdate(Offset position, Offset delta) {
    calls.add('dragUpdate');
    lastDragPosition = position;
    lastDragDelta = delta;
    totalDragDelta += delta;
  }

  @override
  void handleDragEnd() => calls.add('dragEnd');

  @override
  void handleDragCancel() => calls.add('dragCancel');

  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}
