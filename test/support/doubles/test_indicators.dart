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
    this.chartType = FlexiChartType.barSolid,
    this.hideMainIndicatorsInLineChartMode = false,
  }) : super(padding: EdgeInsets.zero);

  /// [CandleBasePaintObject.resolveChartType] 的返回值
  final FlexiChartType chartType;

  /// 线图模式下是否隐藏其余主区指标（内置 CandleIndicator 默认为 true）
  final bool hideMainIndicatorsInLineChartMode;

  /// 最近一次创建的绘制对象
  TestCandlePaintObject? object;

  @override
  CandleBasePaintObject<CandleBaseIndicator> createPaintObject() {
    return object = TestCandlePaintObject();
  }
}

/// 可切换图表类型的蜡烛绘制对象，用于验证线图模式下的隐藏行为。
class TestCandlePaintObject extends CandleBasePaintObject<TestCandleIndicator> {
  /// 覆盖 indicator 的配置；为 null 时取 `indicator.chartType`。
  FlexiChartType? chartTypeOverride;

  @override
  FlexiChartType resolveChartType() => chartTypeOverride ?? indicator.chartType;
  @override
  bool get hideMainIndicatorsInLineChartMode => indicator.hideMainIndicatorsInLineChartMode;
  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
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
  }) : super(padding: EdgeInsets.zero);

  @override
  DirectPaintObject<DirectIndicator> createPaintObject() => _TestDirectPaintObject();
}

class _TestDirectPaintObject extends DirectPaintObject<TestDirectIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
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

  /// 首次命中时返回的结果。
  ///
  /// 默认请求选中；置为 [PaintTapResult.handled] 可模拟「仅处理点击、
  /// 不需要选中态」的指标（如 crossing 中的下单按钮）。
  PaintTapResult tapResult = PaintTapResult.selected;

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

  @override
  PaintTapResult handleTap(Offset position) {
    if (!indicator.hitRect.contains(position)) return PaintTapResult.ignored;
    calls.add('tap');
    // 二次点击同一对象 => 消费点击但放弃选中态, 由框架清除。
    if (isSelected) return PaintTapResult.handled;
    return tapResult;
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
